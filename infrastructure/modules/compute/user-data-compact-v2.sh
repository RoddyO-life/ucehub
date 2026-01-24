#!/bin/bash
set -e

# UCEHub - Compact Backend with Approval
region="${aws_region}"
environment="${environment}"
cafeteria_table="${cafeteria_table}"
support_table="${support_table}"
justifications_table="${justifications_table}"
documents_bucket="${documents_bucket}"
teams_webhook_url="${teams_webhook_url}"
redis_endpoint="${redis_endpoint}"

echo "UCEHub Deployment - $environment"

yum update -y
yum install -y docker nodejs npm nginx
systemctl enable docker && systemctl start docker
sleep 3

mkdir -p /opt/backend
cd /opt/backend

cat > package.json <<'PKG'
{"name":"ucehub","version":"3.1.0","main":"server.js","dependencies":{"express":"^4.18.2","cors":"^2.8.5","@aws-sdk/client-dynamodb":"^3.400.0","@aws-sdk/lib-dynamodb":"^3.400.0","@aws-sdk/client-s3":"^3.400.0","@aws-sdk/s3-request-presigner":"^3.400.0","uuid":"^9.0.0","axios":"^1.4.0"}}
PKG

cat > server.js <<'SRV'
const e=require("express"),cors=require("cors"),{DynamoDBClient}=require("@aws-sdk/client-dynamodb"),{DynamoDBDocumentClient,PutCommand,ScanCommand}=require("@aws-sdk/lib-dynamodb"),{S3Client,PutObjectCommand,GetObjectCommand}=require("@aws-sdk/client-s3"),{getSignedUrl}=require("@aws-sdk/s3-request-presigner"),{v4}=require("uuid"),ax=require("axios");
const app=e(),r=process.env.AWS_REGION||"us-east-1",dc=DynamoDBDocumentClient.from(new DynamoDBClient({region:r})),s3=new S3Client({region:r});
const CT=process.env.CAFETERIA_TABLE,ST=process.env.SUPPORT_TICKETS_TABLE,JT=process.env.ABSENCE_JUSTIFICATIONS_TABLE,DB=process.env.DOCUMENTS_BUCKET,TW=process.env.TEAMS_WEBHOOK_URL,ALB="http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com";
let ip="local";try{ip=require("child_process").execSync("ec2-metadata --local-ipv4 2>/dev/null||echo local").toString().split(":").pop().trim()}catch(e){}
app.use(cors({origin:"*"}));app.use(e.json({limit:"50mb"}));app.use(e.urlencoded({limit:"50mb",extended:true}));

const notify=async(t,m,f=[])=>{if(!TW)return;try{await ax.post(TW,{"@type":"MessageCard","@context":"https://schema.org/extensions",summary:t,themeColor:"0078D7",title:t,text:m,sections:f.length?[{facts:f}]:[]})}catch(e){}};

const approvalCard=async(id,u,em,rs,dt,url)=>{if(!TW)return;try{await ax.post(TW,{"@type":"MessageCard","@context":"https://schema.org/extensions",summary:"Nueva Justificación",themeColor:"FFA500",title:"📋 Justificación - "+id,text:"Requiere aprobación",sections:[{facts:[{name:"👤 Estudiante",value:u},{name:"📧 Email",value:em},{name:"📅 Fecha",value:dt},{name:"📝 Motivo",value:rs},{name:"🔖 Estado",value:"⏳ Pendiente"}]}],potentialAction:[{"@type":"HttpPOST",name:"✅ Aprobar",target:ALB+"/api/justifications/"+id+"/approve",body:"{}",bodyContentType:"application/json"},{"@type":"HttpPOST",name:"❌ Rechazar",target:ALB+"/api/justifications/"+id+"/reject",body:"{}",bodyContentType:"application/json"},{"@type":"OpenUri",name:"📄 Ver Doc",targets:[{os:"default",uri:url||ALB}]}]})}catch(e){}};

app.get("/health",(q,r)=>r.json({status:"healthy",service:"ucehub",version:"3.1",instance:ip,config:{ct:CT,st:ST,jt:JT,db:DB,tw:!!TW}}));
app.get("/",(q,r)=>r.json({msg:"UCEHub API v3.1",instance:ip}));

app.get("/cafeteria/menu",(q,r)=>r.json({success:true,data:[{id:"1",name:"Almuerzo",price:3.5},{id:"2",name:"Desayuno",price:2.5},{id:"3",name:"Snack",price:2},{id:"4",name:"Café",price:1},{id:"5",name:"Jugo",price:1.5}]}));

app.post("/cafeteria/order",async(q,r)=>{try{const{userName:u,userEmail:em,items:it,total:t,paymentMethod:pm}=q.body,id="ORD-"+v4().substring(0,8).toUpperCase(),ts=Date.now();const o={orderId:id,timestamp:ts,userName:u||"Usuario",userEmail:em||"",items:it||[],total:t||0,paymentMethod:pm||"Efectivo",status:"pending"};await dc.send(new PutCommand({TableName:CT,Item:o}));notify("🍽️ Orden "+id,u,[{name:"Total",value:"$"+t}]);r.json({success:true,data:o})}catch(e){r.status(500).json({success:false,error:e.message})}});

app.get("/cafeteria/orders",async(q,r)=>{try{const x=await dc.send(new ScanCommand({TableName:CT}));r.json({success:true,data:x.Items||[]})}catch(e){r.status(500).json({success:false,error:e.message})}});

app.post("/support/ticket",async(q,r)=>{try{const{userName:u,userEmail:em,category:c,subject:s,description:d,priority:p}=q.body,id="TICK-"+v4().substring(0,8).toUpperCase(),ts=Date.now();const t={ticketId:id,createdAt:ts,userName:u||"Usuario",userEmail:em||"",category:c||"general",subject:s||"",description:d||"",priority:p||"medium",status:"open"};await dc.send(new PutCommand({TableName:ST,Item:t}));notify("🎫 Ticket "+id,u,[{name:"Asunto",value:s}]);r.json({success:true,data:t})}catch(e){r.status(500).json({success:false,error:e.message})}});

app.get("/support/tickets",async(q,r)=>{try{const x=await dc.send(new ScanCommand({TableName:ST}));r.json({success:true,data:x.Items||[]})}catch(e){r.status(500).json({success:false,error:e.message})}});

app.post("/justifications/submit",async(q,r)=>{try{const{userName:u,userEmail:em,studentId:si,reason:rs,date:dt,absenceDate:ad,documentBase64:db,documentName:dn}=q.body,id="JUST-"+v4().substring(0,8).toUpperCase(),ts=Date.now();let dk=null,du=null;if(db&&dn&&DB){dk="justifications/"+id+"/"+dn;await s3.send(new PutObjectCommand({Bucket:DB,Key:dk,Body:Buffer.from(db,"base64")}));du=await getSignedUrl(s3,new GetObjectCommand({Bucket:DB,Key:dk}),{expiresIn:604800})}const j={justificationId:id,submittedAt:ts,userName:u||"Usuario",userEmail:em||"",studentId:si||"",reason:rs||"",date:dt||ad||new Date().toISOString().split("T")[0],documentKey:dk,status:"pending"};await dc.send(new PutCommand({TableName:JT,Item:j}));await approvalCard(id,u,em,rs,dt||ad,du);r.json({success:true,data:{...j,documentUrl:du}})}catch(e){r.status(500).json({success:false,error:e.message})}});

app.get("/justifications/list",async(q,r)=>{try{const x=await dc.send(new ScanCommand({TableName:JT}));const items=await Promise.all((x.Items||[]).map(async i=>{if(i.documentKey&&DB){try{i.documentUrl=await getSignedUrl(s3,new GetObjectCommand({Bucket:DB,Key:i.documentKey}),{expiresIn:3600})}catch(e){}}return i}));r.json({success:true,data:items})}catch(e){r.status(500).json({success:false,error:e.message})}});

app.post("/justifications/:id/approve",async(q,r)=>{try{const{id}=q.params;const x=await dc.send(new ScanCommand({TableName:JT,FilterExpression:"justificationId=:id",ExpressionAttributeValues:{":id":id}}));if(!x.Items||!x.Items.length)return r.status(404).json({success:false,message:"No encontrado"});const j=x.Items[0];j.status="approved";j.approvedAt=Date.now();await dc.send(new PutCommand({TableName:JT,Item:j}));notify("✅ Aprobada "+id,j.userName);r.json({success:true,data:j})}catch(e){r.status(500).json({success:false,error:e.message})}});

app.post("/justifications/:id/reject",async(q,r)=>{try{const{id}=q.params;const x=await dc.send(new ScanCommand({TableName:JT,FilterExpression:"justificationId=:id",ExpressionAttributeValues:{":id":id}}));if(!x.Items||!x.Items.length)return r.status(404).json({success:false,message:"No encontrado"});const j=x.Items[0];j.status="rejected";j.rejectedAt=Date.now();await dc.send(new PutCommand({TableName:JT,Item:j}));notify("❌ Rechazada "+id,j.userName);r.json({success:true,data:j})}catch(e){r.status(500).json({success:false,error:e.message})}});

app.listen(3001,"0.0.0.0",()=>console.log("UCEHub Backend v3.1 on 3001"));
SRV

npm install --production

cat > Dockerfile <<'DOCK'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY server.js ./
EXPOSE 3001
CMD ["node","server.js"]
DOCK

docker build -t ucehub-backend .
docker stop ucehub-backend 2>/dev/null || true
docker rm ucehub-backend 2>/dev/null || true

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
IAM_ROLE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
CREDS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/iam/security-credentials/$IAM_ROLE")
export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | grep AccessKeyId | cut -d'"' -f4)
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | grep SecretAccessKey | cut -d'"' -f4)
export AWS_SESSION_TOKEN=$(echo "$CREDS" | grep '"Token"' | cut -d'"' -f4)

docker run -d --name ucehub-backend --restart unless-stopped \
  -p 127.0.0.1:3001:3001 \
  -e PORT=3001 -e AWS_REGION="$region" \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN" \
  -e CAFETERIA_TABLE="$cafeteria_table" \
  -e SUPPORT_TICKETS_TABLE="$support_table" \
  -e ABSENCE_JUSTIFICATIONS_TABLE="$justifications_table" \
  -e DOCUMENTS_BUCKET="$documents_bucket" \
  -e TEAMS_WEBHOOK_URL="$teams_webhook_url" \
  -e REDIS_ENDPOINT="$redis_endpoint" \
  ucehub-backend

mkdir -p /opt/frontend/dist
aws s3 sync "s3://ucehub-frontend-5095/" /opt/frontend/dist/ --region us-east-1 2>/dev/null || echo "<html><body><h1>UCEHub</h1></body></html>" > /opt/frontend/dist/index.html

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
    location /health { proxy_pass http://127.0.0.1:3001/health; }
    location /api/ {
      rewrite ^/api/(.*) /$1 break;
      proxy_pass http://127.0.0.1:3001;
      proxy_http_version 1.1;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_connect_timeout 30s;
      proxy_read_timeout 60s;
      client_max_body_size 100M;
    }
    location / { try_files $uri $uri/ /index.html; }
  }
}
NGX

nginx -t && systemctl enable nginx && systemctl restart nginx

for i in {1..30}; do curl -s http://127.0.0.1:3001/health >/dev/null 2>&1 && break; sleep 2; done
echo "Deployment complete"
