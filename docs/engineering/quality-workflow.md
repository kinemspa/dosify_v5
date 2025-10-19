# Quality Workflow

**Last Updated**: 2025-10-19  
**Status**: Active

## Overview

This document describes the quality assurance workflow for the Dosifi v5 project, including automated tooling, manual checks, and CI/CD integration.

## Local Development

### Before Every Commit

Run the quality script to ensure code meets standards:

```powershell
pwsh ./tool/scripts/quality.ps1
```

This script performs:
1. **Code Formatting** (`dart format . -l 100`)
2. **Quick Fixes** (`dart fix --apply`)
3. **Import Sorting** (`dart run import_sorter:main`)
4. **Static Analysis** (`flutter analyze --no-pub`)

### Individual Commands

You can also run checks individually:

```powershell
# Format only
dart format . -l 100

# Check format without changing files
dart format --output=none --set-exit-if-changed . -l 100

# Apply automated fixes
dart fix --apply

# List available fixes without applying
dart fix --dry-run

# Sort imports
dart run import_sorter:main

# Check import sorting without changes
dart run import_sorter:main --exit-if-changed

# Run analyzer
flutter analyze --no-pub

# Run analyzer with machine-readable output
dart analyze --format=machine > tool/analysis/output.log
```

## Tools

### dart format

**Purpose**: Enforce consistent code style

**Configuration**: `.editorconfig` (100 character line length)

**Features**:
- Indentation (2 spaces)
- Line breaks
- Trailing commas (encourages multiline)
- Bracket placement

**Options**:
- `-l 100` - Set line length to 100 characters
- `--output=none` - Check only, don't modify
- `--set-exit-if-changed` - Exit code 1 if changes needed

### dart fix

**Purpose**: Apply automated refactorings and migrations

**Features**:
- Migrate deprecated APIs
- Add missing `const` keywords
- Convert to interpolation
- Remove redundant arguments
- Add type annotations where helpful

**Options**:
- `--apply` - Apply all fixes
- `--dry-run` - List available fixes
- `--code <lint_code>` - Apply specific fix only

**Example**:
```powershell
# Apply specific fix
dart fix --apply --code prefer_const_constructors
```

### import_sorter

**Purpose**: Organize imports consistently

**Configuration**: `import_sorter.yaml`

**Import Order**:
1. Dart SDK (`dart:*`)
2. Flutter framework (`package:flutter/*`)
3. External packages (`package:*`)
4. Project imports (`package:dosifi_v5/*`)

**Features**:
- Alphabetical within groups
- Removes duplicate imports
- Ignores generated files (*.g.dart, *.freezed.dart)

**Options**:
- `--exit-if-changed` - CI mode (exit 1 if changes needed)
- `--no-comments` - Disable comment preservation

### flutter analyze

**Purpose**: Static analysis for bugs and style violations

**Configuration**: `analysis_options.yaml`

**Features**:
- Type checking (strict mode)
- Lint rule enforcement
- Unused code detection
- Deprecated API warnings

**Severity Levels**:
- **ERROR**: Must fix (build fails)
- **WARNING**: Should fix (merge blocked)
- **INFO**: Optional (track only)

**Output**:
```
lib/main.dart:10:5 - warning - Unused import: 'dart:async' - unused_import
lib/main.dart:15:10 - info - Use const with the constructor - prefer_const_constructors
```

## CI/CD Integration

### Pre-commit Hook (Planned)

File: `.git/hooks/pre-commit` (or use Lefthook)

```bash
#!/bin/sh
set -e

echo "Running quality checks..."

# Format check
dart format --output=none --set-exit-if-changed . -l 100 || exit 1

# Import check
dart run import_sorter:main --exit-if-changed || exit 1

# Analyzer
flutter analyze --no-pub || exit 1

echo "✅ All checks passed"
```

Make executable:
```powershell
chmod +x .git/hooks/pre-commit  # Unix
# Or just create the file on Windows
```

### GitHub Actions Workflow (Planned)

File: `.github/workflows/quality.yml`

```yaml
name: Quality Checks

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  quality:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          channel: beta
          flutter-version: 3.37.0-0.1.pre
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Check formatting
        run: dart format --output=none --set-exit-if-changed . -l 100
      
      - name: Check imports
        run: dart run import_sorter:main --exit-if-changed
      
      - name: Analyze
        run: flutter analyze --no-pub
      
      - name: Run tests
        run: flutter test
      
      - name: Upload analysis reports
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: analysis-reports
          path: tool/analysis/
```

## Metrics & Reporting

### Analysis Reports

Reports are stored in `tool/analysis/`:

- `flutter-analyze.baseline.txt` - Initial state
- `flutter-analyze.after-autofix.txt` - Post-automation state
- `findings.csv` - Categorized issues
- `summary.md` - Issue counts by type

### Generating Reports

```powershell
# Create baseline
flutter analyze --no-pub > tool/analysis/flutter-analyze.baseline.txt

# After changes
flutter analyze --no-pub > tool/analysis/flutter-analyze.current.txt

# Compare
diff tool/analysis/flutter-analyze.baseline.txt tool/analysis/flutter-analyze.current.txt
```

## Issue Triage

### Warning Priority

**P0 - Block Merge**:
- `unused_import`
- `inference_failure_*`
- `unused_element` (public APIs)
- `dead_code`

**P1 - Fix Soon**:
- `deprecated_member_use` (breaking change coming)
- `unused_field`
- `unused_local_variable`

**P2 - Nice to Have**:
- Style lints (formatting, const, quotes)
- Organizational lints (import order, constructor order)

### Suppressing Warnings

Only suppress when absolutely necessary. Always document why:

```dart
// ignore: unused_element - Called via reflection by Hive
void _privateMethod() {}

// ignore_for_file: deprecated_member_use - Migration in progress (issue #123)
```

**Never suppress**:
- Type errors
- Null safety violations
- Security issues

## Best Practices

### Commit Hygiene

1. **Run quality script before committing**
2. **Fix all warnings** (zero-warning policy)
3. **Add tests for new code**
4. **Update docs if changing APIs**
5. **Keep commits focused and atomic**

### Code Review Checklist

- [ ] Passes quality script
- [ ] All tests green
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] Follows architecture guidelines

### Continuous Improvement

- **Weekly**: Review top recurring issues
- **Sprint**: Update lint rules if patterns emerge
- **Monthly**: Review and update documentation
- **Quarterly**: Reassess tooling and metrics

## Troubleshooting

### "Command not found: import_sorter"

Run: `flutter pub get` to install dev dependencies.

### "Analysis taking too long"

1. Exclude generated files in `analysis_options.yaml`
2. Clear build cache: `flutter clean`
3. Restart IDE analyzer

### "Format keeps changing same file"

Check `.editorconfig` matches formatter settings. Ensure IDE formatter uses same line length (100).

### "Imports keep getting reordered"

Ensure `import_sorter.yaml` exists and IDE isn't also sorting imports. Disable IDE auto-sort or configure to match our rules.

## References

- [Linting Policy](./linting.md)
- [Toolchain Documentation](./toolchain.md)
- [analysis_options.yaml](../../analysis_options.yaml)
- [import_sorter.yaml](../../import_sorter.yaml)
- [Quality Script](../../tool/scripts/quality.ps1)

## Changelog

- **2025-10-19**: Initial quality workflow documentation
