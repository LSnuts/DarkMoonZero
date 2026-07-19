# 暗月零点 - 启动脚本
# 同时启动后端 FastAPI 服务（端口 18080）和前端 Vite 开发服务器（端口 14080）

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $ScriptDir "backend"
$FrontendDir = Join-Path $ScriptDir "frontend"

Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Dark Moon Zero" -ForegroundColor Yellow
Write-Host "  The tavern is opening..." -ForegroundColor DarkYellow
Write-Host "================================" -ForegroundColor DarkYellow
Write-Host ""

# 启动后端
Write-Host "[1/2] Starting backend (port 18080)..." -ForegroundColor Cyan
$backendProcess = Start-Process -NoNewWindow -FilePath "python" -ArgumentList "-m uvicorn main:app --host 0.0.0.0 --port 18080 --reload" -WorkingDirectory $BackendDir -PassThru
Start-Sleep -Seconds 3

if ($backendProcess.HasExited) {
    Write-Host "  [FAILED] Backend failed to start." -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Backend running (PID: $($backendProcess.Id))" -ForegroundColor Green

# 启动前端
Write-Host "[2/2] Starting frontend (port 14080)..." -ForegroundColor Cyan
$frontendProcess = Start-Process -NoNewWindow -FilePath "npx.cmd" -ArgumentList "vite --host 0.0.0.0 --port 14080" -WorkingDirectory $FrontendDir -PassThru
Start-Sleep -Seconds 3

if ($frontendProcess.HasExited) {
    Write-Host "  [FAILED] Frontend failed to start." -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Frontend running (PID: $($frontendProcess.Id))" -ForegroundColor Green

Write-Host ""
Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Tavern is open!" -ForegroundColor Yellow
Write-Host "  Frontend: http://localhost:14080" -ForegroundColor Green
Write-Host "  Backend:  http://localhost:18080" -ForegroundColor Green
Write-Host "  Console:  http://localhost:18080/console" -ForegroundColor Green
Write-Host "  Close:    .\stop.ps1" -ForegroundColor DarkYellow
Write-Host "================================" -ForegroundColor DarkYellow

# 保存进程 ID 以便关闭脚本使用
$backendProcess.Id, $frontendProcess.Id | Out-File (Join-Path $ScriptDir ".running_pids") -Encoding UTF8
