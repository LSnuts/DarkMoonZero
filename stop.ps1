# 暗月零点 - 关闭脚本
# 停止正在运行的后端和前端进程

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $ScriptDir ".running_pids"

Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Dark Moon Zero" -ForegroundColor Yellow
Write-Host "  Closing the bar..." -ForegroundColor DarkYellow
Write-Host "================================" -ForegroundColor DarkYellow

# 通过保存的 PID 文件关闭进程
if (Test-Path $pidFile) {
    $pids = Get-Content $pidFile -Encoding UTF8
    foreach ($procId in $pids) {
        $procId = $procId.Trim()
        if ($procId -and $procId -ne "") {
            $process = Get-Process -Id $procId -ErrorAction SilentlyContinue
            if ($process) {
                Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                Write-Host "  [OK] Closed PID: $procId" -ForegroundColor Green
            }
        }
    }
    Remove-Item $pidFile -Force
}

# 仅关闭由 Open for business 启动的进程（通过 PID 文件记录）
Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Bar closed. Good night." -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor DarkYellow
