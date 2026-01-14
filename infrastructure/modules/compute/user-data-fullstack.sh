#!/bin/bash
set -e

# UCEHub Full Stack Deployment (Frontend + Backend)
region="${region}"
environment="${environment}"
project_name="${project_name}"

echo "=========================================="
echo "UCEHub Full Stack Deployment"
echo "Environment: $environment"
echo "=========================================="

# Install Docker and Node.js
yum update -y
yum install -y docker nodejs npm nginx
systemctl enable docker
systemctl start docker
sleep 5

# ============================================================================
# BACKEND: Create and run auth service in Docker
# ============================================================================

echo "Setting up Backend..."
mkdir -p /opt/backend
cd /opt/backend

cat > package.json << 'EOF'
{
  "name": "ucehub-auth-service",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "body-parser": "^1.20.2",
    "cors": "^2.8.5",
    "express": "^4.18.2"
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

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ucehub-fullstack',
    instance: instanceIP,
    components: { backend: 'running', frontend: 'nginx' }
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
  if (!username || !password) {
    return res.status(400).json({ success: false, message: 'Credenciales requeridas' });
  }
  res.json({
    success: true,
    user: { username, name: username.toUpperCase(), role: 'student' },
    token: 'token-' + Date.now()
  });
});

app.post('/certificados/solicitar', (req, res) => {
  const { tipo, motivo } = req.body;
  res.json({
    success: true,
    data: {
      numero: 'CERT-' + Date.now(),
      tipo, motivo,
      estado: 'En proceso'
    }
  });
});

app.post('/biblioteca/reservar', (req, res) => {
  const { libro } = req.body;
  res.json({
    success: true,
    data: {
      reservaId: 'RES-' + Date.now(),
      libro,
      fechaDevolucion: new Date(Date.now() + 14*24*60*60*1000).toISOString()
    }
  });
});

app.post('/soporte/ticket', (req, res) => {
  const { categoria, descripcion } = req.body;
  res.json({
    success: true,
    data: {
      ticketId: 'TICK-' + Date.now(),
      categoria, descripcion,
      estado: 'Abierto'
    }
  });
});

app.post('/becas/solicitar', (req, res) => {
  const { tipo } = req.body;
  res.json({
    success: true,
    data: {
      solicitudId: 'BECA-' + Date.now(),
      tipo,
      estado: 'En revision'
    }
  });
});

const PORT = 3001;
app.listen(PORT, '127.0.0.1', () => {
  console.log('Backend running on port', PORT);
  console.log('Instance:', instanceIP);
});
EOF

cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY index.js ./
EXPOSE 3001
CMD ["node", "index.js"]
EOF

docker build -t ucehub-backend .
docker stop ucehub-backend 2>/dev/null || true
docker rm ucehub-backend 2>/dev/null || true
docker run -d --name ucehub-backend --restart unless-stopped -p 127.0.0.1:3001:3001 ucehub-backend

# ============================================================================
# FRONTEND: Download pre-built frontend from S3
# ============================================================================

echo "Setting up Frontend..."
mkdir -p /opt/frontend/dist
cd /opt/frontend

# Download frontend build from S3
echo "Downloading frontend from S3..."
aws s3 sync s3://ucehub-frontend-5095/ /opt/frontend/dist/ --region us-east-1

# Verify download
if [ ! -f "/opt/frontend/dist/index.html" ]; then
  echo "ERROR: Frontend download failed, creating fallback..."
  cat > /opt/frontend/dist/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>UCEHub - Error</title>
  <style>
    body { 
      font-family: 'Segoe UI', sans-serif; 
      display: flex; 
      justify-content: center; 
      align-items: center; 
      height: 100vh; 
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }
    .container { text-align: center; }
    h1 { font-size: 3em; margin: 0; }
    p { font-size: 1.2em; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🎓 UCEHub</h1>
    <p>Universidad Central del Ecuador</p>
    <p>Frontend deployment error - check logs</p>
  </div>
</body>
</html>
EOF
else
  echo "✅ Frontend downloaded successfully"
fi

# ============================================================================
# NGINX: Configure reverse proxy
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

        # Health check endpoint
        location /health {
            proxy_pass http://127.0.0.1:3001/health;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # API proxy to backend
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
        }

        # Frontend static files
        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
EOF

# Start nginx
systemctl enable nginx
systemctl start nginx

echo "=========================================="
echo "✅ Full Stack Deployment Complete!"
echo "Frontend: Nginx on port 80"
echo "Backend: Docker on port 3001"
echo "=========================================="
