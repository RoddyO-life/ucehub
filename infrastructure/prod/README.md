# UCEHub Production Environment

## ⚠️ IMPORTANTE
Este ambiente es de **PRODUCCIÓN**. Cualquier cambio debe ser aprobado mediante **Pull Request**.

## Reviewer Requerido
- **@JuanGuevara90** - Debe aprobar antes de merge a producción

## Diferencias con QA

| Configuración | QA | Production |
|--------------|-----|------------|
| Instance Type | t3.nano | t3.small |
| Min Instances | 1 | 2 |
| Max Instances | 5 | 10 |
| Desired | 2 | 3 |
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| Deletion Protection | false | true |
| Detailed Monitoring | false | true |

## Despliegue

```bash
cd infrastructure/prod
terraform init
terraform plan
terraform apply
```

## Notas de Seguridad
- Deletion protection habilitado
- Monitoreo detallado habilitado
- Mínimo 2 instancias para alta disponibilidad
- SSH deshabilitado
