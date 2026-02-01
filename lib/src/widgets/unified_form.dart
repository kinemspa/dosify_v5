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
    this.frameless = false,
    this.backgroundColor,
    this.titleStyle,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool neutral;
  final bool frameless;
  final Color? backgroundColor;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: titleStyle ?? sectionTitleStyle(context),
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

    if (frameless) return content;

    return Container(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (neutral
                ? (isDark
                      ? Color.alphaBlend(
                          theme.colorScheme.onSurface.withValues(
                            alpha: kOpacityFaint,
                          ),
                          theme.colorScheme.surface,
                        )
                      : theme.colorScheme.surfaceContainerLowest)
                : theme.colorScheme.primary.withValues(
                    alpha: isDark ? kOpacityFaint : 0.03,
                  )),
        borderRadius: BorderRadius.circular(12),
        border: neutral
            ? Border.all(
                color: theme.colorScheme.outlineVariant.withValues(
                  alpha: isDark ? kOpacityMediumHigh : 0.5,
                ),
                width: kOutlineWidth,
              )
            : Border.all(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDark ? kOpacitySubtleLow : 0.06,
                ),
                width: kOutlineWidth,
              ),
        boxShadow: neutral
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
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
      child: content,
    );
  }
}

/// Collapsible version of [SectionFormCard] that keeps the same styling.
///
/// This is used for reorderable/collapsible sections (e.g. Home screen cards)
/// where dragging should only be enabled when all cards are collapsed.
class CollapsibleSectionFormCard extends StatelessWidget {
  const CollapsibleSectionFormCard({
    required this.title,
    required this.children,
    required this.isExpanded,
    required this.onExpandedChanged,
    super.key,
    this.leading,
    this.trailing,
    this.titleStyle,
    this.neutral = false,
    this.frameless = false,
    this.backgroundColor,
    this.reserveReorderHandleGutterWhenCollapsed = false,
  });

  final String title;
  final List<Widget> children;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final bool neutral;
  final bool frameless;
  final Color? backgroundColor;
  final bool reserveReorderHandleGutterWhenCollapsed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onExpandedChanged(!isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (!isExpanded && reserveReorderHandleGutterWhenCollapsed)
                  const SizedBox(width: kDetailCardReorderHandleGutterWidth),
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: kSpacingS),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: titleStyle ?? sectionTitleStyle(context),
                  ),
                ),
                if (trailing != null) trailing!,
                AnimatedRotation(
                  turns: isExpanded ? 0 : -0.25,
                  duration: kAnimationNormal,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: kIconSizeLarge,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: kAnimationNormal,
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );

    if (frameless) return content;

    return Container(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (neutral
                ? (isDark
                      ? Color.alphaBlend(
                          cs.onSurface.withValues(alpha: kOpacityFaint),
                          cs.surface,
                        )
                      : cs.surfaceContainerLowest)
                : cs.primary.withValues(alpha: isDark ? kOpacityFaint : 0.03)),
        borderRadius: BorderRadius.circular(12),
        border: neutral
            ? Border.all(
                color: cs.outlineVariant.withValues(
                  alpha: isDark ? kOpacityMediumHigh : 0.5,
                ),
                width: kOutlineWidth,
              )
            : Border.all(
                color: cs.primary.withValues(
                  alpha: isDark ? kOpacitySubtleLow : 0.06,
                ),
                width: kOutlineWidth,
              ),
        boxShadow: neutral
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
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
      child: content,
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
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: lightText
                  ? fieldLabelStyle(context)?.copyWith(
                      color: cs.onPrimary.withValues(
                        alpha: kReconTextMediumOpacity,
                      ),
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

class MultiSelectItem<T> {
  const MultiSelectItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A compact multi-select dropdown-like control.
///
/// Uses a Material menu with checkmarks and keeps the menu open while toggling.
class MultiSelectDropdown36<T> extends StatefulWidget {
  const MultiSelectDropdown36({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    required this.buttonLabel,
    this.icon = Icons.tune_rounded,
  });

  final List<MultiSelectItem<T>> items;
  final Set<T> selectedValues;
  final ValueChanged<Set<T>> onChanged;
  final String buttonLabel;
  final IconData icon;

  @override
  State<MultiSelectDropdown36<T>> createState() =>
      _MultiSelectDropdown36State<T>();
}

class _MultiSelectDropdown36State<T> extends State<MultiSelectDropdown36<T>> {
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(covariant MultiSelectDropdown36<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValues != widget.selectedValues) {
      _selected = Set<T>.from(widget.selectedValues);
    }
  }

  void _toggle(T value) {
    final next = Set<T>.from(_selected);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }

    setState(() => _selected = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MenuAnchor(
      builder: (context, controller, child) {
        return SizedBox(
          height: kFieldHeight,
          child: OutlinedButton.icon(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: Icon(widget.icon, size: kIconSizeSmall),
            label: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.buttonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in widget.items)
                  MenuItemButton(
                    closeOnActivate: false,
                    onPressed: () => _toggle(item.value),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: bodyTextStyle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selected.contains(item.value))
                          Icon(
                            Icons.check_rounded,
                            size: kIconSizeSmall,
                            color: cs.primary,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary-styled choice chip (selected = primary bg + white text)
class PrimaryChoiceChip extends StatelessWidget {
  const PrimaryChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
    super.key,
  });
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = color ?? theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.surface.withValues(alpha: 0);
    final labelColor = selected ? theme.colorScheme.onPrimary : selectedColor;
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
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(
        color: selected
            ? selectedColor
            : theme.colorScheme.outlineVariant.withValues(
                alpha: kCardBorderOpacity,
              ),
        width: selected ? kBorderWidthMedium : kBorderWidthThin,
      ),
    );
  }
}

/// Primary-styled filter chip (multi-select).
///
/// Matches [PrimaryChoiceChip] visuals but uses [FilterChip].
class PrimaryFilterChip extends StatelessWidget {
  const PrimaryFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
    super.key,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = color ?? theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.surface.withValues(alpha: 0);
    final labelColor = selected ? theme.colorScheme.onPrimary : selectedColor;
    return FilterChip(
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
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(
        color: selected
            ? selectedColor
            : theme.colorScheme.outlineVariant.withValues(
                alpha: kCardBorderOpacity,
              ),
        width: selected ? kBorderWidthMedium : kBorderWidthThin,
      ),
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
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      width: 0.75,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return CustomPaint(
      size: const Size(double.infinity, 26),
      painter: _SyringePainter(
        totalUnits: totalUnits,
        fillUnits: fillUnits,
        fillColor: cs.primary,
        tickColor: cs.onSurfaceVariant,
        labelColor: cs.onSurfaceVariant,
        labelTextStyle: syringeGaugeSmallTickLabelTextStyle(
          context,
          color: cs.onSurfaceVariant,
        ),
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
    required this.labelTextStyle,
  });
  final double totalUnits;
  final double fillUnits;
  final Color fillColor;
  final Color tickColor;
  final Color labelColor;
  final TextStyle? labelTextStyle;
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
            style: labelTextStyle,
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
///
/// Use [fixedFieldWidth] when using in dialogs (LayoutBuilder doesn't work with IntrinsicWidth).
class StepperRow36 extends StatelessWidget {
  const StepperRow36({
    required this.controller,
    required this.onDec,
    required this.onInc,
    required this.decoration,
    super.key,
    this.compact = false,
    this.enabled = true,
    this.onChanged,
    this.inputFormatters,
    this.validator,
    this.keyboardType,
    this.fixedFieldWidth,
  });

  final TextEditingController controller;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final InputDecoration decoration;
  final bool compact;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  /// When set, bypasses LayoutBuilder (required for use in dialogs).
  final double? fixedFieldWidth;

  @override
  Widget build(BuildContext context) {
    // If fixedFieldWidth is provided, use it directly (for dialogs)
    if (fixedFieldWidth != null) {
      return _buildRow(context, fixedFieldWidth!);
    }

    // Otherwise use LayoutBuilder for responsive sizing
    return LayoutBuilder(
      builder: (context, constraints) {
        // Account for buttons and spacing in the available width
        // 2 buttons (28px each) + 2 spacings (4px each) = 64px total
        const buttonsAndSpacing = 64.0;

        // Calculate field width from available space, subtracting button widths.
        // On narrow layouts, allow the field to shrink below the usual minimum
        // to avoid RenderFlex overflow.
        final availableForField = constraints.maxWidth - buttonsAndSpacing;
        final fieldWidth = availableForField.clamp(
          0.0,
          kMaxCompactControlWidth,
        );

        return _buildRow(context, fieldWidth);
      },
    );
  }

  Widget _buildRow(BuildContext context, double fieldWidth) {
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
                  validator: validator,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  onChanged: onChanged,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        _pillBtn(context, '+', enabled ? onInc : () {}),
      ],
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
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: kCardBorderOpacity,
            ),
            width: kBorderWidthThin,
          ),
          foregroundColor: theme.colorScheme.primary,
        ),
        onPressed: enabled ? onTap : null,
        child: Text(
          symbol,
          style: detailCollapsedTitleTextStyle(context)?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: kFontWeightMedium,
          ),
        ),
      ),
    );
  }
}
