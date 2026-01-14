#!/bin/bash
set -e

# ============================================================================
# UCEHub Auth Service Deployment Script
# ============================================================================

# Variables
region="${region}"
environment="${environment}"
project_name="${project_name}"

echo "=========================================="
echo "UCEHub Auth Service Deployment"
echo "Environment: $environment"
echo "Region: $region"
echo "=========================================="

# ============================================================================
# Install Docker
# ============================================================================

echo "[1/6] Updating system and installing Docker..."
yum update -y
yum install -y docker git

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Wait for Docker to be ready
echo "Waiting for Docker to initialize..."
sleep 5

# ============================================================================
# Create Application Directory
# ============================================================================

echo "[2/6] Creating application directory..."
mkdir -p /opt/ucehub/auth-service
cd /opt/ucehub/auth-service

# ============================================================================
# Create Auth Service Files
# ============================================================================

echo "[3/6] Creating auth service application..."

# Create package.json
cat > package.json <<'PACKAGEJSON'
{
  "name": "ucehub-auth-service",
  "version": "1.0.0",
  "description": "UCEHub Authentication and Services API",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "body-parser": "^1.20.2",
    "cors": "^2.8.5",
    "express": "^4.18.2"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
PACKAGEJSON

# Create index.js with full auth service code
cat > index.js <<'INDEXJS'
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const os = require('os');

const app = express();

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Get instance IP
function getPrivateIP() {
  const interfaces = os.networkInterfaces();
  for (let iface of Object.values(interfaces)) {
    for (let addr of iface) {
      if (addr.family === 'IPv4' && !addr.internal) {
        return addr.address;
      }
    }
  }
  return 'unknown';
}

const instanceIP = getPrivateIP();
const environment = process.env.ENVIRONMENT || 'development';

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ucehub-auth-service',
    environment: environment,
    instance: instanceIP,
    timestamp: new Date().toISOString()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'UCEHub Auth Service API',
    version: '1.0.0',
    environment: environment,
    instance: instanceIP,
    endpoints: {
      health: '/health',
      auth: '/auth/login',
      certificados: '/certificados/solicitar',
      biblioteca: '/biblioteca/reservar',
      soporte: '/soporte/ticket',
      becas: '/becas/solicitar'
    }
  });
});

// Authentication endpoint
app.post('/auth/login', (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({
      success: false,
      message: 'Usuario y contraseña requeridos'
    });
  }

  // Simple authentication (replace with real auth in production)
  if (username && password) {
    return res.json({
      success: true,
      message: 'Autenticación exitosa',
      user: {
        username: username,
        name: username.toUpperCase(),
        role: 'student',
        id: Math.random().toString(36).substr(2, 9)
      },
      token: 'mock-jwt-token-' + Date.now()
    });
  }

  res.status(401).json({
    success: false,
    message: 'Credenciales inválidas'
  });
});

// Certificados endpoint
app.post('/certificados/solicitar', (req, res) => {
  const { tipo, motivo } = req.body;

  if (!tipo) {
    return res.status(400).json({
      success: false,
      message: 'Tipo de certificado requerido'
    });
  }

  res.json({
    success: true,
    message: 'Solicitud de certificado recibida',
    data: {
      numero: 'CERT-' + Date.now(),
      tipo: tipo,
      motivo: motivo || 'No especificado',
      fecha: new Date().toISOString(),
      estado: 'En proceso',
      tiempoEstimado: '2-3 días hábiles'
    }
  });
});

// Biblioteca endpoint
app.post('/biblioteca/reservar', (req, res) => {
  const { libro, titulo } = req.body;

  if (!libro && !titulo) {
    return res.status(400).json({
      success: false,
      message: 'ID o título del libro requerido'
    });
  }

  res.json({
    success: true,
    message: 'Libro reservado exitosamente',
    data: {
      reservaId: 'RES-' + Date.now(),
      libro: libro || titulo,
      fechaReserva: new Date().toISOString(),
      fechaDevolucion: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
      ubicacion: 'Piso 2, Estante A-' + Math.floor(Math.random() * 50)
    }
  });
});

// Soporte endpoint
app.post('/soporte/ticket', (req, res) => {
  const { categoria, descripcion } = req.body;

  if (!categoria || !descripcion) {
    return res.status(400).json({
      success: false,
      message: 'Categoría y descripción requeridas'
    });
  }

  res.json({
    success: true,
    message: 'Ticket de soporte creado',
    data: {
      ticketId: 'TICK-' + Date.now(),
      categoria: categoria,
      descripcion: descripcion,
      estado: 'Abierto',
      prioridad: 'Media',
      fechaCreacion: new Date().toISOString(),
      tiempoRespuesta: '24-48 horas'
    }
  });
});

// Becas endpoint
app.post('/becas/solicitar', (req, res) => {
  const { tipo, promedio } = req.body;

  if (!tipo) {
    return res.status(400).json({
      success: false,
      message: 'Tipo de beca requerido'
    });
  }

  res.json({
    success: true,
    message: 'Solicitud de beca recibida',
    data: {
      solicitudId: 'BECA-' + Date.now(),
      tipo: tipo,
      promedio: promedio || 'No especificado',
      estado: 'En revisión',
      fechaSolicitud: new Date().toISOString(),
      proximoPaso: 'Esperar revisión del comité (10-15 días)'
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint no encontrado',
    path: req.path
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Error interno del servidor',
    error: err.message
  });
});

// Start server
const PORT = process.env.PORT || 3001;

// Check if running in Lambda
if (process.env.AWS_LAMBDA_FUNCTION_NAME) {
  module.exports = app;
} else {
  app.listen(PORT, '0.0.0.0', () => {
    console.log('========================================');
    console.log('UCEHub Auth Service');
    console.log('========================================');
    console.log(\`Server running on port: $\{PORT}\`);
    console.log(\`Environment: $\{environment}\`);
    console.log(\`Instance IP: $\{instanceIP}\`);
    console.log(\`Health check: http://localhost:$\{PORT}/health\`);
    console.log('========================================');
  });
}
INDEXJS

# Create Dockerfile
cat > Dockerfile <<'DOCKERFILE'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY index.js ./

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"

CMD ["node", "index.js"]
DOCKERFILE

# ============================================================================
# Build Docker Image
# ============================================================================

echo "[4/6] Building Docker image..."
docker build -t ucehub-auth-service:latest .

# ============================================================================
# Run Container
# ============================================================================

echo "[5/6] Starting auth service container..."

# Stop and remove old container if exists
docker stop ucehub-auth 2>/dev/null || true
docker rm ucehub-auth 2>/dev/null || true

# Run new container
docker run -d \
  --name ucehub-auth \
  --restart unless-stopped \
  -p 80:3001 \
  -e ENVIRONMENT="$environment" \
  -e PORT=3001 \
  ucehub-auth-service:latest

# Wait for container to start
echo "Waiting for service to start..."
sleep 5

# ============================================================================
# Verify Deployment
# ============================================================================

echo "[6/6] Verifying deployment..."

# Check if container is running
if docker ps | grep -q ucehub-auth; then
  echo "✅ Container is running"
  
  # Test health endpoint
  sleep 3
  if curl -f http://localhost/health 2>/dev/null; then
    echo "✅ Health check passed"
  else
    echo "⚠️ Health check failed, but container is running"
  fi
else
  echo "❌ Container failed to start"
  docker logs ucehub-auth
  exit 1
fi

echo "=========================================="
echo "✅ UCEHub Auth Service Deployed Successfully!"
echo "Instance IP: $instanceIP"
echo "Environment: $environment"
echo "=========================================="
