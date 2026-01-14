# Auth Service

Servicio de autenticación para UCEHub.

## Funcionalidades

- ✅ Health check endpoint
- ✅ Login mock
- 🚧 Integración Microsoft SSO (próximamente)
- 🚧 Validación JWT (próximamente)

## Endpoints

### GET /auth
Health check del servicio.

**Response:**
```json
{
  "message": "UCEHub Auth Service - Running",
  "timestamp": "2025-12-01T...",
  "service": "auth-service",
  "version": "1.0.0"
}
```

### POST /auth/login
Login mock (sin validación real por ahora).

**Request:**
```json
{
  "email": "estudiante@uce.edu.ec",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": "12345",
    "email": "estudiante@uce.edu.ec",
    "name": "Juan Pérez",
    "role": "student"
  },
  "token": "mock-jwt-token-..."
}
```

## Deploy

```bash
# Comprimir y desplegar
npm run deploy

# Solo comprimir
npm run zip

# Desplegar manualmente
aws lambda update-function-code \
  --function-name ucehub-auth-service-qa \
  --zip-file fileb://function.zip
```

## Testing Local

```bash
# Instalar AWS SAM CLI
sam local invoke -e test-event.json
```

## Variables de Entorno

- `ENVIRONMENT`: qa | prod
- `JWT_SECRET`: (próximamente)
- `MS_CLIENT_ID`: (próximamente)
