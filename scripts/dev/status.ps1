param()

$ErrorActionPreference = 'Stop'

Write-Host '=== Dosifi v5 Status ===' -ForegroundColor Cyan

# Git status and recent commits
if (Test-Path .git) {
  git --no-pager status -sb | Write-Host
  git --no-pager log -n 10 --oneline | Write-Host
} else {
  Write-Host 'No git repository found.' -ForegroundColor Yellow
}

Write-Host "`n--- TODO/FIXME scan (Dart/Markdown) ---" -ForegroundColor Cyan
Get-ChildItem -Path . -Recurse -Include *.dart,*.md -File |
  Select-String -Pattern 'TODO|FIXME|NEXT|HACK' -List |
  ForEach-Object { "{0}:{1}: {2}" -f (Resolve-Path $_.Path -Relative), $_.LineNumber, $_.Line.Trim() } |
  Write-Host

Write-Host "`n--- Key docs ---" -ForegroundColor Cyan
$docs = @(
  'docs/status.md',
  'docs/backlog.md',
  'docs/journal.md',
  'docs/product-design.md',
  'docs/schedules.md',
  'docs/notification_scheduling_investigation.md'
)
foreach ($d in $docs) {
  if (Test-Path $d) {
    $ts = (Get-Item $d).LastWriteTime
    Write-Host ("{0} (updated {1})" -f $d, $ts)
  }
}

Write-Host "`n--- Routes quick view ---" -ForegroundColor Cyan
Get-ChildItem -Recurse -Include lib\src\app\router.dart | Select-String -Pattern 'GoRoute|ShellRoute|path:' |
  ForEach-Object { "{0}:{1}: {2}" -f $_.Filename, $_.LineNumber, $_.Line.Trim() } | Write-Host

Write-Host "`nTip: Keep docs/status.md and docs/backlog.md fresh after each focus change." -ForegroundColor DarkGray

