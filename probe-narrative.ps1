# Diagnostic probe - mirrors the first half of start-narrative.ps1
# Run with: .\probe-narrative.ps1

$ErrorActionPreference = 'Stop'
Write-Host "1: top of script reached" -ForegroundColor Cyan

$repo      = "C:\Users\Dan_P\Documents\NarrativeGames"
$mcpScript = Join-Path $repo "start-mcp.ps1"
$port      = 8090
$logDir    = Join-Path $env:LOCALAPPDATA "NarrativeGames"
$tunnelLog = Join-Path $logDir "cloudflared.log"
Write-Host "2: vars set"
Write-Host "   mcpScript exists? $(Test-Path $mcpScript)"
Write-Host "   logDir exists?    $(Test-Path $logDir)"

if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
Write-Host "3: logDir ensured"

Set-Content -Path $tunnelLog -Value "" -Encoding ascii
Write-Host "4: tunnel log truncated"

$mcpAlreadyRunning = $null
try {
    $mcpAlreadyRunning = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop
    Write-Host "5: port $port is ALREADY listening (PID(s): $($mcpAlreadyRunning.OwningProcess -join ','))" -ForegroundColor Yellow
} catch {
    Write-Host "5: port $port is free (will start MCP)"
}

Write-Host "6: about to Start-Process a test child window..."
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "Write-Host 'CHILD WINDOW OK - close me' -ForegroundColor Green"
) | Out-Null
Write-Host "7: Start-Process returned"

Write-Host ""
Write-Host "ALL STEPS COMPLETED. If you see this line, the hang is NOT in steps 1-7." -ForegroundColor Green
Read-Host "Press Enter to exit probe"
