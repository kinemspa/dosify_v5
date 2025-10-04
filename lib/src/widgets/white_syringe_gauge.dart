import 'package:flutter/material.dart';

/// White-styled syringe gauge used in reconstitution summary cards
/// Shows a horizontal line with white IU markers and thick white fill line
class WhiteSyringeGauge extends StatelessWidget {
  const WhiteSyringeGauge({
    super.key,
    required this.totalIU,
    required this.fillIU,
  });

  final double totalIU;
  final double fillIU;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 32),
      painter: _WhiteSyringePainter(totalIU: totalIU, fillIU: fillIU),
    );
  }
}

class _WhiteSyringePainter extends CustomPainter {
  _WhiteSyringePainter({required this.totalIU, required this.fillIU});

  final double totalIU;
  final double fillIU;

  @override
  void paint(Canvas canvas, Size size) {
    const whiteColor = Colors.white;

    // Draw horizontal baseline (entire width) - slightly thicker
    final baselinePaint = Paint()
      ..color = whiteColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(0, 16), Offset(size.width, 16), baselinePaint);

    // Draw IU marker ticks and labels - thicker ticks
    final tickPaint = Paint()
      ..color = whiteColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw ticks: every 5 IU (half tick), every 10 IU (minor), every 50 IU (major)
    for (double iu = 0; iu <= totalIU; iu += 5) {
      final x = totalIU <= 0 ? 0.0 : (iu / totalIU) * size.width;
      final isMajor = iu % 50 == 0;
      final isMinor = iu % 10 == 0 && !isMajor;

      final tickTop = isMajor ? 2.0 : (isMinor ? 8.0 : 12.0);
      final tickBottom = isMajor ? 30.0 : (isMinor ? 24.0 : 20.0);

      canvas.drawLine(Offset(x, tickTop), Offset(x, tickBottom), tickPaint);

      // Draw white labels for major ticks with padding
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: iu.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 10,
              color: whiteColor,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        // Add padding above numbers
        tp.paint(canvas, Offset(x - tp.width / 2, -2));
      }
    }

    // Draw thick white fill line representing the amount in syringe
    final ratio = totalIU <= 0 ? 0.0 : (fillIU / totalIU).clamp(0.0, 1.0);
    if (ratio > 0 && !ratio.isNaN) {
      final fillPaint = Paint()
        ..color = whiteColor
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final fillEndX = size.width * ratio;
      canvas.drawLine(const Offset(0, 16), Offset(fillEndX, 16), fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteSyringePainter oldDelegate) {
    return oldDelegate.totalIU != totalIU || oldDelegate.fillIU != fillIU;
  }
}
