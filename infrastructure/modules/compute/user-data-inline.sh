#!/bin/bash
set -e

# UCEHub - Inline Backend (no S3 dependency)
region="${aws_region}"
environment="${environment}"
cafeteria_table="${cafeteria_table}"
support_table="${support_table}"
justifications_table="${justifications_table}"
documents_bucket="${documents_bucket}"
teams_webhook_url="${teams_webhook_url}"

echo "=========================================="
echo "UCEHub Deployment - Inline Backend"
echo "Region: $region | Env: $environment"
echo "=========================================="

# Install packages
yum update -y
yum install -y docker nodejs npm nginx
systemctl enable docker && systemctl start docker
sleep 3

# ============================================================================
# BACKEND: Create inline (corrected version with Date.now())
# ============================================================================
echo "Creating backend..."
mkdir -p /opt/backend
cd /opt/backend

cat > package.json <<'PKG'
{
  "name": "ucehub-backend",
  "version": "3.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "@aws-sdk/client-dynamodb": "^3.400.0",
    "@aws-sdk/lib-dynamodb": "^3.400.0",
    "@aws-sdk/client-s3": "^3.400.0",
    "@aws-sdk/s3-request-presigner": "^3.400.0",
    "uuid": "^9.0.0",
    "axios": "^1.4.0"
  }
}
PKG

cat > server.js <<'SERVERJS'
const express = require('express');
const cors = require('cors');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');

const app = express();
const region = process.env.AWS_REGION || 'us-east-1';
const dynamoClient = new DynamoDBClient({ region });
const docClient = DynamoDBDocumentClient.from(dynamoClient);
const s3Client = new S3Client({ region });

const CAFETERIA_TABLE = process.env.CAFETERIA_TABLE;
const SUPPORT_TICKETS_TABLE = process.env.SUPPORT_TICKETS_TABLE;
const ABSENCE_JUSTIFICATIONS_TABLE = process.env.ABSENCE_JUSTIFICATIONS_TABLE;
const DOCUMENTS_BUCKET = process.env.DOCUMENTS_BUCKET;
const TEAMS_WEBHOOK_URL = process.env.TEAMS_WEBHOOK_URL || '';

let instanceIP = 'local';
try {
  instanceIP = require('child_process').execSync('ec2-metadata --local-ipv4 2>/dev/null || echo local').toString().split(':').pop().trim();
} catch (e) {}

app.use(cors({ origin: '*', methods: ['GET','POST','PUT','DELETE','OPTIONS'] }));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

const sendTeams = async (title, msg, facts = []) => {
  if (!TEAMS_WEBHOOK_URL) { console.log('Teams:', title, msg); return; }
  try {
    await axios.post(TEAMS_WEBHOOK_URL, {
      "@type": "MessageCard",
      "@context": "https://schema.org/extensions",
      summary: title,
      themeColor: "0078D7",
      title: title,
      text: msg,
      sections: facts.length ? [{ facts }] : []
    });
  } catch (e) { console.log('Teams error:', e.message); }
};

// Send approval card to Teams
const sendApprovalCard = async (justificationId, userName, userEmail, reason, date, documentUrl) => {
  if (!TEAMS_WEBHOOK_URL) { 
    console.log('Teams Approval Card:', justificationId, userName); 
    return; 
  }
  const ALB_URL = 'http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com';
  try {
    await axios.post(TEAMS_WEBHOOK_URL, {
      "@type": "MessageCard",
      "@context": "https://schema.org/extensions",
      "summary": "Nueva Justificación Pendiente",
      "themeColor": "FFA500",
      "title": "📋 Solicitud de Justificación - " + justificationId,
      "text": "Se ha recibido una nueva solicitud de justificación que requiere su aprobación.",
      "sections": [{
        "facts": [
          { "name": "👤 Estudiante", "value": userName },
          { "name": "📧 Email", "value": userEmail },
          { "name": "📅 Fecha de Ausencia", "value": date },
          { "name": "📝 Motivo", "value": reason },
          { "name": "🔖 Estado", "value": "⏳ Pendiente" }
        ]
      }],
      "potentialAction": [
        {
          "@type": "HttpPOST",
          "name": "✅ Aprobar",
          "target": ALB_URL + "/api/justifications/" + justificationId + "/approve",
          "body": "{\"action\":\"approve\"}",
          "bodyContentType": "application/json"
        },
        {
          "@type": "HttpPOST", 
          "name": "❌ Rechazar",
          "target": ALB_URL + "/api/justifications/" + justificationId + "/reject",
          "body": "{\"action\":\"reject\"}",
          "bodyContentType": "application/json"
        },
        {
          "@type": "OpenUri",
          "name": "📄 Ver Documento",
          "targets": [{ "os": "default", "uri": documentUrl || ALB_URL }]
        }
      ]
    });
    console.log('Approval card sent to Teams');
  } catch (e) { console.log('Teams approval card error:', e.message); }
};

// Health
app.get('/health', (req, res) => res.json({
  status: 'healthy',
  service: 'ucehub-backend',
  version: '3.0.0',
  instance: instanceIP,
  timestamp: new Date().toISOString(),
  config: {
    cafeteria_table: CAFETERIA_TABLE,
    support_table: SUPPORT_TICKETS_TABLE,
    justifications_table: ABSENCE_JUSTIFICATIONS_TABLE,
    documents_bucket: DOCUMENTS_BUCKET,
    teams_webhook_configured: !!TEAMS_WEBHOOK_URL
  }
}));

app.get('/', (req, res) => res.json({ msg: 'UCEHub API v3', instance: instanceIP }));

// Cafeteria Menu
app.get('/cafeteria/menu', (req, res) => res.json({
  success: true,
  data: [
    { id: '1', name: 'Almuerzo Ejecutivo', description: 'Sopa + Segundo + Jugo', price: 3.50, icon: '🍽️' },
    { id: '2', name: 'Desayuno Continental', description: 'Café + Pan + Huevos', price: 2.50, icon: '🥐' },
    { id: '3', name: 'Snack Saludable', description: 'Frutas + Yogurt', price: 2.00, icon: '🥗' },
    { id: '4', name: 'Café Americano', description: 'Café negro 250ml', price: 1.00, icon: '☕' },
    { id: '5', name: 'Jugo Natural', description: 'Naranja o Mora', price: 1.50, icon: '🥤' }
  ],
  instance: instanceIP
}));

// Cafeteria Order - FIXED: uses 'timestamp' as Sort Key
app.post('/cafeteria/order', async (req, res) => {
  try {
    const { userName, userEmail, items, total, totalPrice, paymentMethod } = req.body;
    const orderId = 'ORD-' + uuidv4().substring(0, 8).toUpperCase();
    const timestamp = Date.now();
    
    const order = {
      orderId,
      timestamp,
      userName: userName || 'Usuario',
      userEmail: userEmail || 'no-email',
      items: items || [],
      total: total || totalPrice || 0,
      paymentMethod: paymentMethod || 'Efectivo',
      status: 'pending'
    };
    
    await docClient.send(new PutCommand({ TableName: CAFETERIA_TABLE, Item: order }));
    sendTeams('🍽️ Nueva Orden - ' + orderId, 'Cliente: ' + userName, [
      { name: 'Total', value: '$' + (total || totalPrice || 0) },
      { name: 'Email', value: userEmail }
    ]);
    
    res.json({ success: true, data: order, instance: instanceIP });
  } catch (error) {
    console.error('Cafeteria order error:', error);
    res.status(500).json({ success: false, message: 'Error al crear orden', error: error.message, instance: instanceIP });
  }
});

// Get orders
app.get('/cafeteria/orders', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({ TableName: CAFETERIA_TABLE }));
    res.json({ success: true, data: result.Items || [], instance: instanceIP });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, instance: instanceIP });
  }
});

// Support Ticket - FIXED: Date.now()
app.post('/support/ticket', async (req, res) => {
  try {
    const { userName, userEmail, category, subject, description, priority } = req.body;
    const ticketId = 'TICK-' + uuidv4().substring(0, 8).toUpperCase();
    const createdAt = Date.now();
    
    const ticket = {
      ticketId,
      createdAt,
      userName: userName || 'Usuario',
      userEmail: userEmail || 'no-email',
      category: category || 'general',
      subject: subject || 'Sin asunto',
      description: description || '',
      priority: priority || 'medium',
      status: 'open'
    };
    
    await docClient.send(new PutCommand({ TableName: SUPPORT_TICKETS_TABLE, Item: ticket }));
    sendTeams('🎫 Nuevo Ticket - ' + ticketId, 'De: ' + userName, [
      { name: 'Asunto', value: subject },
      { name: 'Categoría', value: category },
      { name: 'Prioridad', value: priority }
    ]);
    
    res.json({ success: true, data: ticket, instance: instanceIP });
  } catch (error) {
    console.error('Support ticket error:', error);
    res.status(500).json({ success: false, message: 'Error al crear el ticket', error: error.message, instance: instanceIP });
  }
});

// Get tickets
app.get('/support/tickets', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({ TableName: SUPPORT_TICKETS_TABLE }));
    res.json({ success: true, data: result.Items || [], instance: instanceIP });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, instance: instanceIP });
  }
});

// Justification Submit - With approval card to Teams
app.post('/justifications/submit', async (req, res) => {
  try {
    const { userName, userEmail, studentId, reason, date, absenceDate, documentBase64, documentName } = req.body;
    const justificationId = 'JUST-' + uuidv4().substring(0, 8).toUpperCase();
    const submittedAt = Date.now();
    
    let documentKey = null;
    let documentUrl = null;
    if (documentBase64 && documentName && DOCUMENTS_BUCKET) {
      documentKey = 'justifications/' + justificationId + '/' + documentName;
      const buffer = Buffer.from(documentBase64, 'base64');
      await s3Client.send(new PutObjectCommand({ Bucket: DOCUMENTS_BUCKET, Key: documentKey, Body: buffer }));
      documentUrl = await getSignedUrl(s3Client, new GetObjectCommand({ Bucket: DOCUMENTS_BUCKET, Key: documentKey }), { expiresIn: 604800 });
    }
    
    const justification = {
      justificationId,
      submittedAt,
      userName: userName || 'Usuario',
      userEmail: userEmail || 'no-email',
      studentId: studentId || '',
      reason: reason || '',
      date: date || absenceDate || new Date().toISOString().split('T')[0],
      documentKey,
      status: 'pending'
    };
    
    await docClient.send(new PutCommand({ TableName: ABSENCE_JUSTIFICATIONS_TABLE, Item: justification }));
    
    // Send approval card to Teams instead of simple notification
    await sendApprovalCard(justificationId, userName, userEmail, reason, date || absenceDate, documentUrl);
    
    res.json({ success: true, data: { ...justification, documentUrl }, instance: instanceIP });
  } catch (error) {
    console.error('Justification error:', error);
    res.status(500).json({ success: false, message: 'Error al enviar justificación', error: error.message, instance: instanceIP });
  }
});

// Get justifications - regenerates document URLs
app.get('/justifications/list', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({ TableName: ABSENCE_JUSTIFICATIONS_TABLE }));
    const items = result.Items || [];
    
    // Regenerate signed URLs for documents
    const itemsWithUrls = await Promise.all(items.map(async (item) => {
      if (item.documentKey && DOCUMENTS_BUCKET) {
        try {
          item.documentUrl = await getSignedUrl(s3Client, new GetObjectCommand({ 
            Bucket: DOCUMENTS_BUCKET, 
            Key: item.documentKey 
          }), { expiresIn: 3600 }); // 1 hour expiry
        } catch (e) {
          item.documentUrl = null;
        }
      }
      return item;
    }));
    
    res.json({ success: true, data: itemsWithUrls, instance: instanceIP });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, instance: instanceIP });
  }
});

// Approve justification
app.post('/justifications/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get the justification first to get submittedAt (sort key)
    const scanResult = await docClient.send(new ScanCommand({ 
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      FilterExpression: 'justificationId = :id',
      ExpressionAttributeValues: { ':id': id }
    }));
    
    if (!scanResult.Items || scanResult.Items.length === 0) {
      return res.status(404).json({ success: false, message: 'Justificación no encontrada' });
    }
    
    const justification = scanResult.Items[0];
    
    // Update status
    justification.status = 'approved';
    justification.approvedAt = Date.now();
    justification.approvedBy = 'Teams Approval';
    
    await docClient.send(new PutCommand({ TableName: ABSENCE_JUSTIFICATIONS_TABLE, Item: justification }));
    
    // Notify Teams
    sendTeams('✅ Justificación Aprobada - ' + id, 'La justificación de ' + justification.userName + ' ha sido aprobada.', [
      { name: 'Estudiante', value: justification.userName },
      { name: 'Fecha', value: justification.date }
    ]);
    
    res.json({ success: true, message: 'Justificación aprobada', data: justification });
  } catch (error) {
    console.error('Approve error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Reject justification
app.post('/justifications/:id/reject', async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    
    const scanResult = await docClient.send(new ScanCommand({ 
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      FilterExpression: 'justificationId = :id',
      ExpressionAttributeValues: { ':id': id }
    }));
    
    if (!scanResult.Items || scanResult.Items.length === 0) {
      return res.status(404).json({ success: false, message: 'Justificación no encontrada' });
    }
    
    const justification = scanResult.Items[0];
    
    justification.status = 'rejected';
    justification.rejectedAt = Date.now();
    justification.rejectedBy = 'Teams Approval';
    justification.rejectionReason = reason || 'Sin motivo especificado';
    
    await docClient.send(new PutCommand({ TableName: ABSENCE_JUSTIFICATIONS_TABLE, Item: justification }));
    
    sendTeams('❌ Justificación Rechazada - ' + id, 'La justificación de ' + justification.userName + ' ha sido rechazada.', [
      { name: 'Estudiante', value: justification.userName },
      { name: 'Motivo de Rechazo', value: reason || 'No especificado' }
    ]);
    
    res.json({ success: true, message: 'Justificación rechazada', data: justification });
  } catch (error) {
    console.error('Reject error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.listen(3001, '0.0.0.0', () => console.log('UCEHub Backend v3 running on port 3001'));
SERVERJS

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

# Get AWS credentials from instance metadata (IMDSv2)
echo "Getting AWS credentials from instance metadata..."
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
IAM_ROLE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
echo "IAM Role detected: $IAM_ROLE"

CREDS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/iam/security-credentials/$IAM_ROLE")
export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | grep AccessKeyId | cut -d'"' -f4)
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | grep SecretAccessKey | cut -d'"' -f4)
export AWS_SESSION_TOKEN=$(echo "$CREDS" | grep '"Token"' | cut -d'"' -f4)

echo "AWS credentials obtained"

docker run -d --name ucehub-backend --restart unless-stopped \
  -p 127.0.0.1:3001:3001 \
  -e PORT=3001 \
  -e AWS_REGION="$region" \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN" \
  -e CAFETERIA_TABLE="$cafeteria_table" \
  -e SUPPORT_TICKETS_TABLE="$support_table" \
  -e ABSENCE_JUSTIFICATIONS_TABLE="$justifications_table" \
  -e DOCUMENTS_BUCKET="$documents_bucket" \
  -e TEAMS_WEBHOOK_URL="$teams_webhook_url" \
  ucehub-backend

echo "Backend container started with AWS credentials"

# ============================================================================
# FRONTEND: Download from S3
# ============================================================================
echo "Downloading frontend..."
mkdir -p /opt/frontend/dist
FRONTEND_BUCKET="ucehub-frontend-5095"
if aws s3 ls "s3://$FRONTEND_BUCKET" 2>/dev/null; then
  aws s3 sync "s3://$FRONTEND_BUCKET/" /opt/frontend/dist/ --region us-east-1
else
  echo "<html><body><h1>UCEHub</h1><p>Frontend not deployed yet</p></body></html>" > /opt/frontend/dist/index.html
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
