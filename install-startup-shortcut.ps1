# One-shot installer: drop a Startup-folder shortcut for start-narrative.ps1
# so it runs at every Windows login. Re-running this is safe (overwrites).

$ws       = New-Object -ComObject WScript.Shell
$startup  = [Environment]::GetFolderPath('Startup')
$lnkPath  = Join-Path $startup 'NarrativeGames.lnk'

$lnk                  = $ws.CreateShortcut($lnkPath)
$lnk.TargetPath       = 'powershell.exe'
$lnk.Arguments        = '-NoProfile -ExecutionPolicy Bypass -File "C:\Users\Dan_P\Documents\NarrativeGames\start-narrative.ps1"'
$lnk.WorkingDirectory = 'C:\Users\Dan_P\Documents\NarrativeGames'
$lnk.WindowStyle      = 7   # 7 = minimized; the script's own popup is what the user sees
$lnk.Description      = 'Boot MCP server + Cloudflare tunnel for NarrativeGames at login'
$lnk.Save()

Write-Host "Created: $lnkPath" -ForegroundColor Green
Write-Host "It will run start-narrative.ps1 at every Windows login." -ForegroundColor DarkGray
Write-Host "To remove: delete the .lnk above, or run:" -ForegroundColor DarkGray
Write-Host "  Remove-Item '$lnkPath'" -ForegroundColor DarkGray
