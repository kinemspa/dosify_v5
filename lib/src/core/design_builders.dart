/// ============================================================================
/// DESIGN BUILDERS — BOX DECORATIONS, INPUT DECORATIONS, HELPER WIDGETS
/// ============================================================================
///
/// All builder functions that return decorations, and shared helper widgets
/// and validation functions.
///
/// Import this file directly, or just import `design_system.dart` (which
/// re-exports everything).
/// ============================================================================

// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/core/design_tokens_opacity.dart';
import 'package:dosifi_v5/src/core/design_tokens_radius.dart';
import 'package:dosifi_v5/src/core/design_tokens_spacing.dart';
import 'package:dosifi_v5/src/core/design_tokens_typography.dart';

// ============================================================================
// CARD DECORATION BUILDERS
// ============================================================================

/// How much to blend a status color toward `onPrimary` when rendering it
/// on top of strong primary/gradient headers.
///
/// 0.0 = raw status color, 1.0 = pure onPrimary.
const double kOnPrimaryStatusColorBlendT = 0.35;

/// Returns a status color adjusted for readability on top of a primary header
/// background (e.g. Medication Details gradient).
Color statusColorOnPrimary(BuildContext context, Color statusColor) {
  final cs = Theme.of(context).colorScheme;
  return Color.lerp(statusColor, cs.onPrimary, kOnPrimaryStatusColorBlendT) ??
      statusColor;
}

/// Builds a standard card decoration with consistent styling across the app.
/// Use this for all cards displayed on light backgrounds.
BoxDecoration buildStandardCardDecoration({
  required BuildContext context,
  bool useGradient = false,
  bool showBorder = true,
  double borderRadius = kBorderRadiusLarge,
}) {
  final cs = Theme.of(context).colorScheme;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(borderRadius),
    color: useGradient ? null : cs.surface,
    gradient: useGradient
        ? LinearGradient(
            colors: [
              cs.surface.withValues(alpha: 0.92),
              cs.primary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null,
    border: showBorder
        ? Border.all(
            color: cs.outlineVariant.withValues(alpha: kStandardCardBorderOpacity),
            width: kBorderWidthMedium,
          )
        : null,
    boxShadow: [
      BoxShadow(
        color: cs.shadow.withValues(alpha: kCardShadowOpacity),
        blurRadius: kCardShadowBlurRadius,
        offset: kCardShadowOffset,
      ),
    ],
  );
}

/// Dose card styling for light background separation.
BoxDecoration buildDoseCardDecoration({
  required BuildContext context,
  required double borderRadius,
}) {
  return buildStandardCardDecoration(
    context: context,
    useGradient: false,
    showBorder: true,
    borderRadius: borderRadius,
  ).copyWith(
    boxShadow: [
      BoxShadow(
        color: Theme.of(
          context,
        ).colorScheme.shadow.withValues(alpha: kDoseCardShadowOpacity),
        blurRadius: kDoseCardShadowBlurRadius,
        offset: kDoseCardShadowOffset,
      ),
    ],
  );
}

/// Builds a lightweight inset section surface (used inside cards).
BoxDecoration buildInsetSectionDecoration({
  required BuildContext context,
  double borderRadius = kBorderRadiusMedium,
  double backgroundOpacity = 1.0,
  bool showBorder = true,
}) {
  final cs = Theme.of(context).colorScheme;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(borderRadius),
    color: cs.surface.withValues(alpha: backgroundOpacity),
    border: showBorder
        ? Border.all(
            color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
            width: kBorderWidthThin,
          )
        : null,
  );
}

/// Color helper functions (NEVER use these - use theme colors)
/// These are kept only for backward compatibility during migration.
@Deprecated('Use Theme.of(context).colorScheme instead')
Color kTextPrimary(BuildContext c) => Theme.of(c).colorScheme.primary;
@Deprecated('Use Theme.of(context).colorScheme instead')
Color kTextDark(BuildContext c) => Theme.of(c).colorScheme.onSurface;
@Deprecated('Use Theme.of(context).colorScheme instead')
Color kTextError(BuildContext c) => Theme.of(c).colorScheme.error;

// ============================================================================
// PAGE / SHEET PADDING BUILDERS
// ============================================================================

/// Standard padding for bottom sheets that should respect the on-screen keyboard.
EdgeInsets buildBottomSheetPagePadding(BuildContext context) {
  final bottomInset = MediaQuery.of(context).viewInsets.bottom;
  return EdgeInsets.fromLTRB(
    kSpacingL,
    kSpacingL,
    kSpacingL,
    kSpacingL + bottomInset,
  );
}

// ============================================================================
// FIELD DECORATION BUILDERS
// ============================================================================

/// Standard input decoration for ALL text fields in the app.
///
/// This is the single source of truth for field styling.
/// Use this instead of creating custom InputDecoration in pages.
///
/// Example:
/// ```dart
/// TextField(
///   decoration: buildFieldDecoration(context, hint: 'Enter name'),
/// )
/// ```
InputDecoration buildFieldDecoration(
  BuildContext context, {
  String? hint,
  String? label,
  Widget? suffixIcon,
  Widget? prefixIcon,
  bool suppressError = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final fill = isDark
      ? Color.alphaBlend(
          cs.onSurface.withValues(alpha: kOpacitySubtleLow),
          cs.surface,
        )
      : cs.surface;
  return InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.never,
    isDense: false,
    isCollapsed: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    constraints: const BoxConstraints(minHeight: kFieldHeight),
    hintText: hint,
    labelText: label,
    suffixIcon: suffixIcon,
    prefixIcon: prefixIcon,
    errorStyle: suppressError
        ? const TextStyle(fontSize: kFontSizeZero, height: 0)
        : null,
    filled: true,
    fillColor: fill,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        width: kOutlineWidth,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: kFocusedOutlineWidth),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
    ),
  );
}

/// Simplified field decoration for compact controls (steppers, dropdowns)
/// Used inside StepperRow36, SmallDropdown36, etc.
InputDecoration buildCompactFieldDecoration({
  BuildContext? context,
  String? hint,
  bool suppressError = true,
}) {
  if (context == null) {
    return InputDecoration(
      hintText: hint,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      errorStyle: suppressError
          ? const TextStyle(fontSize: kFontSizeZero, height: 0)
          : null,
    );
  }

  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final fill = isDark
      ? Color.alphaBlend(
          cs.onSurface.withValues(alpha: kOpacitySubtleLow),
          cs.surface,
        )
      : cs.surface;
  return InputDecoration(
    hintText: hint,
    isDense: false,
    isCollapsed: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    constraints: const BoxConstraints(minHeight: kFieldHeight),
    errorStyle: suppressError
        ? const TextStyle(fontSize: kFontSizeZero, height: 0)
        : null,
    filled: true,
    fillColor: fill,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        width: kOutlineWidth,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: kFocusedOutlineWidth),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
    ),
  );
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

/// Standard helper text widget positioned correctly under form fields.
///
/// Set [fullWidth] to true to span the entire card width (no left padding).
Widget buildHelperText(
  BuildContext context,
  String? text, {
  Color? color,
  bool fullWidth = false,
}) {
  if (text == null || text.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: EdgeInsets.only(
      left: fullWidth ? 0 : kHelperTextLeftPadding,
      top: kHelperTextTopPadding,
      bottom: kHelperTextBottomPadding,
    ),
    child: Text(text, style: helperTextStyle(context, color: color)),
  );
}

/// Helper/support text used under section headers inside cards.
Widget buildSectionHelperText(BuildContext context, String? text) {
  if (text == null || text.isEmpty) return const SizedBox.shrink();
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.fromLTRB(kSpacingL, 0, kSpacingL, kSpacingS),
    child: Text(
      text,
      style: helperTextStyle(
        context,
        color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
      ),
    ),
  );
}

/// Builds a standardized chip for storage conditions.
Widget buildStorageConditionChip(
  BuildContext context, {
  required String label,
  required IconData icon,
  required Color backgroundColor,
}) {
  return Chip(
    avatar: Icon(icon, size: 16),
    label: Text(
      label,
      style: smallHelperTextStyle(
        context,
      )?.copyWith(fontSize: kFontSizeSmallPlus),
    ),
    visualDensity: VisualDensity.compact,
    backgroundColor: backgroundColor,
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

/// Section spacing widget
Widget get sectionSpacing => const SizedBox(height: kSectionSpacing);

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

/// Standard validators for common field types.

String? validateRequired(String? value, {String fieldName = 'This field'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

String? validateNumeric(
  String? value, {
  String fieldName = 'This field',
  double? min,
  double? max,
}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  final number = double.tryParse(value);
  if (number == null) {
    return '$fieldName must be a number';
  }
  if (min != null && number < min) {
    return '$fieldName must be at least $min';
  }
  if (max != null && number > max) {
    return '$fieldName must be at most $max';
  }
  return null;
}

String? validateInteger(
  String? value, {
  String fieldName = 'This field',
  double? min,
  double? max,
}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  final number = int.tryParse(value);
  if (number == null) {
    return '$fieldName must be a whole number';
  }
  if (min != null && number < min) {
    return '$fieldName must be at least $min';
  }
  if (max != null && number > max) {
    return '$fieldName must be at most $max';
  }
  return null;
}

// ============================================================================
// DESIGN SYSTEM DOCUMENTATION
// ============================================================================

/// # Design System Rules
///
/// ## Page Structure
/// 1. Use Stack with SingleChildScrollView for floating summary cards
/// 2. Apply kPagePadding to scroll view
/// 3. Add spacing equal to summary height + 10 at top
/// 4. Use SectionFormCard for all form sections
/// 5. Add kSectionSpacing between sections
///
/// ## Form Fields
/// 1. **ALL** fields MUST use buildFieldDecoration() for decoration
/// 2. Use Field36 wrapper for standard text fields
/// 3. Use StepperRow36 for numeric inputs
/// 4. Use SmallDropdown36 for dropdowns (kSmallControlWidth)
/// 5. Use DateButton36 for date pickers
/// 6. Use LabelFieldRow for label + field layout
///
/// ## Helper Text
/// 1. **ALL** helper text MUST use buildHelperText()
/// 2. Place helper text immediately after the field's LabelFieldRow
/// 3. Never use custom padding for helper text
///
/// ## Colors & Opacity
/// 1. Use theme colors only (no hardcoded colors)
/// 2. Use defined opacity constants (kHelperTextOpacity, etc.)
/// 3. For disabled states, use kDisabledOpacity
///
/// ## Typography
/// 1. Use helper functions: helperTextStyle(), checkboxLabelStyle(), etc.
/// 2. Never create TextStyle with hardcoded values
/// 3. Always use Theme.of(context).textTheme as base
///
/// ## Spacing
/// 1. Section spacing: kSectionSpacing (12px)
/// 2. Row spacing: handled by LabelFieldRow (0px)
/// 3. Helper text: use kHelperText* constants
/// 4. Page padding: kPagePadding
///
/// ## Reference Implementation
/// See: lib/src/features/medications/presentation/med_editor_template_demo_page.dart
