import 'package:flutter/material.dart';

/// Syringe gauge widget used for reconstitution visualization
/// Shows a horizontal line with IU markers and thick fill line
class WhiteSyringeGauge extends StatelessWidget {
  const WhiteSyringeGauge({
    super.key,
    required this.totalIU,
    required this.fillIU,
    this.color,
  });

  final double totalIU;
  final double fillIU;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: const Size(double.infinity, 44),
      painter: _WhiteSyringePainter(
        totalIU: totalIU,
        fillIU: fillIU,
        color: effectiveColor,
      ),
    );
  }
}

class _WhiteSyringePainter extends CustomPainter {
  _WhiteSyringePainter({
    required this.totalIU,
    required this.fillIU,
    required this.color,
  });

  final double totalIU;
  final double fillIU;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Baseline is at bottom of canvas
    final baselineY = size.height - 4;

    // Draw horizontal baseline (entire width)
    final baselinePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      baselinePaint,
    );

    // Draw IU marker ticks and labels
    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw ticks: every 5 IU (half tick), every 10 IU (minor), every 50 IU (major)
    for (double iu = 0; iu <= totalIU; iu += 5) {
      final x = totalIU <= 0 ? 0.0 : (iu / totalIU) * size.width;
      final isMajor = iu % 50 == 0;
      final isMinor = iu % 10 == 0 && !isMajor;

      // All ticks end at baseline, start above it
      final tickHeight = isMajor ? 20.0 : (isMinor ? 12.0 : 6.0);
      final tickTop = baselineY - tickHeight;

      canvas.drawLine(Offset(x, tickTop), Offset(x, baselineY), tickPaint);

      // Draw labels for major and minor ticks below baseline
      if (isMajor || isMinor) {
        final tp = TextPainter(
          text: TextSpan(
            text: iu.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        // Position below baseline with padding
        tp.paint(canvas, Offset(x - tp.width / 2, baselineY + 4));
      }
    }

    // Draw thick fill line representing the amount in syringe
    final ratio = totalIU <= 0 ? 0.0 : (fillIU / totalIU).clamp(0.0, 1.0);
    if (ratio > 0 && !ratio.isNaN) {
      final fillPaint = Paint()
        ..color = color
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final fillEndX = size.width * ratio;
      canvas.drawLine(
        Offset(0, baselineY),
        Offset(fillEndX, baselineY),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteSyringePainter oldDelegate) {
    return oldDelegate.totalIU != totalIU ||
        oldDelegate.fillIU != fillIU ||
        oldDelegate.color != color;
  }
}
