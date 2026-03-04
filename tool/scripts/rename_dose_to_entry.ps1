#!/usr/bin/env pwsh
# Renames all dose → entry (and doses → entries) in Dart source files,
# preserving single/multi-dose-vial product terminology.
# Also renames the affected .dart files and dose_action/ directory.

$root = "F:\Android Apps\dosifi_v5"
Set-Location $root

# ─── PHASE 1: Content replacement in all .dart files ───────────────────────

$dartFiles = Get-ChildItem -Path "lib","test" -Recurse -Include "*.dart"
$changed = 0

foreach ($file in $dartFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $original = $content

    # ── Protect single/multi-dose-vial product strings ──
    $content = $content -creplace 'SingleDoseVialWizardPage', '___SingleXXXVialWizardPage___'
    $content = $content -creplace 'add_single_dose_vial_wizard_page', '___add_single_xxx_vial_wizard_page___'
    $content = $content -creplace 'AddSingleDoseVialWizardPage', '___AddSingleXXXVialWizardPage___'
    $content = $content -creplace 'MultiDoseVial', '___MultiXXXVial___'
    $content = $content -creplace 'SingleDoseVial', '___SingleXXXVial___'
    $content = $content -creplace 'multiDoseVial', '___multiXXXVial___'
    $content = $content -creplace 'singleDoseVial', '___singleXXXVial___'
    $content = $content -creplace 'multi_dose_vial', '___multi_xxx_vial___'
    $content = $content -creplace 'single_dose_vial', '___single_xxx_vial___'
    # Protect UI label strings for vial types
    $content = $content -creplace 'Multi-[Dd]ose [Vv]ial', '___MultiXXXDashXXXVial___'
    $content = $content -creplace 'Single-[Dd]ose [Vv]ial', '___SingleXXXDashXXXVial___'
    $content = $content -creplace 'multi-dose vial', '___multi-xxx-vial___'
    $content = $content -creplace 'single-dose vial', '___single-xxx-vial___'

    # ── Plural first (to avoid Doses → Entrys) ──
    $content = $content -creplace 'Doses', 'Entries'
    $content = $content -creplace 'doses', 'entries'

    # ── Singular ──
    $content = $content -creplace 'Dose', 'Entry'
    $content = $content -creplace 'dose', 'entry'

    # ── Restore protected strings ──
    $content = $content -creplace '___SingleXXXVialWizardPage___', 'SingleDoseVialWizardPage'
    $content = $content -creplace '___add_single_xxx_vial_wizard_page___', 'add_single_dose_vial_wizard_page'
    $content = $content -creplace '___AddSingleXXXVialWizardPage___', 'AddSingleDoseVialWizardPage'
    $content = $content -creplace '___MultiXXXVial___', 'MultiDoseVial'
    $content = $content -creplace '___SingleXXXVial___', 'SingleDoseVial'
    $content = $content -creplace '___multiXXXVial___', 'multiDoseVial'
    $content = $content -creplace '___singleXXXVial___', 'singleDoseVial'
    $content = $content -creplace '___multi_xxx_vial___', 'multi_dose_vial'
    $content = $content -creplace '___single_xxx_vial___', 'single_dose_vial'
    $content = $content -creplace '___MultiXXXDashXXXVial___', 'Multi-Dose Vial'
    $content = $content -creplace '___SingleXXXDashXXXVial___', 'Single-Dose Vial'
    $content = $content -creplace '___multi-xxx-vial___', 'multi-dose vial'
    $content = $content -creplace '___single-xxx-vial___', 'single-dose vial'

    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
        $changed++
    }
}

Write-Host "Phase 1 complete: $changed files updated."

# ─── PHASE 2: Build the file rename map (skip single_dose_vial files) ───────

$renameMap = @{}
$dartFilesAll = Get-ChildItem -Path "lib","test" -Recurse -Include "*.dart"

foreach ($file in $dartFilesAll) {
    $name = $file.Name
    # Skip files that are about the single-dose-vial product
    if ($name -match 'single_dose_vial') { continue }
    if ($name -match 'dose') {
        $newName = $name `
            -creplace 'doses', 'entries' `
            -creplace 'dose', 'entry'
        if ($newName -ne $name) {
            $renameMap[$file.FullName] = Join-Path $file.DirectoryName $newName
        }
    }
}

Write-Host "Phase 2: $($renameMap.Count) files to rename."
foreach ($old in $renameMap.Keys) {
    $new = $renameMap[$old]
    Write-Host "  $($old.Replace($root + '\', '')) -> $($new.Replace($root + '\', ''))"
}

# ─── PHASE 3: Rename files ───────────────────────────────────────────────────

foreach ($old in $renameMap.Keys) {
    $new = $renameMap[$old]
    Move-Item -Path $old -Destination $new -Force
    Write-Host "Renamed: $([System.IO.Path]::GetFileName($old)) -> $([System.IO.Path]::GetFileName($new))"
}

# ─── PHASE 4: Rename dose_action/ directory -> entry_action/ ─────────────────

$doseActionDir = Join-Path $root "lib\src\widgets\dose_action"
$entryActionDir = Join-Path $root "lib\src\widgets\entry_action"
if (Test-Path $doseActionDir) {
    Rename-Item -Path $doseActionDir -NewName "entry_action"
    Write-Host "Renamed directory: dose_action -> entry_action"
}

Write-Host ""
Write-Host "All done. Run: flutter analyze"
