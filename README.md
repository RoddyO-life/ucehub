# UCEHub - Servicios UCE en Microsoft Teams

## 📋 Descripción
Plataforma integrada en Microsoft Teams para centralizar servicios universitarios de la UCE.

## 🏗️ Arquitectura

```
Microsoft Teams App (React + Fluent UI)
            ↓
    API Gateway (AWS)
            ↓
    Lambda Functions
            ↓
    ┌─────────┬──────┐
    │DynamoDB │  S3  │
    └─────────┴──────┘
```

## 🗂️ Estructura del Proyecto

```
ucehub/
├── services/              # Microservicios (Lambda functions)
│   ├── auth-service/
│   ├── student-service/
│   ├── enrollment-service/
│   ├── documents-service/
│   └── shared/           # Código compartido
├── teams-app/            # Aplicación Microsoft Teams
│   ├── src/
│   ├── tabs/
│   └── manifest/
├── infrastructure/       # IaC (Terraform/CloudFormation)
│   ├── qa/
│   ├── prod/
│   └── modules/
├── scripts/             # Scripts de deployment
└── docs/               # Documentación

```

## 🚀 Stack Tecnológico

### Backend
- **Runtime**: Node.js 18.x / Python 3.11
- **API**: AWS API Gateway REST
- **Compute**: AWS Lambda
- **Database**: DynamoDB
- **Storage**: S3
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
