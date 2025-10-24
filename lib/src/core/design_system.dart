/// ============================================================================
/// DOSIFI V5 - UNIVERSAL DESIGN SYSTEM
/// ============================================================================
///
/// This is the SINGLE SOURCE OF TRUTH for ALL styling in the entire app.
///
/// RULES:
/// 1. NEVER create inline styles in pages/widgets
/// 2. NEVER hardcode sizes, colors, fonts, spacing, opacity
/// 3. ALWAYS use constants and builders from this file
/// 4. ALWAYS import this file when creating UI
///
/// COVERAGE:
/// - Sizing (heights, widths, constraints)
/// - Spacing (padding, margins, gaps)
/// - Typography (fonts, sizes, weights, line heights)
/// - Colors (all semantic colors and opacity levels)
/// - Borders (widths, radius, styles)
/// - Decorations (input fields, containers, cards)
/// - Buttons (all variants with consistent sizing)
/// - Animations (durations, curves)
/// - Alignment (all standard alignments)
///
/// Reference implementation: med_editor_template_demo_page.dart
///
/// ============================================================================

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

// ============================================================================
// SIZING CONSTANTS
// ============================================================================

/// Standard field height (ALL text fields, dropdowns, buttons)
const double kStandardFieldHeight = kFieldHeight; // 36px

/// Compact control width (date buttons, small dropdowns)
const double kCompactControlWidth = 120;
const double kCompactControlMinWidth = 120;
const double kCompactControlMaxWidth = 240;

/// Label column width in label-field rows
const double kLabelColumnWidth = 120;

/// Button sizing
const double kStepperButtonSize = 28; // +/- buttons
const double kIconButtonSize = 24;
const double kStandardButtonHeight = 36;
const double kLargeButtonHeight = 44;

/// Icon sizes
const double kIconSizeSmall = 16;
const double kIconSizeMedium = 20;
const double kIconSizeLarge = 24;

/// Card/Container constraints
const double kCardMinHeight = 48;
const double kCardMaxWidth = 800;

// ============================================================================
// SPACING CONSTANTS
// ============================================================================

/// Page-level spacing
const EdgeInsets kPagePadding = EdgeInsets.fromLTRB(16, 16, 16, 100);
const EdgeInsets kPagePaddingNoBottom = EdgeInsets.fromLTRB(16, 16, 16, 16);
const double kPageHorizontalPadding = 16;
const double kPageVerticalPadding = 16;

/// Section/card spacing
const double kSectionSpacing = 12;
const double kCardPadding = 12;
const double kCardInnerSpacing = 8;

/// Field spacing
const double kFieldSpacing = 6; // Between label-field rows
const double kFieldGroupSpacing = 12; // Between field groups
const double kLabelFieldGap = 8; // Between label and field

/// Helper text spacing
const double kHelperTextLeftPadding = kLabelColumnWidth + kLabelFieldGap;
const double kHelperTextTopPadding = 2;
const double kHelperTextBottomPadding = 6;

/// Button spacing
const double kButtonSpacing = 8;
const double kStepperButtonSpacing = 4; // Between stepper buttons

/// List item spacing
const double kListItemSpacing = 4;
const double kListItemPadding = 8;

/// Content padding (inside fields, buttons)
const EdgeInsets kFieldContentPadding = EdgeInsets.symmetric(
  horizontal: 12,
  vertical: 8,
);
const EdgeInsets kButtonContentPadding = EdgeInsets.symmetric(
  horizontal: 12,
  vertical: 10,
);
const EdgeInsets kCompactButtonPadding = EdgeInsets.zero;

// ============================================================================
// BORDER CONSTANTS
// ============================================================================

/// Border widths
const double kBorderWidthThin = kOutlineWidth; // 0.75px
const double kBorderWidthMedium = 1.0;
const double kBorderWidthThick = kFocusedOutlineWidth; // 2px

/// Border radius
const double kBorderRadiusSmall = 8;
const double kBorderRadiusMedium = 12;
const double kBorderRadiusLarge = 16;
const double kBorderRadiusFull = 999; // Pill shape

/// Standard border radius for fields, buttons, cards
const Radius kStandardRadius = Radius.circular(kBorderRadiusMedium);
const BorderRadius kStandardBorderRadius = BorderRadius.all(kStandardRadius);

// ============================================================================
// COLOR & OPACITY CONSTANTS
// ============================================================================

/// Text opacity levels
const double kOpacityFull = 1.0;
const double kOpacityHigh = 0.87; // Primary text
const double kOpacityMediumHigh = 0.85;
const double kOpacityMedium = 0.75; // Helper text
const double kOpacityMediumLow = 0.60; // Placeholder/hint
const double kOpacityLow = 0.50; // Disabled text
const double kOpacityVeryLow = 0.45; // Very muted
const double kOpacityMinimal = 0.30; // Borders, dividers

/// Specific use case opacity
const double kHelperTextOpacity = kOpacityMedium;
const double kDisabledOpacity = kOpacityLow;
const double kCardBorderOpacity = kOpacityLow;
const double kHintTextOpacity = kOpacityMediumLow;

/// Color helper functions (NEVER use these - use theme colors)
/// These are kept only for backward compatibility during migration
@Deprecated('Use Theme.of(context).colorScheme instead')
Color kTextPrimary(BuildContext c) => Theme.of(c).colorScheme.primary;
@Deprecated('Use Theme.of(context).colorScheme instead')
Color kTextDark(BuildContext c) => Theme.of(c).colorScheme.onSurface;
@Deprecated('Use Theme.of(context).colorScheme instead')
Color kTextError(BuildContext c) => Theme.of(c).colorScheme.error;

// ============================================================================
// TYPOGRAPHY CONSTANTS
// ============================================================================

/// Font sizes
const double kFontSizeSmall = 11;
const double kFontSizeMedium = 13;
const double kFontSizeLarge = 15;
const double kFontSizeXLarge = 17;

/// Specific component font sizes
const double kFontSizeInput = kInputFontSize; // 13
const double kFontSizeHint = kHintFontSize; // 10.5
const double kFontSizeHelper = kFontSizeSmall; // 11
const double kFontSizeLabel = kFontSizeMedium; // 13
const double kFontSizeTitle = kFontSizeLarge; // 15

/// Font weights
const FontWeight kFontWeightLight = FontWeight.w300;
const FontWeight kFontWeightNormal = FontWeight.w400;
const FontWeight kFontWeightMedium = FontWeight.w500;
const FontWeight kFontWeightSemiBold = FontWeight.w600;
const FontWeight kFontWeightBold = FontWeight.w700;
const FontWeight kFontWeightExtraBold = FontWeight.w800;

/// Line heights
const double kLineHeightTight = 1.2;
const double kLineHeightNormal = 1.4;
const double kLineHeightRelaxed = 1.6;

// ============================================================================
// ANIMATION CONSTANTS
// ============================================================================

/// Animation durations
const Duration kAnimationFast = Duration(milliseconds: 150);
const Duration kAnimationNormal = Duration(milliseconds: 250);
const Duration kAnimationSlow = Duration(milliseconds: 350);
const Duration kAnimationVerySlow = Duration(milliseconds: 500);

/// Animation curves
const Curve kCurveDefault = Curves.easeInOut;
const Curve kCurveEmphasized = Curves.easeInOutCubic;
const Curve kCurveSnappy = Curves.easeOut;

// ============================================================================
// ELEVATION & SHADOW CONSTANTS
// ============================================================================

const double kElevationNone = 0;
const double kElevationLow = 2;
const double kElevationMedium = 4;
const double kElevationHigh = 8;

// ============================================================================
// ALIGNMENT CONSTANTS
// ============================================================================

const Alignment kAlignTopLeft = Alignment.topLeft;
const Alignment kAlignTopCenter = Alignment.topCenter;
const Alignment kAlignTopRight = Alignment.topRight;
const Alignment kAlignCenterLeft = Alignment.centerLeft;
const Alignment kAlignCenter = Alignment.center;
const Alignment kAlignCenterRight = Alignment.centerRight;
const Alignment kAlignBottomLeft = Alignment.bottomLeft;
const Alignment kAlignBottomCenter = Alignment.bottomCenter;
const Alignment kAlignBottomRight = Alignment.bottomRight;

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
    color:
        color ??
        Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withOpacity(kHelperTextOpacity),
  );
}

/// Checkbox label style
TextStyle? checkboxLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightNormal,
    color: Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withOpacity(kOpacityMediumHigh),
  );
}

/// Section title style
TextStyle? sectionTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    fontSize: kFontSizeLarge,
    fontWeight: kFontWeightBold,
    color: Theme.of(context).colorScheme.primary,
  );
}

/// Field label style (in LabelFieldRow)
TextStyle? fieldLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightBold,
    color: Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withOpacity(kOpacityMedium),
  );
}

/// Input text style (typed text in fields)
TextStyle? inputTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeInput,
    fontWeight: kFontWeightNormal,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(kOpacityHigh),
  );
}

/// Hint text style (placeholder in empty fields)
TextStyle? hintTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeHint,
    fontWeight: kFontWeightNormal,
    color: Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withOpacity(kHintTextOpacity),
  );
}

/// Button text style (text in buttons)
TextStyle? buttonTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightMedium,
  );
}

/// Card title style
TextStyle? cardTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall?.copyWith(
    fontSize: kFontSizeLarge,
    fontWeight: kFontWeightSemiBold,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(kOpacityHigh),
  );
}

/// Body text style (general content)
TextStyle? bodyTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightNormal,
    height: kLineHeightNormal,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(kOpacityHigh),
  );
}

/// Muted text style (secondary/disabled text)
TextStyle? mutedTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeSmall,
    fontWeight: kFontWeightNormal,
    color: Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withOpacity(kDisabledOpacity),
  );
}

/// Error text style
TextStyle? errorTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    fontSize: kFontSizeSmall,
    fontWeight: kFontWeightMedium,
    color: Theme.of(context).colorScheme.error,
  );
}

/// Warning text style
TextStyle? warningTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    fontSize: kFontSizeSmall,
    fontWeight: kFontWeightMedium,
    color: Colors.orange,
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
