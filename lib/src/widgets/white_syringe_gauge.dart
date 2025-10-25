// Flutter imports:
import 'package:flutter/material.dart';

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
  });

  final double totalUnits;
  final double fillUnits;
  final Color? color;
  final ValueChanged<double>? onChanged;
  final bool interactive;
  final double? maxConstraint;
  final VoidCallback? onMaxConstraintHit;

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
        decoration: _isActivelyDragging
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: effectiveColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: CustomPaint(
          size: const Size(double.infinity, 44),
          painter: _WhiteSyringePainter(
            totalUnits: widget.totalUnits,
            fillUnits: currentFill,
            color: effectiveColor,
            interactive: widget.interactive,
            isActivelyDragging: _isActivelyDragging,
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
    this.interactive = false,
    this.isActivelyDragging = false,
  });

  final double totalUnits;
  final double fillUnits;
  final Color color;
  final bool interactive;
  final bool isActivelyDragging;

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
        final tp = TextPainter(
          text: TextSpan(
            text: units.toStringAsFixed(0),
            style: TextStyle(
              // Smaller font for 5U marks on small syringes
              fontSize: isMajor ? 10 : (isMinor ? 9 : 7),
              color: color,
              fontWeight: FontWeight.w600,
            ),
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
        canvas.drawCircle(Offset(fillEndX, baselineY), handleRadius, handlePaint);

        // Draw white center to make it more visible
        final centerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(fillEndX, baselineY), centerRadius, centerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteSyringePainter oldDelegate) {
    return oldDelegate.totalUnits != totalUnits ||
        oldDelegate.fillUnits != fillUnits ||
        oldDelegate.color != color ||
        oldDelegate.interactive != interactive ||
        oldDelegate.isActivelyDragging != isActivelyDragging;
  }
}
