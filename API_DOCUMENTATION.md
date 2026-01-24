# 📡 UCEHub - API Documentation

## Base URL
```
Development: http://localhost:3000
QA: http://ALB_DNS
Production: https://ucehub.edu.ec
```

---

## 🏥 Health & Status

### GET /health
**Description:** Verifica el estado del servidor

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z",
  "environment": "production"
}
```

---

## 📄 Justifications API

### POST /justifications/submit
**Description:** Envía una nueva justificación de ausencia

**Headers:**
```
Content-Type: multipart/form-data
Authorization: Bearer {token}
```

**Body:**
```
file: <PDF binary>
reason: "Cita médica"
startDate: "2024-01-15"
endDate: "2024-01-16" (opcional)
```

**Response (201):**
```json
{
  "success": true,
  "message": "Justificación enviada exitosamente",
  "data": {
    "id": "just-123456",
    "s3Url": "https://s3.amazonaws.com/ucehub-documents/just-123456.pdf",
    "status": "pending",
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

**Error (400):**
```json
{
  "success": false,
  "error": "El motivo es requerido",
  "details": "Missing required field: reason"
}
```

**Error (413):**
```json
{
  "success": false,
  "error": "Archivo muy grande",
  "details": "Max file size: 10 MB"
}
```

---

## 🍽️ Cafetería API

### GET /cafeteria/menu
**Description:** Obtiene el menú completo

**Query Parameters:**
```
?cafeteria=1        # ID de cafetería (opcional)
?category=desayunos # Categoría (opcional)
```

**Response:**
```json
{
  "success": true,
  "data": {
    "cafeterias": [
      {
        "id": "1",
        "nombre": "Cafetería Principal",
        "ubicacion": "Av. 12 de Octubre",
        "horario": "07:00 - 19:00",
        "items": [
          {
            "id": "des1",
            "nombre": "Desayuno Completo",
            "categoria": "desayunos",
            "precio": 5.50,
            "descripcion": "Pan tostado, jugo, café y frutas"
          }
        ]
      }
    ]
  }
}
```

### POST /cafeteria/order
**Description:** Crea un nuevo pedido

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Body:**
```json
{
  "cafeteriaId": "1",
  "items": [
    {
      "itemId": "des1",
      "quantity": 1,
      "price": 5.50
    },
    {
      "itemId": "beb1",
      "quantity": 2,
      "price": 2.00
    }
  ],
  "paymentMethod": "card",
  "taxPercentage": 10,
  "customerName": "Juan Pérez",
  "customerId": "123456",
  "observations": "Sin cebolla" (opcional)
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Pedido creado exitosamente",
  "data": {
    "orderId": "ORD-20240115-001",
    "total": 15.95,
    "subtotal": 14.50,
    "tax": 1.45,
    "paymentMethod": "card",
    "status": "confirmed",
    "estimatedTime": "15 minutos",
    "invoice": "FCT-20240115-001"
  }
}
```

### GET /cafeteria/orders
**Description:** Obtiene historial de pedidos del usuario

**Query Parameters:**
```
?limit=10    # Número de registros
?offset=0    # Desplazamiento
?status=all  # all, completed, pending, cancelled
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total": 12,
    "orders": [
      {
        "orderId": "ORD-20240115-001",
        "date": "2024-01-15T10:30:00Z",
        "items": 2,
        "total": 15.95,
        "status": "completed"
      }
    ]
  }
}
```

---

## 🎫 Support Tickets API

### POST /support/ticket
**Description:** Crea un nuevo ticket de soporte

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Body:**
```json
{
  "title": "No puedo acceder al portal",
  "description": "Error 503 al intentar ingresar. He intentado 3 veces.",
  "category": "technical",
  "priority": "high",
  "attachments": [] (opcional)
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "ticketId": "TK-2024-001",
    "status": "open",
    "createdAt": "2024-01-15T10:30:00Z",
    "estimatedResponse": "24 horas"
  }
}
```

### GET /support/tickets
**Description:** Obtiene lista de tickets del usuario

**Query Parameters:**
```
?status=all           # all, open, in-progress, resolved, closed
?priority=all         # all, low, medium, high
?sortBy=created       # created, updated, priority
?order=desc           # asc, desc
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total": 5,
    "tickets": [
      {
        "ticketId": "TK-2024-001",
        "title": "No puedo acceder al portal",
        "status": "in-progress",
        "priority": "high",
        "createdAt": "2024-01-10T08:00:00Z",
        "lastUpdated": "2024-01-15T10:30:00Z",
        "responses": 2
      }
    ]
  }
}
```

### GET /support/tickets/:ticketId
**Description:** Obtiene detalles de un ticket específico

**Response:**
```json
{
  "success": true,
  "data": {
    "ticketId": "TK-2024-001",
    "title": "No puedo acceder al portal",
    "description": "Error 503 al intentar ingresar...",
    "category": "technical",
    "priority": "high",
    "status": "in-progress",
    "createdAt": "2024-01-10T08:00:00Z",
    "conversations": [
      {
        "id": "msg-1",
        "from": "support@ucehub.edu.ec",
        "message": "Hola, gracias por contactarnos...",
        "timestamp": "2024-01-10T09:00:00Z"
      }
    ]
  }
}
```

### POST /support/tickets/:ticketId/reply
**Description:** Añade una respuesta a un ticket

**Body:**
```json
{
  "message": "Gracias, el problema se resolvió",
  "attachments": []
}
```

**Response:**
```json
{
  "success": true,
  "message": "Respuesta agregada exitosamente"
}
```

---

## 👥 User & Authentication

### GET /user/profile
**Description:** Obtiene perfil del usuario autenticado

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user-123",
    "name": "Juan Pérez",
    "email": "juan@ucehub.edu.ec",
    "facultyId": "1",
    "facultyName": "Facultad de Ciencias Ingenieriles",
    "studentId": "2024-001",
    "teamsId": "teams-user-id",
    "createdAt": "2023-09-01T00:00:00Z"
  }
}
```

### PUT /user/profile
**Description:** Actualiza perfil del usuario

**Body:**
```json
{
  "name": "Juan Pérez Gonzáles",
  "facultyId": "2",
  "phone": "+593 99 1234567"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Perfil actualizado exitosamente"
}
```

---

## 📊 Analytics & Monitoring

### GET /analytics/dashboard
**Description:** Obtiene métricas del dashboard

**Query Parameters:**
```
?period=month   # day, week, month, year
?metric=all     # all, justifications, cafeteria, support
```

**Response:**
```json
{
  "success": true,
  "data": {
    "period": "month",
    "metrics": {
      "justificationsSubmitted": 3,
      "cafeteriaOrders": 12,
      "supportTickets": 1,
      "systemUptime": "99.9%"
    }
  }
}
```

### GET /prometheus/metrics
**Description:** Exporta métricas en formato Prometheus

**Response (text/plain):**
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="POST",endpoint="/cafeteria/order"} 125
http_requests_total{method="GET",endpoint="/justifications/list"} 456

# HELP http_request_duration_seconds Request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{endpoint="/cafeteria/order",le="0.1"} 100
```

---

## 🔐 Error Codes

| Code | Status | Mensaje |
|------|--------|---------|
| 200 | OK | Solicitud exitosa |
| 201 | Created | Recurso creado |
| 400 | Bad Request | Datos inválidos |
| 401 | Unauthorized | No autenticado |
| 403 | Forbidden | No autorizado |
| 404 | Not Found | Recurso no existe |
| 409 | Conflict | Conflicto de datos |
| 413 | Payload Too Large | Archivo muy grande |
| 429 | Too Many Requests | Demasiadas solicitudes |
| 500 | Internal Server Error | Error del servidor |
| 503 | Service Unavailable | Servicio no disponible |

---

## 🔄 Rate Limiting

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642252800
```

**Límites por endpoint:**
- General: 100 requests/hora
- /cafeteria/order: 500 requests/hora
- /support/ticket: 50 requests/hora

---

## 📝 Example Requests

### Crear justificación con cURL
```bash
curl -X POST http://ALB_DNS/justifications/submit \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@documento.pdf" \
  -F "reason=Cita médica" \
  -F "startDate=2024-01-15" \
  -F "endDate=2024-01-16"
```

### Crear pedido con cURL
```bash
curl -X POST http://ALB_DNS/cafeteria/order \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "cafeteriaId": "1",
    "items": [
      {"itemId": "des1", "quantity": 1, "price": 5.50}
    ],
    "paymentMethod": "card",
    "customerName": "Juan Pérez",
    "customerId": "123456"
  }'
```

### Crear ticket de soporte con cURL
```bash
curl -X POST http://ALB_DNS/support/ticket \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "title": "Error al descargar certificado",
    "description": "No puedo descargar mi certificado académico",
    "category": "technical",
    "priority": "medium"
  }'
```

---

## 🔗 Webhooks

### Teams Notification
**Event:** Justificación enviada, Pedido confirmado, Ticket creado

**Payload:**
```json
{
  "type": "message",
  "attachments": [{
    "contentType": "application/vnd.microsoft.card.adaptive",
    "content": {
      "type": "AdaptiveCard",
      "version": "1.4",
      "body": [
        {
          "type": "TextBlock",
          "text": "Justificación Registrada",
          "weight": "bolder"
        }
      ]
    }
  }]
}
```

---

## 📚 Documentación Adicional

- [Guía de Características](FEATURES_GUIDE.md)
- [Guía de Implementación](IMPLEMENTATION_COMPLETE.md)
- [Resumen de Deployment](DEPLOYMENT_SUMMARY.md)

---

**API Version:** 1.0.0  
**Last Updated:** 2024  
**Maintainer:** UCEHub Development Team
