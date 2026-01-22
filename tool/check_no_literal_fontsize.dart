import 'dart:io';

final _fontSizeLiteral = RegExp(r'fontSize\s*:\s*([0-9]+(?:\.[0-9]+)?)');

void main(List<String> args) {
  final root = Directory.current;
  final libSrc = Directory('${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}src');

  if (!libSrc.existsSync()) {
    stderr.writeln('ERROR: Could not find ${libSrc.path}. Run from repo root.');
    exitCode = 2;
    return;
  }

  final violations = <String>[];

  for (final entity in libSrc.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final lines = entity.readAsLinesSync();
    var inBlockComment = false;

    for (var i = 0; i < lines.length; i++) {
      final stripped = _stripComments(lines[i], inBlockComment);
      inBlockComment = stripped.inBlockComment;

      if (_fontSizeLiteral.hasMatch(stripped.text)) {
        final relative = entity.path.replaceFirst('${root.path}${Platform.pathSeparator}', '');
        violations.add('$relative:${i + 1}: ${stripped.text.trim()}');
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Found numeric fontSize literals in lib/src (use design-system constants instead):');
    for (final v in violations) {
      stderr.writeln('  $v');
    }
    exitCode = 1;
  } else {
    stdout.writeln('OK: No numeric fontSize literals found under lib/src/.');
  }
}

class _StripResult {
  _StripResult(this.text, this.inBlockComment);

  final String text;
  final bool inBlockComment;
}

_StripResult _stripComments(String line, bool inBlockComment) {
  var s = line;

  // Remove block comments, tracking state across lines.
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

  // Remove single-line comments.
  final lineComment = s.indexOf('//');
  if (lineComment != -1) {
    s = s.substring(0, lineComment);
  }

  return _StripResult(s, inBlockComment);
}
