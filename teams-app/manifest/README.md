# Teams App Manifest

Este directorio contiene los archivos necesarios para instalar la aplicación en Microsoft Teams.

## 📦 Crear el paquete para Teams

### Conversión de iconos SVG a PNG

Primero, necesitas convertir los iconos SVG a PNG:

**color-icon.png**: 192x192 píxeles
**outline-icon.png**: 32x32 píxeles

Puedes usar:
- https://cloudconvert.com/svg-to-png
- Photoshop / GIMP
- Online: https://svgtopng.com/

### Crear el ZIP

Una vez tengas los archivos PNG, crea un archivo ZIP con:
```
manifest/
├── manifest.json
├── color-icon.png (192x192)
└── outline-icon.png (32x32)
```

**Importante**: El ZIP debe contener los archivos directamente en la raíz, NO en una carpeta.

```bash
# En PowerShell (desde el directorio manifest/)
Compress-Archive -Path manifest.json,color-icon.png,outline-icon.png -DestinationPath ../UCEHub.zip -Force
```

## 🚀 Instalar en Teams Desktop

1. Abre **Microsoft Teams Desktop**
2. Click en **Apps** (esquina inferior izquierda)
3. Click en **Manage your apps** o **Administrar tus aplicaciones**
4. Click en **Upload an app** → **Upload a custom app**
5. Selecciona el archivo `UCEHub.zip`
6. Click en **Add** para añadir la app

## ⚙️ Configuración

### Para Desarrollo Local
El manifest está configurado para `http://localhost:3000`

### Para Producción
Edita `manifest.json` y cambia:
```json
"contentUrl": "https://tu-dominio.com/"
```

## 🔧 Validar Manifest

Usa el validador oficial de Microsoft:
https://dev.teams.microsoft.com/appvalidation.html

## 📚 Referencias

- [Teams App Manifest Schema](https://learn.microsoft.com/en-us/microsoftteams/platform/resources/schema/manifest-schema)
- [Teams Toolkit Documentation](https://learn.microsoft.com/en-us/microsoftteams/platform/toolkit/teams-toolkit-fundamentals)
