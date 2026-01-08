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
const double kIconSizeXXSmall = 12;
const double kIconSizeXSmall = 14;
const double kIconSizeSmall = 16;
const double kIconSizeMedium = 20;
const double kIconSizeLarge = 24;

/// Empty state icon size
const double kEmptyStateIconSize = 48;

/// Card/Container constraints
const double kCardMinHeight = 48;
const double kCardMaxWidth = 800;

/// Home page - mini calendar height.
///
/// Used for the embedded [DoseCalendarWidget] when shown on Home.
const double kHomeMiniCalendarHeight = 420;

/// Detail-card collapsed header padding (Medication Details screen).
///
/// Matches the Reports card header height for consistent collapsed card sizing.
const EdgeInsets kDetailCardCollapsedHeaderPadding = EdgeInsets.symmetric(
  horizontal: kSpacingL,
  vertical: kSpacingS,
);

/// Width reserved at the start of a collapsed detail-card header when showing
/// a reorder drag handle.
const double kDetailCardReorderHandleGutterWidth = kIconSizeMedium + kSpacingS;

/// Tight icon button sizing (avoids default 48px IconButton height).
const BoxConstraints kTightIconButtonConstraints = BoxConstraints.tightFor(
  width: kIconButtonSize,
  height: kIconButtonSize,
);

/// Next-dose date badge sizing (Schedules list)
const double kNextDoseDateCircleSizeCompact = 34;
const double kNextDoseDateCircleSizeLarge = 48;

/// Medication details reports card
const double kMedicationReportsTabHeight = 160;

/// Adherence chart (reports)
const double kAdherenceChartHeight = 96;
const double kAdherenceChartLineStrokeWidth = 2.5;
const double kAdherenceChartGridStrokeWidth = 0.5;
const double kAdherenceChartPointOuterRadius = 4;
const double kAdherenceChartPointInnerRadius = 2;
const double kAdherenceChartValueScale = 0.8;
const double kAdherenceChartVerticalPaddingFraction = 0.1;

/// Taken vs missed chart (reports)
const double kTakenMissedChartHeight = 44;
const double kTakenMissedChartBarSpacing = kSpacingS;
const double kTakenMissedChartBarRadius = 4;

/// Time-of-day histogram (reports)
const double kTimeOfDayHistogramHeight = 36;
const double kTimeOfDayHistogramBarSpacing = 2;
const double kTimeOfDayHistogramBarRadius = 3;

/// Streaks / consistency sparkline (reports)
const double kConsistencySparklineHeight = 24;
const double kConsistencySparklineStrokeWidth = 2.0;
const double kConsistencySparklineVerticalPaddingFraction = 0.2;

/// Dose amount trend (reports)
const double kDoseTrendChartHeight = 36;
const double kDoseTrendChartStrokeWidth = 2.0;
const double kDoseTrendChartPointRadius = 2.5;
const double kDoseTrendChartVerticalPaddingFraction = 0.2;

/// Dose strength history (reports)
const double kDoseStrengthChartHeight = 44;
const double kDoseStrengthChartBarSpacing = 2;
const double kDoseStrengthChartBarRadius = 3;

/// Stock donut gauge sizing
const double kStockDonutGaugeSize = 96;
const double kStockDonutGaugeSizeCompact = 88;
const double kStockDonutGaugeStrokeWidth = 12.0;
const double kDualStockDonutInnerScale = 0.73;
const double kDualStockDonutInnerStrokeWidth = 6.0;

/// White syringe gauge sizing (MDV / reconstitution)
const double kWhiteSyringeGaugeHeight = 56;
const double kWhiteSyringeGaugeBottomLabelPadding = 22;

/// Medication details header gauge sizing
const double kMedicationDetailDonutSize = 112;
const double kMedicationDetailDonutStrokeWidth = 14.0;
const double kMedicationDetailDonutInnerStrokeWidth = 7.0;

/// Medication header text limits
const int kMedicationHeaderDescriptionMaxChars = 90;

/// Calendar component sizing
const double kCalendarDayHeight =
    60; // Height of day cell in month view (reduced from 80)
const double kCalendarHourHeight = 60; // Height of hour row in day view
const double kCalendarDoseBlockHeight = 60; // Default dose block height
const double kCalendarDoseBlockMinHeight = 40; // Minimum when compressed
const double kCalendarDoseIndicatorSize = 6; // Dot indicator diameter
const double kCalendarDoseIndicatorSpacing = 2;
const double kCalendarWeekColumnWidth = 80; // Width of day column in week view
const double kCalendarHeaderHeight = 56; // Calendar header with navigation

/// Bottom sheet sizing
const double kBottomSheetHandleWidth = 40;
const double kBottomSheetHandleHeight = 4;
const double kBottomSheetHandleRadius = 2;
const EdgeInsets kBottomSheetHeaderPadding = EdgeInsets.fromLTRB(
  kSpacingL,
  kSpacingS,
  kSpacingL,
  kSpacingL,
);
const EdgeInsets kBottomSheetContentPadding = EdgeInsets.all(kSpacingL);
const EdgeInsets kBottomSheetHandleMargin = EdgeInsets.symmetric(
  vertical: kSpacingL,
);

/// Month-view day cell styling
const double kCalendarDayNumberSize = 24;
const EdgeInsets kCalendarDayNumberPadding = EdgeInsets.all(kSpacingXS);
const EdgeInsets kCalendarDayDoseIndicatorPadding = EdgeInsets.all(
  kSpacingXS / 2,
);
const double kCalendarDayCellBorderRadius = kBorderRadiusSmall;
const double kCalendarDayOverflowTextOpacity = kOpacityMedium;

/// In the full-screen calendar, allocate a fixed portion of the available
/// height to the selected-day list panel so the calendar grid remains stable
/// across Day/Week/Month views.
const double kCalendarSelectedDayPanelHeightRatio = 0.42;

// ============================================================================
// SPACING CONSTANTS
// ============================================================================

/// Page-level spacing
const EdgeInsets kPagePadding = EdgeInsets.fromLTRB(16, 16, 16, 100);
const EdgeInsets kPagePaddingNoBottom = EdgeInsets.fromLTRB(16, 16, 16, 16);
const double kPageHorizontalPadding = 16;
const double kPageVerticalPadding = 16;

/// Generic spacing scale (apply everywhere before creating new values)
const double kSpacingXXS = 2;
const double kSpacingXS = 4;
const double kSpacingS = 8;
const double kSpacingM = 12;
const double kSpacingL = 16;
const double kSpacingXL = 20;
const double kSpacingXXL = 24;

/// Section/card spacing
const double kSectionSpacing = kSpacingM;
const double kCardPadding = kSpacingM;
const double kCardInnerSpacing = kSpacingS;

/// Compact card spacing
const EdgeInsets kCompactCardPadding = EdgeInsets.all(kSpacingS);

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
const double kBorderRadiusXLarge = 20;
const double kBorderRadiusXXLarge = 24;
const double kBorderRadiusFull = 999; // Pill shape
const double kBorderRadiusChip = 6; // Less rounded for chips
const double kBorderRadiusChipTight = 4; // Even less rounded for small badges

/// Standard border radius for fields, buttons, cards
const Radius kStandardRadius = Radius.circular(kBorderRadiusMedium);
const BorderRadius kStandardBorderRadius = BorderRadius.all(kStandardRadius);

// ============================================================================
// COLOR & OPACITY CONSTANTS
// ============================================================================

/// Text opacity levels - IMPORTANT: Max darkness should result in ~#343434
/// On white background with pure black text: 0.80 opacity ≈ #343434
const double kOpacityFull = 0.80; // Maximum text darkness (#343434)
const double kOpacityHigh = 0.80; // Primary text (same as full)
const double kOpacityMediumHigh = 0.70; // Important secondary text
const double kOpacityMedium = 0.60; // Standard body text
const double kOpacityMediumLow = 0.50; // Helper/support text
const double kOpacityLow = 0.40; // Hint text, disabled states
const double kOpacityVeryLow = 0.30; // Very subtle text
const double kOpacityMinimal = 0.20; // Almost invisible

/// Decorative opacities (for subtle fills/gradients)
const double kOpacityTransparent = 0.0;
const double kOpacityFaint = 0.05;
const double kOpacitySubtleLow = 0.10;
const double kOpacitySubtle = 0.15;
const double kOpacityEmphasis = 0.90;

/// Specific use case opacity
const double kHelperTextOpacity = kOpacityMediumLow;
const double kDisabledOpacity = kOpacityLow;
const double kCardBorderOpacity = kOpacityLow;
const double kHintTextOpacity = kOpacityLow;

/// Reconstitution calculator opacity (white text on dark background)
const double kReconTextHighOpacity = 0.90; // Selected option details
const double kReconTextMediumOpacity = 0.85; // Support text
const double kReconTextNormalOpacity = 0.75; // Unselected labels
const double kReconTextLowOpacity = 0.70; // Unselected details
const double kReconTextMutedOpacity = 0.60; // Explainer text

/// Reconstitution calculator background colors
const Color kReconBackgroundDark = Color(0xFF0A0E27); // Dark blue-black
const Color kReconBackgroundActive = Color(
  0xFF1A1E37,
); // Slightly lighter for active state

/// Theme-aware reconstitution calculator background.
///
/// In light theme, keeps the signature dark-blue look.
/// In dark theme, blends toward the app surface so it feels less harsh and more
/// consistent with the overall dark palette.
Color reconBackgroundDarkColor(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  if (theme.brightness == Brightness.dark) {
    // In dark theme, avoid the blue tint and stay neutral.
    return Color.alphaBlend(
      cs.onSurface.withValues(alpha: kOpacityFaint),
      cs.surface,
    );
  }
  return kReconBackgroundDark;
}

/// Theme-aware active/raised background for reconstitution surfaces.
Color reconBackgroundActiveColor(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  if (theme.brightness == Brightness.dark) {
    // Slightly raised/active surface in dark theme, still neutral.
    return Color.alphaBlend(
      cs.onSurface.withValues(alpha: kOpacitySubtleLow),
      cs.surface,
    );
  }
  return kReconBackgroundActive;
}

/// Theme-aware foreground color for reconstitution calculator surfaces.
///
/// - Light theme: the calculator uses a dark-blue background, so use white.
/// - Dark theme: the calculator background blends toward app surfaces, so use
///   standard onSurface text.
Color reconForegroundColor(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  if (theme.brightness == Brightness.dark) {
    return cs.onSurface;
  }
  return Colors.white;
}

/// Reconstitution divider styling
const double kReconDividerHeight = 1.0;
const double kReconDividerOpacity = 0.7;
const double kReconDividerVerticalMargin = 12.0;
const List<double> kReconDividerStops = [0.0, 0.5, 1.0];

/// Reconstitution summary card styling
const double kReconSummaryBorderWidth = 0.5;
const double kReconSummaryBorderRadius = 20.0;
const EdgeInsets kReconSummaryPadding = EdgeInsets.symmetric(
  horizontal: 12,
  vertical: 12,
);
const double kReconSummaryBlurRadius = 16.0;
const double kReconSummaryShadowSpread = 2.0;
const Offset kReconSummaryShadowOffset = Offset(0, 4);

/// Reconstitution option button styling
const double kReconOptionBorderWidth = 0.5;

/// Reconstitution error colors
const Color kReconErrorBackground = Color(0xFFFF6B35); // Orange-red background
const double kReconErrorOpacity = 0.15;

/// Medication Detail Gradient
const Color kMedicationDetailGradientStart = Color(0xFF09A8BD);
const Color kMedicationDetailGradientEnd = Color(0xFF18537D);

/// Foreground color for the Medication Details header.
///
/// In dark mode, the header background is bright enough that black text/icons
/// are preferred for legibility (per UX request).
Color medicationDetailHeaderForegroundColor(BuildContext context) {
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.dark) {
    return Colors.black;
  }
  return theme.colorScheme.onPrimary;
}

/// Default expiry offset for newly added medications.
///
/// Used when the user hasn't selected an expiry yet.
const int kDefaultMedicationExpiryDays = 90;

/// Expiry status thresholds based on *percentage of shelf-life remaining*.
///
/// - `<= 10%` remaining: critical (red)
/// - `<= 25%` remaining: warning (orange)
const double kExpiryCriticalRemainingRatio = 0.10;
const double kExpiryWarningRemainingRatio = 0.25;

/// Stock status thresholds based on *percentage of stock remaining*.
///
/// - `<= 10%` remaining: critical (red)
/// - `<= 25%` remaining: warning (orange)
const double kStockCriticalRemainingRatio = 0.10;
const double kStockWarningRemainingRatio = 0.25;

/// Returns the fraction of shelf-life remaining in the range 0–1.
///
/// Uses `createdAt → expiry` as the total shelf-life window.
double expiryRemainingRatio({
  required DateTime createdAt,
  required DateTime expiry,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  if (!expiry.isAfter(effectiveNow)) return 0.0;

  final total = expiry.difference(createdAt).inSeconds;
  if (total <= 0) return 0.0;

  final remaining = expiry.difference(effectiveNow).inSeconds;
  return (remaining / total).clamp(0.0, 1.0);
}

/// Semantic expiry color based on percentage remaining.
Color expiryStatusColor(
  BuildContext context, {
  required DateTime createdAt,
  required DateTime expiry,
  DateTime? now,
}) {
  final cs = Theme.of(context).colorScheme;
  final effectiveNow = now ?? DateTime.now();

  if (!expiry.isAfter(effectiveNow)) {
    return cs.error;
  }

  final ratio = expiryRemainingRatio(
    createdAt: createdAt,
    expiry: expiry,
    now: effectiveNow,
  );

  if (ratio <= kExpiryCriticalRemainingRatio) {
    return cs.error;
  }
  if (ratio <= kExpiryWarningRemainingRatio) {
    return cs.secondary;
  }

  return cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh);
}

/// Semantic stock color based on percentage remaining.
///
/// Accepts a ratio in the range 0–1.
Color stockStatusColorFromRatio(BuildContext context, double remainingRatio) {
  final cs = Theme.of(context).colorScheme;
  final ratio = remainingRatio.clamp(0.0, 1.0);

  if (ratio <= 0) return cs.error;
  if (ratio <= kStockCriticalRemainingRatio) return cs.error;
  if (ratio <= kStockWarningRemainingRatio) return cs.secondary;
  return cs.primary;
}

/// Convenience wrapper for stock % remaining.
///
/// Accepts a percentage in the range 0–100.
Color stockStatusColorFromPercentage(
  BuildContext context, {
  required double percentage,
}) {
  final clamped = percentage.clamp(0.0, 100.0);
  return stockStatusColorFromRatio(context, clamped / 100.0);
}

// ============================================================================
// CARD STYLING (Centralized)
// ============================================================================

/// Standard card shadow for all cards on light backgrounds
const double kCardShadowOpacity = 0.08;
const double kCardShadowBlurRadius = 24.0;
const Offset kCardShadowOffset = Offset(0, 8);

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
            color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
            width: kBorderWidthThin,
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

/// Padding used for inset/section surfaces inside larger cards.
const EdgeInsets kInsetSectionPadding = EdgeInsets.all(kSpacingS);

/// Builds a lightweight inset section surface (used inside cards).
///
/// This matches the compact "dialog card" feel used across Medication flows.
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

/// Text scaling guardrails
///
/// These clamp extreme system font scaling so core layouts don't break.
const double kTextScaleFactorMin = 1.0;
const double kTextScaleFactorMax = 1.15;

/// Font sizes
const double kFontSizeXXSmall = 6;
const double kFontSizeXSmall = 9;
const double kFontSizeSmall = 11;
const double kFontSizeMedium = 13;
const double kFontSizeLarge = 15;
const double kFontSizeXLarge = 17;

/// Next-dose date badge typography (Schedules list)
const double kNextDoseDateCircleDayFontSizeCompact = 15;
const double kNextDoseDateCircleDayFontSizeLarge = 18;
const double kNextDoseDateCircleMonthFontSize = kFontSizeSmall;

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
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // In dark mode, slightly lift the field fill above `surface` so fields remain
  // visually distinct from cards/backgrounds.
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
    // Suppress error text to keep field height stable
    errorStyle: suppressError ? const TextStyle(fontSize: 0, height: 0) : null,
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
///
/// IMPORTANT: This MUST match buildFieldDecoration() borders exactly.
InputDecoration buildCompactFieldDecoration({
  BuildContext? context,
  String? hint,
  bool suppressError = true,
}) {
  // If no context provided, return minimal decoration (for backwards compatibility)
  if (context == null) {
    return InputDecoration(
      hintText: hint,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      errorStyle: suppressError
          ? const TextStyle(fontSize: 0, height: 0)
          : null,
    );
  }

  // WITH context: use EXACT same borders as buildFieldDecoration()
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
    errorStyle: suppressError ? const TextStyle(fontSize: 0, height: 0) : null,
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
// TEXT STYLES
// ============================================================================

/// Helper/support text style (used under form fields)
TextStyle? helperTextStyle(BuildContext context, {Color? color}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    color:
        color ??
        Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: kHelperTextOpacity),
  );
}

/// Extra-small helper/support text style.
///
/// Use for secondary lines that should be visually quieter than normal helper
/// text (e.g. compact-card subtitles).
TextStyle? microHelperTextStyle(BuildContext context, {Color? color}) {
  return helperTextStyle(
    context,
    color: color,
  )?.copyWith(fontSize: kFontSizeXSmall, height: kLineHeightTight);
}

/// Checkbox label style
TextStyle? checkboxLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightNormal,
    color: Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: kOpacityMediumHigh),
  );
}

/// Section title style
TextStyle? sectionTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightSemiBold,
    color: Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
  );
}

/// Field label style (in LabelFieldRow)
TextStyle? fieldLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightBold,
    color: Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: kOpacityMedium),
  );
}

/// Input text style (typed text in fields)
TextStyle? inputTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeInput,
    fontWeight: kFontWeightNormal,
    color: Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: kOpacityHigh),
  );
}

/// Hint text style (placeholder in empty fields)
TextStyle? hintTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeHint,
    fontWeight: kFontWeightNormal,
    color: Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: kHintTextOpacity),
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
    color: Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: kOpacityMediumHigh),
  );
}

/// Body text style (general content)
TextStyle? bodyTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightNormal,
    height: kLineHeightNormal,
    color: Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: kOpacityMediumHigh),
  );
}

/// Muted text style (secondary/disabled text)
TextStyle? mutedTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeSmall,
    fontWeight: kFontWeightNormal,
    color: Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: kDisabledOpacity),
  );
}

/// Calendar month-view day number style
TextStyle? calendarDayNumberTextStyle(BuildContext context) {
  return Theme.of(
    context,
  ).textTheme.bodySmall?.copyWith(fontWeight: kFontWeightSemiBold);
}

/// Calendar month-view day count badge style
TextStyle? calendarDayCountBadgeTextStyle(BuildContext context) {
  return Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(fontWeight: kFontWeightBold);
}

/// Calendar month-view overflow text style ("+N")
TextStyle? calendarDayOverflowTextStyle(BuildContext context) {
  return Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(fontWeight: kFontWeightSemiBold);
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
///
/// Set [fullWidth] to true to span the entire card width (no left padding)
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
///
/// Keep this separate from [buildHelperText], which is reserved for helper text
/// under form fields.
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

/// Builds a standardized chip for storage conditions
Widget buildStorageConditionChip(
  BuildContext context, {
  required String label,
  required IconData icon,
  required Color backgroundColor,
}) {
  return Chip(
    avatar: Icon(icon, size: 16),
    label: Text(label, style: const TextStyle(fontSize: 12)),
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
