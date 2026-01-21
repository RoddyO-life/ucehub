# UCEHub v3.0.1 - Guía de Testing

## 🧪 Pruebas de Cada Módulo Corregido

### 1️⃣ Grafana (URL de Monitoreo)

**Pasos de Test:**
1. Abrir la aplicación Teams
2. Ir a Home (página principal)
3. Buscar el card "📊 Monitoreo (Grafana)"
4. Hacer clic en "Acceder"
5. Verificar que se abre Grafana en una nueva ventana

**Validación:**
- ✅ Se abre en nueva pestaña
- ✅ URL es accesible
- ✅ Dashboard visible

**Datos Enviados:** Ninguno (solo abre URL)

---

### 2️⃣ Cafetería (Pedidos con Pago)

**Pasos de Test:**
1. Ir a "Cafetería UCE" desde Home
2. Seleccionar al menos un producto (haciendo clic en "Agregar")
3. Ver el carrito a la derecha
4. **IMPORTANTE**: Llenar nombre y email
5. Seleccionar hora de entrega
6. (Opcional) Agregar notas
7. Hacer clic en "✓ Proceder al Pago"

**Validación en Teams Webhook:**
El webhook debe recibir un mensaje como:
```json
{
  "@type": "MessageCard",
  "@context": "https://schema.org/extensions",
  "summary": "🍽️ Nueva Orden de Cafetería",
  "title": "🍽️ Nueva Orden de Cafetería",
  "text": "{username} ha realizado un pedido",
  "sections": [{
    "facts": [
      { "name": "Email", "value": "juan@email.com" },
      { "name": "Total", "value": "$7.50" },
      { "name": "Horario", "value": "12:00-13:00" },
      { "name": "Items", "value": "Almuerzo Completo, Jugo Natural" },
      { "name": "Orden ID", "value": "UUID-123..." }
    ]
  }]
}
```

**Cambios Respecto a Antes:**
- ✅ AHORA se pide nombre y email ANTES de pagar (antes no había)
- ✅ AHORA se envían datos completos al backend
- ✅ AHORA aparece en Teams correctamente

---

### 3️⃣ Justificaciones (Documentos PDF)

**Pasos de Test:**
1. Ir a "Mis Justificaciones"
2. Hacer clic en "Arrastra tu PDF aquí"
3. Seleccionar un PDF (máx 10 MB)
4. Llenar:
   - Motivo de ausencia (ej: "Cita médica")
   - Fecha de inicio
   - Fecha de fin (opcional)
5. Hacer clic en "📤 Enviar Justificación"

**Validación en Teams Webhook:**
```json
{
  "title": "📜 Nueva Justificación de Ausencia",
  "text": "Estudiante UCE ha enviado una justificación",
  "sections": [{
    "facts": [
      { "name": "Estudiante ID", "value": "EST-1705861234567" },
      { "name": "Email", "value": "estudiante@ucehub.edu.ec" },
      { "name": "Fecha", "value": "2026-01-21" },
      { "name": "Razón", "value": "Cita médica" },
      { "name": "Documento", "value": "✅ Adjuntado" },
      { "name": "Justificación ID", "value": "UUID-456..." }
    ]
  }]
}
```

**Cambios Respecto a Antes:**
- ✅ AHORA se envía el nombre y email correctamente
- ✅ AHORA el documento se guarda en S3
- ✅ AHORA aparece completo en Teams (antes vacío)

**Verificar en DynamoDB:**
```bash
# Tabla: absence-justifications
# Verificar que tiene: userName, userEmail, reason, documentUrl, documentName
```

---

### 4️⃣ Soporte (Tickets)

**Pasos de Test:**
1. Ir a "Soporte Técnico"
2. Llenar:
   - Título (ej: "No puedo descargar documentos")
   - Descripción (ej: "Los PDF no se abren")
   - Categoría (ej: "Técnico")
   - Prioridad (ej: "Alta")
3. Hacer clic en "✉️ Enviar Ticket"

**Validación en Teams Webhook:**
```json
{
  "title": "🎫 Nuevo Ticket de Soporte",
  "text": "Estudiante UCE ha creado un nuevo ticket",
  "sections": [{
    "facts": [
      { "name": "Email", "value": "estudiante@ucehub.edu.ec" },
      { "name": "Categoría", "value": "technical" },
      { "name": "Asunto", "value": "No puedo descargar documentos" },
      { "name": "Prioridad", "value": "high" },
      { "name": "Ticket ID", "value": "UUID-789..." }
    ]
  }]
}
```

**Cambios Respecto a Antes:**
- ✅ AHORA se envía email y nombre del usuario
- ✅ AHORA aparece el asunto/título
- ✅ AHORA los tickets NO vienen vacíos

**Verificar en DynamoDB:**
```bash
# Tabla: support-tickets
# Verificar: ticketId, userName, userEmail, subject, description, priority, status
```

---

### 5️⃣ Descargas de Documentos

**Pasos de Test:**
1. Completar una Justificación (ver sección 3)
2. Ver el historial de justificaciones
3. Hacer clic en "Ver PDF"
4. Verificar que se descarga o abre el PDF

**Endpoints Disponibles:**

#### a) Descarga Directa
```bash
GET /documents/download/{documentId}/{fileName}

# Ejemplo:
curl http://localhost:3001/documents/download/abc-123/documento.pdf \
  -o documento.pdf
```

**Response Headers:**
```
Content-Type: application/pdf
Content-Disposition: attachment; filename="documento.pdf"
```

#### b) URL Presignada (alternativa)
```bash
GET /documents/presigned/{documentId}/{fileName}

# Response:
{
  "success": true,
  "data": {
    "url": "https://s3.amazonaws.com/...",
    "fileName": "documento.pdf",
    "expiresIn": 3600
  }
}
```

**Cambios Respecto a Antes:**
- ✅ AHORA hay endpoints funcionales para descargas
- ✅ AHORA los PDF se abren correctamente
- ✅ AHORA S3 está integrado para almacenamiento

---

## 🔍 Verificación de Datos en Backend

### Ver Órdenes de Cafetería
```bash
curl http://localhost:3001/cafeteria/orders
```

Response esperado:
```json
{
  "success": true,
  "data": [
    {
      "orderId": "uuid",
      "userName": "Juan Pérez",
      "userEmail": "juan@email.com",
      "items": [{...}],
      "totalPrice": 7.50,
      "deliveryTime": "12:00-13:00",
      "status": "pending",
      "createdAt": "2026-01-21T15:30:00Z"
    }
  ]
}
```

### Ver Justificaciones
```bash
curl http://localhost:3001/justifications/list
```

Response esperado:
```json
{
  "success": true,
  "data": [
    {
      "justificationId": "uuid",
      "userName": "Estudiante UCE",
      "userEmail": "estudiante@ucehub.edu.ec",
      "studentId": "EST-123",
      "reason": "Cita médica",
      "date": "2026-01-21",
      "documentUrl": "https://s3.amazonaws.com/...",
      "documentName": "documento.pdf",
      "status": "pending",
      "createdAt": "2026-01-21T15:30:00Z"
    }
  ]
}
```

### Ver Tickets de Soporte
```bash
curl http://localhost:3001/support/tickets
```

Response esperado:
```json
{
  "success": true,
  "data": [
    {
      "ticketId": "uuid",
      "userName": "Estudiante UCE",
      "userEmail": "estudiante@ucehub.edu.ec",
      "subject": "No puedo descargar documentos",
      "description": "Los PDF no se abren",
      "category": "technical",
      "priority": "high",
      "status": "open",
      "createdAt": "2026-01-21T15:30:00Z"
    }
  ]
}
```

---

## 📊 Checklist de Validación Completa

| Item | Antes | Después | ✓ |
|------|-------|---------|---|
| Grafana se abre | ✗ | ✓ | [ ] |
| Cafetería pide nombre | ✗ | ✓ | [ ] |
| Cafetería pide email | ✗ | ✓ | [ ] |
| Justificación en Teams | Vacío | Completo | [ ] |
| Tickets en Teams | Vacío | Completo | [ ] |
| PDFs descargan | ✗ | ✓ | [ ] |
| Datos en DynamoDB | Incompletos | Completos | [ ] |
| Imágenes Docker | Antigua | v3.0.1 | [ ] |

---

## 🚀 Cómo Ejecutar Las Pruebas

### Opción 1: Local (sin Deploy)
```bash
cd ucehub/teams-app
npm install
npm run dev

# En otro terminal:
cd ucehub/services/backend
npm install
node server-production.js
```

### Opción 2: Deploy en AWS
```bash
cd ucehub/infrastructure/qa
.\deploy-fixes-v3.0.1.ps1 -Environment qa
```

### Opción 3: Manual
```bash
cd ucehub/infrastructure/qa
terraform plan -out=tfplan
terraform apply tfplan
```

---

## 📝 Logs para Debugging

### Backend Logs
```bash
# Ver logs en producción
aws logs tail /aws/ecs/ucehub-backend-qa --follow

# Buscar errores específicos
aws logs tail /aws/ecs/ucehub-backend-qa --follow \
  --filter-pattern "ERROR"
```

### CloudWatch Metrics
- Check: `RequestCount`
- Check: `TargetResponseTime`
- Check: `HealthyHostCount`
- Check: `HTTPCode_Target_5XX_Count`

---

## ⚠️ Troubleshooting

### Problema: Grafana no se abre
**Solución:** Verificar que `VITE_GRAFANA_URL` está configurado en `.env`

### Problema: PDF no se descarga
**Solución:** 
1. Verificar que S3 bucket existe
2. Verificar permisos IAM de EC2
3. Ver logs del backend: `docker logs <container_id>`

### Problema: Teams no recibe notificaciones
**Solución:**
1. Verificar URL del webhook en terraform.tfvars
2. Verificar que webhook está activo en Teams
3. Ver logs: `docker logs <container_id> | grep Teams`

### Problema: Datos vacíos en DynamoDB
**Solución:**
1. Verificar tabla existe
2. Verificar nombre de tabla en env variables
3. Verificar permisos IAM

---

## 📞 Contacto y Soporte

Para reportar bugs o problemas:
1. Crear un ticket en /support
2. Incluir logs del backend
3. Incluir screenshot del error
4. Incluir pasos para reproducir

---

**Versión:** 3.0.1  
**Última actualización:** 21 de Enero de 2026
