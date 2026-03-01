/// ============================================================================
/// DESIGN TOKENS — OPACITY & SHADOW
/// ============================================================================
///
/// All opacity scale values, derived semantic opacities, and shadow constants.
///
/// Import this file directly, or just import `design_system.dart` (which
/// re-exports everything).
/// ============================================================================

// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';

// ============================================================================
// OPACITY SCALE
// ============================================================================

/// Text opacity levels — max darkness should result in ~#343434
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

// ============================================================================
// SEMANTIC OPACITIES
// ============================================================================

/// Specific use-case opacity
const double kHelperTextOpacity = kOpacityMediumLow;
const double kDisabledOpacity = kOpacityLow;
const double kCardBorderOpacity = kOpacityLow;

/// Inner/section card border (visible but not heavy)
const double kStandardCardBorderOpacity = 0.22;
const double kHintTextOpacity = kOpacityLow;

/// Frameless card border: noticeably separates cards from the page background.
const double kFramelessCardBorderOpacityLight = 0.25; // Visible in light mode
const double kFramelessCardBorderOpacityDark = 0.35; // Visible in dark mode

/// Frameless card shadow — subtle lift to help cards pop from background.
const double kFramelessCardShadowOpacity = 0.07;
const double kFramelessCardShadowBlur = 10.0;
const Offset kFramelessCardShadowOffset = Offset(0, 3);

// ============================================================================
// CARD SHADOW CONSTANTS
// ============================================================================

/// Subtle shadow for standard/section cards.
const double kCardShadowOpacity = 0.04;
const double kCardShadowBlurRadius = 6.0;
const Offset kCardShadowOffset = Offset(0, 2);

/// Dose item card shadow.
const double kDoseCardShadowOpacity = 0.06;
const double kDoseCardShadowBlurRadius = 6.0;
const Offset kDoseCardShadowOffset = Offset(0, 2);

// ============================================================================
// RECONSTITUTION CALCULATOR OPACITIES
// ============================================================================

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

/// Detail page header gradient colors (shared by Medication/Schedule headers).
const Color kDetailHeaderGradientStart = Color(0xFF09A8BD);
const Color kDetailHeaderGradientEnd = Color(0xFF18537D);

const LinearGradient kDetailHeaderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kDetailHeaderGradientStart, kDetailHeaderGradientEnd],
);
const double kDetailHeaderExpandedHeight = 280;
const double kDetailHeaderExpandedHeightCompact = 220;
const double kDetailHeaderCollapsedHeight = 48;

/// Semantic status colors ΓÇö light-mode base values (use adaptive helpers in widgets).
///
/// Prefer the adaptive helper functions (e.g. [kDoseStatusTakenGreenAdaptive])
/// when you have a [BuildContext], so colors remain legible in dark mode.
const Color kDoseStatusTakenGreen = Color(0xFF2E7D32);        // Green 800 (light mode)
const Color kDoseStatusTakenGreenDark = Color(0xFF81C784);    // Green 300 (dark mode)
const Color kDoseStatusSkippedRed = Color(0xFFD32F2F);        // Red 700 (light mode)
const Color kDoseStatusSkippedRedDark = Color(0xFFEF9A9A);    // Red 200 (dark mode)
const Color kDoseStatusSnoozedOrange = Color(0xFFF57C00);     // Orange 700 (light mode)
const Color kDoseStatusSnoozedOrangeDark = Color(0xFFFFB74D); // Orange 300 (dark mode)
const Color kDoseStatusOverdueAmber = Color(0xFFF9A825);      // Amber (both modes)
const Color kDoseStatusMissedDarkRed = Color(0xFFB71C1C);     // Red 900 (light mode)
const Color kDoseStatusMissedDarkRedDark = Color(0xFFEF9A9A); // Red 200 (dark mode)

/// Adaptive dose status color helpers ΓÇö always use these in widgets.
/// Returns a lighter shade in dark mode for sufficient contrast.
Color kDoseStatusTakenGreenAdaptive(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? kDoseStatusTakenGreenDark : kDoseStatusTakenGreen;
}

Color kDoseStatusSkippedRedAdaptive(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? kDoseStatusSkippedRedDark : kDoseStatusSkippedRed;
}

Color kDoseStatusSnoozedOrangeAdaptive(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? kDoseStatusSnoozedOrangeDark : kDoseStatusSnoozedOrange;
}

Color kDoseStatusMissedDarkRedAdaptive(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? kDoseStatusMissedDarkRedDark : kDoseStatusMissedDarkRed;
}

/// Adherence rate colors ΓÇö adaptive for dark mode.
Color kAdherenceGoodColor(BuildContext context) =>
    kDoseStatusTakenGreenAdaptive(context);
Color kAdherenceWarningColor(BuildContext context) =>
    kDoseStatusSnoozedOrangeAdaptive(context);
Color kAdherencePoorColor(BuildContext context) =>
    kDoseStatusSkippedRedAdaptive(context);

/// Single source of truth for dose status labels.
String doseStatusLabelText(DoseStatus status, {required bool disabled}) {
  if (disabled) return 'DISABLED';

  return switch (status) {
    DoseStatus.logged => 'LOGGED',
    DoseStatus.skipped => 'SKIPPED',
    DoseStatus.snoozed => 'SNOOZED',
    DoseStatus.due => 'OVERDUE',
    DoseStatus.overdue => 'MISSED',
    DoseStatus.pending => 'PENDING',
  };
}

/// Single source of truth for dose status visuals.
({Color color, IconData icon}) doseStatusVisualSpec(
  BuildContext context,
  DoseStatus status, {
  required bool disabled,
}) {
  final cs = Theme.of(context).colorScheme;

  if (disabled) {
    return (
      color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
      icon: Icons.do_not_disturb_on_rounded,
    );
  }

  return switch (status) {
    DoseStatus.logged => (
      color: kDoseStatusTakenGreenAdaptive(context),
      icon: Icons.check_rounded,
    ),
    DoseStatus.skipped => (
      color: kDoseStatusSkippedRedAdaptive(context),
      icon: Icons.block_rounded,
    ),
    DoseStatus.snoozed => (
      color: kDoseStatusSnoozedOrangeAdaptive(context),
      icon: Icons.snooze_rounded,
    ),
    DoseStatus.due => (
      color: kDoseStatusOverdueAmber,
      icon: Icons.schedule_rounded,
    ),
    DoseStatus.overdue => (
      color: kDoseStatusMissedDarkRedAdaptive(context),
      icon: Icons.warning_rounded,
    ),
    DoseStatus.pending => (
      color: cs.primary,
      icon: Icons.notifications_rounded,
    ),
  };
}

/// Single source of truth for dose action visuals.
({Color color, IconData icon}) doseActionVisualSpec(
  BuildContext context,
  DoseAction action,
) {
  return switch (action) {
    DoseAction.logged => (
      color: kDoseStatusTakenGreenAdaptive(context),
      icon: Icons.check_rounded,
    ),
    DoseAction.skipped => (
      color: kDoseStatusSkippedRedAdaptive(context),
      icon: Icons.block_rounded,
    ),
    DoseAction.snoozed => (
      color: kDoseStatusSnoozedOrangeAdaptive(context),
      icon: Icons.snooze_rounded,
    ),
  };
}

/// Single source of truth for inventory change visuals.
({Color color, IconData icon}) inventoryChangeVisualSpec(
  BuildContext context,
  InventoryChangeType changeType,
) {
  final cs = Theme.of(context).colorScheme;

  return switch (changeType) {
    InventoryChangeType.refillAdd => (
      color: kDoseStatusTakenGreenAdaptive(context),
      icon: Icons.add_circle_rounded,
    ),
    InventoryChangeType.refillToMax => (
      color: kDoseStatusTakenGreenAdaptive(context),
      icon: Icons.trending_up_rounded,
    ),
    InventoryChangeType.doseDeducted => (
      color: kDoseStatusSnoozedOrangeAdaptive(context),
      icon: Icons.remove_circle_rounded,
    ),
    InventoryChangeType.adHocDose => (
      color: kDoseStatusSnoozedOrangeAdaptive(context),
      icon: Icons.remove_circle_outline_rounded,
    ),
    InventoryChangeType.manualAdjustment => (
      color: cs.primary,
      icon: Icons.tune_rounded,
    ),
    InventoryChangeType.vialOpened => (
      color: cs.primary,
      icon: Icons.science_rounded,
    ),
    InventoryChangeType.vialRestocked => (
      color: kDoseStatusTakenGreenAdaptive(context),
      icon: Icons.inventory_2_rounded,
    ),
    InventoryChangeType.expired => (
      color: kDoseStatusSkippedRedAdaptive(context),
      icon: Icons.delete_forever_rounded,
    ),
  };
}

/// Common utility colors.
///
/// Keep these centralized so feature code never references `Colors.*`.
const Color kColorTransparent = Color(0x00000000);
const Color kColorOnFilledStatus = Colors.white;

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

/// Reconstitution compact inline label padding (for two-column inputs)
const EdgeInsets kReconInlineFieldLabelPadding = EdgeInsets.only(
  left: 4, // kSpacingXS
  bottom: 4, // kSpacingXS
);

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
/// Always uses a light foreground to keep text/icons readable on the
/// gradient primary header across themes.
Color medicationDetailHeaderForegroundColor(BuildContext context) {
  return Colors.white;
}

/// Default expiry offsets for newly added medications.
///
/// Used when the user hasn't selected an expiry yet.
const int kDefaultTabletCapsuleExpiryDays = 365;
const int kDefaultInjectionExpiryDays = 90;
const int kDefaultSealedVialExpiryDays = 730;

/// Legacy fallback used in generic contexts.
const int kDefaultMedicationExpiryDays = kDefaultInjectionExpiryDays;

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

/// Returns the fraction of shelf-life remaining in the range 0ΓÇô1.
///
/// Uses `createdAt ΓåÆ expiry` as the total shelf-life window.
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
/// Accepts a ratio in the range 0ΓÇô1.
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
/// Accepts a percentage in the range 0ΓÇô100.
Color stockStatusColorFromPercentage(
  BuildContext context, {
  required double percentage,
}) {
  final clamped = percentage.clamp(0.0, 100.0);
  return stockStatusColorFromRatio(context, clamped / 100.0);
}
