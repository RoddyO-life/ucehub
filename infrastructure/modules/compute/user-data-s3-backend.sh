#!/bin/bash
set -e

# UCEHub - Downloads backend from S3 (no size limit)
region="${aws_region}"
environment="${environment}"
cafeteria_table="${cafeteria_table}"
support_table="${support_table}"
justifications_table="${justifications_table}"
documents_bucket="${documents_bucket}"
teams_webhook_url="${teams_webhook_url}"

echo "=========================================="
echo "UCEHub Deployment - S3 Backend"
echo "Region: $region | Env: $environment"
echo "=========================================="

# Install packages
yum update -y
yum install -y docker nodejs npm nginx
systemctl enable docker && systemctl start docker
sleep 3

# ============================================================================
# BACKEND: Download from S3
# ============================================================================
echo "Downloading backend from S3..."
mkdir -p /opt/backend
cd /opt/backend

BACKEND_BUCKET="ucehub-backend-code"
if aws s3 ls "s3://$BACKEND_BUCKET" 2>/dev/null; then
  aws s3 sync "s3://$BACKEND_BUCKET/" /opt/backend/ --region us-east-1
  echo "Backend downloaded from S3"
else
  echo "Backend bucket not found, creating minimal backend..."
  cat > package.json <<'PKG'
{"name":"ucehub-backend","version":"3.0.0","main":"server.js","dependencies":{"express":"^4.18.2","cors":"^2.8.5","@aws-sdk/client-dynamodb":"^3.400.0","@aws-sdk/lib-dynamodb":"^3.400.0","@aws-sdk/client-s3":"^3.400.0","@aws-sdk/s3-request-presigner":"^3.400.0","uuid":"^9.0.0","axios":"^1.4.0"}}
PKG
  cat > server.js <<'SRV'
const e=require("express"),c=require("cors"),{DynamoDBClient:D}=require("@aws-sdk/client-dynamodb"),{DynamoDBDocumentClient:DD,PutCommand:P,ScanCommand:S}=require("@aws-sdk/lib-dynamodb"),{S3Client:S3,PutObjectCommand:PO,GetObjectCommand:GO}=require("@aws-sdk/client-s3"),{getSignedUrl:gs}=require("@aws-sdk/s3-request-presigner"),{v4:u}=require("uuid"),x=require("axios"),a=e(),r=process.env.AWS_REGION||"us-east-1",d=DD.from(new D({region:r})),s=new S3({region:r}),CT=process.env.CAFETERIA_TABLE,ST=process.env.SUPPORT_TICKETS_TABLE,JT=process.env.ABSENCE_JUSTIFICATIONS_TABLE,DB=process.env.DOCUMENTS_BUCKET,TW=process.env.TEAMS_WEBHOOK_URL;let ip="unknown";try{ip=require("child_process").execSync("ec2-metadata --local-ipv4 2>/dev/null||echo local").toString().split(":").pop().trim()}catch(e){}a.use(c()),a.use(e.json({limit:"50mb"}));const tn=async(t,m,f=[])=>{if(!TW)return console.log("Teams:",t,m),1;try{return await x.post(TW,{"@type":"MessageCard","@context":"https://schema.org/extensions",summary:t,themeColor:"0078D7",title:t,text:m,sections:f.length?[{facts:f}]:[]}),1}catch(e){return 0}};a.get("/health",(q,r)=>r.json({status:"healthy",service:"ucehub",instance:ip,config:{ct:CT,st:ST,jt:JT,db:DB}}));a.get("/",(q,r)=>r.json({msg:"UCEHub API v3",instance:ip}));a.get("/cafeteria/menu",(q,r)=>r.json({success:1,data:[{id:"1",name:"Almuerzo Ejecutivo",description:"Sopa+Seco+Jugo",price:3.5,icon:"🍽️"},{id:"2",name:"Desayuno",description:"Café+Pan+Huevos",price:2.5,icon:"🥐"},{id:"3",name:"Snack",description:"Frutas+Yogurt",price:2,icon:"🥗"},{id:"4",name:"Café",description:"Americano",price:1,icon:"☕"},{id:"5",name:"Jugo",description:"Natural",price:1.5,icon:"🥤"}],instance:ip}));a.post("/cafeteria/order",async(q,r)=>{try{const{userName:n,userEmail:e,items:i,totalPrice:t,deliveryTime:d}=q.body,o=u();await d.send(new P({TableName:CT,Item:{orderId:o,userName:n,userEmail:e,items:i,totalPrice:t,deliveryTime:d,status:"pending",createdAt:new Date().toISOString()}}));tn("🍽️ Orden",n,[{name:"Total",value:"$"+t}]);r.json({success:1,data:{orderId:o},instance:ip})}catch(e){r.status(500).json({success:0,error:e.message})}});a.post("/support/ticket",async(q,r)=>{try{const{userName:n,userEmail:e,category:c,subject:s,description:d,priority:p}=q.body,t=u();await d.send(new P({TableName:ST,Item:{ticketId:t,userName:n,userEmail:e,category:c,subject:s,description:d,priority:p||"medium",status:"open",createdAt:new Date().toISOString()}}));tn("🎫 Ticket",n,[{name:"Asunto",value:s}]);r.json({success:1,data:{ticketId:t},instance:ip})}catch(e){r.status(500).json({success:0,error:e.message})}});a.get("/support/tickets",async(q,r)=>{try{const t=await d.send(new S({TableName:ST,Limit:50}));r.json({success:1,data:t.Items||[],instance:ip})}catch(e){r.status(500).json({success:0,error:e.message})}});a.post("/justifications/submit",async(q,r)=>{try{const{userName:n,userEmail:e,studentId:si,reason:rn,date:dt,documentBase64:db,documentName:dn}=q.body,j=u();let du=null;if(db&&dn&&DB){const k="justifications/"+j+"/"+dn,b=Buffer.from(db,"base64");await s.send(new PO({Bucket:DB,Key:k,Body:b}));du=await gs(s,new GO({Bucket:DB,Key:k}),{expiresIn:604800})}await d.send(new P({TableName:JT,Item:{justificationId:j,userName:n,userEmail:e,studentId:si,reason:rn,date:dt,documentUrl:du,status:"pending",createdAt:new Date().toISOString()}}));tn("📜 Justificación",n,[{name:"Fecha",value:dt}]);r.json({success:1,data:{justificationId:j,documentUrl:du},instance:ip})}catch(e){r.status(500).json({success:0,error:e.message})}});a.get("/justifications/list",async(q,r)=>{try{const j=await d.send(new S({TableName:JT,Limit:50}));r.json({success:1,data:j.Items||[],instance:ip})}catch(e){r.status(500).json({success:0,error:e.message})}});a.listen(3001,"0.0.0.0",()=>console.log("UCEHub Backend running on 3001"));
SRV
fi

npm install --production

# Build and run Docker
cat > Dockerfile <<'DOCK'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY server.js ./
EXPOSE 3001
ENV NODE_ENV=production
CMD ["node", "server.js"]
DOCK

docker build -t ucehub-backend .
docker stop ucehub-backend 2>/dev/null || true
docker rm ucehub-backend 2>/dev/null || true
docker run -d --name ucehub-backend --restart unless-stopped \
  -p 127.0.0.1:3001:3001 \
  -e PORT=3001 \
  -e AWS_REGION="$region" \
  -e CAFETERIA_TABLE="$cafeteria_table" \
  -e SUPPORT_TICKETS_TABLE="$support_table" \
  -e ABSENCE_JUSTIFICATIONS_TABLE="$justifications_table" \
  -e DOCUMENTS_BUCKET="$documents_bucket" \
  -e TEAMS_WEBHOOK_URL="$teams_webhook_url" \
  ucehub-backend

echo "Backend container started"

# ============================================================================
# FRONTEND: Download from S3
# ============================================================================
echo "Downloading frontend..."
mkdir -p /opt/frontend/dist
FRONTEND_BUCKET="ucehub-frontend-5095"
if aws s3 ls "s3://$FRONTEND_BUCKET" 2>/dev/null; then
  aws s3 sync "s3://$FRONTEND_BUCKET/" /opt/frontend/dist/ --region us-east-1
else
  echo "<html><body><h1>UCEHub</h1><p>Run: scripts/build-and-upload-frontend.ps1</p></body></html>" > /opt/frontend/dist/index.html
fi

# ============================================================================
# NGINX
# ============================================================================
cat > /etc/nginx/nginx.conf <<'NGX'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
events { worker_connections 1024; }
http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  sendfile on;
  keepalive_timeout 65;
  client_max_body_size 100M;
  
  server {
    listen 80 default_server;
    root /opt/frontend/dist;
    index index.html;
    
    location /health {
      proxy_pass http://127.0.0.1:3001/health;
      proxy_connect_timeout 10s;
      proxy_read_timeout 30s;
    }
    
    location /api/ {
      rewrite ^/api/(.*) /$1 break;
      proxy_pass http://127.0.0.1:3001;
      proxy_http_version 1.1;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_connect_timeout 30s;
      proxy_read_timeout 60s;
      proxy_send_timeout 60s;
      client_max_body_size 100M;
    }
    
    location / {
      try_files $uri $uri/ /index.html;
    }
  }
}
NGX

nginx -t && systemctl enable nginx && systemctl restart nginx

# Wait for backend
echo "Waiting for backend..."
for i in {1..30}; do
  if curl -s http://127.0.0.1:3001/health >/dev/null 2>&1; then
    echo "Backend ready!"
    break
  fi
  sleep 2
done

echo "=========================================="
echo "Deployment Complete!"
echo "Backend: Docker | Frontend: S3 | Nginx: 80"
echo "Max upload: 100MB"
docker ps | grep ucehub
curl -s http://127.0.0.1:3001/health
echo "=========================================="
