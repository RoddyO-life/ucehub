# Script para crear el paquete de Teams App
# Requiere tener instalado ImageMagick o usar una conversion online

Write-Host "Creando paquete UCEHub para Microsoft Teams..." -ForegroundColor Green
Write-Host ""

$manifestDir = ".\manifest"
$outputZip = ".\UCEHub.zip"

# Verificar que existe el directorio manifest
if (-not (Test-Path $manifestDir)) {
    Write-Host "Error: No existe el directorio manifest/" -ForegroundColor Red
    exit 1
}

# Verificar manifest.json
if (-not (Test-Path "$manifestDir\manifest.json")) {
    Write-Host "Error: No existe manifest.json" -ForegroundColor Red
    exit 1
}

Write-Host "Verificando iconos..." -ForegroundColor Cyan

# Verificar si existen los PNG, si no, dar instrucciones
$colorIconPng = "$manifestDir\color-icon.png"
$outlineIconPng = "$manifestDir\outline-icon.png"

if (-not (Test-Path $colorIconPng) -or -not (Test-Path $outlineIconPng)) {
    Write-Host "Los iconos PNG no existen. Necesitas convertir los SVG a PNG:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opcion 1 - Online (Recomendado):" -ForegroundColor White
    Write-Host "  1. Ve a: https://cloudconvert.com/svg-to-png" -ForegroundColor Gray
    Write-Host "  2. Sube color-icon.svg y conviertelo a 192x192 PNG" -ForegroundColor Gray
    Write-Host "  3. Sube outline-icon.svg y conviertelo a 32x32 PNG" -ForegroundColor Gray
    Write-Host "  4. Guarda ambos en manifest/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Opcion 2 - ImageMagick (si lo tienes instalado):" -ForegroundColor White
    Write-Host "  magick convert -resize 192x192 manifest\color-icon.svg manifest\color-icon.png" -ForegroundColor Gray
    Write-Host "  magick convert -resize 32x32 manifest\outline-icon.svg manifest\outline-icon.png" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Opcion 3 - PowerShell con .NET (Alternativa):" -ForegroundColor White
    Write-Host "  Usa cualquier editor de imagenes o herramienta online" -ForegroundColor Gray
    Write-Host ""
    
    # Preguntar si quiere crear iconos temporales simples
    $response = Read-Host "Quieres que cree iconos PNG basicos para prueba? (s/n)"
    if ($response -eq "s" -or $response -eq "S") {
        Write-Host "Creando iconos temporales basicos (solo para prueba)..." -ForegroundColor Yellow
        
        # Crear un PNG simple con PowerShell
        # Nota: Esto requiere System.Drawing
        Add-Type -AssemblyName System.Drawing
        
        try {
            # Color icon 192x192
            $colorBitmap = New-Object System.Drawing.Bitmap(192, 192)
            $graphics = [System.Drawing.Graphics]::FromImage($colorBitmap)
            $graphics.Clear([System.Drawing.Color]::FromArgb(0, 120, 212))
            $font = New-Object System.Drawing.Font("Arial", 60, [System.Drawing.FontStyle]::Bold)
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $graphics.DrawString("UCE", $font, $brush, 30, 65)
            $colorBitmap.Save($colorIconPng, [System.Drawing.Imaging.ImageFormat]::Png)
            $graphics.Dispose()
            $colorBitmap.Dispose()
            Write-Host "  OK color-icon.png creado" -ForegroundColor Green
            
            # Outline icon 32x32
            $outlineBitmap = New-Object System.Drawing.Bitmap(32, 32)
            $graphics2 = [System.Drawing.Graphics]::FromImage($outlineBitmap)
            $graphics2.Clear([System.Drawing.Color]::White)
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 2)
            $graphics2.DrawRectangle($pen, 2, 2, 28, 28)
            $font2 = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
            $brush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
            $graphics2.DrawString("U", $font2, $brush2, 9, 8)
            $outlineBitmap.Save($outlineIconPng, [System.Drawing.Imaging.ImageFormat]::Png)
            $graphics2.Dispose()
            $outlineBitmap.Dispose()
            Write-Host "  OK outline-icon.png creado" -ForegroundColor Green
        }
        catch {
            Write-Host "  Error al crear iconos: $_" -ForegroundColor Red
            Write-Host "  Por favor, usa una herramienta online para convertirlos" -ForegroundColor Yellow
            exit 1
        }
    }
    else {
        Write-Host ""
        Write-Host "Por favor, crea los iconos PNG y vuelve a ejecutar este script" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "OK Iconos encontrados" -ForegroundColor Green
Write-Host ""

# Eliminar ZIP anterior si existe
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
    Write-Host "ZIP anterior eliminado" -ForegroundColor Gray
}

# Crear el ZIP
Write-Host "Creando archivo ZIP..." -ForegroundColor Cyan

try {
    # Crear el ZIP directamente con los archivos en la raíz
    $files = @(
        "$manifestDir\manifest.json",
        "$manifestDir\color-icon.png",
        "$manifestDir\outline-icon.png"
    )
    
    Compress-Archive -Path $files -DestinationPath $outputZip -Force
    
    Write-Host "OK Paquete creado exitosamente: $outputZip" -ForegroundColor Green
    Write-Host ""
    Write-Host "Contenido del paquete:" -ForegroundColor Cyan
    Get-ChildItem $manifestDir\*.json, $manifestDir\*.png | Select-Object Name, Length | Format-Table
    
    Write-Host ""
    Write-Host "Listo! Ahora puedes instalar la app en Microsoft Teams" -ForegroundColor Green
    Write-Host ""
    Write-Host "Pasos para instalar en Teams Desktop:" -ForegroundColor Cyan
    Write-Host "  1. Abre Microsoft Teams Desktop" -ForegroundColor White
    Write-Host "  2. Click en 'Apps' (esquina inferior izquierda)" -ForegroundColor White
    Write-Host "  3. Click en 'Manage your apps' o 'Administrar aplicaciones'" -ForegroundColor White
    Write-Host "  4. Click en 'Upload an app' → 'Upload a custom app'" -ForegroundColor White
    Write-Host "  5. Selecciona el archivo: $outputZip" -ForegroundColor Yellow
    Write-Host "  6. Click en 'Add' para instalar" -ForegroundColor White
    Write-Host ""
    Write-Host "Importante: Asegurate de que el servidor este corriendo en http://localhost:3000" -ForegroundColor Yellow
    Write-Host "   (ejecuta 'npm run dev' si no esta corriendo)" -ForegroundColor Gray
    Write-Host ""
    
}
catch {
    Write-Host "Error al crear el ZIP: $_" -ForegroundColor Red
    exit 1
}
