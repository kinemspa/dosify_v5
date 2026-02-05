Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location (Split-Path -Parent $PSCommandPath) | Out-Null
Set-Location .. | Out-Null

function To-OsPath([string]$relPath) {
  if (-not $relPath) { return $null }
  return $relPath.Replace('/','\')
}

function Normalize-RelPath([string]$fullPath) {
  $root = (Get-Location).Path
  $p = [System.IO.Path]::GetFullPath($fullPath)
  if (-not $p.StartsWith($root)) { return $null }
  return $p.Substring($root.Length + 1).Replace('\','/')
}

function Resolve-DartUriToLibPath([string]$fromPath, [string]$uri) {
  if ($uri -match '^dart:' -or $uri -match '^flutter:') { return $null }

  if ($uri -match '^package:dosifi_v5/(.+)$') {
    return ('lib/' + $Matches[1])
  }

  if ($uri -match '^package:') { return $null }

  # Relative to current file
  if ($uri.StartsWith('./') -or $uri.StartsWith('../') -or $uri.StartsWith('src/') -or $uri.StartsWith('widgets/') -or $uri.StartsWith('features/') -or $uri.StartsWith('core/') -or $uri.StartsWith('app/')) {
    $fromDir = Split-Path -Parent (To-OsPath $fromPath)
    $combined = Join-Path $fromDir (To-OsPath $uri)
    $full = [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $combined))
    $rel = Normalize-RelPath $full
    if ($rel -and $rel.StartsWith('lib/')) { return $rel }
  }

  return $null
}

$main = 'lib/main.dart'
$testRoots = Get-ChildItem -File -Recurse test -Filter '*.dart' -ErrorAction SilentlyContinue |
  ForEach-Object { Normalize-RelPath $_.FullName } |
  Where-Object { $_ }

$roots = @($main) + @($testRoots)

$libFiles = Get-ChildItem -File -Recurse lib -Filter '*.dart' |
  ForEach-Object { Normalize-RelPath $_.FullName } |
  Where-Object { $_ -and ($_ -notmatch '\.g\.dart$') -and ($_ -notmatch '\.freezed\.dart$') } |
  Sort-Object

$deps = @{}
$inbound = @{}
foreach ($f in $libFiles) {
  $deps[$f] = New-Object System.Collections.Generic.HashSet[string]
  $inbound[$f] = New-Object System.Collections.Generic.HashSet[string]
}

$directiveRegex = [regex]'(?m)^\s*(import|export|part)\s+["'']([^"'']+)["'']\s*;'

foreach ($f in $libFiles) {
  $text = Get-Content -Raw -LiteralPath (To-OsPath $f) -ErrorAction SilentlyContinue
  if (-not $text) { continue }

  foreach ($m in $directiveRegex.Matches($text)) {
    $uri = $m.Groups[2].Value
    $resolved = Resolve-DartUriToLibPath $f $uri
    if ($resolved -and $deps.ContainsKey($resolved)) {
      $deps[$f].Add($resolved) | Out-Null
      $inbound[$resolved].Add($f) | Out-Null
    }
  }
}

$reachable = New-Object System.Collections.Generic.HashSet[string]
$queue = New-Object System.Collections.Generic.Queue[string]

function EnqueueIfLib([string]$path) {
  if ($path -and $deps.ContainsKey($path) -and -not $reachable.Contains($path)) {
    $reachable.Add($path) | Out-Null
    $queue.Enqueue($path)
  }
}

foreach ($r in $roots) {
  if (-not (Test-Path (To-OsPath $r))) { continue }
  $text = Get-Content -Raw -LiteralPath (To-OsPath $r) -ErrorAction SilentlyContinue
  if (-not $text) { continue }
  foreach ($m in $directiveRegex.Matches($text)) {
    $uri = $m.Groups[2].Value
    $resolved = Resolve-DartUriToLibPath $r $uri
    EnqueueIfLib $resolved
  }
}

while ($queue.Count -gt 0) {
  $cur = $queue.Dequeue()
  foreach ($d in $deps[$cur]) { EnqueueIfLib $d }
}

# Roots that are themselves lib files should be considered reachable.
foreach ($r in $roots) {
  if ($r -and $r.StartsWith('lib/') -and $deps.ContainsKey($r)) {
    $reachable.Add($r) | Out-Null
  }
}

$entryPointFiles = New-Object System.Collections.Generic.HashSet[string]
foreach ($f in $libFiles) {
  $text = Get-Content -Raw -LiteralPath (To-OsPath $f) -ErrorAction SilentlyContinue
  if ($text -and $text -match 'vm:entry-point') { $entryPointFiles.Add($f) | Out-Null }
}

New-Item -ItemType Directory -Force -Path 'docs/audits' | Out-Null
$reportPath = 'docs/audits/LIB_USAGE_REPORT.md'

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# lib/ Usage Report') | Out-Null
$lines.Add('') | Out-Null
$lines.Add('Roots used for reachability:') | Out-Null
$lines.Add('- `lib/main.dart`') | Out-Null
$lines.Add('- all `test/**/*.dart`') | Out-Null
$lines.Add('') | Out-Null
$lines.Add('Legend:') | Out-Null
$lines.Add('- **Reachable**: reachable via import/export/part graph from roots') | Out-Null
$lines.Add('- **Entry-point**: contains `vm:entry-point` pragma (keep even if unreachable)') | Out-Null
$lines.Add('') | Out-Null
$lines.Add('| File | Reachable | Entry-point | Inbound (lib) | Suggestion |') | Out-Null
$lines.Add('|---|---:|---:|---:|---|') | Out-Null

foreach ($f in $libFiles) {
  $isReach = $reachable.Contains($f)
  $isEntry = $entryPointFiles.Contains($f)
  $inCount = $inbound[$f].Count
  $suggest = if ($isReach -or $isEntry) { 'KEEP' } else { 'CANDIDATE_DELETE' }
  $lines.Add("| $f | $($isReach.ToString().ToUpper()) | $($isEntry.ToString().ToUpper()) | $inCount | $suggest |") | Out-Null
}

Set-Content -LiteralPath $reportPath -Value ($lines -join "`n") -Encoding UTF8


$unused = @($libFiles | Where-Object { -not $reachable.Contains($_) -and -not $entryPointFiles.Contains($_) })
$unused | Set-Content -LiteralPath 'docs/audits/lib_unused_candidates.txt' -Encoding UTF8

Write-Host "Wrote $reportPath"
Write-Host "Unused candidates: $(@($unused).Count)"
$unused | Select-Object -First 50 | ForEach-Object { Write-Host $_ }
