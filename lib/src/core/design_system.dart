/// Design System - Dosifi v5
///
/// This file defines ALL UI styling standards for the entire app.
/// Every screen MUST use these constants and helpers to ensure consistency.
///
/// DO NOT create custom styling in individual pages - use these helpers instead.
///
/// Reference implementation: med_editor_template_demo_page.dart

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

// ============================================================================
// SPACING & SIZING CONSTANTS
// ============================================================================

/// Standard padding around page content
const EdgeInsets kPagePadding = EdgeInsets.fromLTRB(16, 16, 16, 100);

/// Spacing between sections
const double kSectionSpacing = 12;

/// Spacing between form rows
const double kRowSpacing = 0; // Handled by LabelFieldRow

/// Helper text left padding (aligns with field start after label)
const double kHelperTextLeftPadding = kLabelColWidth + 8;

/// Helper text top padding
const double kHelperTextTopPadding = 2;

/// Helper text bottom padding
const double kHelperTextBottomPadding = 6;

// ============================================================================
// COLOR & OPACITY CONSTANTS
// ============================================================================

/// Helper text opacity
const double kHelperTextOpacity = 0.75;

/// Disabled field opacity
const double kDisabledOpacity = 0.5;

/// Section card border opacity
const double kCardBorderOpacity = 0.5;

// ============================================================================
// FIELD DECORATION BUILDER
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
    // Suppress error text to keep field height stable
    errorStyle: suppressError ? const TextStyle(fontSize: 0, height: 0) : null,
    filled: true,
    fillColor: cs.surfaceContainerLowest,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: cs.outlineVariant.withOpacity(kCardBorderOpacity),
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
  String? hint,
  bool suppressError = true,
}) {
  return InputDecoration(
    hintText: hint,
    isDense: false,
    isCollapsed: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    constraints: const BoxConstraints(minHeight: kFieldHeight),
    errorStyle: suppressError ? const TextStyle(fontSize: 0, height: 0) : null,
  );
}

// ============================================================================
// TEXT STYLES
// ============================================================================

/// Helper/support text style (used under form fields)
TextStyle? helperTextStyle(BuildContext context, {Color? color}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color ??
            Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(kHelperTextOpacity),
      );
}

/// Checkbox label style
TextStyle? checkboxLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium;
}

/// Section title style
TextStyle? sectionTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      );
}

/// Field label style (in LabelFieldRow)
TextStyle? fieldLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

/// Standard helper text widget positioned correctly under form fields.
///
/// Use this for all helper/support text under fields.
///
/// Example:
/// ```dart
/// LabelFieldRow(label: 'Name', field: nameField),
/// buildHelperText(context, 'Enter your full name'),
/// ```
Widget buildHelperText(BuildContext context, String? text, {Color? color}) {
  if (text == null || text.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(
      left: kHelperTextLeftPadding,
      top: kHelperTextTopPadding,
      bottom: kHelperTextBottomPadding,
    ),
    child: Text(text, style: helperTextStyle(context, color: color)),
  );
}

/// Section spacing widget
Widget get sectionSpacing => const SizedBox(height: kSectionSpacing);

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

/// Standard validators for common field types

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
  int? min,
  int? max,
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
///
/// ## Common Mistakes to Avoid
/// - ❌ Creating custom InputDecoration in pages
/// - ❌ Hardcoding padding values
/// - ❌ Using raw Colors instead of theme colors
/// - ❌ Custom TextStyle without theme base
/// - ❌ Inconsistent spacing between sections
/// - ❌ Not using Field36 wrapper
/// - ❌ Not using helper functions for text styles
///
/// ## Migration Checklist
/// When updating an existing page:
/// 1. [ ] Replace all custom InputDecoration with buildFieldDecoration()
/// 2. [ ] Wrap all text fields in Field36
/// 3. [ ] Use LabelFieldRow for all label + field pairs
/// 4. [ ] Replace all helper text with buildHelperText()
/// 5. [ ] Use sectionSpacing between sections
/// 6. [ ] Apply kPagePadding to scroll view
/// 7. [ ] Use compact controls (SmallDropdown36, DateButton36, StepperRow36)
/// 8. [ ] Remove all hardcoded styling constants
