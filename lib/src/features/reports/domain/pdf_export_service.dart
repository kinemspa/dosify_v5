// Dart imports:
import 'dart:typed_data';

// Package imports:
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a formatted PDF document from a CSV string.
///
/// The resulting document contains a branded header (title + date),
/// a styled data table with a Skedux-teal header row, alternating row
/// colours, and automatic pagination — ready to share via email or save.
class PdfExportService {
  const PdfExportService();

  // ── brand constants ────────────────────────────────────────────────────────

  static final _brandColor = PdfColor.fromHex('#09A8BD');
  static final _rowAltColor = PdfColor.fromHex('#F3FBFC'); // very light teal tint
  static const _headerFontSize = 9.0;
  static const _cellFontSize = 8.0;
  static const _cellPadding = pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4);

  // ── public API ─────────────────────────────────────────────────────────────

  /// Builds a PDF from [csv] (header row + data rows) and returns the bytes.
  ///
  /// Set [landscape] to `true` for wide tables (many columns).
  Future<Uint8List> buildTablePdf({
    required String title,
    required String csv,
    bool landscape = false,
  }) async {
    final doc = pw.Document(title: title, creator: 'Skedux');

    final lines = csv
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList(growable: false);

    final headers = lines.isNotEmpty ? _parseLine(lines.first) : <String>[];
    final rows = lines.skip(1).map(_parseLine).toList(growable: false);

    final pageFormat =
        landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    final exportedAt =
        DateFormat('MMM d, y  HH:mm').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(28),
        // ── per-page header ────────────────────────────────────────────────
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Skedux',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _brandColor,
                  ),
                ),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  exportedAt,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Container(
              height: 1.5,
              color: _brandColor,
              margin: const pw.EdgeInsets.only(top: 4, bottom: 8),
            ),
          ],
        ),
        // ── per-page footer ────────────────────────────────────────────────
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'For informational and tracking purposes only.',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        // ── content ────────────────────────────────────────────────────────
        build: (ctx) => [
          if (headers.isEmpty)
            pw.Text('No data available.')
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              // Header row styling
              headerStyle: pw.TextStyle(
                fontSize: _headerFontSize,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: _brandColor),
              headerPadding: _cellPadding,
              // Cell styling
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

  // ── CSV parsing (mirrors CsvExportService._parseCsvLine) ──────────────────

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
