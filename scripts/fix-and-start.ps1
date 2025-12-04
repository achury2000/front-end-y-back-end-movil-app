<#
fix-and-start.ps1
Automatiza: detener procesos node, asegurar puerto libre, instalar deps y arrancar backend.

Uso:
  - Abre PowerShell como Administrador
  - Ejecuta:
      powershell -ExecutionPolicy Bypass -File .\scripts\fix-and-start.ps1

Advertencia: este script terminará procesos `node` en ejecución. Asegúrate de no tener otros servidores Node importantes abiertos.
#>

param(
    [int]$Port = 3000
)

function Stop-NodeProcesses {
    $nodes = Get-Process -Name node -ErrorAction SilentlyContinue
    if ($nodes) {
        Write-Host "Encontrados procesos node: $($nodes.Count). Terminando..." -ForegroundColor Yellow
        foreach ($n in $nodes) {
            try {
                Stop-Process -Id $n.Id -Force -ErrorAction Stop
                Write-Host "Detenido PID $($n.Id) ($($n.ProcessName))"
            } catch {
                Write-Host ("No se pudo detener PID {0}: {1}" -f $n.Id, $_) -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No hay procesos node activos." -ForegroundColor Green
    }
}

function Kill-Process-OnPort {
    param($port)
    # Try using Get-NetTCPConnection (may require elevated privileges)
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($conn) {
            $pids = $conn | Select-Object -ExpandProperty OwningProcess -Unique
            foreach ($pid in $pids) {
                try {
                    Stop-Process -Id $pid -Force -ErrorAction Stop
                    Write-Host "Matado proceso PID $pid que escuchaba en el puerto $port" -ForegroundColor Yellow
                } catch {
                    Write-Host ("No se pudo matar PID {0}: {1}" -f $pid, $_) -ForegroundColor Red
                }
            }
        } else {
            Write-Host "No hay procesos escuchando en el puerto $port (Get-NetTCPConnection)." -ForegroundColor Green
        }
    } catch {
        Write-Host "Get-NetTCPConnection no disponible o falló: $_" -ForegroundColor Yellow
        # Fallback a netstat + taskkill
        $net = & netstat -ano | findstr :$port
        if ($net) {
            $lines = $net -split "`n"
            foreach ($line in $lines) {
                $parts = $line -split '\s+' | Where-Object { $_ -ne '' }
                $pid = $parts[-1]
                if ($pid -and $pid -match '^[0-9]+$') {
                    try {
                        taskkill /PID $pid /F /T | Out-Null
                        Write-Host "Matado PID $pid (netstat fallback)" -ForegroundColor Yellow
                    } catch {
                        Write-Host ("No se pudo matar PID {0} (netstat fallback): {1}" -f $pid, $_) -ForegroundColor Red
                    }
                }
            }
        } else {
            Write-Host "No se detectaron procesos en el puerto $port (netstat fallback)." -ForegroundColor Green
        }
    }
}

function Start-Backend {
    Write-Host "Instalando dependencias y arrancando el backend..." -ForegroundColor Cyan
    Push-Location "$(Split-Path -Path $PSScriptRoot -Parent)\backend"
    try {
        & npm.cmd install
    } catch {
        Write-Host "npm install falló: $_" -ForegroundColor Red
    }
    try {
        Write-Host "Arrancando backend (npm run dev)..." -ForegroundColor Cyan
        # Arrancar en un proceso separado para evitar que prompts en la sesión actual terminen el servidor
        Start-Process -FilePath "npm.cmd" -ArgumentList "run","dev" -WorkingDirectory (Get-Location) -WindowStyle Normal
    } finally {
        Pop-Location
    }
}

Write-Host "=== fix-and-start.ps1: iniciar limpieza y arranque ===" -ForegroundColor Green
Stop-NodeProcesses
Kill-Process-OnPort -port $Port
Start-Backend
