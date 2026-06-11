# Boots the Narrative Adventure stack at login:
#   1. Local MCP filesystem server (port 8090) via start-mcp.ps1
#   2. Cloudflare quick tunnel exposing it publicly
#   3. Copies the new public /mcp URL to clipboard, opens the claude.ai
#      connectors page, and shows a top-most popup with the URL so the
#      NarrativeGames connector can be updated by hand.
#      (mcp-proxy exposes both /sse legacy and /mcp Streamable HTTP;
#      claude.ai's connectors require Streamable HTTP, so we publish /mcp.)

$ErrorActionPreference = 'Stop'

$repo          = "C:\Users\Dan_P\Documents\NarrativeGames"
$mcpScript     = Join-Path $repo "start-mcp.ps1"
$port          = 8090
$logDir        = Join-Path $env:LOCALAPPDATA "NarrativeGames"
$tunnelLog     = Join-Path $logDir "cloudflared.log"
$connectorsUrl = "https://claude.ai/settings/connectors"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
# Truncate previous log so the URL match below is unambiguous
Set-Content -Path $tunnelLog -Value "" -Encoding ascii

# --- 1. Start MCP server in its own window (skip if port already bound) ---
# Use a direct TCP connect rather than Get-NetTCPConnection: the latter is
# CIM/WMI-backed and can hang indefinitely if the WMI service is stuck.
function Test-PortListening($p) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $client.BeginConnect('127.0.0.1', $p, $null, $null)
        if ($iar.AsyncWaitHandle.WaitOne(500)) {
            $client.EndConnect($iar)
            return $true
        }
        return $false
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}
$mcpAlreadyRunning = Test-PortListening $port

if ($mcpAlreadyRunning) {
    Write-Host "MCP server already listening on port $port - skipping start." -ForegroundColor Yellow
} else {
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy", "Bypass",
        "-File", $mcpScript
    ) | Out-Null
    Write-Host "Starting MCP server on port $port..." -ForegroundColor Cyan
    # Give the MCP server time to bind before the tunnel attaches
    Start-Sleep -Seconds 5
}

# --- 2. Start Cloudflare quick tunnel in its own visible PowerShell window ---
# Pipe cloudflared output through ForEach-Object so each line is both
# echoed live to the window AND appended to the log (Add-Content writes
# ASCII by default in Windows PowerShell 5.1, so URL parsing below works).
$cfCmd = "& { cloudflared tunnel --no-autoupdate --url http://localhost:$port 2>&1 | ForEach-Object { `$l = `$_.ToString(); Write-Host `$l; Add-Content -Path '$tunnelLog' -Value `$l } }"
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command", $cfCmd
) | Out-Null
Write-Host "Starting cloudflared quick tunnel..." -ForegroundColor Cyan

# --- 3. Wait for the trycloudflare URL to appear in the log ---
$publicUrl = $null
$deadline  = (Get-Date).AddMinutes(2)
while ((Get-Date) -lt $deadline -and -not $publicUrl) {
    Start-Sleep -Seconds 1
    $match = Get-Content -Path $tunnelLog -ErrorAction SilentlyContinue |
             Select-String -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' |
             Select-Object -First 1
    if ($match) {
        $publicUrl = $match.Matches[0].Value
    }
}

if (-not $publicUrl) {
    Write-Host "Timed out waiting for cloudflared URL. Check $tunnelLog" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    return
}

$mcpUrl = "$publicUrl/mcp"

# --- 4. Copy SSE URL to clipboard + open the connectors page ---
Set-Clipboard -Value $mcpUrl
Start-Process $connectorsUrl

# --- 5. Show a top-most popup so the user notices it even if focus is elsewhere ---
Add-Type -AssemblyName System.Windows.Forms | Out-Null
$msg = "Tunnel URL (already on your clipboard):`n`n$mcpUrl`n`n" +
       "1. The claude.ai connectors page is open.`n" +
       "2. Edit the NarrativeGames connector.`n" +
       "3. Paste (Ctrl+V) and Save.`n`n" +
       "Click OK to dismiss this popup."

# Hidden top-most owner so the MessageBox is forced to the front
$ownerForm = New-Object System.Windows.Forms.Form
$ownerForm.TopMost       = $true
$ownerForm.ShowInTaskbar = $false
$ownerForm.WindowState   = 'Minimized'
$ownerForm.Show()
$ownerForm.Hide()

[System.Windows.Forms.MessageBox]::Show(
    $ownerForm,
    $msg,
    "NarrativeGames tunnel ready",
    'OK',
    'Information'
) | Out-Null

$ownerForm.Dispose()

Write-Host ""
Write-Host "Public SSE URL: $mcpUrl" -ForegroundColor Green
Write-Host "  - Copied to clipboard." -ForegroundColor Green
Write-Host "  - Connectors page opened in browser." -ForegroundColor Green
Write-Host "  - Tunnel + MCP server windows remain open; close them to stop." -ForegroundColor DarkGray
