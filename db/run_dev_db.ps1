# PowerShell helper to bring up dev DB using docker-compose
# Usage: Run this script from the repository root or directly in the db/ folder.
param()

$cwd = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $cwd

Write-Host "Starting dev DB (docker compose up -d) in $cwd..."
docker compose up -d

if ($LASTEXITCODE -eq 0) {
  Write-Host "Dev DB started."
  Write-Host "If you need to apply seeds manually, run:" -ForegroundColor Yellow
  Write-Host "  docker exec -it <pg_container_name> psql -U occi_user -d occitours_dev -f /workspace/db/seed_minimal.sql"
} else {
  Write-Host "docker compose failed. Ensure Docker is running." -ForegroundColor Red
}
