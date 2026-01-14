#!/bin/bash
set -e

# UCEHub Full Deployment - Con DynamoDB y S3
region="${region}"
environment="${environment}"
project_name="${project_name}"

echo "=========================================="
echo "UCEHub Full Deployment with DynamoDB"
echo "Environment: $environment"
echo "=========================================="

# Instalar Node.js y Nginx
yum update -y
yum install -y nodejs npm nginx
systemctl enable nginx

# ============================================================================
# BACKEND: Node.js con AWS SDK para DynamoDB
# ============================================================================

echo "Setting up Backend with DynamoDB..."
mkdir -p /opt/backend
cd /opt/backend

cat > package.json << 'EOF'
{
  "name": "ucehub-backend",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "express": "^4.18.2",
    "body-parser": "^1.20.2",
    "cors": "^2.8.5",
    "@aws-sdk/client-dynamodb": "^3.490.0",
    "@aws-sdk/lib-dynamodb": "^3.490.0",
    "@aws-sdk/client-s3": "^3.490.0",
    "uuid": "^9.0.1"
  }
}
EOF

cat > index.js << 'BACKEND_EOF'
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const os = require('os');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand, QueryCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(cors({ origin: '*' }));
app.use(bodyParser.json());

// AWS SDK Configuration
const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const ddbDocClient = DynamoDBDocumentClient.from(client);

// Environment Variables
const CAFETERIA_TABLE = process.env.CAFETERIA_TABLE || 'ucehub-cafeteria-orders-qa';
const SUPPORT_TABLE = process.env.SUPPORT_TICKETS_TABLE || 'ucehub-support-tickets-qa';
const ABSENCE_TABLE = process.env.ABSENCE_JUSTIFICATIONS_TABLE || 'ucehub-absence-justifications-qa';

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
const startTime = new Date().toISOString();

// ============================================================================
// HEALTH CHECK
// ============================================================================
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ucehub-backend',
    instance: instanceIP,
    uptime: process.uptime(),
    startTime: startTime,
    timestamp: new Date().toISOString(),
    tables: {
      cafeteria: CAFETERIA_TABLE,
      support: SUPPORT_TABLE,
      absence: ABSENCE_TABLE
    }
  });
});

app.get('/', (req, res) => {
  res.json({
    message: 'UCEHub API v2.0 - DynamoDB Enabled',
    instance: instanceIP,
    endpoints: [
      '/health',
      '/auth/login',
      '/certificados/solicitar',
      '/biblioteca/reservar',
      '/soporte/ticket',
      '/soporte/tickets',
      '/becas/solicitar',
      '/cafeteria/order',
      '/cafeteria/orders'
    ]
  });
});

// ============================================================================
// AUTENTICACIÓN
// ============================================================================
app.post('/auth/login', (req, res) => {
  const { username, password } = req.body;
  
  if (!username || !password) {
    return res.status(400).json({ success: false, message: 'Username y password requeridos' });
  }

  // Mock authentication
  res.json({
    success: true,
    token: 'jwt-' + uuidv4(),
    user: {
      id: uuidv4(),
      username: username,
      email: username + '@uce.edu.ec',
      role: 'student',
      fullName: username.toUpperCase()
    },
    instance: instanceIP
  });
});

// ============================================================================
// CERTIFICADOS
// ============================================================================
app.post('/certificados/solicitar', async (req, res) => {
  try {
    const { userEmail, tipo, motivo } = req.body;
    
    const certificateId = 'CERT-' + uuidv4();
    const certificate = {
      certificateId,
      userEmail: userEmail || 'student@uce.edu.ec',
      tipo: tipo || 'Matricula',
      motivo: motivo || 'Trámite personal',
      estado: 'Solicitado',
      fechaSolicitud: new Date().toISOString(),
      timestamp: Date.now()
    };

    res.json({
      success: true,
      message: 'Certificado solicitado correctamente',
      data: certificate,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error en certificados:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ============================================================================
// BIBLIOTECA
// ============================================================================
app.post('/biblioteca/reservar', async (req, res) => {
  try {
    const { userEmail, recurso, fecha } = req.body;
    
    const reservationId = 'RES-' + uuidv4();
    const reservation = {
      reservationId,
      userEmail: userEmail || 'student@uce.edu.ec',
      recurso: recurso || 'Sala de estudio',
      fecha: fecha || new Date().toISOString().split('T')[0],
      hora: '10:00-12:00',
      estado: 'Confirmado',
      timestamp: Date.now()
    };

    res.json({
      success: true,
      message: 'Reserva confirmada',
      data: reservation,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error en biblioteca:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ============================================================================
// BECAS
// ============================================================================
app.post('/becas/solicitar', async (req, res) => {
  try {
    const { userEmail, tipoBeca, ingresos } = req.body;
    
    const applicationId = 'BECA-' + uuidv4();
    const application = {
      applicationId,
      userEmail: userEmail || 'student@uce.edu.ec',
      tipoBeca: tipoBeca || 'Socioeconómica',
      ingresos: ingresos || 'Menos de $400',
      estado: 'En revisión',
      fechaSolicitud: new Date().toISOString(),
      timestamp: Date.now()
    };

    res.json({
      success: true,
      message: 'Solicitud de beca enviada correctamente',
      data: application,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error en becas:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ============================================================================
// SOPORTE TÉCNICO (CON DYNAMODB)
// ============================================================================
app.post('/soporte/ticket', async (req, res) => {
  try {
    const { userEmail, asunto, descripcion, prioridad } = req.body;
    
    const ticketId = 'TICKET-' + uuidv4();
    const ticket = {
      ticketId,
      userEmail: userEmail || 'student@uce.edu.ec',
      asunto: asunto || 'Consulta general',
      descripcion: descripcion || 'Sin descripción',
      prioridad: prioridad || 'Media',
      status: 'Abierto',
      createdAt: Date.now(),
      updatedAt: Date.now()
    };

    // Guardar en DynamoDB
    await ddbDocClient.send(new PutCommand({
      TableName: SUPPORT_TABLE,
      Item: ticket
    }));

    res.json({
      success: true,
      message: 'Ticket creado correctamente',
      data: ticket,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error creando ticket:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.get('/soporte/tickets', async (req, res) => {
  try {
    const userEmail = req.query.email || 'student@uce.edu.ec';
    
    const result = await ddbDocClient.send(new QueryCommand({
      TableName: SUPPORT_TABLE,
      IndexName: 'UserEmailIndex',
      KeyConditionExpression: 'userEmail = :email',
      ExpressionAttributeValues: {
        ':email': userEmail
      },
      Limit: 10
    }));

    res.json({
      success: true,
      tickets: result.Items || [],
      count: result.Count,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error obteniendo tickets:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ============================================================================
// CAFETERÍA (CON DYNAMODB)
// ============================================================================
app.post('/cafeteria/order', async (req, res) => {
  try {
    const { userEmail, items, total } = req.body;
    
    const orderId = 'ORDER-' + uuidv4();
    const order = {
      orderId,
      userEmail: userEmail || 'student@uce.edu.ec',
      items: items || [{ name: 'Menu del día', quantity: 1, price: 3.50 }],
      total: total || 3.50,
      status: 'Pendiente',
      timestamp: Date.now(),
      expirationTime: Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60) // 30 días TTL
    };

    // Guardar en DynamoDB
    await ddbDocClient.send(new PutCommand({
      TableName: CAFETERIA_TABLE,
      Item: order
    }));

    res.json({
      success: true,
      message: 'Pedido registrado correctamente',
      data: order,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error creando orden:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.get('/cafeteria/orders', async (req, res) => {
  try {
    const userEmail = req.query.email || 'student@uce.edu.ec';
    
    const result = await ddbDocClient.send(new QueryCommand({
      TableName: CAFETERIA_TABLE,
      IndexName: 'UserEmailIndex',
      KeyConditionExpression: 'userEmail = :email',
      ExpressionAttributeValues: {
        ':email': userEmail
      },
      Limit: 10
    }));

    res.json({
      success: true,
      orders: result.Items || [],
      count: result.Count,
      instance: instanceIP
    });
  } catch (error) {
    console.error('Error obteniendo órdenes:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ============================================================================
// START SERVER
// ============================================================================
const PORT = 3001;
app.listen(PORT, '127.0.0.1', () => {
  console.log('========================================');
  console.log('UCEHub Backend v2.0 - DynamoDB Enabled');
  console.log('Port: ' + PORT);
  console.log('Instance IP: ' + instanceIP);
  console.log('Region: ' + (process.env.AWS_REGION || 'us-east-1'));
  console.log('Tables:');
  console.log('  - Cafeteria: ' + CAFETERIA_TABLE);
  console.log('  - Support: ' + SUPPORT_TABLE);
  console.log('  - Absence: ' + ABSENCE_TABLE);
  console.log('========================================');
});
BACKEND_EOF

# Instalar dependencias
echo "Installing Node.js dependencies..."
npm install

# Crear servicio systemd
cat > /etc/systemd/system/ucehub-backend.service << 'SERVICE_EOF'
[Unit]
Description=UCEHub Backend Service with DynamoDB
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/backend
Environment="NODE_ENV=production"
Environment="AWS_REGION=${region}"
Environment="CAFETERIA_TABLE=${cafeteria_table}"
Environment="SUPPORT_TICKETS_TABLE=${support_table}"
Environment="ABSENCE_JUSTIFICATIONS_TABLE=${absence_table}"
ExecStart=/usr/bin/node /opt/backend/index.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Reemplazar variables en el servicio
sed -i "s/\${region}/$region/g" /etc/systemd/system/ucehub-backend.service
sed -i "s/\${cafeteria_table}/$project_name-cafeteria-orders-$environment/g" /etc/systemd/system/ucehub-backend.service
sed -i "s/\${support_table}/$project_name-support-tickets-$environment/g" /etc/systemd/system/ucehub-backend.service
sed -i "s/\${absence_table}/$project_name-absence-justifications-$environment/g" /etc/systemd/system/ucehub-backend.service

systemctl daemon-reload
systemctl enable ucehub-backend
systemctl start ucehub-backend

sleep 3
if systemctl is-active --quiet ucehub-backend; then
    echo "✅ Backend iniciado correctamente"
    systemctl status ucehub-backend --no-pager
else
    echo "❌ Error al iniciar backend"
    journalctl -u ucehub-backend -n 50 --no-pager
fi

# ============================================================================
# FRONTEND: HTML mejorado con funcionalidades reales
# ============================================================================

echo "Creating Enhanced Frontend..."
mkdir -p /opt/frontend/dist
cd /opt/frontend/dist

cat > index.html << 'FRONTEND_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>UCEHub - Universidad Central del Ecuador</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }
    .header {
      background: rgba(255, 255, 255, 0.95);
      padding: 1rem 2rem;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    .header h1 {
      color: #667eea;
      font-size: 2rem;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    .header p { color: #666; margin-top: 0.25rem; }
    .container {
      flex: 1;
      max-width: 1200px;
      margin: 2rem auto;
      padding: 0 2rem;
      width: 100%;
    }
    .welcome-card {
      background: white;
      border-radius: 15px;
      padding: 3rem;
      box-shadow: 0 10px 30px rgba(0,0,0,0.2);
      text-align: center;
      margin-bottom: 2rem;
    }
    .welcome-card h2 {
      color: #333;
      font-size: 2.5rem;
      margin-bottom: 1rem;
    }
    .welcome-card p {
      color: #666;
      font-size: 1.2rem;
      line-height: 1.6;
    }
    .services-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 1.5rem;
      margin-top: 2rem;
    }
    .service-card {
      background: white;
      border-radius: 10px;
      padding: 2rem;
      box-shadow: 0 5px 15px rgba(0,0,0,0.1);
      transition: transform 0.3s ease, box-shadow 0.3s ease;
      cursor: pointer;
      text-align: center;
    }
    .service-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 10px 25px rgba(0,0,0,0.2);
    }
    .service-icon {
      font-size: 3rem;
      margin-bottom: 1rem;
    }
    .service-card h3 {
      color: #667eea;
      font-size: 1.3rem;
      margin-bottom: 0.5rem;
    }
    .service-card p {
      color: #666;
      font-size: 0.95rem;
    }
    .status-bar {
      background: rgba(255, 255, 255, 0.95);
      padding: 1rem;
      border-radius: 10px;
      margin-top: 2rem;
      text-align: center;
    }
    .status-bar .status {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      color: #27ae60;
      font-weight: 600;
    }
    .status-indicator {
      width: 10px;
      height: 10px;
      background: #27ae60;
      border-radius: 50%;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }
    .footer {
      background: rgba(0, 0, 0, 0.2);
      color: white;
      text-align: center;
      padding: 1rem;
      margin-top: auto;
    }
    @media (max-width: 768px) {
      .welcome-card { padding: 2rem 1rem; }
      .welcome-card h2 { font-size: 1.8rem; }
      .services-grid { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>🎓 UCEHub</h1>
    <p>Portal Universitario - Universidad Central del Ecuador</p>
  </div>

  <div class="container">
    <div class="welcome-card">
      <h2>¡Bienvenido a UCEHub!</h2>
      <p>Tu portal universitario completo con integración a DynamoDB</p>
    </div>

    <div class="services-grid">
      <div class="service-card" onclick="testAuth()">
        <div class="service-icon">🔐</div>
        <h3>Autenticación</h3>
        <p>Sistema de login seguro</p>
      </div>

      <div class="service-card" onclick="testCertificados()">
        <div class="service-icon">📜</div>
        <h3>Certificados</h3>
        <p>Solicita certificados académicos</p>
      </div>

      <div class="service-card" onclick="testBiblioteca()">
        <div class="service-icon">📚</div>
        <h3>Biblioteca</h3>
        <p>Reserva recursos bibliográficos</p>
      </div>

      <div class="service-card" onclick="testBecas()">
        <div class="service-icon">💰</div>
        <h3>Becas</h3>
        <p>Solicita becas estudiantiles</p>
      </div>

      <div class="service-card" onclick="testSoporte()">
        <div class="service-icon">🎫</div>
        <h3>Soporte (DynamoDB)</h3>
        <p>Crea tickets en DynamoDB</p>
      </div>

      <div class="service-card" onclick="testCafeteria()">
        <div class="service-icon">🍽️</div>
        <h3>Cafetería (DynamoDB)</h3>
        <p>Registra pedidos en DynamoDB</p>
      </div>
    </div>

    <div class="status-bar">
      <div class="status">
        <div class="status-indicator"></div>
        <span>Sistema operativo | Backend: DynamoDB integrado</span>
      </div>
    </div>
  </div>

  <div class="footer">
    <p>&copy; 2026 Universidad Central del Ecuador | UCEHub v2.0</p>
    <p>DynamoDB + S3 + Terraform + AWS</p>
  </div>

  <script>
    const userEmail = 'student@uce.edu.ec';

    async function testAuth() {
      try {
        const response = await fetch('/api/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ username: 'Juan Perez', password: 'test123' })
        });
        const data = await response.json();
        alert('✅ AUTENTICACIÓN EXITOSA\n\n' + JSON.stringify(data, null, 2));
      } catch (error) {
        alert('❌ Error: ' + error.message);
      }
    }

    async function testCertificados() {
      try {
        const response = await fetch('/api/certificados/solicitar', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            userEmail: userEmail,
            tipo: 'Certificado de Matrícula',
            motivo: 'Trámite bancario'
          })
        });
        const data = await response.json();
        alert('✅ CERTIFICADO SOLICITADO\n\n' + JSON.stringify(data.data, null, 2));
      } catch (error) {
        alert('❌ Error: ' + error.message);
      }
    }

    async function testBiblioteca() {
      try {
        const response = await fetch('/api/biblioteca/reservar', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            userEmail: userEmail,
            recurso: 'Sala de estudio #3',
            fecha: new Date().toISOString().split('T')[0]
          })
        });
        const data = await response.json();
        alert('✅ RESERVA CONFIRMADA\n\n' + JSON.stringify(data.data, null, 2));
      } catch (error) {
        alert('❌ Error: ' + error.message);
      }
    }

    async function testBecas() {
      try {
        const response = await fetch('/api/becas/solicitar', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            userEmail: userEmail,
            tipoBeca: 'Beca Socioeconómica',
            ingresos: 'Menos de $400'
          })
        });
        const data = await response.json();
        alert('✅ BECA SOLICITADA\n\n' + JSON.stringify(data.data, null, 2));
      } catch (error) {
        alert('❌ Error: ' + error.message);
      }
    }

    async function testSoporte() {
      try {
        const response = await fetch('/api/soporte/ticket', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            userEmail: userEmail,
            asunto: 'Problema con el portal',
            descripcion: 'No puedo acceder a mis notas',
            prioridad: 'Alta'
          })
        });
        const data = await response.json();
        alert('✅ TICKET CREADO EN DYNAMODB\n\n' + JSON.stringify(data.data, null, 2));
      } catch (error) {
        alert('❌ Error: ' + error.message);
      }
    }

    async function testCafeteria() {
      try {
        const response = await fetch('/api/cafeteria/order', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            userEmail: userEmail,
            items: [
              { name: 'Menú del día', quantity: 1, price: 3.50 },
              { name: 'Jugo natural', quantity: 1, price: 1.50 }
            ],
            total: 5.00
          })
        });
        const data = await response.json();
        alert('✅ PEDIDO GUARDADO EN DYNAMODB\n\n' + JSON.stringify(data.data, null, 2));
      } catch (error) {
        alert('❌ Error: ' + error.message);
      }
    }

    console.log('UCEHub v2.0 Ready - DynamoDB Integrated');
  </script>
</body>
</html>
FRONTEND_EOF

echo "✅ Frontend created"

# ============================================================================
# NGINX Configuration
# ============================================================================

echo "Configuring Nginx..."

cat > /etc/nginx/nginx.conf << 'EOF'
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
                      '"$http_user_agent"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen 80 default_server;
        server_name _;
        root /opt/frontend/dist;
        index index.html;

        location /health {
            proxy_pass http://127.0.0.1:3001/health;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_connect_timeout 5s;
            proxy_read_timeout 10s;
        }

        location /api/ {
            rewrite ^/api/(.*) /$1 break;
            proxy_pass http://127.0.0.1:3001;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 5s;
            proxy_read_timeout 10s;
        }

        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
EOF

systemctl restart nginx
systemctl enable nginx

sleep 2
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE - v2.0"
echo "=========================================="
echo "Backend: $(systemctl is-active ucehub-backend)"
echo "Nginx: $(systemctl is-active nginx)"
echo "DynamoDB Integration: ENABLED"
echo "=========================================="
