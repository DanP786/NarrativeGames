# Verifies the narrativegames-gm Cloudflare Worker end to end.
# PowerShell 5.1 compatible. ASCII only.
#
# Usage (from the repo root):
#   .\chatgpt\worker\verify.ps1 -Worker "https://narrativegames-gm.YOUR-SUBDOMAIN.workers.dev" -Key "your-api-key"

param(
    [Parameter(Mandatory = $true)][string]$Worker,
    [Parameter(Mandatory = $true)][string]$Key
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Worker = $Worker.TrimEnd('/')
$headers = @{ 'X-API-Key' = $Key }

Write-Host ""
Write-Host "Test 1: request WITHOUT key (expect rejection)..."
try {
    $r = Invoke-RestMethod -Uri "$Worker/list" -ErrorAction Stop
    Write-Host "  PROBLEM: worker answered without a key. Check the API_KEY secret exists." -ForegroundColor Red
} catch {
    Write-Host "  OK - rejected without key" -ForegroundColor Green
}

Write-Host ""
Write-Host "Test 2: list campaigns..."
$r = Invoke-RestMethod -Uri "$Worker/list?path=campaigns" -Headers $headers
foreach ($item in $r) { Write-Host ("  " + $item.type + "  " + $item.path) }
Write-Host "  OK" -ForegroundColor Green

Write-Host ""
Write-Host "Test 3: read rules.md (first 150 chars)..."
$t = Invoke-RestMethod -Uri "$Worker/read?path=rules.md" -Headers $headers
Write-Host ("  " + $t.Substring(0, [Math]::Min(150, $t.Length)))
Write-Host "  OK" -ForegroundColor Green

Write-Host ""
Write-Host "Test 4: write commit + cleanup commit..."
$body1 = @{
    message = 'worker write test'
    files   = @(@{ path = 'chatgpt/write-test.txt'; content = 'hello from the worker' })
} | ConvertTo-Json -Depth 5
$r1 = Invoke-RestMethod -Uri "$Worker/commit" -Method Post -Headers $headers -ContentType 'application/json' -Body $body1
Write-Host ("  write commit:   " + $r1.commit)

$body2 = @{
    message = 'worker write test cleanup'
    files   = @()
    deletes = @('chatgpt/write-test.txt')
} | ConvertTo-Json -Depth 5
$r2 = Invoke-RestMethod -Uri "$Worker/commit" -Method Post -Headers $headers -ContentType 'application/json' -Body $body2
Write-Host ("  cleanup commit: " + $r2.commit)
Write-Host "  OK" -ForegroundColor Green

Write-Host ""
Write-Host "All four tests passed. Transport is good - remember to 'git pull' locally." -ForegroundColor Green
