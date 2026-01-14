#!/bin/bash
set -e

# Variables desde Terraform
REGION="${aws_region}"
CAFE_TABLE="${cafeteria_table}"
SUPPORT_TABLE="${support_table}"
TEAMS_WEBHOOK="${teams_webhook_url}"

# Actualizar sistema
yum update -y
yum install -y nodejs npm nginx

# Backend Node.js
mkdir -p /opt/backend && cd /opt/backend
cat > package.json << 'PKG'
{"name":"ucehub","version":"1.0.0","dependencies":{"express":"^4.18.2","@aws-sdk/client-dynamodb":"^3.460.0","@aws-sdk/lib-dynamodb":"^3.460.0","uuid":"^9.0.1"}}
PKG

npm install

cat > server.js << 'SERV'
const express=require('express'),{DynamoDBClient}=require('@aws-sdk/client-dynamodb'),{DynamoDBDocumentClient,PutCommand}=require('@aws-sdk/lib-dynamodb'),{v4:uuid}=require('uuid'),https=require('https');
const app=express(),client=new DynamoDBClient({region:process.env.AWS_REGION}),ddb=DynamoDBDocumentClient.from(client);
app.use(express.json());

app.get('/health',(q,s)=>s.json({status:'ok',time:new Date().toISOString()}));

app.post('/certificados/solicitar',async(q,s)=>{
try{
const id=uuid(),data={certificateId:id,userEmail:q.body.userEmail,tipo:q.body.tipo,motivo:q.body.motivo||'',estado:'Pendiente',timestamp:Date.now()};
await sendTeams('📜 Nuevo Certificado','Usuario: '+data.userEmail+'\nTipo: '+data.tipo+'\nMotivo: '+data.motivo);
s.json({success:true,message:'Certificado solicitado',data});
}catch(e){s.status(500).json({error:e.message})}});

app.post('/soporte/ticket',async(q,s)=>{
try{
const id=uuid(),item={ticketId:id,userEmail:q.body.userEmail,asunto:q.body.asunto,descripcion:q.body.descripcion,prioridad:q.body.prioridad||'Media',status:'Abierto',timestamp:Date.now()};
await ddb.send(new PutCommand({TableName:process.env.SUPPORT_TABLE,Item:item}));
s.json({success:true,message:'Ticket guardado en DynamoDB',data:item});
}catch(e){s.status(500).json({error:e.message})}});

app.post('/cafeteria/order',async(q,s)=>{
try{
const id=uuid(),item={orderId:id,userEmail:q.body.userEmail,items:q.body.items,total:q.body.total,notas:q.body.notas||'',status:'Pendiente',timestamp:Date.now()};
await ddb.send(new PutCommand({TableName:process.env.CAFE_TABLE,Item:item}));
s.json({success:true,message:'Pedido guardado en DynamoDB',data:item});
}catch(e){s.status(500).json({error:e.message})}});

function sendTeams(title,text){
return new Promise((ok,fail)=>{
const u=new URL(process.env.TEAMS_WEBHOOK),body=JSON.stringify({type:'message',attachments:[{contentType:'application/vnd.microsoft.card.adaptive',content:{type:'AdaptiveCard',version:'1.4',body:[{type:'TextBlock',text:title,weight:'Bolder',size:'Large'},{type:'TextBlock',text:text,wrap:true}]}}]});
const req=https.request({hostname:u.hostname,path:u.pathname+u.search,method:'POST',headers:{'Content-Type':'application/json','Content-Length':body.length}},r=>{r.statusCode===200?ok():fail(new Error('Teams failed'))});
req.on('error',fail);
req.write(body);
req.end();
});}

app.listen(3001,'127.0.0.1',()=>console.log('Backend on 3001'));
SERV

cat > /etc/systemd/system/ucehub.service << 'SVC'
[Unit]
Description=UCEHub Backend
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/opt/backend
Environment="AWS_REGION=REGION_PLACEHOLDER"
Environment="CAFE_TABLE=CAFE_PLACEHOLDER"
Environment="SUPPORT_TABLE=SUPPORT_PLACEHOLDER"
Environment="TEAMS_WEBHOOK=TEAMS_PLACEHOLDER"
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
SVC

sed -i "s|REGION_PLACEHOLDER|$REGION|g" /etc/systemd/system/ucehub.service
sed -i "s|CAFE_PLACEHOLDER|$CAFE_TABLE|g" /etc/systemd/system/ucehub.service
sed -i "s|SUPPORT_PLACEHOLDER|$SUPPORT_TABLE|g" /etc/systemd/system/ucehub.service
sed -i "s|TEAMS_PLACEHOLDER|$TEAMS_WEBHOOK|g" /etc/systemd/system/ucehub.service

systemctl daemon-reload
systemctl enable ucehub
systemctl start ucehub

# Nginx
cat > /etc/nginx/nginx.conf << 'NGX'
user nginx;worker_processes auto;error_log /var/log/nginx/error.log;pid /run/nginx.pid;
events{worker_connections 1024;}
http{
include /etc/nginx/mime.types;default_type application/octet-stream;
server{
listen 80;server_name _;
location /{root /opt/frontend/dist;index index.html;try_files $uri $uri/ /index.html;}
location /api/{proxy_pass http://127.0.0.1:3001;proxy_set_header Host $host;}
}}
NGX

# Frontend
mkdir -p /opt/frontend/dist && cd /opt/frontend/dist
cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>UCEHub - 3 Servicios</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Arial,sans-serif;background:linear-gradient(135deg,#667eea,#764ba2);min-height:100vh;padding:20px}
.container{max-width:1000px;margin:0 auto}
h1{color:#fff;text-align:center;margin-bottom:30px;font-size:2.5rem}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:20px}
.card{background:#fff;border-radius:10px;padding:20px;box-shadow:0 5px 15px rgba(0,0,0,.3);cursor:pointer;transition:.3s}
.card:hover{transform:translateY(-5px)}
.icon{font-size:3rem;text-align:center;margin-bottom:10px}
.card h3{color:#667eea;text-align:center;font-size:1.3rem}
.modal{display:none;position:fixed;z-index:999;left:0;top:0;width:100%;height:100%;background:rgba(0,0,0,.7);padding:20px}
.modal-content{background:#fff;margin:50px auto;padding:30px;border-radius:10px;max-width:500px;position:relative}
.close{position:absolute;right:15px;top:10px;font-size:28px;cursor:pointer;color:#999}
.close:hover{color:#000}
input,select,textarea{width:100%;padding:10px;margin:8px 0;border:1px solid #ddd;border-radius:5px;font-size:1rem}
textarea{min-height:80px;resize:vertical}
button{width:100%;background:#667eea;color:#fff;padding:12px;border:none;border-radius:5px;font-size:1.1rem;cursor:pointer;margin-top:10px}
button:hover{background:#5568d3}
.result{margin-top:15px;padding:15px;border-radius:5px;background:#f0f0f0}
</style>
</head>
<body>
<div class="container">
<h1>🎓 UCEHub - Portal Universitario</h1>
<div class="grid">
<div class="card" onclick="openModal('cert')">
<div class="icon">📜</div>
<h3>Certificados</h3>
<p style="text-align:center;color:#666;margin-top:5px">Solicita certificados académicos</p>
</div>
<div class="card" onclick="openModal('support')">
<div class="icon">🎫</div>
<h3>Soporte Técnico</h3>
<p style="text-align:center;color:#666;margin-top:5px">Crea tickets con DynamoDB</p>
</div>
<div class="card" onclick="openModal('cafe')">
<div class="icon">🍽️</div>
<h3>Cafetería</h3>
<p style="text-align:center;color:#666;margin-top:5px">Realiza pedidos con DynamoDB</p>
</div>
</div>
</div>

<div id="modal" class="modal">
<div class="modal-content">
<span class="close" onclick="closeModal()">&times;</span>
<div id="modalBody"></div>
</div>
</div>

<script>
function openModal(type){
const forms={
cert:'<h2>📜 Solicitar Certificado</h2><input id="email" placeholder="Email" value="student@uce.edu.ec"><select id="tipo"><option>Certificado de Matrícula</option><option>Certificado de Notas</option><option>Certificado de Conducta</option></select><textarea id="motivo" placeholder="Motivo de la solicitud"></textarea><button onclick="submitCert()">Solicitar</button><div id="result"></div>',
support:'<h2>🎫 Ticket de Soporte</h2><input id="email" placeholder="Email" value="student@uce.edu.ec"><input id="asunto" placeholder="Asunto del ticket"><textarea id="desc" placeholder="Descripción del problema"></textarea><select id="prior"><option>Baja</option><option selected>Media</option><option>Alta</option></select><button onclick="submitSupport()">Crear Ticket</button><div id="result"></div>',
cafe:'<h2>🍽️ Pedido de Cafetería</h2><input id="email" placeholder="Email" value="student@uce.edu.ec"><select id="item"><option value="3.50">Menú del día - $3.50</option><option value="4.00">Almuerzo ejecutivo - $4.00</option><option value="2.50">Sándwich - $2.50</option><option value="1.50">Jugo natural - $1.50</option></select><textarea id="notas" placeholder="Notas adicionales (opcional)"></textarea><button onclick="submitCafe()">Realizar Pedido</button><div id="result"></div>'
};
document.getElementById('modalBody').innerHTML=forms[type];
document.getElementById('modal').style.display='block';
}

function closeModal(){
document.getElementById('modal').style.display='none';
}

async function submitCert(){
const email=document.getElementById('email').value;
const tipo=document.getElementById('tipo').value;
const motivo=document.getElementById('motivo').value;
const res=document.getElementById('result');
if(!email||!tipo){res.innerHTML='<p style="color:red">Complete los campos obligatorios</p>';return;}
res.innerHTML='<p style="color:blue">Enviando...</p>';
try{
const r=await fetch('/api/certificados/solicitar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({userEmail:email,tipo:tipo,motivo:motivo})});
const d=await r.json();
if(d.success){
res.innerHTML='<div class="result" style="background:#d4edda;color:#155724"><strong>✅ Certificado Solicitado</strong><br>ID: '+d.data.certificateId+'<br>Tipo: '+d.data.tipo+'<br>Estado: '+d.data.estado+'<br><small>Notificación enviada a Teams</small></div>';
}else{
res.innerHTML='<p style="color:red">Error: '+d.error+'</p>';
}
}catch(e){
res.innerHTML='<p style="color:red">Error de conexión: '+e.message+'</p>';
}
}

async function submitSupport(){
const email=document.getElementById('email').value;
const asunto=document.getElementById('asunto').value;
const desc=document.getElementById('desc').value;
const prior=document.getElementById('prior').value;
const res=document.getElementById('result');
if(!email||!asunto||!desc){res.innerHTML='<p style="color:red">Complete los campos obligatorios</p>';return;}
res.innerHTML='<p style="color:blue">Guardando en DynamoDB...</p>';
try{
const r=await fetch('/api/soporte/ticket',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({userEmail:email,asunto:asunto,descripcion:desc,prioridad:prior})});
const d=await r.json();
if(d.success){
res.innerHTML='<div class="result" style="background:#d4edda;color:#155724"><strong>✅ Ticket Guardado en DynamoDB</strong><br>ID: '+d.data.ticketId+'<br>Asunto: '+d.data.asunto+'<br>Prioridad: '+d.data.prioridad+'<br>Estado: '+d.data.status+'</div>';
}else{
res.innerHTML='<p style="color:red">Error: '+d.error+'</p>';
}
}catch(e){
res.innerHTML='<p style="color:red">Error de conexión: '+e.message+'</p>';
}
}

async function submitCafe(){
const email=document.getElementById('email').value;
const item=document.getElementById('item');
const itemText=item.options[item.selectedIndex].text;
const price=parseFloat(item.value);
const notas=document.getElementById('notas').value;
const res=document.getElementById('result');
if(!email){res.innerHTML='<p style="color:red">Ingrese su email</p>';return;}
res.innerHTML='<p style="color:blue">Guardando pedido en DynamoDB...</p>';
try{
const r=await fetch('/api/cafeteria/order',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({userEmail:email,items:[{name:itemText,quantity:1,price:price}],total:price,notas:notas})});
const d=await r.json();
if(d.success){
res.innerHTML='<div class="result" style="background:#d4edda;color:#155724"><strong>✅ Pedido Guardado en DynamoDB</strong><br>ID: '+d.data.orderId+'<br>Item: '+d.data.items[0].name+'<br>Total: $'+d.data.total+'<br>Estado: '+d.data.status+'</div>';
}else{
res.innerHTML='<p style="color:red">Error: '+d.error+'</p>';
}
}catch(e){
res.innerHTML='<p style="color:red">Error de conexión: '+e.message+'</p>';
}
}

window.onclick=function(e){
if(e.target==document.getElementById('modal'))closeModal();
}
</script>
</body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx

echo "Deployment complete"
