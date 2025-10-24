// Flutter imports:
import 'package:flutter/material.dart';

/// Interactive syringe slider that combines the gauge visualization with slider functionality
/// User can drag the syringe fill level directly on the graphic
class InteractiveSyringeSlider extends StatefulWidget {
  const InteractiveSyringeSlider({
    required this.totalUnits,
    required this.fillUnits,
    required this.minUnits,
    required this.maxUnits,
    required this.onChanged,
    super.key,
    this.divisions,
    this.color,
  });

  final double totalUnits;
  final double fillUnits;
  final double minUnits;
  final double maxUnits;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final Color? color;

  @override
  State<InteractiveSyringeSlider> createState() =>
      _InteractiveSyringeSliderState();
}

class _InteractiveSyringeSliderState extends State<InteractiveSyringeSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;
    final currentValue = _dragValue ?? widget.fillUnits;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final box = context.findRenderObject()! as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final height = box.size.height;

        // Calculate fill percentage from bottom (inverted Y axis)
        // Top of widget = maxUnits, bottom = minUnits
        final fillPercentage =
            1.0 - (localPosition.dy / height).clamp(0.0, 1.0);

        // Convert to units value within min/max range
        final newValue =
            widget.minUnits +
            (fillPercentage * (widget.maxUnits - widget.minUnits));

        setState(() {
          _dragValue = newValue.clamp(widget.minUnits, widget.maxUnits);
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragValue != null) {
          widget.onChanged(_dragValue!);
          setState(() {
            _dragValue = null;
          });
        }
      },
      onVerticalDragCancel: () {
        setState(() {
          _dragValue = null;
        });
      },
      onTapUp: (details) {
        final box = context.findRenderObject()! as RenderBox;
        final localPosition = box.localToGlobal(Offset.zero);
        final tapLocal = details.globalPosition - localPosition;
        final height = box.size.height;

        // Calculate fill from tap position
        final fillPercentage = 1.0 - (tapLocal.dy / height).clamp(0.0, 1.0);
        final newValue =
            widget.minUnits +
            (fillPercentage * (widget.maxUnits - widget.minUnits));

        widget.onChanged(newValue.clamp(widget.minUnits, widget.maxUnits));
      },
      child: CustomPaint(
        size: const Size(double.infinity, 60),
        painter: _InteractiveSyringePainter(
          totalUnits: widget.totalUnits,
          fillUnits: currentValue,
          minUnits: widget.minUnits,
          maxUnits: widget.maxUnits,
          color: effectiveColor,
        ),
      ),
    );
  }
}

class _InteractiveSyringePainter extends CustomPainter {
  _InteractiveSyringePainter({
    required this.totalUnits,
    required this.fillUnits,
    required this.minUnits,
    required this.maxUnits,
    required this.color,
  });

  final double totalUnits;
  final double fillUnits;
  final double minUnits;
  final double maxUnits;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;

    // Main syringe barrel dimensions
    final barrelLeft = width * 0.1;
    final barrelRight = width * 0.9;
    final barrelWidth = barrelRight - barrelLeft;
    final barrelTop = height * 0.15;
    final barrelBottom = height * 0.85;
    final barrelHeight = barrelBottom - barrelTop;

    // Draw outer barrel
    canvas.drawLine(
      Offset(barrelLeft, barrelTop),
      Offset(barrelLeft, barrelBottom),
      paint,
    );
    canvas.drawLine(
      Offset(barrelRight, barrelTop),
      Offset(barrelRight, barrelBottom),
      paint,
    );

    // Draw plunger at top
    final plungerWidth = barrelWidth * 0.4;
    final plungerLeft = barrelLeft + (barrelWidth - plungerWidth) / 2;
    final plungerRight = plungerLeft + plungerWidth;
    canvas.drawLine(
      Offset(plungerLeft, barrelTop - 4),
      Offset(plungerRight, barrelTop - 4),
      paint,
    );
    canvas.drawLine(
      Offset(plungerLeft + plungerWidth / 2, barrelTop - 4),
      Offset(plungerLeft + plungerWidth / 2, barrelTop),
      paint,
    );

    // Draw needle at bottom
    final needleWidth = barrelWidth * 0.15;
    final needleLeft = barrelLeft + (barrelWidth - needleWidth) / 2;
    final needleRight = needleLeft + needleWidth;
    canvas.drawLine(
      Offset(needleLeft, barrelBottom),
      Offset(needleLeft + needleWidth / 2, barrelBottom + 8),
      paint,
    );
    canvas.drawLine(
      Offset(needleRight, barrelBottom),
      Offset(needleLeft + needleWidth / 2, barrelBottom + 8),
      paint,
    );

    // Calculate fill position within the allowed range
    final fillRatio =
        (fillUnits - minUnits) /
        (maxUnits - minUnits).clamp(0.001, double.infinity);
    final fillHeight = fillRatio * barrelHeight;
    final fillTop = barrelBottom - fillHeight;

    // Draw fill indicator with thick line
    if (fillHeight > 0) {
      canvas.drawLine(
        Offset(barrelLeft, fillTop),
        Offset(barrelRight, fillTop),
        fillPaint,
      );
    }

    // Draw tick marks and labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw min/max range indicators
    final rangePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Min line
    final minY = barrelBottom;
    canvas.drawLine(
      Offset(barrelLeft - 4, minY),
      Offset(barrelRight + 4, minY),
      rangePaint,
    );

    // Max line
    final maxY = barrelTop;
    canvas.drawLine(
      Offset(barrelLeft - 4, maxY),
      Offset(barrelRight + 4, maxY),
      rangePaint,
    );

    // Draw unit labels on major intervals (every 50 units or adjusted for range)
    final range = maxUnits - minUnits;
    final labelInterval = range <= 50 ? 10.0 : 50.0;

    for (
      var units = (minUnits / labelInterval).ceil() * labelInterval;
      units <= maxUnits;
      units += labelInterval
    ) {
      final ratio = (units - minUnits) / (maxUnits - minUnits);
      final y = barrelBottom - (ratio * barrelHeight);

      // Draw tick
      canvas.drawLine(
        Offset(barrelRight + 2, y),
        Offset(barrelRight + 8, y),
        paint,
      );

      // Draw label
      textPainter.text = TextSpan(
        text: units.toInt().toString(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(barrelRight + 12, y - textPainter.height / 2),
      );
    }

    // Draw current fill value
    textPainter.text = TextSpan(
      text:
          '${fillUnits.toStringAsFixed(fillUnits == fillUnits.roundToDouble() ? 0 : 1)} U',
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
    );
    textPainter.layout();

    // Position label near fill line
    final labelY = (fillTop - 16).clamp(4.0, height - textPainter.height - 4);
    textPainter.paint(canvas, Offset((width - textPainter.width) / 2, labelY));
  }

  @override
  bool shouldRepaint(_InteractiveSyringePainter oldDelegate) {
    return oldDelegate.fillUnits != fillUnits ||
        oldDelegate.totalUnits != totalUnits ||
        oldDelegate.minUnits != minUnits ||
        oldDelegate.maxUnits != maxUnits ||
        oldDelegate.color != color;
  }
}
