import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

class FormFieldStyler {
  // 10 visual variants for Add Medication form fields (excluding summary)
  static InputDecoration decoration({
    required BuildContext context,
    required int styleIndex,
    required String label,
    String? hint,
    String? helper,
  }) {
    final theme = Theme.of(context);
    final InputDecoration base = InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      // Global hybrid defaults
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.60),
        fontSize: kHintFontSize,
      ),
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.60),
        fontSize: kHintFontSize,
      ),
    );
    switch (styleIndex) {
      case 0: // Filled tonal
        return base.copyWith(
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        );
      case 1: // Outlined sharp
        return base.copyWith(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        );
      case 2: // Outline minimal (no underlines globally)
        return base.copyWith(border: const OutlineInputBorder());
      case 3: // Elevated card-like
        return base.copyWith(
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      case 4: // Left accent
        return base.copyWith(
          border: const OutlineInputBorder(),
          prefixIcon: Container(
            width: 6,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case 5: // Dense compact (still respect min 40px height)
        return base.copyWith(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        );
      case 6: // Borderless + bottom divider style
        return base.copyWith(border: InputBorder.none);
      case 7: // Chip label above
        return base.copyWith(
          label: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontSize: 12,
              ),
            ),
          ),
          labelStyle: const TextStyle(color: Colors.transparent),
        );
      case 8: // Large stacked label
        return base.copyWith(
          labelStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        );
      default: // Monochrome minimal
        return base.copyWith(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black87),
          ),
        );
    }
  }

  static BoxDecoration sectionDecoration(BuildContext context, int styleIndex) {
    switch (styleIndex) {
      case 0: // filled tonal section
        return BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        );
      case 1: // outlined sharp
        return BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Theme.of(context).dividerColor),
        );
      case 2: // underline minimal
        return const BoxDecoration();
      case 3: // elevated card
        return BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case 4: // left accent
        return BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
        );
      case 5: // dense compact
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        );
      case 6: // borderless + divider
        return const BoxDecoration();
      case 7: // chip header
        return BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        );
      case 8: // large header
        return BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        );
      default: // monochrome minimal
        return BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        );
    }
  }
}
