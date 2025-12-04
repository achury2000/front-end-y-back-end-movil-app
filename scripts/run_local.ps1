# Script de ayuda para ejecutar la app localmente en Windows PowerShell
# - Limpia build, elimina temporales de flutter_tools que causan errores en tests
# - Obtiene dependencias y ejecuta la app

Write-Host "-> Limpiando build y temporales..." -ForegroundColor Cyan
try {
    flutter clean
} catch {
    Write-Host "flutter clean falló (quizá no esté en PATH). Continúo..." -ForegroundColor Yellow
}

# Eliminar carpetas temporales flutter_tools.* que a veces generan PathNotFoundException
Write-Host "-> Eliminando directorios temporales 'flutter_tools.*' en %TEMP%..." -ForegroundColor Cyan
Get-ChildItem -Path $env:TEMP -Directory -Filter 'flutter_tools.*' -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Eliminando: $($_.FullName)" -ForegroundColor DarkGray
    Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "-> Obteniendo dependencias (flutter pub get)..." -ForegroundColor Cyan
flutter pub get

Write-Host "-> Iniciando la app (flutter run). Selecciona tu dispositivo/emulador si es necesario..." -ForegroundColor Cyan
flutter run

Write-Host "Listo. Si la app no arranca, copia aquí el error mostrado y te ayudo a solucionarlo." -ForegroundColor Green
