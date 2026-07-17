$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $ScriptDir ".running_pids"

Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Dark Moon Zero" -ForegroundColor Yellow
Write-Host "  Closing the bar..." -ForegroundColor DarkYellow
Write-Host "================================" -ForegroundColor DarkYellow

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

Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -match "uvicorn"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -match "vite"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "================================" -ForegroundColor DarkYellow
Write-Host "  Bar closed. Good night." -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor DarkYellow