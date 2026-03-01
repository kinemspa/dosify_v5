/// ============================================================================
/// DESIGN TOKENS — TYPOGRAPHY, ANIMATION, ELEVATION, TEXT STYLES
/// ============================================================================
///
/// All font-size constants, font-weight constants, line-height constants,
/// animation durations/curves, elevation values, alignment aliases, and
/// TextStyle helper functions.
///
/// Import this file directly, or just import `design_system.dart` (which
/// re-exports everything).
/// ============================================================================

// Dart imports:
import 'dart:ui' show lerpDouble;

// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/core/design_tokens_opacity.dart';
import 'package:dosifi_v5/src/core/design_tokens_spacing.dart';

// ============================================================================
// TYPOGRAPHY CONSTANTS
// ============================================================================

/// Text scaling guardrails
///
/// These clamp extreme system font scaling so core layouts don't break.
const double kTextScaleFactorMin = 1.0;
const double kTextScaleFactorMax = 1.15;

/// Font sizes
const double kFontSizeZero = 0;
const double kFontSizeXXSmall = 6;
const double kFontSizeTiny = 8;
const double kFontSizeXSmall = 9;
const double kFontSizeCaption = 10;
const double kFontSizeSmall = 11;
const double kFontSizeSmallPlus = 12;
const double kFontSizeMedium = 13;
const double kFontSizeLarge = 15;
const double kFontSizeXLarge = 17;

// Detail header typography
const double kFontSizeDetailCollapsedTitle = 16;
const double kFontSizeDetailHeaderTitle = 24;

/// Home page hero title font size (slightly smaller than detail headers).
const double kFontSizeHomeHeroTitle = 11;

/// Medication detail header typography
const double kMedicationDetailHeaderNameExpandedFontSize = 22;
const double kMedicationDetailHeaderNameCollapsedFontSize =
    kFontSizeXLarge; // 17
const double kMedicationDetailFormChipFontSize = 10;
const double kMedicationDetailHeaderTileLabelFontSize = 10;
const double kMedicationDetailHeaderTileValueFontSize = 12;
const double kMedicationDetailToggleTextFontSize = 12;
const double kMedicationDetailSyringeLabelFontSize = 11;

/// Medication detail stock forecast typography
const double kMedicationDetailStockForecastLabelFontSize = 10;
const double kMedicationDetailStockForecastSubLabelFontSize =
    kFontSizeXSmall; // 9
const double kMedicationDetailStockForecastDateFontSize = 14;
const double kMedicationDetailStockForecastDaysFontSize = 12;
const double kMedicationDetailStockForecastExpiryFontSize = 10;

/// Next-dose date badge typography (Schedules list)
const double kNextDoseDateCircleDayFontSizeCompact = 16;
const double kNextDoseDateCircleDayFontSizeLarge = 18;
const double kNextDoseDateCircleMonthFontSize = kFontSizeSmall;

/// Specific component font sizes
const double kFontSizeInput = kInputFontSize; // 13
const double kFontSizeHint = kHintFontSize; // 10.5
const double kFontSizeHelper = kFontSizeSmall; // 11
const double kFontSizeLabel = kFontSizeMedium; // 13
const double kFontSizeTitle = kFontSizeLarge; // 15

/// Wizard typography
const double kWizardHeaderTitleFontSize = 20;
const double kWizardStepNumberFontSize = 10;

/// Font weights
const FontWeight kFontWeightLight = FontWeight.w300;
const FontWeight kFontWeightNormal = FontWeight.w400;
const FontWeight kFontWeightMedium = FontWeight.w500;
const FontWeight kFontWeightSemiBold = FontWeight.w600;
const FontWeight kFontWeightBold = FontWeight.w700;
const FontWeight kFontWeightExtraBold = FontWeight.w800;
const FontWeight kFontWeightBlack = FontWeight.w900;

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

/// Default duration for app snackbars (top-of-screen toasts).
const Duration kAppSnackBarDuration = Duration(seconds: 3);

/// Short duration for brief instructional snackbars.
const Duration kAppSnackBarDurationShort = Duration(seconds: 2);

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
// RECONSTITUTION SUMMARY TYPOGRAPHY
// ============================================================================

const double kReconSummaryStrengthValueFontSizeCompact = 16;
const double kReconSummaryStrengthValueFontSize = 20;
const double kReconSummaryNameFontSizeCompact = 14;
const double kReconSummaryNameFontSize = 18;
const double kReconSummaryMetaFontSizeCompact = 11;
const double kReconSummaryMetaFontSize = 13;
const double kReconSummaryOfFontSizeCompact = 12;
const double kReconSummaryOfFontSize = 14;
const double kReconSummaryTotalVolumeFontSizeCompact = 18;
const double kReconSummaryTotalVolumeFontSize = 22;
const double kReconSummaryValueFontSizeCompact = 14;
const double kReconSummaryValueFontSize = 18;
const double kReconSummarySyringeLineFontSize = 11;
const double kReconSummaryVolumeHugeFontSize = 32;
const double kReconSummaryDrawUnitsFontSize = 22;
const double kReconCalculatorOptionTitleFontSize = 16;

/// White syringe gauge tick label font sizes.
const double kSyringeGaugeTickFontSizeMajor = 10;
const double kSyringeGaugeTickFontSizeMinor = kFontSizeXSmall; // 9
const double kSyringeGaugeTickFontSizeMicro = 7;

// ============================================================================
// THEME-AWARE COLOR HELPERS (used by text styles below)
// ============================================================================

/// Theme-aware snackbar background: white in light mode, elevated dark surface in dark.
Color snackBarBackgroundColor(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  if (Theme.of(context).brightness == Brightness.dark) {
    return cs.surfaceContainerHigh;
  }
  return Colors.white;
}

/// Theme-aware snackbar foreground: dark in light mode, light in dark.
Color snackBarForegroundColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface;
}

/// Muted icon color (e.g. inactive toolbar icons).
Color mutedIconColor(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return cs.onSurfaceVariant.withValues(alpha: kOpacityLow);
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
TextStyle? microHelperTextStyle(BuildContext context, {Color? color}) {
  return helperTextStyle(
    context,
    color: color,
  )?.copyWith(fontSize: kFontSizeXSmall, height: kLineHeightTight);
}

/// Small helper/support text style.
TextStyle? smallHelperTextStyle(BuildContext context, {Color? color}) {
  return helperTextStyle(
    context,
    color: color,
  )?.copyWith(fontSize: kFontSizeSmall, height: kLineHeightTight);
}

/// Hint-sized helper/support text style.
TextStyle? hintLabelTextStyle(BuildContext context, {Color? color}) {
  return helperTextStyle(
    context,
    color: color,
  )?.copyWith(fontSize: kFontSizeHint, height: kLineHeightTight);
}

TextStyle? nextDoseBadgeTodayTextStyle(
  BuildContext context, {
  required bool dense,
  required Color color,
}) {
  return bodyTextStyle(context)?.copyWith(
    fontSize: kFontSizeXSmall,
    fontWeight: kFontWeightExtraBold,
    height: 1,
    color: color,
  );
}

TextStyle? nextDoseBadgeDayTextStyle(
  BuildContext context, {
  required bool dense,
  required Color color,
}) {
  return bodyTextStyle(context)?.copyWith(
    fontSize: dense
        ? kNextDoseDateCircleDayFontSizeCompact
        : kNextDoseDateCircleDayFontSizeLarge,
    fontWeight: kFontWeightExtraBold,
    height: 1,
    color: color,
  );
}

TextStyle? nextDoseBadgeMonthTextStyle(
  BuildContext context, {
  required bool dense,
  required Color color,
}) {
  return bodyTextStyle(context)?.copyWith(
    fontSize: dense ? kFontSizeXSmall : kNextDoseDateCircleMonthFontSize,
    fontWeight: kFontWeightSemiBold,
    height: 1,
    color: color,
  );
}

TextStyle? nextDoseBadgeNextTagTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return bodyTextStyle(context)?.copyWith(
    fontSize: kFontSizeXXSmall,
    fontWeight: kFontWeightExtraBold,
    height: 1,
    color: color,
  );
}

TextStyle? nextDoseBadgeTimeTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return helperTextStyle(
    context,
    color: color,
  )?.copyWith(fontSize: kFontSizeXSmall, fontWeight: kFontWeightBold);
}

TextStyle? stockDonutPrimaryLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.titleLarge?.copyWith(
    fontWeight: kFontWeightExtraBold,
    color: color,
  );
}

TextStyle? stockDonutSecondaryLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return helperTextStyle(
    context,
    color: color,
  )?.copyWith(fontSize: kFontSizeXXSmall, height: 1.0);
}

/// Dose-card leading time label style.
TextStyle? doseCardTimeTextStyle(BuildContext context, {required Color color}) {
  return helperTextStyle(context, color: color)?.copyWith(
    fontSize: kFontSizeXSmall,
    fontWeight: kFontWeightBold,
    height: kLineHeightTight,
  );
}

/// Dose-card primary title style (med name).
TextStyle? doseCardPrimaryTitleTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return cardTitleStyle(context)?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightSemiBold,
    height: kLineHeightTight,
    color: color,
  );
}

/// Dose-card secondary title style (schedule/dose name).
TextStyle? doseCardSecondaryTitleTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return bodyTextStyle(context)?.copyWith(
    fontSize: kFontSizeSmall,
    fontWeight: kFontWeightSemiBold,
    height: kLineHeightTight,
    color: color,
  );
}

/// Dose-card leading dose-number label style.
TextStyle? doseCardDoseNumberTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return helperTextStyle(
    context,
    color: color,
  )?.copyWith(fontSize: kFontSizeXXSmall, height: kLineHeightTight);
}

/// Dose-card status-chip label style.
TextStyle? doseCardStatusChipLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return helperTextStyle(context, color: color)?.copyWith(
    fontSize: kFontSizeXSmall,
    fontWeight: kFontWeightBold,
    height: kLineHeightTight,
  );
}

/// Dose-card "Take ..." metrics line style.
TextStyle? doseCardTakeMetricsTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return bodyTextStyle(context)?.copyWith(
    color: color,
    fontWeight: kFontWeightSemiBold,
    fontSize: kFontSizeXSmall,
  );
}

/// Centralized DoseCard content padding.
EdgeInsets doseCardContentPadding({required bool compact}) {
  return EdgeInsets.symmetric(
    horizontal: compact ? kSpacingL : kSpacingXL,
    vertical: compact ? kSpacingXS : kSpacingS,
  );
}

double doseCardColumnGap({required bool compact}) {
  return compact ? kSpacingS : (kSpacingM - kSpacingXXS);
}

// ============================================================================
// SPECIALIZED TYPOGRAPHY
// ============================================================================

TextStyle? syringeGaugeTickLabelTextStyle(
  BuildContext context, {
  required Color color,
  required double fontSize,
}) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    fontSize: fontSize,
    height: kLineHeightTight,
    fontWeight: kFontWeightSemiBold,
    color: color,
  );
}

TextStyle? syringeGaugeMajorTickLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return syringeGaugeTickLabelTextStyle(
    context,
    color: color,
    fontSize: kSyringeGaugeTickFontSizeMajor,
  );
}

TextStyle? syringeGaugeMinorTickLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return syringeGaugeTickLabelTextStyle(
    context,
    color: color,
    fontSize: kSyringeGaugeTickFontSizeMinor,
  );
}

TextStyle? syringeGaugeMicroTickLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return syringeGaugeTickLabelTextStyle(
    context,
    color: color,
    fontSize: kSyringeGaugeTickFontSizeMicro,
  );
}

TextStyle? syringeGaugeSmallTickLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return syringeGaugeTickLabelTextStyle(
    context,
    color: color,
    fontSize: kFontSizeXSmall,
  );
}

TextStyle? scheduleStatusBadgeTextStyle(
  BuildContext context, {
  required bool dense,
  required Color color,
}) {
  return helperTextStyle(context, color: color)?.copyWith(
    fontSize: dense ? kFontSizeXXSmall : kFontSizeXSmall,
    fontWeight: kFontWeightMedium,
    height: kLineHeightTight,
  );
}

TextStyle? syringeGaugeValueLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    fontSize: kFontSizeSmall,
    height: kLineHeightTight,
    fontWeight: kFontWeightBold,
    color: color,
  );
}

TextStyle? headerMetaLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    fontSize: kFontSizeXSmall,
    fontWeight: kFontWeightMedium,
    letterSpacing: 0.5,
    height: kLineHeightTight,
    color: color,
  );
}

TextStyle? headerTinyLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    fontSize: kFontSizeTiny,
    fontWeight: kFontWeightMedium,
    letterSpacing: 0.0,
    height: kLineHeightTight,
    color: color,
  );
}

TextStyle? headerValueTextStyle(
  BuildContext context, {
  required Color color,
  double fontSize = kFontSizeMedium,
}) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: color,
    fontWeight: kFontWeightSemiBold,
    fontSize: fontSize,
    letterSpacing: 0.1,
    height: 1.1,
  );
}

TextStyle? headerValueSmallTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return headerValueTextStyle(context, color: color, fontSize: kFontSizeSmall);
}

TextStyle? medicationDetailFormChipTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    color: color,
    fontSize: kMedicationDetailFormChipFontSize,
    fontWeight: kFontWeightSemiBold,
    height: kLineHeightTight,
  );
}

TextStyle? medicationDetailHeaderNameTextStyle(
  BuildContext context, {
  required Color color,
  required double t,
}) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    color: color,
    fontSize: lerpDouble(
      kMedicationDetailHeaderNameExpandedFontSize,
      kMedicationDetailHeaderNameCollapsedFontSize,
      t,
    ),
    fontWeight: kFontWeightSemiBold,
  );
}

TextStyle? medicationDetailCollapsedTitleTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    color: color,
    fontSize: kFontSizeXLarge,
    fontWeight: kFontWeightSemiBold,
  );
}

TextStyle? medicationDetailHeaderTileLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    color: color,
    fontSize: kMedicationDetailHeaderTileLabelFontSize,
    fontWeight: kFontWeightNormal,
    height: kLineHeightTight,
  );
}

TextStyle? medicationDetailHeaderTileValueTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    color: color,
    fontSize: kMedicationDetailHeaderTileValueFontSize,
    fontWeight: kFontWeightBold,
    height: kLineHeightTight,
  );
}

TextStyle? medicationDetailToggleTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    color: color,
    fontSize: kMedicationDetailToggleTextFontSize,
    fontWeight: kFontWeightMedium,
    height: kLineHeightTight,
  );
}

TextStyle? medicationDetailSyringeLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    color: color,
    fontSize: kMedicationDetailSyringeLabelFontSize,
    fontWeight: kFontWeightBold,
    height: kLineHeightTight,
  );
}

TextStyle? medicationDetailStockForecastLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    color: color,
    fontSize: kMedicationDetailStockForecastLabelFontSize,
    fontWeight: kFontWeightNormal,
    height: kLineHeightTight,
  );
}

TextStyle? medicationDetailStockForecastSubLabelTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    color: color,
    fontSize: kMedicationDetailStockForecastSubLabelFontSize,
    fontWeight: kFontWeightNormal,
    height: kLineHeightTight,
  );
}

TextStyle? medicationDetailStockForecastDateTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: color,
    fontSize: kMedicationDetailStockForecastDateFontSize,
    fontWeight: kFontWeightBold,
    height: kLineHeightTight,
  );
}

TextStyle? medicationDetailStockForecastDaysTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    color: color,
    fontSize: kMedicationDetailStockForecastDaysFontSize,
    fontWeight: kFontWeightMedium,
    height: kLineHeightTight,
  );
}

TextStyle? medicationDetailStockForecastExpiryTextStyle(
  BuildContext context, {
  required Color color,
  required bool emphasized,
}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    color: color,
    fontSize: kMedicationDetailStockForecastExpiryFontSize,
    fontWeight: emphasized ? kFontWeightBold : kFontWeightNormal,
    height: kLineHeightTight,
  );
}

TextStyle? reconSummaryBaseTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    color: color,
    fontWeight: kFontWeightSemiBold,
    height: 1.4,
  );
}

TextStyle? reconSummaryEmphasisTextStyle(
  BuildContext context, {
  required Color color,
  required double fontSize,
  FontWeight fontWeight = kFontWeightBold,
}) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: 1.4,
  );
}

TextStyle? reconSummaryStrengthTextStyle(
  BuildContext context, {
  required bool compact,
  required Color color,
  FontWeight fontWeight = kFontWeightExtraBold,
}) {
  return reconSummaryEmphasisTextStyle(
    context,
    color: color,
    fontSize: compact
        ? kReconSummaryStrengthValueFontSizeCompact
        : kReconSummaryStrengthValueFontSize,
    fontWeight: fontWeight,
  );
}

TextStyle? reconSummaryOfTextStyle(
  BuildContext context, {
  required bool compact,
  required Color color,
  FontWeight fontWeight = kFontWeightNormal,
}) {
  return reconSummaryEmphasisTextStyle(
    context,
    color: color,
    fontSize: compact
        ? kReconSummaryOfFontSizeCompact
        : kReconSummaryOfFontSize,
    fontWeight: fontWeight,
  );
}

TextStyle? reconSummaryMedicationNameTextStyle(
  BuildContext context, {
  required bool compact,
  required Color color,
  FontWeight fontWeight = kFontWeightBold,
}) {
  return reconSummaryEmphasisTextStyle(
    context,
    color: color,
    fontSize: compact
        ? kReconSummaryNameFontSizeCompact
        : kReconSummaryNameFontSize,
    fontWeight: fontWeight,
  );
}

TextStyle? reconSummaryMetaTextStyle(
  BuildContext context, {
  required bool compact,
  required Color color,
  FontWeight fontWeight = kFontWeightMedium,
}) {
  return reconSummaryEmphasisTextStyle(
    context,
    color: color,
    fontSize: compact
        ? kReconSummaryMetaFontSizeCompact
        : kReconSummaryMetaFontSize,
    fontWeight: fontWeight,
  );
}

TextStyle? reconSummaryTotalVolumeTextStyle(
  BuildContext context, {
  required bool compact,
  required Color color,
  FontWeight fontWeight = kFontWeightExtraBold,
}) {
  return reconSummaryEmphasisTextStyle(
    context,
    color: color,
    fontSize: compact
        ? kReconSummaryTotalVolumeFontSizeCompact
        : kReconSummaryTotalVolumeFontSize,
    fontWeight: fontWeight,
  );
}

TextStyle? reconSummaryHugeVolumeTextStyle(
  BuildContext context, {
  required Color color,
  FontWeight fontWeight = kFontWeightExtraBold,
}) {
  return reconSummaryEmphasisTextStyle(
    context,
    color: color,
    fontSize: kReconSummaryVolumeHugeFontSize,
    fontWeight: fontWeight,
  );
}

TextStyle? reconSummaryDrawUnitsTextStyle(
  BuildContext context, {
  required Color color,
  FontWeight fontWeight = kFontWeightExtraBold,
}) {
  return reconSummaryEmphasisTextStyle(
    context,
    color: color,
    fontSize: kReconSummaryDrawUnitsFontSize,
    fontWeight: fontWeight,
  );
}

TextStyle? reconSummaryValueTextStyle(
  BuildContext context, {
  required bool compact,
  required Color color,
  FontWeight fontWeight = kFontWeightBold,
}) {
  return reconSummaryEmphasisTextStyle(
    context,
    color: color,
    fontSize: compact
        ? kReconSummaryValueFontSizeCompact
        : kReconSummaryValueFontSize,
    fontWeight: fontWeight,
  );
}

TextStyle? reconSummarySyringeLineTextStyle(
  BuildContext context, {
  required Color color,
  FontWeight fontWeight = kFontWeightMedium,
}) {
  return reconSummaryEmphasisTextStyle(
    context,
    color: color,
    fontSize: kReconSummarySyringeLineFontSize,
    fontWeight: fontWeight,
  );
}

TextStyle? reconCalculatorOptionTitleTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.titleSmall?.copyWith(
    fontSize: kReconCalculatorOptionTitleFontSize,
    fontWeight: kFontWeightBold,
    color: color,
    height: 1.0,
  );
}

/// Week-view compact dose indicator (value/initial) text style.
TextStyle? calendarWeekDoseIndicatorValueTextStyle(
  BuildContext context, {
  Color? color,
}) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    fontSize: kFontSizeSmall,
    height: kLineHeightTight,
    fontWeight: kFontWeightBold,
    color: color ?? cs.onSurface,
  );
}

/// Week-view compact dose indicator (time) text style.
TextStyle? calendarWeekDoseIndicatorTimeTextStyle(
  BuildContext context, {
  Color? color,
}) {
  final cs = Theme.of(context).colorScheme;
  final base = color ?? cs.onSurface;
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    fontSize: kFontSizeXSmall,
    height: kLineHeightTight,
    fontWeight: kFontWeightMedium,
    color: base.withValues(alpha: kOpacityMedium),
  );
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

/// Card heading style (primary-colored).
TextStyle? cardSectionTitleStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return sectionTitleStyle(context)?.copyWith(color: cs.primary);
}

/// Review-card heading style (e.g. wizard Step 5 review sections).
TextStyle? reviewCardTitleStyle(BuildContext context) {
  return cardSectionTitleStyle(context);
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

/// Review-row label style (left column labels on Step 5 review rows).
TextStyle? reviewRowLabelStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return smallHelperTextStyle(
    context,
    color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
  )?.copyWith(fontWeight: kFontWeightSemiBold);
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

TextStyle? wizardHeaderTitleTextStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    color: color,
    fontSize: kWizardHeaderTitleFontSize,
    fontWeight: kFontWeightSemiBold,
    height: kLineHeightTight,
  );
}

TextStyle? wizardStepNumberTextStyle(
  BuildContext context, {
  required Color color,
  FontWeight fontWeight = kFontWeightExtraBold,
}) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    color: color,
    fontSize: kWizardStepNumberFontSize,
    fontWeight: fontWeight,
    height: kLineHeightTight,
  );
}

/// Compact button text (used where space is tight, e.g. app header actions).
TextStyle? compactButtonTextStyle(BuildContext context) {
  return buttonTextStyle(context)?.copyWith(fontSize: kFontSizeSmall);
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

/// Home page hero title style.
TextStyle? homeHeroTitleStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: kFontSizeHomeHeroTitle,
    fontWeight: kFontWeightMedium,
    color: cs.onSurface.withValues(alpha: kOpacityMedium),
  );
}

/// Home page hero subtitle style (used for centered "Today" line).
TextStyle? homeHeroSubtitleStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    fontSize: kFontSizeXLarge,
    fontWeight: kFontWeightSemiBold,
    letterSpacing: 0.4,
    color: cs.onSurface.withValues(alpha: kOpacityMediumHigh),
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

/// Branded splash tagline style.
TextStyle? splashTaglineTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall?.copyWith(
    fontSize: kFontSizeDetailHeaderTitle,
    fontWeight: kFontWeightSemiBold,
    color: Theme.of(context).colorScheme.onPrimary,
    letterSpacing: 0.2,
  );
}

/// App snackbar text style (used for app snackbars).
TextStyle? appSnackBarTextStyle(BuildContext context) {
  return bodyTextStyle(context)?.copyWith(
    color: snackBarForegroundColor(context),
    fontWeight: kFontWeightSemiBold,
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

/// Calendar compact dose-block title style (e.g. schedule name in a block).
TextStyle? calendarDoseBlockTitleTextStyle(
  BuildContext context, {
  Color? color,
}) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.labelMedium?.copyWith(
    fontWeight: kFontWeightSemiBold,
    color: (color ?? cs.onSurface).withValues(alpha: kOpacityHigh),
  );
}

/// Calendar compact dose-block subtitle style (e.g. dose description in a block).
TextStyle? calendarDoseBlockSubtitleTextStyle(
  BuildContext context, {
  Color? color,
}) {
  final cs = Theme.of(context).colorScheme;
  final base = color ?? cs.onSurface;
  return helperTextStyle(
    context,
    color: base.withValues(alpha: kOpacityMediumHigh),
  );
}

/// Calendar selected-day stage header title style.
TextStyle? calendarSelectedDayHeaderTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightSemiBold,
    color: Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: kOpacityMediumHigh),
  );
}

/// Calendar selected-day stage hour label style (left column, like day view).
TextStyle? calendarStageHourLabelTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    fontSize: kFontSizeSmall,
    height: kLineHeightTight,
    color: Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: kOpacityMedium),
  );
}

/// Calendar week-view header day label style (e.g. Mon)
TextStyle? calendarWeekHeaderDayLabelTextStyle(BuildContext context) {
  return Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(fontWeight: kFontWeightSemiBold);
}

/// Calendar week-view header day number style (e.g. 9)
TextStyle? calendarWeekHeaderDayNumberTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    fontSize: kFontSizeXSmall,
    height: kLineHeightTight,
    fontWeight: kFontWeightSemiBold,
  );
}

/// Calendar header (Month/Year) title style.
TextStyle? calendarHeaderTitleTextStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.titleSmall?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightSemiBold,
    color: cs.onSurface.withValues(alpha: kOpacityMediumHigh),
  );
}

/// Standard dialog title text style.
TextStyle? dialogTitleTextStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return cardTitleStyle(context)?.copyWith(color: cs.primary);
}

/// Collapsed title style used in detail-page headers.
TextStyle? detailCollapsedTitleTextStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    fontSize: kFontSizeDetailCollapsedTitle,
    fontWeight: kFontWeightSemiBold,
    color: cs.onPrimary,
  );
}

/// Large title style used in detail-page header banners.
TextStyle? detailHeaderBannerTitleTextStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.titleLarge?.copyWith(
    fontSize: kFontSizeDetailHeaderTitle,
    fontWeight: kFontWeightBold,
    color: cs.onPrimary,
  );
}

/// Standard dialog content text style.
TextStyle? dialogContentTextStyle(BuildContext context) {
  return bodyTextStyle(context);
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
