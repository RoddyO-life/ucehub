# UCEHub - Servicios UCE en Microsoft Teams

## ✅ STATUS: READY FOR PRODUCTION

**Última Actualización**: Enero 20, 2026
**Versión**: 3.0.0  
**Estado**: Todos los bugs corregidos, listo para deployment

---

## 🎯 Inicio Rápido (5 minutos)

### 1️⃣ Configuración
```powershell
# Abrir PowerShell como Admin
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Navegar al proyecto
cd "C:\Users\ASUS TUF A15\Desktop\TERRAFORM\terraform-infraestructura-como-codigo\3-infra-con-terraform\ucehub"

# Verificar que terraform.tfvars tenga webhook
cat infrastructure/qa/terraform.tfvars
```

### 2️⃣ Deploy
```powershell
# Opción A: Automático (RECOMENDADO)
.\deploy-all.ps1 -Environment qa

# Opción B: Manual
cd infrastructure/qa
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 3️⃣ Esperar ~10 minutos hasta que esté ready

### 4️⃣ Test
```bash
curl http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health
```

---

## 📋 Descripción
Plataforma integrada en Microsoft Teams para centralizar servicios universitarios de la UCE.

## 🏗️ Arquitectura

```
Microsoft Teams App (React + Fluent UI)
            ↓
    ALB (Application Load Balancer)
            ↓
    EC2 Auto Scaling (1-5 instancias)
            ↓
    Express.js Backend
            ↓
    ┌─────────┬──────┬────────┐
    │DynamoDB │  S3  │ Teams  │
    └─────────┴──────┴────────┘
```

## 🗂️ Estructura del Proyecto

```
ucehub/
├── services/              # Backend APIs
│   ├── backend/           # Main API (Express.js)
│   ├── auth-service/      # Auth endpoints
│   └── Dockerfile
├── teams-app/             # Frontend (React + Vite)
│   ├── src/
│   ├── manifest/
│   └── vite.config.ts
├── infrastructure/        # IaC (Terraform)
│   ├── qa/               # QA Environment
│   ├── prod/             # Production (template)
│   └── modules/
│       ├── vpc/
│       ├── compute/
│       ├── load-balancer/
│       ├── dynamodb/
│       ├── s3/
│       └── security-groups/
├── scripts/              # Deployment & testing scripts
│   ├── deploy-full.ps1
│   ├── test-apis.sh
│   └── build-teams-app.sh
└── docs/                 # Documentation
```

## 🚀 Stack Tecnológico

### Backend
- **Runtime**: Node.js 18 (Docker)
- **Framework**: Express.js
- **Database**: AWS DynamoDB
- **Storage**: AWS S3
- **Notifications**: Microsoft Teams Webhooks
- **Infrastructure**: AWS EC2, ALB, ASG

### Frontend
- **Framework**: React 18
- **Build**: Vite
- **UI**: Fluent UI (Microsoft)
- **Teams SDK**: @microsoft/teams-js
- **Package Manager**: npm
- **Monitoring**: CloudWatch

### Frontend (Teams)
- **Framework**: React 18 + TypeScript
- **UI Library**: Fluent UI React v9
- **Teams SDK**: Teams Toolkit
- **State**: React Query + Zustand
- **Build**: Vite

### Infrastructure
- **IaC**: Terraform / AWS SAM
- **CI/CD**: GitHub Actions
- **Version Control**: Git

## 📦 Ambientes

| Ambiente | API URL | Database | Propósito |
|----------|---------|----------|-----------|
| QA       | TBD     | DynamoDB QA | Testing |
| Production | TBD   | DynamoDB Prod | Live |

## 🔧 Setup Local

### Prerequisitos
- Node.js 18+
- AWS CLI configurado
- Teams Toolkit para VS Code
- Cuenta Microsoft 365 Developer

### Instalación
```bash
# Clonar repositorio
git clone <repo-url>
cd ucehub

# Instalar dependencias Teams App
cd teams-app
npm install

# Instalar dependencias de servicios
cd ../services/auth-service
npm install
```

## 📝 Convenciones

### Commits
- `feat:` Nueva funcionalidad
- `fix:` Corrección de bugs
- `docs:` Documentación
- `refactor:` Refactorización
- `test:` Tests

### Branches
- `main` - Producción
- `develop` - QA
- `feature/*` - Nuevas funcionalidades
- `hotfix/*` - Fixes urgentes

## 🔐 Seguridad
- Autenticación: Microsoft Entra ID (Azure AD)
- Autorización: JWT + Lambda Authorizers
- Secrets: AWS Systems Manager Parameter Store
- HTTPS only

## 📖 Documentación

Ver carpeta `/docs` para:
- Arquitectura detallada
- Guía de desarrollo
- APIs documentation
- Deployment guides

## 👥 Equipo
Universidad Central del Ecuador (UCE)

## 📄 Licencia
Uso interno UCE
