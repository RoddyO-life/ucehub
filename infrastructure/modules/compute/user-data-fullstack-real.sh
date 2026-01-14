#!/bin/bash
set -e

# UCEHub Full Stack with Real Backend (DynamoDB + S3)
region="${aws_region}"
environment="${environment}"
project_name="${project_name}"
cafeteria_table="${cafeteria_table}"
support_table="${support_table}"
justifications_table="${justifications_table}"
documents_bucket="${documents_bucket}"
teams_webhook_url="${teams_webhook_url}"

echo "=========================================="
echo "UCEHub Deployment - Full Stack Real Backend"
echo "Environment: $environment"
echo "Region: $region"
echo "=========================================="

# Install Docker, Node.js and Nginx
yum update -y
yum install -y docker nodejs npm nginx git
systemctl enable docker
systemctl start docker
sleep 5

# ============================================================================
# BACKEND: Deploy Real Backend with DynamoDB + S3
# ============================================================================

echo "Setting up Real Backend with DynamoDB and S3..."
mkdir -p /opt/backend
cd /opt/backend

# Create package.json with all required dependencies
cat > package.json << 'EOF'
{
  "name": "ucehub-backend-teams",
  "version": "3.0.0",
  "main": "server-teams.js",
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
EOF

# Create the real backend server
cat > server-teams.js << 'BACKEND_EOF'
const express = require('express');
const cors = require('cors');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// AWS Configuration
const region = process.env.AWS_REGION || 'us-east-1';
const dynamoClient = new DynamoDBClient({ region });
const docClient = DynamoDBDocumentClient.from(dynamoClient);
const s3Client = new S3Client({ region });

// Environment variables
const CAFETERIA_TABLE = process.env.CAFETERIA_TABLE;
const SUPPORT_TICKETS_TABLE = process.env.SUPPORT_TICKETS_TABLE;
const ABSENCE_JUSTIFICATIONS_TABLE = process.env.ABSENCE_JUSTIFICATIONS_TABLE;
const DOCUMENTS_BUCKET = process.env.DOCUMENTS_BUCKET;
const TEAMS_WEBHOOK_URL = process.env.TEAMS_WEBHOOK_URL || '';

// Get instance metadata
let instanceIP = 'unknown';
try {
  const response = require('child_process').execSync('ec2-metadata --local-ipv4').toString();
  instanceIP = response.split(':')[1].trim();
} catch (error) {
  console.log('Running locally, no instance metadata available');
}

console.log('========================================');
console.log('UCEHub Backend Starting...');
console.log('Instance IP:', instanceIP);
console.log('Region:', region);
console.log('Cafeteria Table:', CAFETERIA_TABLE);
console.log('Support Table:', SUPPORT_TICKETS_TABLE);
console.log('Justifications Table:', ABSENCE_JUSTIFICATIONS_TABLE);
console.log('Documents Bucket:', DOCUMENTS_BUCKET);
console.log('Teams Webhook Configured:', !!TEAMS_WEBHOOK_URL);
console.log('========================================');

// Send notification to Microsoft Teams
async function sendTeamsNotification(title, message, facts = [], actions = []) {
  if (!TEAMS_WEBHOOK_URL) {
    console.log('TEAMS NOTIFICATION (Webhook not configured)');
    console.log('Title:', title);
    console.log('Message:', message);
    return true;
  }

  try {
    const card = {
      "@type": "MessageCard",
      "@context": "https://schema.org/extensions",
      "summary": title,
      "themeColor": "0078D7",
      "title": title,
      "text": message,
      "sections": facts.length > 0 ? [{ "facts": facts }] : [],
      "potentialAction": actions
    };

    await axios.post(TEAMS_WEBHOOK_URL, card);
    console.log('Teams notification sent successfully');
    return true;
  } catch (error) {
    console.error('Error sending Teams notification:', error.message);
    return false;
  }
}

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ucehub-backend-teams',
    instance: instanceIP,
    timestamp: new Date().toISOString(),
    config: {
      cafeteria_table: CAFETERIA_TABLE,
      support_table: SUPPORT_TICKETS_TABLE,
      justifications_table: ABSENCE_JUSTIFICATIONS_TABLE,
      documents_bucket: DOCUMENTS_BUCKET,
      teams_webhook_configured: !!TEAMS_WEBHOOK_URL
    }
  });
});

app.get('/', (req, res) => {
  res.json({
    message: 'UCEHub API v3.0 - Real Backend with DynamoDB + S3',
    instance: instanceIP,
    endpoints: {
      cafeteria: ['/cafeteria/menu', '/cafeteria/order', '/cafeteria/orders'],
      support: ['/support/ticket', '/support/tickets'],
      justifications: ['/justifications/submit', '/justifications/list']
    }
  });
});

// ========================================
// CAFETERIA ENDPOINTS
// ========================================

// Get cafeteria menu
app.get('/cafeteria/menu', async (req, res) => {
  try {
    const menu = [
      { id: '1', name: 'Almuerzo Ejecutivo', description: 'Sopa + Seco + Jugo', price: 3.50, category: 'almuerzos', icon: '🍽️' },
      { id: '2', name: 'Desayuno Continental', description: 'Café + Pan + Huevos', price: 2.50, category: 'desayunos', icon: '🥐' },
      { id: '3', name: 'Snack Saludable', description: 'Frutas + Yogurt + Granola', price: 2.00, category: 'snacks', icon: '🥗' },
      { id: '4', name: 'Bebida Caliente', description: 'Café o Té', price: 1.00, category: 'bebidas', icon: '☕' },
      { id: '5', name: 'Jugo Natural', description: 'Naranja, Mora o Piña', price: 1.50, category: 'bebidas', icon: '🥤' }
    ];

    res.json({
      success: true,
      data: menu,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error getting menu:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener el menú',
      error: error.message
    });
  }
});

// Create cafeteria order
app.post('/cafeteria/order', async (req, res) => {
  try {
    const { userName, userEmail, items, totalPrice, deliveryTime } = req.body;
    const orderId = uuidv4();
    const timestamp = new Date().toISOString();

    const order = {
      orderId,
      userName,
      userEmail,
      items,
      totalPrice,
      deliveryTime,
      status: 'pending',
      createdAt: timestamp,
      instance: instanceIP
    };

    await docClient.send(new PutCommand({
      TableName: CAFETERIA_TABLE,
      Item: order
    }));

    // Send Teams notification
    await sendTeamsNotification(
      '🍽️ Nueva Orden de Cafetería',
      `$${userName} ha realizado una orden`,
      [
        { name: 'Email', value: userEmail },
        { name: 'Total', value: `$$${totalPrice.toFixed(2)}` },
        { name: 'Horario', value: deliveryTime },
        { name: 'Orden ID', value: orderId }
      ]
    );

    res.json({
      success: true,
      message: 'Orden creada exitosamente',
      data: { orderId, status: 'pending' },
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear la orden',
      error: error.message
    });
  }
});

// ========================================
// SUPPORT ENDPOINTS
// ========================================

// Create support ticket
app.post('/support/ticket', async (req, res) => {
  try {
    const { userName, userEmail, category, subject, description, priority } = req.body;
    const ticketId = uuidv4();
    const timestamp = new Date().toISOString();

    const ticket = {
      ticketId,
      userName,
      userEmail,
      category,
      subject,
      description,
      priority: priority || 'medium',
      status: 'open',
      createdAt: timestamp,
      instance: instanceIP
    };

    await docClient.send(new PutCommand({
      TableName: SUPPORT_TICKETS_TABLE,
      Item: ticket
    }));

    // Send Teams notification
    await sendTeamsNotification(
      '🎫 Nuevo Ticket de Soporte',
      `$${userName} ha creado un ticket`,
      [
        { name: 'Email', value: userEmail },
        { name: 'Categoría', value: category },
        { name: 'Asunto', value: subject },
        { name: 'Prioridad', value: priority },
        { name: 'Ticket ID', value: ticketId }
      ]
    );

    res.json({
      success: true,
      message: 'Ticket creado exitosamente',
      data: { ticketId, status: 'open' },
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error creating ticket:', error);
    res.status(500).json({
      success: false,
      message: 'Error al crear el ticket',
      error: error.message
    });
  }
});

// Get all support tickets
app.get('/support/tickets', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({
      TableName: SUPPORT_TICKETS_TABLE,
      Limit: 50
    }));

    res.json({
      success: true,
      data: result.Items || [],
      count: result.Items?.length || 0,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error getting tickets:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener tickets',
      error: error.message
    });
  }
});

// ========================================
// JUSTIFICATIONS ENDPOINTS
// ========================================

// Submit justification with document
app.post('/justifications/submit', async (req, res) => {
  try {
    const { userName, userEmail, studentId, reason, date, documentBase64, documentName } = req.body;
    const justificationId = uuidv4();
    const timestamp = new Date().toISOString();

    let documentUrl = null;

    // Upload document to S3 if provided
    if (documentBase64 && documentName) {
      const documentKey = `justifications/$${justificationId}/$${documentName}`;
      const buffer = Buffer.from(documentBase64, 'base64');

      await s3Client.send(new PutObjectCommand({
        Bucket: DOCUMENTS_BUCKET,
        Key: documentKey,
        Body: buffer,
        ContentType: 'application/pdf'
      }));

      // Generate presigned URL (valid for 7 days)
      documentUrl = await getSignedUrl(s3Client, new GetObjectCommand({
        Bucket: DOCUMENTS_BUCKET,
        Key: documentKey
      }), { expiresIn: 604800 });
    }

    const justification = {
      justificationId,
      userName,
      userEmail,
      studentId,
      reason,
      date,
      documentUrl,
      status: 'pending',
      createdAt: timestamp,
      instance: instanceIP
    };

    await docClient.send(new PutCommand({
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      Item: justification
    }));

    // Send Teams notification
    await sendTeamsNotification(
      '📜 Nueva Justificación de Ausencia',
      `$${userName} ha enviado una justificación`,
      [
        { name: 'Estudiante', value: studentId },
        { name: 'Email', value: userEmail },
        { name: 'Fecha', value: date },
        { name: 'Razón', value: reason },
        { name: 'Documento', value: documentUrl ? 'Adjuntado' : 'No adjuntado' },
        { name: 'Justificación ID', value: justificationId }
      ]
    );

    res.json({
      success: true,
      message: 'Justificación enviada exitosamente',
      data: { justificationId, status: 'pending', documentUrl },
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error submitting justification:', error);
    res.status(500).json({
      success: false,
      message: 'Error al enviar la justificación',
      error: error.message
    });
  }
});

// Get all justifications
app.get('/justifications/list', async (req, res) => {
  try {
    const result = await docClient.send(new ScanCommand({
      TableName: ABSENCE_JUSTIFICATIONS_TABLE,
      Limit: 50
    }));

    res.json({
      success: true,
      data: result.Items || [],
      count: result.Items?.length || 0,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error getting justifications:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener justificaciones',
      error: error.message
    });
  }
});

// Start server
app.listen(PORT, '127.0.0.1', () => {
  console.log('========================================');
  console.log(`✅ UCEHub Backend running on http://127.0.0.1:$${PORT}`);
  console.log('Instance IP:', instanceIP);
  console.log('========================================');
});
BACKEND_EOF

echo "Installing npm dependencies..."
npm install --production

# Build Docker image
cat > Dockerfile << 'DOCKERFILE_EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY server-teams.js ./
EXPOSE 3001
ENV NODE_ENV=production
CMD ["node", "server-teams.js"]
DOCKERFILE_EOF

echo "Building Docker image..."
docker build -t ucehub-backend-real .

# Stop and remove old container if exists
docker stop ucehub-backend 2>/dev/null || true
docker rm ucehub-backend 2>/dev/null || true

# Run backend container
echo "Starting backend container..."
docker run -d \
  --name ucehub-backend \
  --restart unless-stopped \
  -p 127.0.0.1:3001:3001 \
  -e PORT=3001 \
  -e AWS_REGION="$region" \
  -e CAFETERIA_TABLE="$cafeteria_table" \
  -e SUPPORT_TICKETS_TABLE="$support_table" \
  -e ABSENCE_JUSTIFICATIONS_TABLE="$justifications_table" \
  -e DOCUMENTS_BUCKET="$documents_bucket" \
  -e TEAMS_WEBHOOK_URL="$teams_webhook_url" \
  ucehub-backend-real

echo "✅ Backend container started"
docker ps | grep ucehub-backend

# ============================================================================
# FRONTEND: Download from S3
# ============================================================================

echo "Downloading frontend from S3..."
mkdir -p /opt/frontend/dist

# Frontend bucket name
FRONTEND_BUCKET="ucehub-frontend-5095"

# Check if bucket exists and download
if aws s3 ls "s3://$FRONTEND_BUCKET" 2>/dev/null; then
  echo "Downloading frontend files from S3..."
  aws s3 sync "s3://$FRONTEND_BUCKET/" /opt/frontend/dist/ --region us-east-1 --delete
  echo "✅ Frontend downloaded successfully"
else
  echo "⚠️ Frontend bucket not found, creating placeholder..."
  cat > /opt/frontend/dist/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>UCEHub - Cargando...</title>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0;
    }
    .container {
      background: white;
      padding: 3rem;
      border-radius: 15px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
      text-align: center;
      max-width: 500px;
    }
    h1 { color: #667eea; margin-bottom: 1rem; }
    p { color: #666; line-height: 1.6; }
    .status { color: #27ae60; font-weight: bold; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🎓 UCEHub</h1>
    <p><span class="status">✅ Backend Funcionando</span></p>
    <p>Frontend en proceso de construcción. Por favor construye y sube el frontend:</p>
    <code>cd scripts && .\build-and-upload-frontend.ps1</code>
  </div>
</body>
</html>
HTML_EOF
fi

# ============================================================================
# NGINX: Configure reverse proxy
# ============================================================================

echo "Configuring Nginx..."

cat > /etc/nginx/nginx.conf << 'NGINX_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        root /opt/frontend/dist;
        index index.html;

        # Health check endpoint - proxy to backend
        location /health {
            proxy_pass http://127.0.0.1:3001/health;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_http_version 1.1;
        }

        # API proxy to backend - IMPORTANT: This removes /api prefix
        location /api/ {
            rewrite ^/api/(.*) /$1 break;
            proxy_pass http://127.0.0.1:3001;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_cache_bypass $http_upgrade;
            
            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
        }

        # Frontend static files - React Router support
        location / {
            try_files $uri $uri/ /index.html;
            add_header Cache-Control "no-cache, must-revalidate";
        }
    }
}
NGINX_EOF

# Test nginx configuration
echo "Testing Nginx configuration..."
nginx -t

# Start nginx
systemctl enable nginx
systemctl restart nginx

echo "✅ Nginx configured and started"

# ============================================================================
# VERIFICATION
# ============================================================================

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo "Backend: Docker container with real DynamoDB + S3"
echo "Frontend: Downloaded from S3 bucket"
echo "Nginx: Reverse proxy on port 80"
echo ""
echo "Testing backend health..."
sleep 3
curl -s http://127.0.0.1:3001/health | head -20
echo ""
echo "Testing through Nginx..."
curl -s http://127.0.0.1/health | head -20
echo ""
echo "=========================================="
echo "Instance IP: $instanceIP"
echo "Cafeteria Table: $cafeteria_table"
echo "Support Table: $support_table"
echo "Justifications Table: $justifications_table"
echo "Documents Bucket: $documents_bucket"
echo "=========================================="
