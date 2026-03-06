// Dart imports:
import 'dart:typed_data';

// Package imports:
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a formatted PDF document from a CSV string.
///
/// The resulting document contains a branded graphical banner, a styled data
/// table with a Skedux-teal header row and alternating row colours, and
/// automatic pagination — ready to share via email or save.
class PdfExportService {
  const PdfExportService();

  // ── brand constants ────────────────────────────────────────────────────────

  static final _brandColor = PdfColor.fromHex('#09A8BD');
  static final _brandDark = PdfColor.fromHex('#077A8A');
  static final _rowAltColor = PdfColor.fromHex('#F0FAFB');
  static const _headerFontSize = 8.5;
  static const _cellFontSize = 8.0;
  static const _cellPadding = pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5);

  // ── public API ─────────────────────────────────────────────────────────────

  /// Builds a PDF from [csv] (header row + data rows) and returns the bytes.
  ///
  /// [excludeColumns] — set of raw CSV header names to drop from the PDF
  /// (e.g. `{'id', 'medicationId'}`).
  /// Set [landscape] to `true` for wide tables (many columns).
  Future<Uint8List> buildTablePdf({
    required String title,
    required String csv,
    bool landscape = false,
    Set<String> excludeColumns = const {},
  }) async {
    final doc = pw.Document(title: title, creator: 'Skedux');

    final lines = csv
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList(growable: false);

    // Parse raw headers and build exclude-index set
    final rawHeaders =
        lines.isNotEmpty ? _parseLine(lines.first) : <String>[];
    final excludeIdx = <int>{};
    if (excludeColumns.isNotEmpty) {
      for (var i = 0; i < rawHeaders.length; i++) {
        if (excludeColumns.contains(rawHeaders[i])) excludeIdx.add(i);
      }
    }

    // Human-readable column labels
    final headers = [
      for (var i = 0; i < rawHeaders.length; i++)
        if (!excludeIdx.contains(i)) _humanizeHeader(rawHeaders[i]),
    ];

    // Data rows — strip excluded columns, clean values
    final rows = lines
        .skip(1)
        .map((l) => [
              for (final (i, v) in _parseLine(l).indexed)
                if (!excludeIdx.contains(i)) _cleanValue(v),
            ])
        .toList(growable: false);

    final pageFormat =
        landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
    final exportedAt = DateFormat('MMM d, y  HH:mm').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(28),
        // ── per-page header ────────────────────────────────────────────────
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Graphical banner
            pw.Container(
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [_brandColor, _brandDark],
                  begin: pw.Alignment.centerLeft,
                  end: pw.Alignment.centerRight,
                ),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // App name
                  pw.Text(
                    'Skedux',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // Report title (centred)
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  // Export timestamp
                  pw.Text(
                    exportedAt,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        // ── per-page footer ────────────────────────────────────────────────
        footer: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              height: 0.5,
              color: _brandColor,
              margin: const pw.EdgeInsets.only(bottom: 4),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'For informational and tracking purposes only.',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        // ── content ────────────────────────────────────────────────────────
        build: (ctx) => [
          if (headers.isEmpty)
            pw.Text('No data available.')
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(
                fontSize: _headerFontSize,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: _brandColor),
              headerPadding: _cellPadding,
              cellStyle: const pw.TextStyle(fontSize: _cellFontSize),
              cellPadding: _cellPadding,
              cellDecoration: (index, data, rowNum) => pw.BoxDecoration(
                color: rowNum.isOdd ? _rowAltColor : PdfColors.white,
              ),
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
            ),
        ],
      ),
    );

    return doc.save();
  }

  // ── value cleaning ─────────────────────────────────────────────────────────

  static final _trailingZeroRe = RegExp(r'^-?\d+\.0+$');
  // ISO-8601 UTC: ends with Z or +00:00
  static final _utcIsoRe = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]00:00)$',
  );
  static final _utcDateFmt = DateFormat('MMM d, y  HH:mm');

  /// Cleans a single cell value for display:
  /// - Strips trailing `.0` from whole-number decimals (e.g. `50.0` → `50`)
  /// - Converts ISO-8601 UTC timestamps to local time in a readable format
  String _cleanValue(String v) {
    if (v.isEmpty) return v;

    // Strip trailing zeros: 50.0 → 50, 3.00 → 3
    if (_trailingZeroRe.hasMatch(v)) {
      return v.substring(0, v.indexOf('.'));
    }

    // UTC ISO timestamp → local datetime
    if (_utcIsoRe.hasMatch(v)) {
      try {
        final dt = DateTime.parse(v).toLocal();
        return _utcDateFmt.format(dt);
      } catch (_) {
        // fall through
      }
    }

    return v;
  }

  // ── header humanisation ────────────────────────────────────────────────────

  static const _headerOverrides = <String, String>{
    'id': 'ID',
    'name': 'Name',
    'form': 'Form',
    'manufacturer': 'Manufacturer',
    'strengthValue': 'Strength',
    'strengthUnit': 'Unit',
    'stockValue': 'Stock',
    'stockUnit': 'Stock Unit',
    'createdAtUtc': 'Created',
    'updatedAtUtc': 'Updated',
    'medicationId': 'Med ID',
    'medicationName': 'Medication',
    'scheduleName': 'Schedule',
    'scheduledTimeUtc': 'Scheduled',
    'actionTimeUtc': 'Logged At',
    'action': 'Action',
    'entryValue': 'Dose',
    'entryUnit': 'Unit',
    'actualEntryValue': 'Actual Dose',
    'actualEntryUnit': 'Actual Unit',
    'notes': 'Notes',
    'active': 'Active',
    'startAtUtc': 'Start',
    'endAtUtc': 'End',
    'daysOfWeek': 'Days',
    'timesOfDay': 'Times',
    'timestampUtc': 'Date',
    'changeType': 'Change',
    'previousStock': 'Prev Stock',
    'newStock': 'New Stock',
    'changeAmount': 'Amount',
  };

  /// Converts a raw CSV column name to a human-readable label.
  String _humanizeHeader(String raw) {
    final override = _headerOverrides[raw];
    if (override != null) return override;

    // camelCase → words
    final spaced = raw.replaceAllMapped(
      RegExp('([a-z])([A-Z])'),
      (m) => '${m[1]!} ${m[2]!}',
    );
    // Remove trailing "Utc" suffix (case-insensitive)
    final noUtc = spaced.replaceAll(RegExp(r'\s*[Uu][Tt][Cc]$'), '');
    // Title-case
    return noUtc
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // ── CSV parsing ────────────────────────────────────────────────────────────

  List<String> _parseLine(String line) {
    final values = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i += 1;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        values.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    values.add(buf.toString());
    return values;
  }
}
