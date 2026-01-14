#!/bin/bash
set -e

# UCEHub Auth Service Deployment
region="${region}"
environment="${environment}"
project_name="${project_name}"

echo "=========================================="
echo "UCEHub Auth Service Deployment"
echo "Environment: $environment"
echo "=========================================="

# Install Docker
yum update -y
yum install -y docker
systemctl enable docker
systemctl start docker
sleep 5

# Create app directory
mkdir -p /opt/app
cd /opt/app

# Create package.json
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

# Create auth service
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
    service: 'ucehub-auth-service',
    instance: instanceIP
  });
});

app.get('/', (req, res) => {
  res.json({
    message: 'UCEHub Auth Service',
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
      estado: 'En revisión'
    }
  });
});

const PORT = 3001;
app.listen(PORT, '0.0.0.0', () => {
  console.log('UCEHub Auth Service running on port', PORT);
  console.log('Instance:', instanceIP);
});
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY index.js ./
EXPOSE 3001
CMD ["node", "index.js"]
EOF

# Build and run
docker build -t ucehub-auth .
docker stop ucehub 2>/dev/null || true
docker rm ucehub 2>/dev/null || true
docker run -d --name ucehub --restart unless-stopped -p 80:3001 ucehub-auth

echo "✅ Deployment complete!"
