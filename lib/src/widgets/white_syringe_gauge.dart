// Flutter imports:
import 'package:flutter/material.dart';

/// Syringe gauge widget used for reconstitution visualization
/// Shows a horizontal line with IU markers and thick fill line
/// Can be interactive - drag the fill line to adjust value
class WhiteSyringeGauge extends StatefulWidget {
  const WhiteSyringeGauge({
    required this.totalIU, required this.fillIU, super.key,
    this.color,
    this.onChanged,
    this.interactive = false,
    this.maxConstraint,
    this.onMaxConstraintHit,
  });

  final double totalIU;
  final double fillIU;
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

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final currentFill = _dragValue ?? widget.fillIU;

    return GestureDetector(
      onHorizontalDragUpdate: widget.interactive
          ? (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final localPosition = box.globalToLocal(details.globalPosition);
              final width = box.size.width;
              final fillRatio = (localPosition.dx / width).clamp(0.0, 1.0);
              var newFillIU = fillRatio * widget.totalIU;

              // Check max constraint
              if (widget.maxConstraint != null && newFillIU > widget.maxConstraint!) {
                newFillIU = widget.maxConstraint!;
                if (!_hitConstraint) {
                  _hitConstraint = true;
                  widget.onMaxConstraintHit?.call();
                }
              } else {
                _hitConstraint = false;
              }

              setState(() {
                _dragValue = newFillIU;
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
              var newFillIU = fillRatio * widget.totalIU;

              // Check max constraint
              if (widget.maxConstraint != null && newFillIU > widget.maxConstraint!) {
                newFillIU = widget.maxConstraint!;
                widget.onMaxConstraintHit?.call();
              }

              if (widget.onChanged != null) {
                widget.onChanged!(newFillIU);
              }
            }
          : null,
      child: CustomPaint(
        size: const Size(double.infinity, 44),
        painter: _WhiteSyringePainter(
          totalIU: widget.totalIU,
          fillIU: currentFill,
          color: effectiveColor,
          interactive: widget.interactive,
        ),
      ),
    );
  }
}

class _WhiteSyringePainter extends CustomPainter {
  _WhiteSyringePainter({
    required this.totalIU,
    required this.fillIU,
    required this.color,
    this.interactive = false,
  });

  final double totalIU;
  final double fillIU;
  final Color color;
  final bool interactive;

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

    canvas.drawLine(Offset(0, baselineY), Offset(size.width, baselineY), baselinePaint);

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
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
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
      canvas.drawLine(Offset(0, baselineY), Offset(fillEndX, baselineY), fillPaint);

      // Draw draggable handle indicator if interactive
      if (interactive && fillEndX > 0) {
        final handlePaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        // Draw a circular handle at the end of the fill line
        canvas.drawCircle(Offset(fillEndX, baselineY), 6, handlePaint);

        // Draw white center to make it more visible
        final centerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(fillEndX, baselineY), 3, centerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteSyringePainter oldDelegate) {
    return oldDelegate.totalIU != totalIU ||
        oldDelegate.fillIU != fillIU ||
        oldDelegate.color != color ||
        oldDelegate.interactive != interactive;
  }
}
