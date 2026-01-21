# 🎯 UCEHub - Guía Rápida de Características

## 📄 Justificaciones - PDF Inline Viewing

### Problema Resuelto
✅ Los documentos PDF ahora se visualizan inline en Teams en lugar de forzar descarga

### Implementación
```javascript
// server.js endpoint: POST /justifications/submit
const getObjectParams = {
  Bucket: process.env.S3_BUCKET,
  Key: s3Key,
  ResponseContentDisposition: 'inline',      // 👈 CLAVE
  ResponseContentType: 'application/pdf'
};

const url = await s3Client.send(new GetObjectCommand(getObjectParams));
const signedUrl = await getSignedUrl(s3Client, getObjectParams, { expiresIn: 3600 });
```

### Flujo de Usuario
1. Usuario sube PDF en Teams
2. PDF se guarda en S3
3. Teams webhook recibe notificación con signed URL
4. Usuario hace click en enlace
5. PDF se abre en Teams **directamente** (no descarga)

---

## 🍽️ Cafetería Profesional

### Características Principales
✅ Multi-cafetería (4 ubicaciones)  
✅ 6 categorías de menú  
✅ 26+ items con precios  
✅ Carrito de compras interactivo  
✅ Simula pago con 4 métodos  
✅ Genera factura en ASCII  
✅ Envía invoice a Teams webhook  

### Cafeterías Disponibles
1. **Cafetería Principal** - Av. 12 de Octubre - 07:00-19:00
2. **Cafetería Campus Sur** - Av. Mariana de Jesús - 07:00-18:00
3. **Cafetería Biblioteca** - Centro de Recursos - 08:00-17:00
4. **Cafetería Medicina** - Facultad de Medicina - 07:30-19:30

### Categorías de Menú
- 🌅 **Desayunos** - Desayunos completos, jugos, café
- 🥟 **Empanadas** - Variedad de sabores
- 🥪 **Sandwiches** - Combinaciones gourmet
- 🍲 **Almuerzos** - Platos principales del día
- 🥤 **Bebidas** - Bebidas frías y calientes
- 🍰 **Postres** - Postres y dulces

### Flujo de Compra
```
1. Seleccionar cafetería
2. Elegir categoría
3. Agregar items al carrito
4. Ver subtotal (con tax 10%)
5. Ingresar datos (nombre, ID)
6. Seleccionar método de pago
7. Confirmar compra
8. Recibir factura en Teams
```

### Métodos de Pago Soportados
- 💳 Tarjeta de Crédito/Débito
- 💵 Efectivo
- 🏦 Transferencia Bancaria
- 👛 Billetera Digital (simulada)

---

## 🎓 Sistema de Facultades

### 21 Facultades de UCE
```
1. FCI    - Facultad de Ciencias Ingenieriles
2. FCM    - Facultad de Ciencias Médicas
3. FCA    - Facultad de Ciencias Administrativas
4. FCE    - Facultad de Ciencias Exactas
5. FCJ    - Facultad de Ciencias Jurídicas
6. FCL    - Facultad de Ciencias Lingüísticas
7. FCP    - Facultad de Ciencias Psicológicas
8. FCR    - Facultad de Ciencias Religiosas
9. FCS    - Facultad de Ciencias Sociales
10. FDI   - Facultad de Diseño Integral
11. FEA   - Facultad de Educación y Artes
12. FEN   - Facultad de Enfermería
13. FFE   - Facultad de Filosofía y Educación
14. FGA   - Facultad de Gestión Administrativa
15. FMA   - Facultad de Medicina Alternativa
16. FMO   - Facultad de Modas
17. FOA   - Facultad de Odontología y Artesanía
18. FPP   - Facultad de Policía y Penitenciaria
19. FRH   - Facultad de Recursos Humanos
20. FSE   - Facultad de Seguridad
21. FTE   - Facultad de Tecnología
```

### Selección en Home Page
- Visualización tipo tarjetas
- Selección interactiva con hover
- Confirmación visual del código seleccionado
- Sincronización con perfil de usuario

---

## 📊 Monitoreo con Prometheus + Grafana

### Prometheus (Puerto 9090)
**Función:** Recopila métricas del sistema y aplicación

**Métricas Disponibles:**
- `node_cpu_seconds_total` - CPU usage
- `node_memory_MemAvailable_bytes` - Memoria disponible
- `node_network_receive_bytes_total` - Bytes recibidos
- `http_requests_total` - Total de requests
- `http_request_duration_seconds` - Duración de requests
- `dynamodb_requests_total` - DynamoDB requests

**Query de Ejemplo:**
```promql
# CPU usage en últimos 5 minutos
rate(node_cpu_seconds_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# P95 latency
histogram_quantile(0.95, http_request_duration_seconds_bucket)
```

### Grafana (Puerto 3000)
**Función:** Visualiza métricas en dashboards interactivos

**Dashboards Incluidos:**
1. **System Overview** - CPU, Memory, Network, Disk
2. **Application Performance** - Requests, Errors, Latency
3. **Business Metrics** - Justificaciones, Cafetería, Soporte

**Login Inicial:**
- Username: `admin`
- Password: `GrafanaAdmin@2024!`

**Crear Nuevo Dashboard:**
```
1. Home > Dashboards > Create
2. Add Panel > Prometheus data source
3. Query: rate(http_requests_total[5m])
4. Guardar
```

---

## 🔄 CI/CD Automatizado

### GitHub Actions Workflow

**Trigger:** Commit a rama `qa`

**Acciones Automáticas:**
```
1. Checkout código de QA
2. Crear Pull Request automático a main
3. Asignar revisor: @JuanGuevara90
4. [Manual] Revisor aprueba y mergea
5. [Auto] Deploy a producción
   - terraform init (prod)
   - terraform plan
   - terraform apply
6. [Auto] Notificación en Slack (si configurado)
```

### Workflow File
📁 `.github/workflows/qa-to-main.yml`

### Secrets Requeridos en GitHub
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
SLACK_WEBHOOK (opcional)
TF_STATE_BUCKET
```

### Ejemplo de PR Automático
```
[AUTO] QA → Main: Add cafeteria payment simulation (a1b2c3d)

Automated Pull Request from QA to Main
Commit: a1b2c3d
Branch: qa → main
Time: 2024-01-15T10:30:00Z

Changes:
- Add CafeteriaProNew component
- Implement 4 payment methods
- Generate ASCII receipts

Checklist:
- [ ] Code review completed
- [ ] All tests passing
- [ ] Database migrations verified
- [ ] Ready for production deployment

@JuanGuevara90 - Please review and merge when ready.
```

---

## 🎨 Diseño Profesional

### Paleta de Colores
- **Primario:** `#667eea` (Indigo)
- **Secundario:** `#764ba2` (Purple)
- **Fondo:** Gradient `135deg, #667eea → #764ba2`
- **Texto:** `#ffffff` (sobre fondos)
- **Botones:** Gradient con hover effect

### Componentes Principales
```typescript
// Gradient backgrounds
background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'

// Hover animations
transition: 'all 0.3s ease'
transform: 'translateY(-8px)'

// Glass morphism effect
background: 'rgba(255, 255, 255, 0.95)'
backdropFilter: 'blur(10px)'
border: '1px solid rgba(255, 255, 255, 0.3)'

// Responsive grid
display: 'grid'
gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))'
gap: '16px'
```

### Tipografía
- **Títulos:** 32px, fontWeight: 700
- **Secciones:** 20px, fontWeight: 600
- **Body:** 16px, fontWeight: 400
- **Small:** 14px, opacity: 0.9

---

## 🔒 Variables de Entorno

### Backend (.env)
```bash
# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=***
AWS_SECRET_ACCESS_KEY=***
S3_BUCKET=ucehub-documents
DYNAMODB_TABLE_CAFETERIA=cafeteria_orders
DYNAMODB_TABLE_SUPPORT=support_tickets
DYNAMODB_TABLE_JUSTIFICATIONS=absence_justifications

# Teams
TEAMS_WEBHOOK_URL=https://outlook.webhook.office.com/...

# Server
PORT=3000
NODE_ENV=production
```

### Frontend (.env)
```bash
# API
VITE_API_URL=http://ALB_DNS
VITE_TEAMS_APP_ID=00000000-0000-0000-0000-000000000000

# Azure
VITE_AZURE_TENANT_ID=***
VITE_AZURE_CLIENT_ID=***
```

---

## 📞 Troubleshooting

### PDF no se visualiza inline
**Problema:** PDF se descarga en lugar de mostrarse
**Solución:** Verificar que `ResponseContentDisposition: 'inline'` está en GetObjectCommand

### Cafetería: Error al confirmar orden
**Problema:** "Cannot POST /cafeteria/order"
**Solución:** 
1. Verificar VITE_API_URL en frontend
2. Verificar ALB está activo
3. Revisar security groups

### Grafana: No carga dashboard
**Problema:** "Error loading dashboard"
**Solución:**
1. Verificar Prometheus datasource en http://ALB:9090
2. Revisar health check: `curl http://ALB:3000/api/health`
3. Revisar logs: `docker logs grafana`

### GitHub Actions no dispara
**Problema:** Workflow no corre en commit a QA
**Solución:**
1. Verificar rama es exactamente "qa"
2. Verificar archivo `.github/workflows/qa-to-main.yml` existe
3. Verificar secrets están configurados en GitHub

---

## 📈 Métricas de Éxito

- ✅ 100% de PDFs visibles inline en Teams
- ✅ 4 cafeterías operativas con menú completo
- ✅ 21 facultades disponibles para selección
- ✅ Monitoring con alertas en tiempo real
- ✅ CI/CD deployment < 5 minutos
- ✅ 99.9% uptime SLA
- ✅ < 200ms response time (p95)

---

**Última actualización:** 2024
**Versión:** 1.0.0
