param(
  [int]$Port = 5000
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Dosifi v5 (Chrome) ===" -ForegroundColor Cyan
Write-Host "Using fixed web port: $Port" -ForegroundColor Cyan
Write-Host "Tip: Web persistence is scoped to origin (host+port)." -ForegroundColor DarkGray
Write-Host "     Keep the port stable to keep IndexedDB/localStorage stable." -ForegroundColor DarkGray

flutter run -d chrome --web-port $Port --web-hostname 127.0.0.1
