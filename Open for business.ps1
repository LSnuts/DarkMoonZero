# Open for business - 一键启动脚本
# 启动后端、Cloudflare Tunnel，以及可选的本地前端

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $ScriptDir "backend"
$FrontendDir = Join-Path $ScriptDir "frontend"
$PidFile = Join-Path $ScriptDir ".running_pids"
$TunnelName = "darkmoonzero-backend"
$ApiDomain = "api.8000021.xyz"

Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Dark Moon Zero" -ForegroundColor Yellow
Write-Host "  Open for business..." -ForegroundColor DarkYellow
Write-Host "================================" -ForegroundColor DarkYellow
Write-Host ""

# 清理旧 PID 文件
if (Test-Path $PidFile) {
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}

# 启动后端
Write-Host "[1/3] Starting backend (port 8000)..." -ForegroundColor Cyan
$backendProcess = Start-Process -NoNewWindow -FilePath "python" -ArgumentList "-m","uvicorn","main:app","--host","127.0.0.1","--port","8000" -WorkingDirectory $BackendDir -PassThru
Start-Sleep -Seconds 3
if ($backendProcess.HasExited) {
    Write-Host "  [FAILED] Backend failed to start." -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Backend running (PID: $($backendProcess.Id))" -ForegroundColor Green

# 启动 Cloudflare Tunnel
Write-Host "[2/3] Starting Cloudflare Tunnel for $ApiDomain..." -ForegroundColor Cyan
$tunnelProcess = Start-Process -NoNewWindow -FilePath "cloudflared" -ArgumentList "tunnel","run","--url","http://localhost:8000",$TunnelName -PassThru
Start-Sleep -Seconds 5
if ($tunnelProcess.HasExited) {
    Write-Host "  [FAILED] Cloudflare Tunnel failed to start." -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Cloudflare Tunnel running (PID: $($tunnelProcess.Id))" -ForegroundColor Green

# 启动本地前端（可选）
$frontendProcess = $null
if (Test-Path (Join-Path $FrontendDir "package.json")) {
    Write-Host "[3/3] Starting frontend (port 3000)..." -ForegroundColor Cyan
    $frontendProcess = Start-Process -NoNewWindow -FilePath "npx.cmd" -ArgumentList "vite","--host","0.0.0.0","--port","3000" -WorkingDirectory $FrontendDir -PassThru
    Start-Sleep -Seconds 3
    if ($frontendProcess.HasExited) {
        Write-Host "  [WARN] Frontend failed to start. Please make sure dependencies are installed." -ForegroundColor Yellow
        $frontendProcess = $null
    } else {
        Write-Host "  [OK] Frontend running (PID: $($frontendProcess.Id))" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Open for business!" -ForegroundColor Yellow
Write-Host "  Backend: http://localhost:8000" -ForegroundColor Green
Write-Host "  Tunnel:  https://$ApiDomain" -ForegroundColor Green
if ($frontendProcess) {
    Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Green
}
Write-Host "  Close: .\stop.ps1" -ForegroundColor DarkYellow
Write-Host "================================" -ForegroundColor DarkYellow

# 保存进程 ID 以便关闭脚本使用
$ids = @($backendProcess.Id, $tunnelProcess.Id)
if ($frontendProcess) { $ids += $frontendProcess.Id }
$ids | Out-File $PidFile -Encoding UTF8
