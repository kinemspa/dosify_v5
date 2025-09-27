import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

/// Unified form building blocks to guarantee identical look & feel across screens.
///
/// Use these instead of ad-hoc rows/containers to match Tablet/Capsule styling
/// for labels, fonts, colors, paddings, and control sizing.

/// Default label column width used in left-label layouts (matches Tablet/Capsule)
const double kLabelColWidth = 120.0;

/// Default width for compact controls (dropdowns, numeric fields, date button)
const double kSmallControlWidth = 120.0;

/// A section card with identical decoration to the Tablet/Capsule screens.
class SectionFormCard extends StatelessWidget {
  const SectionFormCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.neutral = false,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: neutral
            ? theme.colorScheme.surfaceContainerLowest
            : theme.colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: neutral
            ? Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 0.75,
              )
            : Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
              ),
        boxShadow: neutral
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// A left-label / right-field row. Label has fixed width and unified style.
class LabelFieldRow extends StatelessWidget {
  const LabelFieldRow({
    super.key,
    required this.label,
    required this.field,
    this.labelWidth = kLabelColWidth,
  });

  final String label;
  final Widget field;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: field),
        ],
      ),
    );
  }
}

/// A 120x36 OutlinedButton with a calendar icon, matching Tablet/Capsule date picker button.
class DateButton36 extends StatelessWidget {
  const DateButton36({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kFieldHeight,
      width: kSmallControlWidth,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_today, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, kFieldHeight),
        ),
      ),
    );
  }
}

/// A 120x36 Dropdown wrapper matching Tablet/Capsule sizing.
class SmallDropdown36<T> extends StatelessWidget {
  const SmallDropdown36({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.decoration,
    this.width,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final InputDecoration? decoration;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: kFieldHeight,
      width: width ?? kSmallControlWidth,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: false,
        alignment: AlignmentDirectional.center,
        style: theme.textTheme.bodyMedium,
        items: items,
        onChanged: onChanged,
        icon: Icon(
          Icons.arrow_drop_down,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        decoration: decoration ?? const InputDecoration(isDense: true),
        menuMaxHeight: 320,
      ),
    );
  }
}

/// Primary-styled choice chip (selected = primary bg + white text)
class PrimaryChoiceChip extends StatelessWidget {
  const PrimaryChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.surfaceContainerHighest;
    return ChoiceChip(
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: selected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor,
      backgroundColor: unselectedColor,
      showCheckmark: false,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }
}

/// Visual insulin syringe gauge with tick markers
/// Reusable soft white card decoration used across selection tiles and neutral form sections
BoxDecoration softWhiteCardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  return BoxDecoration(
    color: theme.colorScheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
      width: 0.75,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class SyringeGauge extends StatelessWidget {
  const SyringeGauge({super.key, required this.totalIU, required this.fillIU});
  final double totalIU;
  final double fillIU;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity as double, 26),
      painter: _SyringePainter(totalIU: totalIU, fillIU: fillIU),
    );
  }
}

class _SyringePainter extends CustomPainter {
  _SyringePainter({required this.totalIU, required this.fillIU});
  final double totalIU;
  final double fillIU;
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 6, size.width, 14);
    final radius = const Radius.circular(7);
    final bg = Paint()
      ..color = const Color(0xFFEAEAEA)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFFB0B0B0)
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(r, radius), bg);
    canvas.drawRRect(RRect.fromRectAndRadius(r, radius), outline);
    // Fill
    final ratio = totalIU <= 0 ? 0.0 : (fillIU / totalIU).clamp(0.0, 1.0);
    final fillRect = Rect.fromLTWH(
      0,
      6,
      size.width * (ratio.isNaN ? 0 : ratio),
      14,
    );
    final fillPaint = Paint()..color = Colors.blueAccent;
    canvas.drawRRect(RRect.fromRectAndRadius(fillRect, radius), fillPaint);
    // Tick marks every 10 IU, major every 50 IU
    final tickPaint = Paint()
      ..color = const Color(0xFF6B6B6B)
      ..strokeWidth = 1;
    for (double iu = 0; iu <= totalIU; iu += 10) {
      final x = (iu / totalIU) * size.width;
      final isMajor = iu % 50 == 0;
      final tickTop = isMajor ? 2.0 : 4.0;
      final tickBottom = isMajor ? 24.0 : 20.0;
      canvas.drawLine(Offset(x, tickTop), Offset(x, tickBottom), tickPaint);
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: iu.toStringAsFixed(0),
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B6B6B)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 0));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SyringePainter oldDelegate) {
    return oldDelegate.totalIU != totalIU || oldDelegate.fillIU != fillIU;
  }
}

/// A [-] [ 120x36 Field36 TextField ] [+] row used for numeric steppers.
class StepperRow36 extends StatelessWidget {
  const StepperRow36({
    super.key,
    required this.controller,
    required this.onDec,
    required this.onInc,
    required this.decoration,
  });

  final TextEditingController controller;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pillBtn(context, '−', onDec),
        const SizedBox(width: 6),
        SizedBox(
          width: kSmallControlWidth,
          child: Field36(
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                  decoration: decoration,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 6),
        _pillBtn(context, '+', onInc),
      ],
    );
  }

  Widget _pillBtn(BuildContext context, String symbol, VoidCallback onTap) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 30,
      width: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(30, 30),
        ),
        onPressed: onTap,
        child: Text(
          symbol,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
        ),
      ),
    );
  }
}
