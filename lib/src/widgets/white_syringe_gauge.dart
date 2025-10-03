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
      size: const Size(double.infinity, 26),
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

    // Draw fine horizontal baseline (entire width)
    final baselinePaint = Paint()
      ..color = whiteColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(0, 13), Offset(size.width, 13), baselinePaint);

    // Draw IU marker ticks and labels
    final tickPaint = Paint()
      ..color = whiteColor
      ..strokeWidth = 1.0;

    // Draw ticks: every 5 IU (half tick), every 10 IU (minor), every 50 IU (major)
    for (double iu = 0; iu <= totalIU; iu += 5) {
      final x = totalIU <= 0 ? 0.0 : (iu / totalIU) * size.width;
      final isMajor = iu % 50 == 0;
      final isMinor = iu % 10 == 0 && !isMajor;

      final tickTop = isMajor ? 1.0 : (isMinor ? 5.0 : 9.0);
      final tickBottom = isMajor ? 25.0 : (isMinor ? 21.0 : 17.0);

      canvas.drawLine(Offset(x, tickTop), Offset(x, tickBottom), tickPaint);

      // Draw white labels for major ticks
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: iu.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 9,
              color: whiteColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 0));
      }
    }

    // Draw thick white fill line representing the amount in syringe
    final ratio = totalIU <= 0 ? 0.0 : (fillIU / totalIU).clamp(0.0, 1.0);
    if (ratio > 0 && !ratio.isNaN) {
      final fillPaint = Paint()
        ..color = whiteColor
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final fillEndX = size.width * ratio;
      canvas.drawLine(const Offset(0, 13), Offset(fillEndX, 13), fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteSyringePainter oldDelegate) {
    return oldDelegate.totalIU != totalIU || oldDelegate.fillIU != fillIU;
  }
}
