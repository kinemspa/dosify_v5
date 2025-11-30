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
    this.color,
    this.backgroundColor,
    this.textColor,
    this.showGlow = true,
    this.isOutline = false,
    this.labelStyle,
  });

  /// Percentage remaining, in the range 0–100.
  final double percentage;

  /// Main label inside the donut (e.g. `12` or `450 mL`).
  final String primaryLabel;

  /// Color of the progress arc.
  final Color? color;

  /// Color of the background ring.
  final Color? backgroundColor;

  /// Color of the center text.
  final Color? textColor;

  /// Whether to show the radial glass glow.
  final bool showGlow;

  /// Whether to render as an outline (thin borders) instead of a filled arc.
  final bool isOutline;
  final TextStyle? labelStyle;

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
          if (showGlow)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.16),
                      cs.surface.withValues(alpha: 0.0),
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
              baseColor:
                  backgroundColor ??
                  cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
              fillColor: color ?? cs.primary,
              isOutline: isOutline,
            ),
          ),
          // Center label (percentage only).
          Text(
            primaryLabel,
            style:
                labelStyle ??
                Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: kFontWeightExtraBold,
                  color:
                      textColor ??
                      cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
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
    this.color,
    this.backgroundColor,
    this.textColor,
    this.showGlow = true,
    this.isOutline = false,
    this.labelStyle,
  });

  /// Outer ring percentage (e.g. active vial volume), 0–100.
  final double outerPercentage;

  /// Inner ring percentage (e.g. sealed vials coverage), 0–100.
  final double innerPercentage;

  /// Main label in the centre (typically the active vial percentage).
  final String primaryLabel;

  /// Color of the outer progress arc.
  final Color? color;

  /// Color of the background ring.
  final Color? backgroundColor;

  /// Color of the center text.
  final Color? textColor;

  /// Whether to show the radial glass glow.
  final bool showGlow;

  /// Whether to render as an outline (thin borders) instead of a filled arc.
  final bool isOutline;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final outerFraction = outerPercentage.clamp(0, 100) / 100.0;
    final innerFraction = innerPercentage.clamp(0, 100) / 100.0;
    final effectiveColor = color ?? cs.primary;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shared glow.
          if (showGlow)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.16),
                      cs.surface.withValues(alpha: 0.0),
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
              baseColor:
                  backgroundColor ??
                  cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
              fillColor: effectiveColor,
              isOutline: isOutline,
            ),
          ),
          // Inner ring (sealed/backup vials) – same thickness, smaller radius
          CustomPaint(
            size: const Size.square(76), // Smaller size for inner ring
            painter: _StockDonutPainter(
              fraction: innerFraction,
              baseColor:
                  backgroundColor?.withValues(alpha: 0.5) ??
                  cs.outlineVariant.withValues(alpha: kCardBorderOpacity * 0.6),
              fillColor: effectiveColor.withValues(
                alpha: 0.4,
              ), // Low opacity primary color
              isOutline: isOutline,
              strokeWidth: 10.0,
            ),
          ),
          // Centre label.
          Text(
            primaryLabel,
            style:
                labelStyle ??
                Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: kFontWeightExtraBold,
                  color:
                      textColor ??
                      cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
                ),
          ),
        ],
      ),
    );
  }
}

class _StockDonutPainter extends CustomPainter {
  _StockDonutPainter({
    required this.fraction,
    required this.baseColor,
    required this.fillColor,
    this.isOutline = false,
    this.strokeWidth,
  });

  final double fraction; // 0.0–1.0
  final Color baseColor;
  final Color fillColor;
  final bool isOutline;
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    // The "thickness" of the donut if it were filled
    final thickness = strokeWidth ?? (size.width >= 90 ? 10.0 : 5.0);
    // The thin border line width
    final borderWidth = isOutline ? kBorderWidthThin : thickness;

    // 1. Draw Background Ring (Track)
    if (isOutline) {
      // Outline mode: Draw thin lines for track
      final basePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;

      canvas.drawCircle(center, radius - 4, basePaint);
      canvas.drawCircle(center, radius - 4 - thickness, basePaint);
    } else {
      // Filled mode: Draw thick track
      final basePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius - thickness / 2, basePaint);
    }

    // 2. Draw Foreground Arc
    if (fraction > 0) {
      if (isOutline) {
        // Outline mode: Draw thin borders for the arc
        final outlinePaint = Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeCap = StrokeCap.round;

        final startAngle = -math.pi / 2;
        final sweepAngle = 2 * math.pi * fraction;

        // Draw Outer Arc
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 4),
          startAngle,
          sweepAngle,
          false,
          outlinePaint,
        );

        // Draw Inner Arc
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 4 - thickness),
          startAngle,
          sweepAngle,
          false,
          outlinePaint,
        );

        // Draw Caps (Round ends connecting inner and outer)
        // Start Cap
        final startOuter = Offset(
          center.dx + (radius - 4) * math.cos(startAngle),
          center.dy + (radius - 4) * math.sin(startAngle),
        );
        final startInner = Offset(
          center.dx + (radius - 4 - thickness) * math.cos(startAngle),
          center.dy + (radius - 4 - thickness) * math.sin(startAngle),
        );
        final startCapCenter = Offset(
          (startOuter.dx + startInner.dx) / 2,
          (startOuter.dy + startInner.dy) / 2,
        );
        canvas.drawArc(
          Rect.fromCircle(center: startCapCenter, radius: thickness / 2),
          startAngle + math.pi,
          math.pi,
          false,
          outlinePaint,
        );

        // End Cap
        final endAngle = startAngle + sweepAngle;
        final endOuter = Offset(
          center.dx + (radius - 4) * math.cos(endAngle),
          center.dy + (radius - 4) * math.sin(endAngle),
        );
        final endInner = Offset(
          center.dx + (radius - 4 - thickness) * math.cos(endAngle),
          center.dy + (radius - 4 - thickness) * math.sin(endAngle),
        );
        final endCapCenter = Offset(
          (endOuter.dx + endInner.dx) / 2,
          (endOuter.dy + endInner.dy) / 2,
        );
        canvas.drawArc(
          Rect.fromCircle(center: endCapCenter, radius: thickness / 2),
          endAngle,
          math.pi,
          false,
          outlinePaint,
        );
      } else {
        // Filled mode: Draw thick arc
        final fillPaint = Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round;

        final startAngle = -math.pi / 2;
        final sweepAngle = 2 * math.pi * fraction;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - thickness / 2),
          startAngle,
          sweepAngle,
          false,
          fillPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StockDonutPainter oldDelegate) {
    return fraction != oldDelegate.fraction ||
        baseColor != oldDelegate.baseColor ||
        fillColor != oldDelegate.fillColor ||
        isOutline != oldDelegate.isOutline ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

/// Miniature stock gauge for compact cards.
///
/// If [size] is provided, it forces a square size.
/// Otherwise, it expands to fill the parent (useful in IntrinsicHeight rows).
class MiniStockGauge extends StatelessWidget {
  const MiniStockGauge({
    super.key,
    required this.percentage,
    this.color,
    this.size,
  });

  final double percentage;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fraction = percentage.clamp(0, 100) / 100.0;
    final effectiveColor = color ?? cs.primary;

    Widget gauge = CustomPaint(
      painter: _StockDonutPainter(
        fraction: fraction,
        baseColor: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        fillColor: effectiveColor,
      ),
    );

    if (size != null) {
      return SizedBox(width: size, height: size, child: gauge);
    }

    return AspectRatio(aspectRatio: 1, child: gauge);
  }
}
