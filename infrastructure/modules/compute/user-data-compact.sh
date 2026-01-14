#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== UCEHub Deployment v2 - Compact ==="
yum update -y
yum install -y nodejs npm nginx git

# Backend
mkdir -p /opt/backend && cd /opt/backend
cat > package.json << 'EOF'
{"name":"ucehub","version":"2.0.0","dependencies":{"express":"^4.18.2","body-parser":"^1.20.2","cors":"^2.8.5","@aws-sdk/client-dynamodb":"^3.490.0","@aws-sdk/lib-dynamodb":"^3.490.0","uuid":"^9.0.1"}}
EOF

# Backend code - Compressed
cat > index.js << 'EOF'
const express=require('express'),bodyParser=require('body-parser'),cors=require('cors'),os=require('os'),{DynamoDBClient}=require('@aws-sdk/client-dynamodb'),{DynamoDBDocumentClient,PutCommand,QueryCommand}=require('@aws-sdk/lib-dynamodb'),{v4:uuidv4}=require('uuid'),app=express();app.use(cors({origin:'*'}));app.use(bodyParser.json());const client=new DynamoDBClient({region:process.env.AWS_REGION||'us-east-1'}),ddb=DynamoDBDocumentClient.from(client),CAFETERIA_TABLE=process.env.CAFETERIA_TABLE||'',SUPPORT_TABLE=process.env.SUPPORT_TICKETS_TABLE||'',getIP=()=>{const ifaces=os.networkInterfaces();for(let iface of Object.values(ifaces))for(let addr of iface)if(addr.family==='IPv4'&&!addr.internal)return addr.address;return'unknown'},instanceIP=getIP();app.get('/health',(req,res)=>res.json({status:'healthy',service:'ucehub',instance:instanceIP,uptime:process.uptime(),tables:{cafeteria:CAFETERIA_TABLE,support:SUPPORT_TABLE}}));app.get('/',(req,res)=>res.json({message:'UCEHub API v2',instance:instanceIP}));app.post('/auth/login',(req,res)=>res.json({success:true,token:'jwt-'+uuidv4(),user:{id:uuidv4(),username:req.body.username||'test',email:(req.body.username||'test')+'@uce.edu.ec',role:'student'},instance:instanceIP}));app.post('/certificados/solicitar',(req,res)=>res.json({success:true,message:'Certificado solicitado',data:{certificateId:'CERT-'+uuidv4(),userEmail:req.body.userEmail||'student@uce.edu.ec',tipo:req.body.tipo||'Matricula',estado:'Solicitado',timestamp:Date.now()},instance:instanceIP}));app.post('/biblioteca/reservar',(req,res)=>res.json({success:true,message:'Reserva confirmada',data:{reservationId:'RES-'+uuidv4(),userEmail:req.body.userEmail||'student@uce.edu.ec',recurso:req.body.recurso||'Sala de estudio',fecha:req.body.fecha||new Date().toISOString().split('T')[0],estado:'Confirmado',timestamp:Date.now()},instance:instanceIP}));app.post('/becas/solicitar',(req,res)=>res.json({success:true,message:'Beca solicitada',data:{applicationId:'BECA-'+uuidv4(),userEmail:req.body.userEmail||'student@uce.edu.ec',tipoBeca:req.body.tipoBeca||'Socioeconómica',estado:'En revisión',timestamp:Date.now()},instance:instanceIP}));app.post('/soporte/ticket',async(req,res)=>{try{const ticket={ticketId:'TICKET-'+uuidv4(),userEmail:req.body.userEmail||'student@uce.edu.ec',asunto:req.body.asunto||'Consulta',descripcion:req.body.descripcion||'',prioridad:req.body.prioridad||'Media',status:'Abierto',createdAt:Date.now(),updatedAt:Date.now()};await ddb.send(new PutCommand({TableName:SUPPORT_TABLE,Item:ticket}));res.json({success:true,message:'Ticket creado',data:ticket,instance:instanceIP})}catch(e){res.status(500).json({success:false,message:e.message})}});app.get('/soporte/tickets',async(req,res)=>{try{const result=await ddb.send(new QueryCommand({TableName:SUPPORT_TABLE,IndexName:'UserEmailIndex',KeyConditionExpression:'userEmail = :email',ExpressionAttributeValues:{':email':req.query.email||'student@uce.edu.ec'},Limit:10}));res.json({success:true,tickets:result.Items||[],count:result.Count,instance:instanceIP})}catch(e){res.status(500).json({success:false,message:e.message})}});app.post('/cafeteria/order',async(req,res)=>{try{const order={orderId:'ORDER-'+uuidv4(),userEmail:req.body.userEmail||'student@uce.edu.ec',items:req.body.items||[{name:'Menu del día',quantity:1,price:3.50}],total:req.body.total||3.50,status:'Pendiente',timestamp:Date.now(),expirationTime:Math.floor(Date.now()/1000)+(30*24*60*60)};await ddb.send(new PutCommand({TableName:CAFETERIA_TABLE,Item:order}));res.json({success:true,message:'Pedido registrado',data:order,instance:instanceIP})}catch(e){res.status(500).json({success:false,message:e.message})}});app.get('/cafeteria/orders',async(req,res)=>{try{const result=await ddb.send(new QueryCommand({TableName:CAFETERIA_TABLE,IndexName:'UserEmailIndex',KeyConditionExpression:'userEmail = :email',ExpressionAttributeValues:{':email':req.query.email||'student@uce.edu.ec'},Limit:10}));res.json({success:true,orders:result.Items||[],count:result.Count,instance:instanceIP})}catch(e){res.status(500).json({success:false,message:e.message})}});app.listen(3001,'127.0.0.1',()=>console.log('UCEHub Backend v2 running on port 3001'));
EOF

npm install

# Systemd service
cat > /etc/systemd/system/ucehub-backend.service << EOF
[Unit]
Description=UCEHub Backend
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/opt/backend
Environment="AWS_REGION=${region}"
Environment="CAFETERIA_TABLE=${cafeteria_table}"
Environment="SUPPORT_TICKETS_TABLE=${support_table}"
Environment="ABSENCE_JUSTIFICATIONS_TABLE=${absence_table}"
ExecStart=/usr/bin/node /opt/backend/index.js
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ucehub-backend
systemctl start ucehub-backend

# Frontend - Download from GitHub gist or create minimal
mkdir -p /opt/frontend/dist && cd /opt/frontend/dist
cat > index.html << 'EOF'
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>UCEHub</title><style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:'Segoe UI',sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;display:flex;flex-direction:column}.header{background:rgba(255,255,255,.95);padding:1rem 2rem;box-shadow:0 2px 10px rgba(0,0,0,.1)}.header h1{color:#667eea;font-size:2rem}.container{flex:1;max-width:1200px;margin:2rem auto;padding:0 2rem;width:100%}.welcome-card{background:#fff;border-radius:15px;padding:3rem;box-shadow:0 10px 30px rgba(0,0,0,.2);text-align:center;margin-bottom:2rem}.welcome-card h2{color:#333;font-size:2.5rem;margin-bottom:1rem}.services-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:1.5rem;margin-top:2rem}.service-card{background:#fff;border-radius:10px;padding:2rem;box-shadow:0 5px 15px rgba(0,0,0,.1);transition:transform .3s,box-shadow .3s;cursor:pointer;text-align:center}.service-card:hover{transform:translateY(-5px);box-shadow:0 10px 25px rgba(0,0,0,.2)}.service-icon{font-size:3rem;margin-bottom:1rem}.service-card h3{color:#667eea;font-size:1.3rem;margin-bottom:.5rem}.footer{background:rgba(0,0,0,.2);color:#fff;text-align:center;padding:1rem;margin-top:auto}</style></head><body><div class="header"><h1>🎓 UCEHub</h1><p>Universidad Central del Ecuador</p></div><div class="container"><div class="welcome-card"><h2>¡Bienvenido a UCEHub!</h2><p>Portal Universitario con DynamoDB</p></div><div class="services-grid"><div class="service-card" onclick="t('auth')"><div class="service-icon">🔐</div><h3>Autenticación</h3></div><div class="service-card" onclick="t('cert')"><div class="service-icon">📜</div><h3>Certificados</h3></div><div class="service-card" onclick="t('bib')"><div class="service-icon">📚</div><h3>Biblioteca</h3></div><div class="service-card" onclick="t('beca')"><div class="service-icon">💰</div><h3>Becas</h3></div><div class="service-card" onclick="t('soporte')"><div class="service-icon">🎫</div><h3>Soporte (DB)</h3></div><div class="service-card" onclick="t('cafe')"><div class="service-icon">🍽️</div><h3>Cafetería (DB)</h3></div></div></div><div class="footer"><p>&copy; 2026 UCE | UCEHub v2.0 - DynamoDB</p></div><script>const e='student@uce.edu.ec';async function t(s){const ep={auth:'/api/auth/login',cert:'/api/certificados/solicitar',bib:'/api/biblioteca/reservar',beca:'/api/becas/solicitar',soporte:'/api/soporte/ticket',cafe:'/api/cafeteria/order'};try{const r=await fetch(ep[s],{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({userEmail:e,username:'Juan Perez',password:'test',tipo:'Matricula',recurso:'Sala',tipoBeca:'Socioeconómica',asunto:'Consulta',descripcion:'Test',prioridad:'Media',items:[{name:'Menu',quantity:1,price:3.5}],total:3.5})});const d=await r.json();alert('✅ '+s.toUpperCase()+'\n\n'+JSON.stringify(d,null,2))}catch(er){alert('❌ Error: '+er.message)}}</script></body></html>
EOF

# Nginx
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;worker_processes auto;error_log /var/log/nginx/error.log;pid /run/nginx.pid;events{worker_connections 1024;}http{log_format main '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent';access_log /var/log/nginx/access.log main;sendfile on;tcp_nopush on;keepalive_timeout 65;types_hash_max_size 4096;include /etc/nginx/mime.types;default_type application/octet-stream;server{listen 80 default_server;server_name _;root /opt/frontend/dist;index index.html;location /health{proxy_pass http://127.0.0.1:3001/health;proxy_set_header Host $host;}location /api/{rewrite ^/api/(.*) /$1 break;proxy_pass http://127.0.0.1:3001;proxy_set_header Host $host;}location /{try_files $uri $uri/ /index.html;}}}
EOF

systemctl restart nginx
systemctl enable nginx

echo "=== Deployment Complete ==="
systemctl status ucehub-backend --no-pager | head -10
systemctl status nginx --no-pager | head -5
