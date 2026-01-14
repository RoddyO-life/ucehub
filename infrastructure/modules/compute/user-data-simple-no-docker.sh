#!/bin/bash
set -e

# UCEHub Deployment - Sin Docker (más confiable)
region="${region}"
environment="${environment}"
project_name="${project_name}"

echo "=========================================="
echo "UCEHub Deployment (No Docker)"
echo "Environment: $environment"
echo "=========================================="

# Instalar Node.js y Nginx
yum update -y
yum install -y nodejs npm nginx
systemctl enable nginx

# ============================================================================
# BACKEND: Node.js directo (sin Docker)
# ============================================================================

echo "Setting up Backend..."
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
    "cors": "^2.8.5"
  }
}
EOF

cat > index.js << 'EOF'
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const os = require('os');

const app = express();
app.use(cors({ origin: '*' }));
app.use(bodyParser.json());

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

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ucehub-backend',
    instance: instanceIP,
    uptime: process.uptime(),
    startTime: startTime,
    timestamp: new Date().toISOString()
  });
});

app.get('/', (req, res) => {
  res.json({
    message: 'UCEHub API',
    instance: instanceIP,
    endpoints: ['/health', '/auth/login', '/certificados/solicitar', '/biblioteca/reservar', '/soporte/ticket', '/becas/solicitar']
  });
});

app.post('/auth/login', (req, res) => {
  const { username, password } = req.body;
  res.json({
    success: true,
    token: 'mock-jwt-' + Date.now(),
    user: { id: 1, username: username || 'test', role: 'student' },
    instance: instanceIP
  });
});

app.post('/certificados/solicitar', (req, res) => {
  res.json({ success: true, message: 'Certificado solicitado', requestId: Date.now(), instance: instanceIP });
});

app.post('/biblioteca/reservar', (req, res) => {
  res.json({ success: true, message: 'Recurso reservado', reservationId: Date.now(), instance: instanceIP });
});

app.post('/soporte/ticket', (req, res) => {
  res.json({ success: true, message: 'Ticket creado', ticketId: Date.now(), instance: instanceIP });
});

app.post('/becas/solicitar', (req, res) => {
  res.json({ success: true, message: 'Solicitud de beca enviada', applicationId: Date.now(), instance: instanceIP });
});

const PORT = 3001;
app.listen(PORT, '127.0.0.1', () => {
  console.log('UCEHub Backend running on port ' + PORT);
  console.log('Instance IP: ' + instanceIP);
});
EOF

# Instalar dependencias
npm install

# Crear servicio systemd para auto-start
cat > /etc/systemd/system/ucehub-backend.service << 'EOF'
[Unit]
Description=UCEHub Backend Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/backend
ExecStart=/usr/bin/node /opt/backend/index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ucehub-backend
systemctl start ucehub-backend

# Verificar que está corriendo
sleep 3
if systemctl is-active --quiet ucehub-backend; then
    echo "✅ Backend iniciado correctamente"
else
    echo "❌ Error al iniciar backend"
    systemctl status ucehub-backend
fi

# ============================================================================
# FRONTEND: HTML embebido
# ============================================================================

echo "Creating Frontend..."
mkdir -p /opt/frontend/dist
cd /opt/frontend/dist

cat > index.html << 'EOF'
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
      <p>Tu portal universitario completo para gestionar todos los servicios académicos y administrativos</p>
    </div>

    <div class="services-grid">
      <div class="service-card" onclick="testService('auth')">
        <div class="service-icon">🔐</div>
        <h3>Autenticación</h3>
        <p>Sistema de login seguro</p>
      </div>

      <div class="service-card" onclick="testService('certificados')">
        <div class="service-icon">📜</div>
        <h3>Certificados</h3>
        <p>Solicita certificados académicos</p>
      </div>

      <div class="service-card" onclick="testService('biblioteca')">
        <div class="service-icon">📚</div>
        <h3>Biblioteca</h3>
        <p>Reserva recursos bibliográficos</p>
      </div>

      <div class="service-card" onclick="testService('becas')">
        <div class="service-icon">💰</div>
        <h3>Becas</h3>
        <p>Solicita becas estudiantiles</p>
      </div>

      <div class="service-card" onclick="testService('soporte')">
        <div class="service-icon">🎫</div>
        <h3>Soporte</h3>
        <p>Crea tickets de ayuda</p>
      </div>

      <div class="service-card" onclick="testService('cafeteria')">
        <div class="service-icon">🍽️</div>
        <h3>Cafetería</h3>
        <p>Servicio de comedor</p>
      </div>
    </div>

    <div class="status-bar">
      <div class="status">
        <div class="status-indicator"></div>
        <span id="status-text">Sistema operativo</span>
      </div>
    </div>
  </div>

  <div class="footer">
    <p>&copy; 2026 Universidad Central del Ecuador | UCEHub v1.0</p>
    <p>Desplegado con Terraform + AWS | Load Balanced Infrastructure</p>
  </div>

  <script>
    async function testService(service) {
      const endpoints = {
        auth: '/api/auth/login',
        certificados: '/api/certificados/solicitar',
        biblioteca: '/api/biblioteca/reservar',
        becas: '/api/becas/solicitar',
        soporte: '/api/soporte/ticket',
        cafeteria: '/health'
      };

      try {
        const response = await fetch(endpoints[service], {
          method: service === 'cafeteria' ? 'GET' : 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: service === 'cafeteria' ? undefined : JSON.stringify({
            username: 'test',
            password: 'test',
            data: 'test'
          })
        });

        const data = await response.json();
        alert('✅ ' + service.toUpperCase() + ' funcionando!\n\nRespuesta:\n' + JSON.stringify(data, null, 2));
      } catch (error) {
        alert('❌ Error en ' + service + ':\n' + error.message);
      }
    }

    console.log('UCEHub Frontend Ready');
  </script>
</body>
</html>
EOF

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

# Iniciar nginx
systemctl restart nginx
systemctl enable nginx

# Verificar servicios
sleep 2
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE"
echo "=========================================="
echo "Backend status: $(systemctl is-active ucehub-backend)"
echo "Nginx status: $(systemctl is-active nginx)"
echo "=========================================="
