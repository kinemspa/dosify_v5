import 'dart:math' as math;

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';

/// Circular stock donut gauge with a subtle glass effect.
///
/// This is the centralized gauge used by Large Cards and other views.
class StockDonutGauge extends StatelessWidget {
  const StockDonutGauge({
    super.key,
    required this.percentage,
    required this.primaryLabel,
  });

  /// Percentage remaining, in the range 0–100.
  final double percentage;

  /// Main label inside the donut (e.g. `12` or `450 mL`).
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clamped = percentage.clamp(0, 100);
    final fraction = clamped / 100.0;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft radial "glass" glow behind the ring.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withOpacity(0.16),
                    cs.surface.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Donut ring.
          CustomPaint(
            size: const Size.square(96),
            painter: _StockDonutPainter(
              fraction: fraction,
              baseColor: cs.outlineVariant.withOpacity(kCardBorderOpacity),
              fillColor: cs.primary,
            ),
          ),
          // Center label (percentage only).
          Text(
            primaryLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: kFontWeightExtraBold,
              color: cs.onSurfaceVariant.withOpacity(kOpacityMediumHigh),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dual-ring variant for showing two related stock percentages.
///
/// Useful for Multi Dose Vials where the outer ring can represent
/// the active vial volume and the inner ring can represent sealed
////backup vials status.
class DualStockDonutGauge extends StatelessWidget {
  const DualStockDonutGauge({
    super.key,
    required this.outerPercentage,
    required this.innerPercentage,
    required this.primaryLabel,
  });

  /// Outer ring percentage (e.g. active vial volume), 0–100.
  final double outerPercentage;

  /// Inner ring percentage (e.g. sealed vials coverage), 0–100.
  final double innerPercentage;

  /// Main label in the centre (typically the active vial percentage).
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final outerFraction = outerPercentage.clamp(0, 100) / 100.0;
    final innerFraction = innerPercentage.clamp(0, 100) / 100.0;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shared glow.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withOpacity(0.16),
                    cs.surface.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Outer ring (active vial).
          CustomPaint(
            size: const Size.square(96),
            painter: _StockDonutPainter(
              fraction: outerFraction,
              baseColor: cs.outlineVariant.withOpacity(kCardBorderOpacity),
              fillColor: cs.primary,
            ),
          ),
          // Inner ring (sealed/backup vials) – much thinner, very faint.
          CustomPaint(
            size: const Size.square(84),
            painter: _StockDonutPainter(
              fraction: innerFraction,
              baseColor: cs.outlineVariant.withOpacity(
                kCardBorderOpacity * 0.6,
              ),
              fillColor: _lighten(cs.primary, 0.28),
            ),
          ),
          // Centre label.
          Text(
            primaryLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: kFontWeightExtraBold,
              color: cs.onSurfaceVariant.withOpacity(kOpacityMediumHigh),
            ),
          ),
        ],
      ),
    );
  }
}

Color _lighten(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightened = hsl.withLightness(
    (hsl.lightness + amount).clamp(0.0, 1.0),
  );
  return lightened.toColor();
}

class _StockDonutPainter extends CustomPainter {
  _StockDonutPainter({
    required this.fraction,
    required this.baseColor,
    required this.fillColor,
  });

  final double fraction; // 0.0–1.0
  final Color baseColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = size.width >= 90 ? 10.0 : 5.0;
    final rect = Rect.fromCircle(center: center, radius: radius - 4);

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [fillColor.withOpacity(0.9), fillColor.withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Background ring.
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, basePaint);

    // Foreground arc.
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StockDonutPainter oldDelegate) {
    return fraction != oldDelegate.fraction ||
        baseColor != oldDelegate.baseColor ||
        fillColor != oldDelegate.fillColor;
  }
}
