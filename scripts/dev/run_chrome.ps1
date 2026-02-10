param(
  [int]$Port = 5000
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Dosifi v5 (Chrome) ===" -ForegroundColor Cyan
Write-Host "Using fixed web port: $Port" -ForegroundColor Cyan
Write-Host "Tip: Flutter launches Chrome with a TEMP profile by default." -ForegroundColor DarkGray
Write-Host "     A temp profile means IndexedDB/localStorage is wiped between runs." -ForegroundColor DarkGray
Write-Host "     This script pins BOTH the origin (host+port) and the Chrome profile." -ForegroundColor DarkGray

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ProfileDir = Join-Path $RepoRoot '.dart_tool\chrome_profile'
New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null

Write-Host "Using Chrome user data dir: $ProfileDir" -ForegroundColor Cyan

flutter run -d chrome --web-port $Port --web-hostname 127.0.0.1 `
  --web-browser-flag="--user-data-dir=$ProfileDir" `
  --web-browser-flag="--disable-features=LockProfileCookieDatabase"
