// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';

/// Syringe gauge widget used for reconstitution visualization
/// Shows a horizontal line with unit markers and thick fill line
/// Can be interactive - drag the fill line to adjust value
class WhiteSyringeGauge extends StatefulWidget {
  const WhiteSyringeGauge({
    required this.totalUnits,
    required this.fillUnits,
    super.key,
    this.color,
    this.onChanged,
    this.interactive = false,
    this.maxConstraint,
    this.onMaxConstraintHit,
    this.showValueLabel = false,
  });

  final double totalUnits;
  final double fillUnits;
  final Color? color;
  final ValueChanged<double>? onChanged;
  final bool interactive;
  final double? maxConstraint;
  final VoidCallback? onMaxConstraintHit;
  final bool showValueLabel;

  @override
  State<WhiteSyringeGauge> createState() => _WhiteSyringeGaugeState();
}

class _WhiteSyringeGaugeState extends State<WhiteSyringeGauge> {
  double? _dragValue;
  bool _hitConstraint = false;
  bool _isActivelyDragging = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;
    final currentFill = _dragValue ?? widget.fillUnits;
    final labelBackgroundColor = reconBackgroundActiveColor(context);
    final cs = Theme.of(context).colorScheme;
    final labelTextColor = cs.onPrimary;

    return GestureDetector(
      onHorizontalDragStart: widget.interactive
          ? (details) {
              setState(() {
                _isActivelyDragging = true;
              });
            }
          : null,
      onHorizontalDragUpdate: widget.interactive
          ? (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final localPosition = box.globalToLocal(details.globalPosition);
              final width = box.size.width;
              final fillRatio = (localPosition.dx / width).clamp(0.0, 1.0);
              var newFillUnits = fillRatio * widget.totalUnits;

              // Check max constraint
              if (widget.maxConstraint != null &&
                  newFillUnits > widget.maxConstraint!) {
                newFillUnits = widget.maxConstraint!;
                if (!_hitConstraint) {
                  _hitConstraint = true;
                  widget.onMaxConstraintHit?.call();
                }
              } else {
                _hitConstraint = false;
              }

              setState(() {
                _dragValue = newFillUnits;
              });
            }
          : null,
      onHorizontalDragEnd: widget.interactive
          ? (details) {
              if (_dragValue != null && widget.onChanged != null) {
                widget.onChanged!(_dragValue!);
              }
              setState(() {
                _dragValue = null;
                _hitConstraint = false;
                _isActivelyDragging = false;
              });
            }
          : null,
      onTapUp: widget.interactive
          ? (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final localPosition = box.globalToLocal(details.globalPosition);
              final width = box.size.width;
              final fillRatio = (localPosition.dx / width).clamp(0.0, 1.0);
              var newFillUnits = fillRatio * widget.totalUnits;

              // Check max constraint
              if (widget.maxConstraint != null &&
                  newFillUnits > widget.maxConstraint!) {
                newFillUnits = widget.maxConstraint!;
                widget.onMaxConstraintHit?.call();
              }

              if (widget.onChanged != null) {
                widget.onChanged!(newFillUnits);
              }
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: null, // Removed glow animation entirely
        child: CustomPaint(
          size: const Size(double.infinity, kWhiteSyringeGaugeHeight),
          painter: _WhiteSyringePainter(
            totalUnits: widget.totalUnits,
            fillUnits: currentFill,
            color: effectiveColor,
            labelBackgroundColor: labelBackgroundColor,
            labelTextColor: labelTextColor,
            handleCenterColor: cs.surface,
            majorTickLabelStyle: syringeGaugeTickLabelTextStyle(
              context,
              color: effectiveColor,
              fontSize: kSyringeGaugeTickFontSizeMajor,
            ),
            minorTickLabelStyle: syringeGaugeTickLabelTextStyle(
              context,
              color: effectiveColor,
              fontSize: kSyringeGaugeTickFontSizeMinor,
            ),
            microTickLabelStyle: syringeGaugeTickLabelTextStyle(
              context,
              color: effectiveColor,
              fontSize: kSyringeGaugeTickFontSizeMicro,
            ),
            valueLabelStyle: syringeGaugeValueLabelTextStyle(
              context,
              color: labelTextColor,
            ),
            interactive: widget.interactive,
            isActivelyDragging: _isActivelyDragging,
            showValueLabel: widget.showValueLabel,
          ),
        ),
      ),
    );
  }
}

class _WhiteSyringePainter extends CustomPainter {
  _WhiteSyringePainter({
    required this.totalUnits,
    required this.fillUnits,
    required this.color,
    required this.labelBackgroundColor,
    required this.labelTextColor,
    required this.handleCenterColor,
    required this.majorTickLabelStyle,
    required this.minorTickLabelStyle,
    required this.microTickLabelStyle,
    required this.valueLabelStyle,
    this.interactive = false,
    this.isActivelyDragging = false,
    this.showValueLabel = false,
  });

  final double totalUnits;
  final double fillUnits;
  final Color color;
  final Color labelBackgroundColor;
  final Color labelTextColor;
  final Color handleCenterColor;
  final TextStyle? majorTickLabelStyle;
  final TextStyle? minorTickLabelStyle;
  final TextStyle? microTickLabelStyle;
  final TextStyle? valueLabelStyle;
  final bool interactive;
  final bool isActivelyDragging;
  final bool showValueLabel;

  @override
  void paint(Canvas canvas, Size size) {
    // Reserve bottom space so tick labels are not clipped.
    final baselineY = size.height - kWhiteSyringeGaugeBottomLabelPadding;

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

    // Draw unit marker ticks and labels
    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // For 0.3ml (30U) and 0.5ml (50U) syringes, use finer 1-unit increments
    // For 1ml (100U), use 5-unit increments
    // For 3ml (300U) and 5ml (500U), use 10-unit increments (label every 50U)
    final isSmallSyringe = totalUnits <= 50;
    final isMediumSyringe = totalUnits > 50 && totalUnits <= 100;
    final isLargeSyringe = totalUnits > 100;
    final tickInterval = isSmallSyringe ? 1.0 : (isMediumSyringe ? 5.0 : 10.0);

    // Draw ticks with appropriate intervals
    for (double units = 0; units <= totalUnits; units += tickInterval) {
      final x = totalUnits <= 0 ? 0.0 : (units / totalUnits) * size.width;
      final isMajor =
          units % 100 == 0 ||
          (isLargeSyringe &&
              units % 50 == 0); // For large syringes, 50U is major
      final isMinor = !isLargeSyringe && units % 10 == 0 && !isMajor;
      // For small syringes, 5-unit marks are special
      final isFiveUnit =
          isSmallSyringe && units % 5 == 0 && !isMinor && !isMajor;

      // All ticks end at baseline, start above it
      double tickHeight;
      if (isMajor) {
        tickHeight = 20.0;
      } else if (isMinor) {
        tickHeight = 12.0;
      } else if (isFiveUnit) {
        tickHeight = 8.0; // Medium tick for 5-unit marks on small syringes
      } else {
        tickHeight = isSmallSyringe
            ? 4.0
            : 6.0; // Smaller ticks for 1-unit on small syringes
      }
      final tickTop = baselineY - tickHeight;

      canvas.drawLine(Offset(x, tickTop), Offset(x, baselineY), tickPaint);

      // Draw labels:
      // - 0.3ml/0.5ml: label every 5U (5, 10, 15, 20, 25, 30...)
      // - 1ml: label every 10U (10, 20, 30, 40, 50...)
      // - 3ml/5ml: label only 50U marks (50, 100, 150...)
      final shouldLabel = isMajor || isMinor || (isSmallSyringe && isFiveUnit);

      if (shouldLabel) {
        final tickTextStyle = isMajor
            ? majorTickLabelStyle
            : (isMinor ? minorTickLabelStyle : microTickLabelStyle);
        final tp = TextPainter(
          text: TextSpan(
            text: units.toStringAsFixed(0),
            style: tickTextStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        // Position below baseline with more padding for better spacing
        tp.paint(canvas, Offset(x - tp.width / 2, baselineY + 8));
      }
    }

    // Draw thick fill line representing the amount in syringe
    final ratio = totalUnits <= 0
        ? 0.0
        : (fillUnits / totalUnits).clamp(0.0, 1.0);
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

      // Draw draggable handle indicator if interactive
      if (interactive && fillEndX > 0) {
        // Larger handle when actively dragging
        final handleRadius = isActivelyDragging ? 8.0 : 6.0;
        final centerRadius = isActivelyDragging ? 4.0 : 3.0;

        final handlePaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        // Draw a circular handle at the end of the fill line
        canvas.drawCircle(
          Offset(fillEndX, baselineY),
          handleRadius,
          handlePaint,
        );

        // Draw white center to make it more visible
        final centerPaint = Paint()
          ..color = handleCenterColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(fillEndX, baselineY),
          centerRadius,
          centerPaint,
        );

        // Draw numeric unit indicator on handle (interactive: only while dragging)
        if (interactive && showValueLabel && isActivelyDragging) {
          final unitsText = fillUnits.round().toString();
          final unitPainter = TextPainter(
            text: TextSpan(
              text: unitsText,
              style: valueLabelStyle,
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          // Position above the handle
          final textX = fillEndX - unitPainter.width / 2;
          final textY = baselineY - handleRadius - unitPainter.height - 6;

          // Draw dark background circle behind number for contrast
          final backgroundRadius =
              (unitPainter.width > unitPainter.height
                      ? unitPainter.width
                      : unitPainter.height) /
                  2 +
              3;
          final backgroundPaint = Paint()
            ..color = labelBackgroundColor
            ..style = PaintingStyle.fill;
          canvas.drawCircle(
            Offset(fillEndX, textY + unitPainter.height / 2),
            backgroundRadius,
            backgroundPaint,
          );

          unitPainter.paint(canvas, Offset(textX, textY));
        }
      }

      // Draw value label for non-interactive gauges
      if (showValueLabel && !interactive && fillEndX > 0) {
        final unitsText = '${fillUnits.round()} U';
        final unitPainter = TextPainter(
          text: TextSpan(
            text: unitsText,
            style: valueLabelStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Position above the fill line
        final textX = fillEndX - unitPainter.width / 2;
        final textY = baselineY - 20 - unitPainter.height;

        final backgroundRadius =
            (unitPainter.width > unitPainter.height
                    ? unitPainter.width
                    : unitPainter.height) /
                2 +
            3;
        final backgroundPaint = Paint()
          ..color = labelBackgroundColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(fillEndX, textY + unitPainter.height / 2),
          backgroundRadius,
          backgroundPaint,
        );

        unitPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteSyringePainter oldDelegate) {
    return oldDelegate.totalUnits != totalUnits ||
        oldDelegate.fillUnits != fillUnits ||
        oldDelegate.color != color ||
        oldDelegate.interactive != interactive ||
        oldDelegate.isActivelyDragging != isActivelyDragging ||
        oldDelegate.showValueLabel != showValueLabel;
  }
}
