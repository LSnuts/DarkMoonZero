# Open for business - 一键启动脚本
# 启动后端、Cloudflare Tunnel、可选本地前端，并统一管理进程

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $ScriptDir "backend"
$FrontendDir = Join-Path $ScriptDir "frontend"
$PidFile = Join-Path $ScriptDir ".running_pids"
$TunnelConfig = Join-Path $ScriptDir "cloudflared.yml"
$ApiDomain = "api.8000021.xyz"

Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Dark Moon Zero" -ForegroundColor Yellow
Write-Host "  Open for business..." -ForegroundColor DarkYellow
Write-Host "================================" -ForegroundColor DarkYellow
Write-Host ""

if (Test-Path $PidFile) {
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}

function Test-PortInUse {
    param([int]$Port)
    try {
        return $null -ne (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop)
    } catch {
        $netstat = netstat -ano | Select-String ":$Port\s"
        return $null -ne $netstat
    }
}

function New-TunnelConfig {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        $content = @"
tunnel: darkmoonzero-backend
credentials-file: C:\Users\ASUS\.cloudflared\65b2c497-8ae9-4675-8e95-9431aa70c9c8.json
ingress:
  - hostname: $ApiDomain
    service: http://localhost:8000
  - service: http_status:404
"@
        $content | Set-Content -Path $Path -Encoding UTF8
        Write-Host "  [INFO] Created missing tunnel config: $Path" -ForegroundColor Green
    }
}

function Start-ProcessIfAvailable {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )
    try {
        if (-not (Get-Command $FilePath -ErrorAction SilentlyContinue)) {
            Write-Host "  [WARN] Command not found: $FilePath" -ForegroundColor Yellow
            return $null
        }
        return Start-Process -NoNewWindow -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -PassThru
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host ("  [ERROR] Failed to start " + $FilePath + ": " + $errorMessage) -ForegroundColor Red
        return $null
    }
}

New-TunnelConfig -Path $TunnelConfig

# 启动后端
Write-Host "[1/4] Starting backend (port 8000)..." -ForegroundColor Cyan
$backendProcess = $null
if (Test-PortInUse -Port 8000) {
    Write-Host "  [WARN] Port 8000 is already in use. Skipping backend startup." -ForegroundColor Yellow
} else {
    $backendProcess = Start-ProcessIfAvailable -FilePath "python" -Arguments @("-m","uvicorn","main:app","--host","127.0.0.1","--port","8000") -WorkingDirectory $BackendDir
    Start-Sleep -Seconds 3
    if ($backendProcess -and $backendProcess.HasExited) {
        Write-Host "  [FAILED] Backend failed to start." -ForegroundColor Red
        exit 1
    }
    if ($backendProcess) {
        Write-Host "  [OK] Backend running (PID: $($backendProcess.Id))" -ForegroundColor Green
    }
}

# 启动 Cloudflare Tunnel
Write-Host "[2/4] Starting Cloudflare Tunnel for $ApiDomain..." -ForegroundColor Cyan
$tunnelProcess = Start-ProcessIfAvailable -FilePath "cloudflared" -Arguments @("tunnel","--config","$TunnelConfig","run","darkmoonzero-backend") -WorkingDirectory $ScriptDir
Start-Sleep -Seconds 5
if ($tunnelProcess -and $tunnelProcess.HasExited) {
    Write-Host "  [FAILED] Cloudflare Tunnel failed to start." -ForegroundColor Red
    exit 1
}
if ($tunnelProcess) {
    Write-Host "  [OK] Cloudflare Tunnel running (PID: $($tunnelProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Cloudflare Tunnel not started." -ForegroundColor Yellow
}

# 启动本地前端（可选）
Write-Host "[3/4] Starting frontend (port 3000)..." -ForegroundColor Cyan
$frontendProcess = $null
if (Test-Path (Join-Path $FrontendDir "package.json")) {
    $frontendProcess = Start-ProcessIfAvailable -FilePath "npx.cmd" -Arguments @("vite","--host","0.0.0.0","--port","3000") -WorkingDirectory $FrontendDir
    Start-Sleep -Seconds 3
    if ($frontendProcess -and $frontendProcess.HasExited) {
        Write-Host "  [WARN] Frontend failed to start. Please make sure dependencies are installed." -ForegroundColor Yellow
        $frontendProcess = $null
    } elseif ($frontendProcess) {
        Write-Host "  [OK] Frontend running (PID: $($frontendProcess.Id))" -ForegroundColor Green
    }
} else {
    Write-Host "  [WARN] Frontend package.json not found, skipping frontend startup." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Open for business!" -ForegroundColor Yellow
if ($backendProcess) {
    Write-Host "  Backend: http://localhost:8000" -ForegroundColor Green
} else {
    Write-Host "  Backend: already running or skipped" -ForegroundColor Yellow
}
if ($tunnelProcess) {
    Write-Host "  Tunnel:  https://$ApiDomain" -ForegroundColor Green
} else {
    Write-Host "  Tunnel:  not started" -ForegroundColor Yellow
}
if ($frontendProcess) {
    Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Green
} else {
    Write-Host "  Frontend: not started" -ForegroundColor Yellow
}
Write-Host "  Close: .\stop.ps1" -ForegroundColor DarkYellow
Write-Host "================================" -ForegroundColor DarkYellow

$ids = @()
if ($backendProcess) { $ids += $backendProcess.Id }
if ($tunnelProcess) { $ids += $tunnelProcess.Id }
if ($frontendProcess) { $ids += $frontendProcess.Id }
if ($ids.Count -gt 0) { $ids | Out-File $PidFile -Encoding UTF8 }
