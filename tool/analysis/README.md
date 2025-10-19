# Analysis Reports

This directory contains analyzer outputs and metrics reports for tracking code quality improvements.

## Files

### Baseline Reports
- `flutter-analyze.baseline.txt` - Initial analyzer output before quality sprint
- `dart-analyze.machine.log` - Machine-readable baseline for parsing

### After Automated Fixes
- `flutter-analyze.after-autofix.txt` - Post-automation analyzer output
- `dart-analyze.after-autofix.machine.log` - Machine-readable post-fix log

### Parsed Results
- `findings.csv` - Categorized issues with file/line references
- `summary.md` - Issue counts by severity and type

### Metrics
- `dcm-analyze.txt` - Dart Code Metrics analysis (complexity, maintainability)
- `dcm-unused.txt` - Unused code detection results

### Final Reports
- `final-summary.md` - Before/after comparison and remaining issues

## Usage

Run full quality analysis:
```powershell
pwsh ./tool/scripts/quality.ps1
```

Generate summary:
```powershell
dart run tool/analysis/parse_analyze.dart
```
