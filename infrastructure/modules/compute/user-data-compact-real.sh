#!/bin/bash
set -e

# UCEHub Compact Deployment - Downloads backend from repo
region="${aws_region}"
environment="${environment}"
project_name="${project_name}"
cafeteria_table="${cafeteria_table}"
support_table="${support_table}"
justifications_table="${justifications_table}"
documents_bucket="${documents_bucket}"
teams_webhook_url="${teams_webhook_url}"

echo "=========================================="
echo "UCEHub Compact Deployment"
echo "Environment: $environment"
echo "=========================================="

# Install required packages
yum update -y
yum install -y docker nodejs npm nginx git
systemctl enable docker
systemctl start docker
sleep 3

# ============================================================================
# BACKEND: Clone and Deploy Real Backend
# ============================================================================

echo "Setting up Backend from repository..."
mkdir -p /opt/ucehub
cd /opt/ucehub

# Create backend directly (optimized version)
mkdir -p backend
cd backend

cat > package.json <<'EOF'
{"name":"ucehub-backend","version":"3.0.0","main":"server.js","dependencies":{"express":"^4.18.2","cors":"^2.8.5","@aws-sdk/client-dynamodb":"^3.400.0","@aws-sdk/lib-dynamodb":"^3.400.0","@aws-sdk/client-s3":"^3.400.0","@aws-sdk/s3-request-presigner":"^3.400.0","uuid":"^9.0.0","axios":"^1.4.0"}}
EOF

# Download server-teams.js from your existing services folder or create optimized version
cat > server.js <<'BACKEND'
const express=require('express'),cors=require('cors'),{DynamoDBClient}=require('@aws-sdk/client-dynamodb'),{DynamoDBDocumentClient,PutCommand,ScanCommand}=require('@aws-sdk/lib-dynamodb'),{S3Client,PutObjectCommand,GetObjectCommand}=require('@aws-sdk/client-s3'),{getSignedUrl}=require('@aws-sdk/s3-request-presigner'),{v4:uuidv4}=require('uuid'),axios=require('axios'),app=express(),PORT=process.env.PORT||3001,region=process.env.AWS_REGION||'us-east-1',dynamoClient=new DynamoDBClient({region}),docClient=DynamoDBDocumentClient.from(dynamoClient),s3Client=new S3Client({region}),CAFETERIA_TABLE=process.env.CAFETERIA_TABLE,SUPPORT_TICKETS_TABLE=process.env.SUPPORT_TICKETS_TABLE,ABSENCE_JUSTIFICATIONS_TABLE=process.env.ABSENCE_JUSTIFICATIONS_TABLE,DOCUMENTS_BUCKET=process.env.DOCUMENTS_BUCKET,TEAMS_WEBHOOK_URL=process.env.TEAMS_WEBHOOK_URL||'';let instanceIP='unknown';try{instanceIP=require('child_process').execSync('ec2-metadata --local-ipv4').toString().split(':')[1].trim()}catch(e){console.log('Local mode')}app.use(cors()),app.use(express.json({limit:'10mb'}));async function sendTeams(title,msg,facts=[]){if(!TEAMS_WEBHOOK_URL)return console.log('Teams:',title,msg),!0;try{return await axios.post(TEAMS_WEBHOOK_URL,{"@type":"MessageCard","@context":"https://schema.org/extensions",summary:title,themeColor:"0078D7",title:title,text:msg,sections:facts.length>0?[{facts:facts}]:[]}),!0}catch(e){return console.error('Teams error:',e.message),!1}}app.get('/health',(req,res)=>res.json({status:'healthy',service:'ucehub-backend',instance:instanceIP,timestamp:new Date().toISOString(),config:{cafeteria_table:CAFETERIA_TABLE,support_table:SUPPORT_TICKETS_TABLE,justifications_table:ABSENCE_JUSTIFICATIONS_TABLE,documents_bucket:DOCUMENTS_BUCKET}})),app.get('/',(req,res)=>res.json({message:'UCEHub API v3.0',instance:instanceIP,endpoints:{cafeteria:['/cafeteria/menu','/cafeteria/order'],support:['/support/ticket','/support/tickets'],justifications:['/justifications/submit','/justifications/list']}})),app.get('/cafeteria/menu',async(req,res)=>{try{const menu=[{id:'1',name:'Almuerzo Ejecutivo',description:'Sopa + Seco + Jugo',price:3.5,category:'almuerzos',icon:'🍽️'},{id:'2',name:'Desayuno Continental',description:'Café + Pan + Huevos',price:2.5,category:'desayunos',icon:'🥐'},{id:'3',name:'Snack Saludable',description:'Frutas + Yogurt',price:2,category:'snacks',icon:'🥗'},{id:'4',name:'Bebida Caliente',description:'Café o Té',price:1,category:'bebidas',icon:'☕'},{id:'5',name:'Jugo Natural',description:'Naranja, Mora o Piña',price:1.5,category:'bebidas',icon:'🥤'}];res.json({success:!0,data:menu,instance:instanceIP})}catch(e){res.status(500).json({success:!1,message:'Error',error:e.message})}}),app.post('/cafeteria/order',async(req,res)=>{try{const{userName,userEmail,items,totalPrice,deliveryTime}=req.body,orderId=uuidv4(),order={orderId,userName,userEmail,items,totalPrice,deliveryTime,status:'pending',createdAt:new Date().toISOString(),instance:instanceIP};await docClient.send(new PutCommand({TableName:CAFETERIA_TABLE,Item:order})),await sendTeams('🍽️ Nueva Orden',`$${userName} realizó orden`,[{name:'Email',value:userEmail},{name:'Total',value:`$$${totalPrice.toFixed(2)}`},{name:'ID',value:orderId}]),res.json({success:!0,message:'Orden creada',data:{orderId,status:'pending'},instance:instanceIP})}catch(e){res.status(500).json({success:!1,message:'Error',error:e.message})}}),app.post('/support/ticket',async(req,res)=>{try{const{userName,userEmail,category,subject,description,priority}=req.body,ticketId=uuidv4(),ticket={ticketId,userName,userEmail,category,subject,description,priority:priority||'medium',status:'open',createdAt:new Date().toISOString(),instance:instanceIP};await docClient.send(new PutCommand({TableName:SUPPORT_TICKETS_TABLE,Item:ticket})),await sendTeams('🎫 Nuevo Ticket',`$${userName} creó ticket`,[{name:'Email',value:userEmail},{name:'Asunto',value:subject},{name:'ID',value:ticketId}]),res.json({success:!0,message:'Ticket creado',data:{ticketId,status:'open'},instance:instanceIP})}catch(e){res.status(500).json({success:!1,message:'Error',error:e.message})}}),app.get('/support/tickets',async(req,res)=>{try{const result=await docClient.send(new ScanCommand({TableName:SUPPORT_TICKETS_TABLE,Limit:50}));res.json({success:!0,data:result.Items||[],count:result.Items?.length||0,instance:instanceIP})}catch(e){res.status(500).json({success:!1,message:'Error',error:e.message})}}),app.post('/justifications/submit',async(req,res)=>{try{const{userName,userEmail,studentId,reason,date,documentBase64,documentName}=req.body,justificationId=uuidv4();let documentUrl=null;if(documentBase64&&documentName){const key=`justifications/$${justificationId}/$${documentName}`,buffer=Buffer.from(documentBase64,'base64');await s3Client.send(new PutObjectCommand({Bucket:DOCUMENTS_BUCKET,Key:key,Body:buffer,ContentType:'application/pdf'})),documentUrl=await getSignedUrl(s3Client,new GetObjectCommand({Bucket:DOCUMENTS_BUCKET,Key:key}),{expiresIn:604800})}const justification={justificationId,userName,userEmail,studentId,reason,date,documentUrl,status:'pending',createdAt:new Date().toISOString(),instance:instanceIP};await docClient.send(new PutCommand({TableName:ABSENCE_JUSTIFICATIONS_TABLE,Item:justification})),await sendTeams('📜 Nueva Justificación',`$${userName} envió justificación`,[{name:'Estudiante',value:studentId},{name:'Fecha',value:date},{name:'ID',value:justificationId}]),res.json({success:!0,message:'Justificación enviada',data:{justificationId,status:'pending',documentUrl},instance:instanceIP})}catch(e){res.status(500).json({success:!1,message:'Error',error:e.message})}}),app.get('/justifications/list',async(req,res)=>{try{const result=await docClient.send(new ScanCommand({TableName:ABSENCE_JUSTIFICATIONS_TABLE,Limit:50}));res.json({success:!0,data:result.Items||[],count:result.Items?.length||0,instance:instanceIP})}catch(e){res.status(500).json({success:!1,message:'Error',error:e.message})}}),app.listen(PORT,'127.0.0.1',()=>{console.log('='.repeat(40)),console.log(`✅ Backend running on http://127.0.0.1:$${PORT}`),console.log('Instance:',instanceIP),console.log('='.repeat(40))});
BACKEND

npm install --production

cat > Dockerfile <<'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY server.js ./
EXPOSE 3001
CMD ["node","server.js"]
EOF

docker build -t ucehub-backend .
docker stop ucehub-backend 2>/dev/null || true
docker rm ucehub-backend 2>/dev/null || true
docker run -d --name ucehub-backend --restart unless-stopped -p 127.0.0.1:3001:3001 \
  -e PORT=3001 -e AWS_REGION="$region" \
  -e CAFETERIA_TABLE="$cafeteria_table" \
  -e SUPPORT_TICKETS_TABLE="$support_table" \
  -e ABSENCE_JUSTIFICATIONS_TABLE="$justifications_table" \
  -e DOCUMENTS_BUCKET="$documents_bucket" \
  -e TEAMS_WEBHOOK_URL="$teams_webhook_url" \
  ucehub-backend

# ============================================================================
# FRONTEND: Download from S3
# ============================================================================

echo "Downloading frontend..."
mkdir -p /opt/frontend/dist
FRONTEND_BUCKET="ucehub-frontend-5095"
if aws s3 ls "s3://$FRONTEND_BUCKET" 2>/dev/null; then
  aws s3 sync "s3://$FRONTEND_BUCKET/" /opt/frontend/dist/ --region us-east-1 --delete
else
  echo '<html><body><h1>UCEHub</h1><p>Backend Ready. Build frontend: scripts/build-and-upload-frontend.ps1</p></body></html>' > /opt/frontend/dist/index.html
fi

# ============================================================================
# NGINX: Configure
# ============================================================================

cat > /etc/nginx/nginx.conf <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
events{worker_connections 1024;}
http{
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  sendfile on;
  keepalive_timeout 65;
  client_max_body_size 20M;
  server{
    listen 80 default_server;
    root /opt/frontend/dist;
    index index.html;
    location /health{
      proxy_pass http://127.0.0.1:3001/health;
      proxy_connect_timeout 5s;
      proxy_read_timeout 10s;
    }
    location /api/{
      rewrite ^/api/(.*) /$1 break;
      proxy_pass http://127.0.0.1:3001;
      proxy_http_version 1.1;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_connect_timeout 10s;
      proxy_read_timeout 30s;
      proxy_send_timeout 30s;
      client_max_body_size 20M;
    }
    location /{try_files $uri $uri/ /index.html;}
  }
}
EOF

nginx -t && systemctl enable nginx && systemctl restart nginx

# Wait for backend to be ready
echo "Waiting for backend to start..."
for i in {1..30}; do
  if curl -s http://127.0.0.1:3001/health > /dev/null 2>&1; then
    echo "✅ Backend is ready!"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

# Final verification
echo "=========================================="
echo "✅ Deployment Complete!"
echo "Backend: Docker (DynamoDB+S3)"
echo "Frontend: S3"
echo "Nginx: Port 80 (max upload: 20MB)"
echo ""
echo "Backend status:"
docker ps | grep ucehub-backend
echo ""
echo "Backend health:"
curl -s http://127.0.0.1:3001/health | head -10
echo ""
echo "=========================================="
