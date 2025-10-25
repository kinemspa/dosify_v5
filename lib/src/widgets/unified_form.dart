// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';

/// Unified form building blocks to guarantee identical look & feel across screens.
///
/// Use these instead of ad-hoc rows/containers to match Tablet/Capsule styling
/// for labels, fonts, colors, paddings, and control sizing.

/// Default label column width used in left-label layouts (matches Tablet/Capsule)
const double kLabelColWidth = 120;

/// Default width for compact controls (dropdowns, numeric fields, date button)
const double kSmallControlWidth = 120;

/// Responsive width fraction for compact controls (as percentage of available field space)
/// Changed from 0.75 to 1.0 to use full available width up to max constraint
const double kCompactControlWidthFraction = 1;

/// Minimum width for compact controls (prevents controls from becoming too small)
const double kMinCompactControlWidth = 120;

/// Maximum width for compact controls (prevents controls from becoming too large)
/// Increased from 180 to 240 to allow more expansion on larger screens
const double kMaxCompactControlWidth = 240;

/// A section card with identical decoration to the Tablet/Capsule screens.
class SectionFormCard extends StatelessWidget {
  const SectionFormCard({
    required this.title,
    required this.children,
    super.key,
    this.trailing,
    this.neutral = false,
    this.backgroundColor,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool neutral;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (neutral
                ? theme.colorScheme.surfaceContainerLowest
                : theme.colorScheme.primary.withValues(alpha: 0.03)),
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
            children: [
              Expanded(child: Text(title, style: sectionTitleStyle(context))),
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
    required this.label,
    required this.field,
    super.key,
    this.labelWidth = kLabelColWidth,
    this.lightText = false,
  });

  final String label;
  final Widget field;
  final double labelWidth;
  final bool lightText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: lightText
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontSize: kFontSizeMedium,
                      fontWeight: kFontWeightBold,
                      color: Colors.white.withOpacity(kReconTextMediumOpacity),
                    )
                  : fieldLabelStyle(context),
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
  const DateButton36({
    required this.label,
    required this.onPressed,
    super.key,
    this.width,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final double? width;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final btn = selected
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(width ?? kSmallControlWidth, kFieldHeight),
            ),
          );
    // Use responsive width if no explicit width provided
    if (width == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Match dropdown calculation: account for stepper buttons width
          // This makes date button align perfectly with dropdown and stepper
          const stepperButtonsWidth = 64.0;
          final adjustedMax = constraints.maxWidth - stepperButtonsWidth;
          final width = adjustedMax.clamp(
            kMinCompactControlWidth,
            kMaxCompactControlWidth,
          );
          return Align(
            child: SizedBox(height: kFieldHeight, width: width, child: btn),
          );
        },
      );
    }
    // Use explicit width if provided
    return UnconstrainedBox(
      child: SizedBox(height: kFieldHeight, width: width, child: btn),
    );
  }
}

/// A 120x36 Dropdown wrapper matching Tablet/Capsule sizing.
class SmallDropdown36<T> extends StatelessWidget {
  const SmallDropdown36({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
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
    // Use responsive width if no explicit width provided
    if (width == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Account for stepper buttons: 2 buttons (28px each) + 2 spacings (4px each) = 64px
          // This makes dropdown match the width of the stepper field (excluding buttons)
          const stepperButtonsWidth = 64.0;
          final adjustedMax = constraints.maxWidth - stepperButtonsWidth;
          final width = adjustedMax.clamp(
            kMinCompactControlWidth,
            kMaxCompactControlWidth,
          );
          return Align(
            child: SizedBox(
              height: kFieldHeight,
              width: width,
              child: DropdownButtonFormField<T>(
                initialValue: value,
                isExpanded: true,
                alignment: AlignmentDirectional.center,
                style: bodyTextStyle(context),
                items: items,
                onChanged: onChanged,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                decoration:
                    decoration ?? buildCompactFieldDecoration(context: context),
                menuMaxHeight: 480,
              ),
            ),
          );
        },
      );
    }
    // Use explicit width if provided
    return UnconstrainedBox(
      child: SizedBox(
        height: kFieldHeight,
        width: width,
        child: DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          alignment: AlignmentDirectional.center,
          style: bodyTextStyle(context),
          items: items,
          onChanged: onChanged,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          decoration:
              decoration ?? buildCompactFieldDecoration(context: context),
          menuMaxHeight: 480,
        ),
      ),
    );
  }
}

/// Primary-styled choice chip (selected = primary bg + white text)
class PrimaryChoiceChip extends StatelessWidget {
  const PrimaryChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.surfaceContainerHighest;
    final labelColor = selected ? Colors.white : theme.colorScheme.onSurface;
    return ChoiceChip(
      label: DefaultTextStyle(
        style:
            theme.textTheme.labelLarge?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ) ??
            TextStyle(color: labelColor),
        child: label,
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

/// Visual syringe gauge with tick markers
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
  const SyringeGauge({
    required this.totalUnits,
    required this.fillUnits,
    super.key,
  });
  final double totalUnits;
  final double fillUnits;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 26),
      painter: _SyringePainter(
        totalUnits: totalUnits,
        fillUnits: fillUnits,
        fillColor: Theme.of(context).colorScheme.primary,
        tickColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SyringePainter extends CustomPainter {
  _SyringePainter({
    required this.totalUnits,
    required this.fillUnits,
    required this.fillColor,
    required this.tickColor,
    required this.labelColor,
  });
  final double totalUnits;
  final double fillUnits;
  final Color fillColor;
  final Color tickColor;
  final Color labelColor;
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 6, size.width, 14);
    const radius = Radius.circular(7);
    final bg = Paint()
      ..color = const Color(0xFFEAEAEA)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFFB0B0B0)
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(r, radius), bg);
    canvas.drawRRect(RRect.fromRectAndRadius(r, radius), outline);
    // Fill
    final ratio = totalUnits <= 0
        ? 0.0
        : (fillUnits / totalUnits).clamp(0.0, 1.0);
    final fillRect = Rect.fromLTWH(
      0,
      6,
      size.width * (ratio.isNaN ? 0 : ratio),
      14,
    );
    final fillPaint = Paint()..color = fillColor;
    canvas.drawRRect(RRect.fromRectAndRadius(fillRect, radius), fillPaint);
    // Tick marks every 10 units, major every 50 units
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1;
    // Draw minor half ticks every 5 units, full minor every 10 units, major every 50 units
    for (double units = 0; units <= totalUnits; units += 5) {
      final x = (units / totalUnits) * size.width;
      final isMajor = units % 50 == 0;
      final isMinor = units % 10 == 0 && !isMajor;
      final tickTop = isMajor ? 1.0 : (isMinor ? 3.0 : 6.0);
      final tickBottom = isMajor ? 25.0 : (isMinor ? 22.0 : 18.0);
      canvas.drawLine(Offset(x, tickTop), Offset(x, tickBottom), tickPaint);
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: units.toStringAsFixed(0),
            style: TextStyle(fontSize: 9, color: labelColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 0));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SyringePainter oldDelegate) {
    return oldDelegate.totalUnits != totalUnits ||
        oldDelegate.fillUnits != fillUnits;
  }
}

/// A [-] [ 120x36 Field36 TextField ] [+] row used for numeric steppers.
class StepperRow36 extends StatelessWidget {
  const StepperRow36({
    required this.controller,
    required this.onDec,
    required this.onInc,
    required this.decoration,
    super.key,
    this.compact = false,
    this.enabled = true,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final InputDecoration decoration;
  final bool compact;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Account for buttons and spacing in the available width
        // 2 buttons (28px each) + 2 spacings (4px each) = 64px total
        const buttonsAndSpacing = 64.0;

        // Calculate field width from available space, subtracting button widths
        final availableForField = constraints.maxWidth - buttonsAndSpacing;
        final fieldWidth = availableForField.clamp(
          kMinCompactControlWidth,
          kMaxCompactControlWidth,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _pillBtn(context, '−', enabled ? onDec : () {}),
            const SizedBox(width: 4),
            SizedBox(
              width: fieldWidth,
              child: Field36(
                child: Builder(
                  builder: (context) {
                    final style = compact
                        ? inputTextStyle(context)
                        : bodyTextStyle(context);
                    return TextFormField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      style: style,
                      decoration: decoration,
                      enabled: enabled,
                      inputFormatters: inputFormatters,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 4),
            _pillBtn(context, '+', enabled ? onInc : () {}),
          ],
        );
      },
    );
  }

  Widget _pillBtn(BuildContext context, String symbol, VoidCallback onTap) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 28,
      width: 28,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(28, 28),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(
              kCardBorderOpacity,
            ),
            width: kBorderWidthThin,
          ),
          foregroundColor: theme.colorScheme.onSurface,
        ),
        onPressed: enabled ? onTap : null,
        child: Text(
          symbol,
          style: bodyTextStyle(context)?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
