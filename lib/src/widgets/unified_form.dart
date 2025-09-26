import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

/// Unified form building blocks to guarantee identical look & feel across screens.
///
/// Use these instead of ad-hoc rows/containers to match Tablet/Capsule styling
/// for labels, fonts, colors, paddings, and control sizing.

/// Default label column width used in left-label layouts (matches Tablet/Capsule)
const double kLabelColWidth = 120.0;

/// A section card with identical decoration to the Tablet/Capsule screens.
class SectionFormCard extends StatelessWidget {
  const SectionFormCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.06)),
        boxShadow: [
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
  const DateButton36({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kFieldHeight,
      width: 120,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_today, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(minimumSize: const Size(120, kFieldHeight)),
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
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: kFieldHeight,
      width: 120,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: false,
        alignment: AlignmentDirectional.center,
        style: theme.textTheme.bodyMedium,
        items: items,
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
        decoration: decoration ?? const InputDecoration(isDense: true),
        menuMaxHeight: 320,
      ),
    );
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
          width: 120,
          child: Field36(
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              decoration: decoration,
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
        child: Text(symbol, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14)),
      ),
    );
  }
}
