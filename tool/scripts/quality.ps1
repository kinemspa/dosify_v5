#!/usr/bin/env pwsh
# Quality check script for Dosifi v5
# Runs formatter, linter, and analyzer

$ErrorActionPreference = "Stop"

Write-Host "🔧 Running Quality Checks..." -ForegroundColor Cyan
Write-Host ""

# Format code
Write-Host "📝 Formatting code (100 char line length)..." -ForegroundColor Yellow
dart format . -l 100
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Formatting failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Formatting complete" -ForegroundColor Green
Write-Host ""

# Apply quick fixes
Write-Host "🔨 Applying automated fixes..." -ForegroundColor Yellow
dart fix --apply
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Fix application failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Fixes applied" -ForegroundColor Green
Write-Host ""

# Sort imports
Write-Host "📦 Sorting imports..." -ForegroundColor Yellow
dart run import_sorter:main
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Import sorting failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Imports sorted" -ForegroundColor Green
Write-Host ""

# Run analyzer
Write-Host "🔍 Running analyzer..." -ForegroundColor Yellow
flutter analyze --no-pub
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Analyzer found issues" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Analyzer passed" -ForegroundColor Green
Write-Host ""

# Enforce no-literal-styling rule in feature code (baseline-based)
Write-Host "🎨 Checking for forbidden styling literals in feature code..." -ForegroundColor Yellow
dart run tool/check_no_literal_styling.dart --baseline tool/analysis/literal_styling.baseline.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Styling literal check failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Styling literal check passed" -ForegroundColor Green
Write-Host ""

Write-Host "🎉 All quality checks passed!" -ForegroundColor Green
