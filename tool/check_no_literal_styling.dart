import 'dart:convert';
import 'dart:io';

final _patterns = <_Pattern>[
  _Pattern('Colors.*', RegExp(r'\bColors\.[A-Za-z_][A-Za-z0-9_]*')),
  _Pattern('Color(0x...)', RegExp(r'\bColor\s*\(\s*0x[0-9A-Fa-f]{8}')),
  _Pattern('EdgeInsets.*', RegExp(r'\bEdgeInsets\.[A-Za-z_][A-Za-z0-9_]*')),
  _Pattern('BorderRadius.*', RegExp(r'\bBorderRadius\.[A-Za-z_][A-Za-z0-9_]*')),
  _Pattern('TextStyle(...)', RegExp(r'\bTextStyle\s*\(')),
];

void main(List<String> args) {
  final parsed = _Args.parse(args);
  final root = Directory.current;

  final featuresDir = Directory(
    '${root.path}${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}src'
    '${Platform.pathSeparator}features',
  );

  if (!featuresDir.existsSync()) {
    stderr.writeln(
      'ERROR: Could not find ${featuresDir.path}. Run from repo root.',
    );
    exitCode = 2;
    return;
  }

  final findings = _scan(featuresDir: featuresDir, root: root);

  if (parsed.writeReportPath != null) {
    final reportFile = File(parsed.writeReportPath!);
    reportFile.parent.createSync(recursive: true);
    reportFile.writeAsStringSync(_buildMarkdownReport(findings));
  }

  if (parsed.writeBaselinePath != null) {
    final baselineFile = File(parsed.writeBaselinePath!);
    baselineFile.parent.createSync(recursive: true);

    final signatures = findings.map((f) => f.signature).toSet().toList()
      ..sort();

    baselineFile.writeAsStringSync('${signatures.join('\n')}\n');
    stdout.writeln(
      'Wrote baseline with ${signatures.length} entries to ${baselineFile.path}.',
    );
    return;
  }

  if (parsed.baselinePath == null) {
    // No baseline requested: treat any finding as a failure.
    _printAllFindings(findings);
    exitCode = findings.isEmpty ? 0 : 1;
    return;
  }

  final baselineFile = File(parsed.baselinePath!);
  if (!baselineFile.existsSync()) {
    stderr.writeln(
      'ERROR: Baseline file not found at ${baselineFile.path}.\n'
      'Run: dart run tool/check_no_literal_styling.dart '
      '--write-baseline ${baselineFile.path}',
    );
    exitCode = 2;
    return;
  }

  final baselineSignatures = baselineFile
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toSet();

  final currentBySignature = <String, _Finding>{
    for (final f in findings) f.signature: f,
  };

  final newSignatures =
      currentBySignature.keys
          .where((sig) => !baselineSignatures.contains(sig))
          .toList()
        ..sort();

  if (newSignatures.isEmpty) {
    stdout.writeln(
      'OK: No new literal styling violations under lib/src/features/.\n'
      'Baseline: ${baselineFile.path}',
    );
    return;
  }

  stderr.writeln(
    'Found ${newSignatures.length} NEW literal styling violation(s) under '
    'lib/src/features/ (update code to use design system tokens/widgets).',
  );
  stderr.writeln('Baseline: ${baselineFile.path}');
  stderr.writeln('');

  for (final sig in newSignatures) {
    final f = currentBySignature[sig]!;
    stderr.writeln(
      '  ${f.relativePath}:${f.lineNumber} '
      '[${f.patternId}] ${f.preview}',
    );
  }

  stderr.writeln('');
  stderr.writeln(
    'If you intentionally introduced new styling literals, convert them to '
    'design-system tokens (or add a shared widget).\n'
    'If you refactored existing code and line signatures changed, regenerate '
    'the baseline (temporary):\n'
    '  dart run tool/check_no_literal_styling.dart '
    '--write-baseline ${baselineFile.path}',
  );

  exitCode = 1;
}

class _Args {
  _Args({
    required this.baselinePath,
    required this.writeBaselinePath,
    required this.writeReportPath,
  });

  factory _Args.parse(List<String> args) {
    String? baseline;
    String? writeBaseline;
    String? writeReport;

    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      String? nextArg() => (i + 1 < args.length) ? args[i + 1] : null;

      if (a == '--baseline') {
        baseline = nextArg();
        i++;
        continue;
      }

      if (a == '--write-baseline') {
        writeBaseline = nextArg();
        i++;
        continue;
      }

      if (a == '--write-report') {
        writeReport = nextArg();
        i++;
        continue;
      }

      if (a == '--help' || a == '-h') {
        stdout.writeln(
          'Usage: dart run tool/check_no_literal_styling.dart [opts]',
        );
        stdout.writeln('  --baseline <path>        Baseline signatures file.');
        stdout.writeln(
          '  --write-baseline <path>  Write baseline signatures from current scan.',
        );
        stdout.writeln(
          '  --write-report <path>    Write a markdown offenders report.',
        );
        exit(0);
      }

      stderr.writeln('Unknown arg: $a');
      exit(2);
    }

    return _Args(
      baselinePath: baseline,
      writeBaselinePath: writeBaseline,
      writeReportPath: writeReport,
    );
  }

  final String? baselinePath;
  final String? writeBaselinePath;
  final String? writeReportPath;
}

class _Pattern {
  const _Pattern(this.id, this.regex);
  final String id;
  final RegExp regex;
}

class _Finding {
  _Finding({
    required this.relativePath,
    required this.lineNumber,
    required this.patternId,
    required this.preview,
  });

  final String relativePath;
  final int lineNumber;
  final String patternId;
  final String preview;

  String get signature {
    final normalized = preview.trim().replaceAll(RegExp(r'\s+'), ' ');
    final hash = _fnv1a32(normalized);
    return '$relativePath|$patternId|$hash';
  }
}

List<_Finding> _scan({
  required Directory featuresDir,
  required Directory root,
}) {
  final findings = <_Finding>[];

  for (final entity in featuresDir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final lines = entity.readAsLinesSync();
    var inBlockComment = false;

    for (var i = 0; i < lines.length; i++) {
      final stripped = _stripComments(lines[i], inBlockComment);
      inBlockComment = stripped.inBlockComment;

      final text = stripped.text;
      if (text.trim().isEmpty) continue;

      for (final p in _patterns) {
        if (p.regex.hasMatch(text)) {
          final relative = entity.path.replaceFirst(
            '${root.path}${Platform.pathSeparator}',
            '',
          );

          findings.add(
            _Finding(
              relativePath: relative,
              lineNumber: i + 1,
              patternId: p.id,
              preview: text.trim(),
            ),
          );
        }
      }
    }
  }

  return findings;
}

void _printAllFindings(List<_Finding> findings) {
  if (findings.isEmpty) {
    stdout.writeln(
      'OK: No literal styling violations found under lib/src/features/.',
    );
    return;
  }

  stderr.writeln(
    'Found ${findings.length} literal styling violation(s) under '
    'lib/src/features/ (use design system tokens/widgets):',
  );

  final sorted = [...findings]
    ..sort((a, b) {
      final c = a.relativePath.compareTo(b.relativePath);
      if (c != 0) return c;
      return a.lineNumber.compareTo(b.lineNumber);
    });

  for (final f in sorted) {
    stderr.writeln(
      '  ${f.relativePath}:${f.lineNumber} [${f.patternId}] ${f.preview}',
    );
  }
}

String _buildMarkdownReport(List<_Finding> findings) {
  final byFile = <String, int>{};
  final byPattern = <String, int>{};

  for (final f in findings) {
    byFile.update(f.relativePath, (v) => v + 1, ifAbsent: () => 1);
    byPattern.update(f.patternId, (v) => v + 1, ifAbsent: () => 1);
  }

  final topFiles = byFile.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final topPatterns = byPattern.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final buf = StringBuffer();
  buf.writeln('# UI Styling — Top Offenders');
  buf.writeln('');
  buf.writeln('Generated by `tool/check_no_literal_styling.dart`.');
  buf.writeln('');
  buf.writeln('## Summary');
  buf.writeln('');
  buf.writeln('- Total findings: ${findings.length}');
  buf.writeln('- Files with findings: ${byFile.length}');
  buf.writeln('');
  buf.writeln('## Findings by pattern');
  buf.writeln('');
  buf.writeln('| Pattern | Count |');
  buf.writeln('|---|---:|');
  for (final e in topPatterns) {
    buf.writeln('| ${e.key} | ${e.value} |');
  }
  buf.writeln('');
  buf.writeln('## Top offending files');
  buf.writeln('');
  buf.writeln('| File | Count |');
  buf.writeln('|---|---:|');
  for (final e in topFiles.take(30)) {
    buf.writeln('| `${e.key}` | ${e.value} |');
  }
  buf.writeln('');
  buf.writeln('## Next steps (migration map)');
  buf.writeln('');
  buf.writeln(
    '- Replace repeated cards with `UnifiedCardSurface` or a dedicated shared card widget.',
  );
  buf.writeln(
    '- Replace repeated chips/badges with `UnifiedStatusBadge` or a feature-specific wrapper.',
  );
  buf.writeln(
    '- Replace direct `EdgeInsets.*` in feature code with design-system padding constants (e.g., `kPagePadding`, `kDetailPageSectionsPadding`) or add a new centralized token.',
  );
  buf.writeln(
    '- Replace `Colors.*` / `Color(0x...)` with `Theme.of(context).colorScheme.*` via design-system helpers.',
  );
  buf.writeln('');
  return buf.toString();
}

class _StripResult {
  _StripResult(this.text, this.inBlockComment);

  final String text;
  final bool inBlockComment;
}

_StripResult _stripComments(String line, bool inBlockComment) {
  var s = line;

  while (true) {
    if (inBlockComment) {
      final end = s.indexOf('*/');
      if (end == -1) {
        return _StripResult('', true);
      }
      s = s.substring(end + 2);
      inBlockComment = false;
      continue;
    }

    final start = s.indexOf('/*');
    if (start == -1) break;

    final end = s.indexOf('*/', start + 2);
    if (end == -1) {
      s = s.substring(0, start);
      inBlockComment = true;
      break;
    }

    s = s.substring(0, start) + s.substring(end + 2);
  }

  final lineComment = s.indexOf('//');
  if (lineComment != -1) {
    s = s.substring(0, lineComment);
  }

  return _StripResult(s, inBlockComment);
}

int _fnv1a32(String input) {
  const fnvPrime = 16777619;
  var hash = 2166136261;

  final bytes = utf8.encode(input);
  for (final b in bytes) {
    hash ^= b;
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
  }

  return hash;
}
