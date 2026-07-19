# 暗月零点 - 关闭脚本（强力版）
# 按进程名杀干净，不依赖 PID 文件

Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Dark Moon Zero" -ForegroundColor Yellow
Write-Host "  Closing the bar..." -ForegroundColor DarkYellow
Write-Host "================================" -ForegroundColor DarkYellow

# PID 文件方式（兼容旧版）
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $ScriptDir ".running_pids"
if (Test-Path $pidFile) {
    $pids = Get-Content $pidFile -Encoding UTF8
    foreach ($procId in $pids) {
        $procId = $procId.Trim()
        if ($procId -and $procId -ne "") {
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        }
    }
    Remove-Item $pidFile -Force
}

# 强力清理：按进程名杀 uvicorn / cloudflared / vite
$killed = $false
Get-Process -Name "python" -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Killed python PID: $($_.Id)" -ForegroundColor Green
    $killed = $true
}
Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Killed cloudflared PID: $($_.Id)" -ForegroundColor Green
    $killed = $true
}
Get-Process -Name "node" -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Killed node PID: $($_.Id)" -ForegroundColor Green
    $killed = $true
}

if (-not $killed) {
    Write-Host "  No running processes found." -ForegroundColor Yellow
}

# 等待端口释放
Start-Sleep -Seconds 2

Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Bar closed. Good night." -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor DarkYellow
