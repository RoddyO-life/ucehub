#!/bin/bash
set -e
set -x

# UCEHub Full Stack Deployment v2.0 with DynamoDB Integration
region="${region}"
environment="${environment}"
project_name="${project_name}"

echo "=========================================="
echo "UCEHub Full Stack Deployment v2.0"
echo "Environment: $environment"
echo "Region: $region"
echo "=========================================="

# Install Docker, Node.js, and required packages
yum update -y
yum install -y docker nodejs npm nginx git
systemctl enable docker
systemctl start docker
sleep 5

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# ============================================================================
# BACKEND: Build and run with DynamoDB integration
# ============================================================================

echo "Setting up Backend with DynamoDB..."
mkdir -p /opt/backend
cd /opt/backend

# Get table names from instance metadata or environment
CAFETERIA_TABLE="${project_name}-cafeteria-orders-${environment}"
SUPPORT_TICKETS_TABLE="${project_name}-support-tickets-${environment}"
ABSENCE_JUSTIFICATIONS_TABLE="${project_name}-absence-justifications-${environment}"
DOCUMENTS_BUCKET="${project_name}-documents-${environment}-$(aws sts get-caller-identity --query Account --output text)"

cat > package.json << 'PACKAGE_EOF'
{
  "name": "ucehub-backend",
  "version": "2.0.0",
  "description": "UCEHub Backend API with DynamoDB, S3, and SES integration",
  "main": "server.js",
  "dependencies": {
    "@aws-sdk/client-dynamodb": "^3.478.0",
    "@aws-sdk/client-s3": "^3.478.0",
    "@aws-sdk/client-ses": "^3.478.0",
    "@aws-sdk/lib-dynamodb": "^3.478.0",
    "@aws-sdk/s3-request-presigner": "^3.478.0",
    "body-parser": "^1.20.2",
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "uuid": "^9.0.1"
  }
}
PACKAGE_EOF

# Copy server.js from S3 or create inline
cat > server.js << 'SERVER_EOF'
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const os = require('os');
const { v4: uuidv4 } = require('uuid');

// AWS SDK v3
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors({ origin: '*' }));
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));

// AWS Configuration from environment
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';
const CAFETERIA_TABLE = process.env.CAFETERIA_TABLE;
const SUPPORT_TICKETS_TABLE = process.env.SUPPORT_TICKETS_TABLE;
const ABSENCE_JUSTIFICATIONS_TABLE = process.env.ABSENCE_JUSTIFICATIONS_TABLE;
const DOCUMENTS_BUCKET = process.env.DOCUMENTS_BUCKET;
const NOTIFICATION_EMAIL = process.env.NOTIFICATION_EMAIL || 'rjortega@uce.edu.ec';

// AWS Clients
const dynamoClient = new DynamoDBClient({ region: AWS_REGION });
const docClient = DynamoDBDocumentClient.from(dynamoClient);
const s3Client = new S3Client({ region: AWS_REGION });
const sesClient = new SESClient({ region: AWS_REGION });

function getPrivateIP() {
  const interfaces = os.networkInterfaces();
  for (let iface of Object.values(interfaces)) {
    for (let addr of iface) {
      if (addr.family === 'IPv4' && !addr.internal) return addr.address;
    }
  }
  return 'unknown';
}

const instanceIP = getPrivateIP();

async function sendEmailNotification(subject, htmlBody, textBody) {
  try {
    // AWS Academy does not allow SES, so we simulate email sending
    console.log('========================================');
    console.log('EMAIL NOTIFICATION (Simulated for AWS Academy)');
    console.log('To: rjortega@uce.edu.ec');
    console.log('Subject:', subject);
    console.log('Body:', textBody);
    console.log('========================================');
    
    // In production with SES enabled, uncomment this:
    // await sesClient.send(new SendEmailCommand({
    //   Source: NOTIFICATION_EMAIL,
    //   Destination: { ToAddresses: [NOTIFICATION_EMAIL] },
    //   Message: {
    //     Subject: { Data: subject },
    //     Body: {
    //       Html: { Data: htmlBody },
    //       Text: { Data: textBody }
    //     }
    //   }
    // }));
    
    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    return false;
  }
}

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ucehub-backend-v2',
    instance: instanceIP,
    timestamp: new Date().toISOString(),
    config: {
      cafeteria_table: CAFETERIA_TABLE,
      support_table: SUPPORT_TICKETS_TABLE,
      justifications_table: ABSENCE_JUSTIFICATIONS_TABLE,
      documents_bucket: DOCUMENTS_BUCKET
    }
  });
});

app.get('/', (req, res) => {
  res.json({
    message: 'UCEHub API v2.0 - Integrated with DynamoDB',
    instance: instanceIP,
    endpoints: {
      cafeteria: ['/api/cafeteria/menu', '/api/cafeteria/order'],
      support: ['/api/support/ticket'],
      justifications: ['/api/justifications/submit']
    }
  });
});

// Cafeteria Menu
app.get('/api/cafeteria/menu', (req, res) => {
  const menu = [
    { id: 'cafe-1', name: 'Café Americano', price: 1.50, category: 'Bebidas', image: '☕' },
    { id: 'cafe-2', name: 'Café con Leche', price: 2.00, category: 'Bebidas', image: '☕' },
    { id: 'cafe-3', name: 'Capuchino', price: 2.50, category: 'Bebidas', image: '☕' },
    { id: 'juice-1', name: 'Jugo Natural', price: 2.00, category: 'Bebidas', image: '🥤' },
    { id: 'snack-1', name: 'Sánduche de Pollo', price: 3.50, category: 'Comida', image: '🥪' },
    { id: 'snack-2', name: 'Sánduche Vegetariano', price: 3.00, category: 'Comida', image: '🥪' },
    { id: 'meal-1', name: 'Almuerzo Ejecutivo', price: 5.00, category: 'Comida', image: '🍽️' },
    { id: 'dessert-1', name: 'Pastel', price: 2.50, category: 'Postres', image: '🍰' }
  ];
  res.json({ success: true, data: menu });
});

// Create Cafeteria Order
app.post('/api/cafeteria/order', async (req, res) => {
  try {
    const { items, total, userEmail, userName, paymentMethod } = req.body;
    const orderId = "ORD-" + uuidv4().substring(0, 8).toUpperCase();
    const timestamp = Date.now();
    
    const order = {
      orderId, timestamp, userEmail,
      userName: userName || 'Usuario',
      items, total,
      paymentMethod: paymentMethod || 'cash',
      status: 'pending',
      createdAt: new Date().toISOString(),
      expirationTime: Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60)
    };
    
    await docClient.send(new PutCommand({ TableName: CAFETERIA_TABLE, Item: order }));
    
    const itemsList = items.map(i => "- " + i.name + " x" + i.quantity + " - $" + (i.price * i.quantity).toFixed(2)).join('\\n');
    await sendEmailNotification(
      "Nueva Orden de Cafeteria - " + orderId,
      "<h2>Nueva Orden</h2><p>ID: " + orderId + "</p><p>Cliente: " + userName + "</p><p>Total: $" + total.toFixed(2) + "</p><pre>" + itemsList + "</pre>",
      "Nueva Orden: " + orderId + "\\nCliente: " + userName + "\\nTotal: $" + total.toFixed(2) + "\\n\\n" + itemsList
    );
    
    res.json({ success: true, data: order });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create Support Ticket
app.post('/api/support/ticket', async (req, res) => {
  try {
    const { userEmail, userName, category, subject, description, priority } = req.body;
    const ticketId = "TICK-" + uuidv4().substring(0, 8).toUpperCase();
    const createdAt = Date.now();
    
    const ticket = {
      ticketId, createdAt, userEmail,
      userName: userName || 'Usuario',
      category, subject, description,
      priority: priority || 'medium',
      status: 'open',
      createdAtISO: new Date().toISOString()
    };
    
    await docClient.send(new PutCommand({ TableName: SUPPORT_TICKETS_TABLE, Item: ticket }));
    
    await sendEmailNotification(
      "Nuevo Ticket de Soporte - " + ticketId,
      "<h2>Nuevo Ticket</h2><p>ID: " + ticketId + "</p><p>Usuario: " + userName + "</p><p>Asunto: " + subject + "</p><p>" + description + "</p>",
      "Nuevo Ticket: " + ticketId + "\\nUsuario: " + userName + "\\n\\n" + description
    );
    
    res.json({ success: true, data: ticket });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Submit Justification
app.post('/api/justifications/submit', async (req, res) => {
  try {
    const { userEmail, userName, reason, startDate, endDate, documentBase64, documentName } = req.body;
    const justificationId = "JUST-" + uuidv4().substring(0, 8).toUpperCase();
    const submittedAt = Date.now();
    let documentUrl = null;
    
    if (documentBase64 && documentName) {
      const buffer = Buffer.from(documentBase64.split(',')[1], 'base64');
      const key = "justifications/" + justificationId + "/" + documentName;
      
      await s3Client.send(new PutObjectCommand({
        Bucket: DOCUMENTS_BUCKET,
        Key: key,
        Body: buffer,
        ContentType: 'application/pdf'
      }));
      
      const command = new GetObjectCommand({ Bucket: DOCUMENTS_BUCKET, Key: key });
      documentUrl = await getSignedUrl(s3Client, command, { expiresIn: 604800 });
    }
    
    const justification = {
      justificationId, submittedAt, userEmail,
      userName: userName || 'Usuario',
      reason, startDate, endDate,
      documentKey: documentBase64 ? ("justifications/" + justificationId + "/" + documentName) : null,
      documentUrl,
      status: 'pending',
      submittedAtISO: new Date().toISOString()
    };
    
    await docClient.send(new PutCommand({ TableName: ABSENCE_JUSTIFICATIONS_TABLE, Item: justification }));
    
    await sendEmailNotification(
      "Nueva Justificacion de Falta - " + justificationId,
      "<h2>Nueva Justificacion</h2><p>ID: " + justificationId + "</p><p>Estudiante: " + userName + "</p><p>Motivo: " + reason + "</p><p>Periodo: " + startDate + " - " + endDate + "</p>" + (documentUrl ? "<p><a href='" + documentUrl + "'>Descargar PDF</a></p>" : ""),
      "Nueva Justificacion: " + justificationId + "\\nEstudiante: " + userName + "\\nPeriodo: " + startDate + " - " + endDate
    );
    
    res.json({ success: true, data: justification });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log("UCEHub Backend v2.0 listening on port " + PORT);
  console.log("Instance: " + instanceIP);
});
SERVER_EOF

cat > Dockerfile << 'DOCKERFILE_EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY server.js ./
EXPOSE 3001
CMD ["node", "server.js"]
DOCKERFILE_EOF

# Install dependencies and build Docker image
npm install --production
docker build -t ucehub-backend .

# Stop and remove old container if exists
docker stop ucehub-backend 2>/dev/null || true
docker rm ucehub-backend 2>/dev/null || true

# Run backend container with environment variables
docker run -d \
  --name ucehub-backend \
  --restart unless-stopped \
  -p 127.0.0.1:3001:3001 \
  -e AWS_REGION="$region" \
  -e CAFETERIA_TABLE="$CAFETERIA_TABLE" \
  -e SUPPORT_TICKETS_TABLE="$SUPPORT_TICKETS_TABLE" \
  -e ABSENCE_JUSTIFICATIONS_TABLE="$ABSENCE_JUSTIFICATIONS_TABLE" \
  -e DOCUMENTS_BUCKET="$DOCUMENTS_BUCKET" \
  -e NOTIFICATION_EMAIL="rjortega@uce.edu.ec" \
  ucehub-backend

echo "✅ Backend container started"

# ============================================================================
# FRONTEND: Download from S3
# ============================================================================

echo "Setting up Frontend..."
mkdir -p /opt/frontend/dist
cd /opt/frontend

aws s3 sync s3://ucehub-frontend-5095/ /opt/frontend/dist/ --region us-east-1

if [ ! -f "/opt/frontend/dist/index.html" ]; then
  echo "ERROR: Frontend download failed"
  cat > /opt/frontend/dist/index.html << 'FALLBACK_EOF'
<!DOCTYPE html>
<html><head><title>UCEHub</title></head>
<body><h1>UCEHub - Frontend Error</h1><p>Contact admin</p></body></html>
FALLBACK_EOF
fi

# ============================================================================
# NGINX: Configure
# ============================================================================

cat > /etc/nginx/nginx.conf << 'NGINX_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;

events { worker_connections 1024; }

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        root /opt/frontend/dist;
        index index.html;

        location /health {
            proxy_pass http://127.0.0.1:3001/health;
        }

        location /api/ {
            proxy_pass http://127.0.0.1:3001;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
NGINX_EOF

systemctl enable nginx
systemctl restart nginx

echo "=========================================="
echo "✅ Deployment Complete!"
echo "Backend: Docker on port 3001"
echo "Frontend: Nginx on port 80"
echo "DynamoDB Tables: $CAFETERIA_TABLE, $SUPPORT_TICKETS_TABLE, $ABSENCE_JUSTIFICATIONS_TABLE"
echo "S3 Bucket: $DOCUMENTS_BUCKET"
echo "=========================================="
