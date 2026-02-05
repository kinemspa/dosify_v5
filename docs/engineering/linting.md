# Linting Policy

**Last Updated**: 2025-10-19  
**Status**: Active

## Overview

This document defines the linting and code style standards for the Dosifi v5 Flutter project. All code must pass analyzer checks before merging to main.

## Analyzer Configuration

### Base Ruleset

We extend `package:very_good_analysis` which provides a comprehensive baseline of Flutter/Dart best practices.

### Strict Mode Settings

```yaml
analyzer:
  language:
    strict-casts: true        # No implicit downcasts
    strict-inference: true    # Fail on unresolved type inference
    strict-raw-types: true    # No raw generic types
```

**Rationale**: Catch type errors at compile time rather than runtime.

### Error Severity Mapping

| Issue Type | Severity | Rationale |
|------------|----------|-----------|
| `unused_import` | WARNING | Dead code, confuses navigation |
| `inference_failure_*` | WARNING | Leads to runtime type errors |
| `unused_element` | WARNING | Maintenance burden |
| `unused_field` | WARNING | Dead code |
| `unused_local_variable` | WARNING | Potential logic error |
| `deprecated_member_use` | INFO | Track but don't block |

### Generated Code Exclusions

Exclude code generation outputs:
- `**/*.g.dart` (Hive, JSON serialization)
- `**/*.freezed.dart` (Freezed unions/DTOs)
- `build/**` (Build artifacts)

## Lint Rules

### Import Management

**Rules**:
- `directives_ordering` - Sort imports alphabetically by group
- `avoid_relative_lib_imports` - No `../` imports within `lib/`
- `always_use_package_imports` - Use `package:dosifi_v5/...` for lib imports
- `unnecessary_import` - Remove redundant imports

**Import Order**:
1. Dart SDK (`dart:*`)
2. Flutter framework (`package:flutter/*`)
3. External packages (`package:*`)
4. Project imports (`package:dosifi_v5/*`)

**Example**:
```dart
// Good
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dosifi_v5/src/core/utils/format.dart';

// Bad
import 'package:dosifi_v5/src/core/utils/format.dart';
import '../../../core/utils/format.dart';  // Relative import
import 'package:hive/hive.dart';
import 'dart:async';  // Wrong order
```

### Safety Rules

**Curly Braces**:
- `curly_braces_in_flow_control_structures` - Always use `{}` for if/for/while

**Rationale**: Prevents bugs from unintended control flow (e.g., Apple's goto fail bug).

```dart
// Good
if (condition) {
  doSomething();
}

// Bad
if (condition) doSomething();
```

**Immutability**:
- `prefer_final_locals` - Use `final` for variables that don't change
- `prefer_final_in_for_each` - Use `final` in for-each loops

**Rationale**: Immutability reduces bugs, improves readability.

```dart
// Good
final count = items.length;
for (final item in items) { ... }

// Bad
var count = items.length;  // Never reassigned
for (var item in items) { ... }
```

**No Console Logging**:
- `avoid_print` - Use a proper logger

**Rationale**: Production apps shouldn't log to stdout. Use `logger` package or similar.

### Style Rules

**Constants**:
- `prefer_const_constructors` - Use `const` where possible
- `prefer_const_literals_to_create_immutables` - Collections too
- `prefer_const_declarations` - Variables holding constants

**Rationale**: Performance (shared instances), enforces immutability.

```dart
// Good
const padding = EdgeInsets.all(16.0);
const colors = [Colors.red, Colors.blue];

// Bad
final padding = EdgeInsets.all(16.0);  // Should be const
final colors = [Colors.red, Colors.blue];
```

**Clean Code**:
- `avoid_redundant_argument_values` - Omit args matching defaults
- `prefer_single_quotes` - Use `'text'` unless interpolation needed
- `prefer_interpolation_to_compose_strings` - Use `'$var'` not `'' + var`

```dart
// Good
Text('Hello $name')
Container(color: Colors.blue)  // color is required, no default

// Bad
Text("Hello " + name)
Container(color: Colors.blue, alignment: Alignment.topLeft)  // topLeft is default
```

### Organization

- `sort_constructors_first` - Constructors before methods
- `sort_unnamed_constructors_first` - Default constructor first

**Rationale**: Consistent code layout improves scanability.

## Line Length

**Limit**: 100 characters (configured in `.editorconfig`)

**Why 100 vs 80?**:
- Modern displays accommodate wider text
- Flutter widget trees often nest deeply
- Reduces need for excessive line breaks

**Enforcement**: `dart format -l 100`

Use trailing commas on parameter lists and collections to encourage multiline formatting:

```dart
// Good
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    child: Text('Hello'),
  );  // Trailing comma forces multiline
}
```

## Workflow

### Before Committing

```powershell
# Format code
dart format . -l 100

# Apply quick fixes
dart fix --apply

# Run analyzer
flutter analyze --no-pub
```

### CI Pipeline

All PRs must pass:
1. Formatter check (`dart format --set-exit-if-changed`)
2. Analyzer with zero warnings (`flutter analyze`)
3. Unit tests (if applicable)

### Suppressing Warnings

Only suppress warnings when absolutely necessary. Add justification:

```dart
// ignore: unused_element - Called via reflection by Hive adapter
void _internalMethod() { ... }

// ignore_for_file: prefer_const_constructors - Legacy file, will refactor in #123
```

## Migration Notes

### withOpacity Deprecation

**Issue**: `Color.withOpacity()` is being deprecated in favor of `withValues(alpha: ...)`

**Migration**:
```dart
// Old (deprecated)
color.withOpacity(0.5)

// New
color.withValues(alpha: 0.5)

// Or prefer theme colors where semantic
Theme.of(context).colorScheme.onSurfaceVariant  // Already has opacity
```

### Relative Imports

**Issue**: Project uses relative imports (`import '../../../file.dart'`)

**Migration**: Convert to package imports:
```dart
// Old
import '../../../core/utils/format.dart';

// New
import 'package:dosifi_v5/src/core/utils/format.dart';
```

Tool: `dart run tool/analysis/convert_imports.dart` (when created)

## References

- [Very Good Analysis Package](https://pub.dev/packages/very_good_analysis)
- [Effective Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Lints](https://pub.dev/packages/flutter_lints)
- [analysis_options.yaml](../../analysis_options.yaml) - Project configuration

## Changelog

- **2025-10-19**: Initial policy documentation for quality sprint
