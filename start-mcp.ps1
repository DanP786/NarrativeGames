# Starts the MCP proxy + filesystem server for the Narrative Adventure Engine.
# Leave this window open while playing; Ctrl+C to stop.

$campaignDir = "C:\Users\Dan_P\Documents\NarrativeGames"
$port = 8090

Write-Host "Starting MCP filesystem server on http://127.0.0.1:$port/sse" -ForegroundColor Cyan
Write-Host "Allowed directory: $campaignDir" -ForegroundColor Cyan
Write-Host ""

python -m mcp_proxy --port $port --allow-origin "*" -- npx -y "@modelcontextprotocol/server-filesystem" $campaignDir
