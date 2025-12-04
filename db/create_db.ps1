<#
.SYNOPSIS
  Script para crear la base de datos local y ejecutar el schema.sql incluido en el repo.

USAGE
  Desde PowerShell (ejecutar como administrador si es necesario):
    powershell -ExecutionPolicy Bypass -File db\create_db.ps1

  Opciones: el script pedirá la contraseña del superusuario `postgres` cuando sea necesario.

#>

param(
  [string]$PgUser = 'postgres',
  [string]$PgHost = 'localhost',
  [int]$PgPort = 5432,
  [string]$DbUser = 'occi_user',
  [string]$DbPass = 'secretpassword',
  [string]$DbName = 'occitours_dev',
  [string]$SchemaPath = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\schema.sql"
)

Write-Host "Preparando creación de base de datos '$DbName' en ${PgHost}:${PgPort} (usuario administrador: ${PgUser})" -ForegroundColor Cyan

function Run-PsqlCommand {
  param(
    [string]$Sql
  )
  $cmd = "psql -h $PgHost -p $PgPort -U $PgUser -c `"$Sql`""
  Write-Host "Ejecutando: $Sql" -ForegroundColor Yellow
  & psql -h $PgHost -p $PgPort -U $PgUser -c $Sql
  if ($LASTEXITCODE -ne 0) { throw "Error ejecutando psql." }
}

try {
  Write-Host "1) Creando usuario de aplicación (si no existe) ..." -ForegroundColor Green
  $roleExists = & psql -h $PgHost -p $PgPort -U $PgUser -tAc "SELECT 1 FROM pg_roles WHERE rolname = '$DbUser'"
  if ($roleExists -ne '1') {
    Write-Host "Rol $DbUser no existe. Creando..." -ForegroundColor Yellow
    & psql -h $PgHost -p $PgPort -U $PgUser -c "CREATE ROLE $DbUser LOGIN PASSWORD '$DbPass';"
    if ($LASTEXITCODE -ne 0) { throw "Error creando rol $DbUser." }
  } else {
    Write-Host "Rol $DbUser ya existe, omitiendo creación." -ForegroundColor Yellow
  }

  Write-Host "2) Creando base de datos (si no existe) ..." -ForegroundColor Green
  $exists = & psql -h $PgHost -p $PgPort -U $PgUser -tAc "SELECT 1 FROM pg_database WHERE datname = '$DbName'"
  if ($exists -ne '1') {
    & psql -h $PgHost -p $PgPort -U $PgUser -c "CREATE DATABASE $DbName OWNER $DbUser"
    if ($LASTEXITCODE -ne 0) { throw "Error creando la base de datos $DbName." }
  } else {
    Write-Host "Base de datos $DbName ya existe, omitiendo creación." -ForegroundColor Yellow
  }

  Write-Host "3) Otorgando privilegios ..." -ForegroundColor Green
  Run-PsqlCommand "GRANT ALL PRIVILEGES ON DATABASE $DbName TO $DbUser"

  Write-Host "4) Importando esquema desde: $SchemaPath" -ForegroundColor Green
  if (-Not (Test-Path $SchemaPath)) { throw "No se encontró $SchemaPath" }
  & psql -h $PgHost -p $PgPort -U $PgUser -d $DbName -f $SchemaPath
  if ($LASTEXITCODE -ne 0) { throw "Error importando el schema desde $SchemaPath" }

  Write-Host "Importación completada correctamente." -ForegroundColor Green
  Write-Host "Conectar como usuario app: psql -h ${PgHost} -p ${PgPort} -U ${DbUser} -d ${DbName}" -ForegroundColor Cyan
} catch {
  Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
