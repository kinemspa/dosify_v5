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
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';

/// Assets
const String kPrimaryLogoAssetPath = 'assets/logo/logo_001_primary.png';
const String kWhiteLogoAssetPath = 'assets/logo/logo_001_white.png';
const String kSplashLogoAssetPath = kWhiteLogoAssetPath;
const String kAndroidLegacyIconAssetPath =
    'assets/logo/logo_001_android_icon.png';
const String kPrimaryBrandTagline = 'Track Smarter Every Day';

/// Branded app-launch hold timing.
const Duration kBrandedLaunchHoldDuration = Duration(milliseconds: 1200);

/// Branded launch logo sizing.
const double kBrandedLaunchLogoMinWidth = 220;
const double kBrandedLaunchLogoMaxWidth = 420;
const double kBrandedLaunchLogoWidthFactor = 0.82;

/// First-run onboarding layout sizing.
const double kOnboardingContentMaxWidth = 520;
const double kOnboardingLogoWidthFactor = 0.62;
const double kOnboardingLogoMinWidth = 160;
const double kOnboardingLogoMaxWidth = 280;
const double kOnboardingTipIconSize = kIconSizeLarge;
const double kOnboardingCoachBubbleMaxWidth = 360;
const double kOnboardingCoachTargetSize = 44;
const double kOnboardingCoachPointerSize = 16; // Arrow tip height (px); width is 2× this
const double kOnboardingCoachPointerOverlap = 1;
const double kOnboardingCoachPointerClamp = 0.88;
const double kOnboardingCoachTitleFontSize = kFontSizeXLarge;
const double kOnboardingCoachMessageFontSize = kFontSizeLarge;
const double kOnboardingCoachMetaFontSize = kFontSizeMedium;
const EdgeInsets kOnboardingCoachBubblePadding = EdgeInsets.all(kSpacingM);
const Color kOnboardingCoachForegroundColor = Colors.white;

/// Logo sizing (in-app)
const double kAppBarLogoHeight = 22;
const double kAppBarLogoWidth = 22;

/// App bar logo padding.
///
/// Used by [GradientAppBar] when showing the logo as the leading widget.
const EdgeInsets kAppBarLogoPadding = EdgeInsets.only(left: kSpacingM);

const double kAboutDialogLogoSize = 48;
const double kSettingsAboutTileLogoSize = 28;

// ============================================================================
// SIZING CONSTANTS
// ============================================================================

/// Standard field height (ALL text fields, dropdowns, buttons)
const double kStandardFieldHeight = kFieldHeight; // 36px

/// Default capitalization for user-entered text fields.
///
/// Applies sentence-case by default so the OSK starts with a capital letter.
const TextCapitalization kTextCapitalizationDefault =
    TextCapitalization.sentences;

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

/// Floating Action Button sizing
///
/// Default Material FABs can feel oversized in this UI; we standardize them
/// here so all screens stay consistent.
const double kFabSize = 48;

/// Size constraints for circular (non-extended) FABs.
const BoxConstraints kFabSizeConstraints = BoxConstraints.tightFor(
  width: kFabSize,
  height: kFabSize,
);

/// Size constraints for extended FABs (height is fixed, width is flexible).
const BoxConstraints kFabExtendedSizeConstraints = BoxConstraints.tightFor(
  height: kFabSize,
);

/// Horizontal padding for extended FABs.
const EdgeInsets kFabExtendedPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
);

/// Anchored banner ad layout
const double kAnchoredAdBannerHeight = 50;
const EdgeInsets kAnchoredAdBannerPadding = EdgeInsets.fromLTRB(
  kSpacingS,
  kSpacingXS,
  kSpacingS,
  kSpacingXS,
);

/// Icon sizes
const double kIconSizeXXSmall = 12;
const double kIconSizeXSmall = 14;
const double kIconSizeSmall = 16;
const double kIconSizeMedium = 20;
const double kIconSizeLarge = 24;

/// Empty state icon size
const double kEmptyStateIconSize = 48;

/// Empty state icon size (large)
const double kEmptyStateIconSizeLarge = 64;

/// Card/Container constraints
const double kCardMinHeight = 48;
const double kCardMaxWidth = 800;

/// Home page - mini calendar height.
///
/// Sized to fit the 6-row month grid (CalendarHeader 56 + day-names 28 +
/// 6 × kCalendarDayHeight 52 = 396) PLUS a dose-stage panel below it
/// (~184 dp) so the panel never overlaps calendar day cells.
/// 396 + 184 = 580.
const double kHomeMiniCalendarHeight = 580;

/// Home page - Today (Up Next) preview.
///
/// Limit the visible portion of the Today list so the card stays compact,
/// while still allowing users to scroll for more upcoming items.
const int kHomeTodayMaxPreviewItems = 3;

/// Max height for the scrollable Today preview list.
///
/// Tuned so ~3 [DoseCard] rows are visible before scrolling.
const double kHomeTodayDosePreviewListMaxHeight = 280;

/// Detail pages - compact calendar height.
///
/// Used for embedded [DoseCalendarWidget] on detail screens.
const double kDetailCompactCalendarHeight = 400;

/// Detail-card collapsed header padding (Medication Details screen).
///
/// Matches the Reports card header height for consistent collapsed card sizing.
const EdgeInsets kDetailCardCollapsedHeaderPadding = EdgeInsets.symmetric(
  horizontal: kCardPadding,
  vertical: kSpacingS,
);

/// Width reserved at the start of a collapsed detail-card header when showing
/// a reorder drag handle.
const double kDetailCardReorderHandleGutterWidth = kIconSizeMedium + kSpacingS;

/// Minimum tap target size for interactive header rows.
///
/// Centralized wrapper around Material's default minimum interactive dimension.
const double kMinTapTargetSize = kMinInteractiveDimension;

/// Tight icon button sizing (avoids default 48px IconButton height).
const BoxConstraints kTightIconButtonConstraints = BoxConstraints.tightFor(
  width: kIconButtonSize,
  height: kIconButtonSize,
);

/// Next-dose date badge sizing (Schedules list)
const double kNextDoseDateCircleSizeCompact = 42;
const double kNextDoseDateCircleSizeLarge = 48;
const EdgeInsets kNextDoseDateCircleContentPaddingCompact =
    EdgeInsets.symmetric(horizontal: kSpacingXS, vertical: kSpacingXXS);
const EdgeInsets kNextDoseDateCircleContentPaddingLarge = EdgeInsets.symmetric(
  horizontal: kSpacingXXS,
  vertical: kSpacingXXS / 2,
);

/// Dose-card leading pill badge (replaces circle when dense+time mode).
/// Pill shape: wider/taller than the circle so times like "10:30 AM" sit
/// comfortably, with optional dose-metrics row below a hairline divider.
const double kDoseTimePillMinWidth = 54.0;
const double kDoseTimePillMaxWidth = 88.0;
const double kDoseTimePillBorderRadius = 40.0;
const EdgeInsets kDoseTimePillPadding = EdgeInsets.symmetric(
  horizontal: 4,
  vertical: 4,
);

/// Next-dose badge "Next" label padding variants.
const EdgeInsets kNextDoseBadgeNextLabelPaddingTall = EdgeInsets.symmetric(
  horizontal: kSpacingXS,
  vertical: kSpacingXXS,
);
const EdgeInsets kNextDoseBadgeNextLabelPaddingStandard = EdgeInsets.symmetric(
  horizontal: kSpacingXS,
  vertical: 0,
);

/// Medication details reports card
const double kMedicationReportsTabHeight = 160;

/// Medication Reports card padding/layout
const EdgeInsets kMedicationReportsTabLabelPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
);
const EdgeInsets kMedicationReportsHistoryListPadding = EdgeInsets.fromLTRB(
  kCardPadding,
  0,
  kCardPadding,
  kCardPadding,
);
const EdgeInsets kMedicationReportsLoadMorePadding = EdgeInsets.symmetric(
  vertical: kSpacingS,
);

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

/// Default label width used by Medication Details inline rows.
///
/// Kept intentionally compact so values have room on small screens.
const double kMedicationDetailInlineLabelWidth = 90;

/// Label width used by compact info rows on Medication Details.
///
/// Centralized to avoid hardcoded sizes in feature code.
const double kMedicationDetailCompactInfoLabelWidth = 110;

/// Top padding between Medication Detail header name/form and manufacturer.
///
/// Keep this centralized to avoid inline literal paddings in feature UI.
const double kMedicationDetailHeaderManufacturerTopPadding = 1;

/// Medication header text limits
const int kMedicationHeaderDescriptionMaxChars = 90;

/// Medication details header layout
///
/// Reserved vertical space inside [MedicationHeaderWidget] so the
/// SliverAppBar's animated name/form/manufacturer overlay never overlaps
/// the header content on smaller screens.
///
/// Calculated as: identity top offset (44dp) + identity height with
/// manufacturer (~46dp) = 90dp.
/// NOT text-scaled — the overlay is positioned in absolute dp.
const double kMedicationDetailHeaderOverlayReservedHeight = 90;

/// Medication details animated header identity layout.
///
/// Centralized values used by the SliverAppBar overlay for name/form/
/// manufacturer so horizontal and vertical spacing remains consistent across
/// screen sizes and text scales.
const double kMedicationDetailHeaderIdentityExpandedTopOffset = 44;
const double kMedicationDetailHeaderIdentityCollapsedVisualHeight = 26;
const double kMedicationDetailHeaderIdentityRightReservedMinWidth = 152;
const double kMedicationDetailHeaderIdentityRightReservedExpandedFraction =
    0.46;

/// Medication header description/notes spacing (inside [MedicationHeaderWidget]).
const EdgeInsets kMedicationHeaderDescriptionPadding = EdgeInsets.only(
  bottom: kSpacingXXS,
);
const EdgeInsets kMedicationHeaderNotesPadding = EdgeInsets.only(
  bottom: kSpacingS,
);

/// Medication details form-chip layout
const double kMedicationDetailFormChipPaddingHorizontal = 6;
const double kMedicationDetailFormChipPaddingVertical = 1;
const EdgeInsets kMedicationDetailFormChipPadding = EdgeInsets.symmetric(
  horizontal: kMedicationDetailFormChipPaddingHorizontal,
  vertical: kMedicationDetailFormChipPaddingVertical,
);

/// Calendar component sizing
const double kCalendarDayHeight =
    52; // Height of day cell in month view (reduced from 80)
const double kCalendarMonthDayHeaderHeight = 28;
const double kCalendarHourHeight = 60; // Height of hour row in day view
const double kCalendarHourHeightCollapsed = 24; // Height of empty/collapsed hour row
const double kCalendarDoseBlockHeight = 60; // Default dose block height
const double kCalendarDoseBlockMinHeight = 40; // Minimum when compressed
const double kCalendarDoseIndicatorSize = 6; // Dot indicator diameter
const double kCalendarDoseIndicatorBorderRadius = 2; // Subtle rounding for dot
const double kCalendarDoseIndicatorSpacing = 2;
const double kCalendarEmptyStateIconSize = 64;

/// Calendar selected-day (Dose Card Stage) layout
const double kCalendarStageHourLabelWidth = 48;
const EdgeInsets kCalendarStageHourLabelPadding = EdgeInsets.only(
  top: kListItemSpacing,
  bottom: kSpacingXS,
);
const EdgeInsets kCalendarStageHourRowPadding = EdgeInsets.fromLTRB(
  kSpacingXS,
  0,
  kSpacingXS,
  kSpacingS,
);
const EdgeInsets kCalendarStageDoseCardPadding = EdgeInsets.only(
  bottom: kSpacingS,
);

/// Selected-day stage sizing (full-screen calendar).
///
/// When collapsed, the stage should leave a visible "tab" at the bottom to
/// indicate it can be dragged upward.
const double kCalendarSelectedDayStagePeekRatio = 0.10;
const double kCalendarSelectedDayStageMaxInitialRatio = 0.85;

/// Selected-day stage header spacing (kept compact so it fits in peek mode).
const EdgeInsets kCalendarSelectedDayStageHandleMargin = EdgeInsets.symmetric(
  vertical: kSpacingS,
);
const EdgeInsets kCalendarSelectedDayStageHeaderPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
  vertical: 0,
);

/// Calendar stage scroll indicator (Scrollbar)
const double kCalendarStageScrollbarThickness = 3;
const Radius kCalendarStageScrollbarThumbRadius = Radius.circular(
  kBorderRadiusChipTight,
);
const double kCalendarStageScrollHintIconSize = kIconSizeMedium;
const EdgeInsets kCalendarStageScrollHintPadding = EdgeInsets.only(
  bottom: kSpacingXS,
);
const EdgeInsets kCalendarSelectedDayHeaderPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
  vertical: kSpacingXS,
);

EdgeInsets calendarStageListPadding(double bottomPadding) {
  return EdgeInsets.only(bottom: bottomPadding);
}

const double kCalendarWeekColumnWidth = 80; // Width of day column in week view
const double kCalendarWeekHeaderHeight = 40;
const double kCalendarWeekGridHeight = 108;
const EdgeInsets kCalendarWeekHeaderCellMargin = EdgeInsets.all(kSpacingXXS);
const double kCalendarWeekHeaderCellBorderRadius = kBorderRadiusSmall;
const double kCalendarWeekHeaderLabelGap = kSpacingXXS;

/// Week-view compact dose indicator sizing.
const double kCalendarWeekDoseIndicatorHeight = 28;

/// Minimum width required to show the time label in week-view dose indicators.
const double kCalendarWeekDoseIndicatorMinWidthForTime = 52;
const EdgeInsets kCalendarWeekDoseIndicatorPadding = EdgeInsets.symmetric(
  horizontal: kSpacingXS,
  vertical: kSpacingXXS,
);

const EdgeInsets kCalendarWeekColumnPadding = EdgeInsets.symmetric(
  horizontal: kListItemSpacing,
  vertical: kCardInnerSpacing,
);
const double kCalendarHeaderHeight = 56; // Calendar header with navigation
const double kCalendarUpNextReservedHeight =
    148; // Includes Up Next card and vertical outer padding in full view

/// Bottom sheet sizing
const double kBottomSheetHandleWidth = 40;
const double kBottomSheetHandleHeight = 4;
const double kBottomSheetHandleRadius = 2;
const EdgeInsets kDoseActionSheetDialogInsetPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
  vertical: kSpacingM,
);

/// DoseActionSheet scroll indicator (Scrollbar)
const double kDoseActionSheetScrollbarThickness = 3;
const Radius kDoseActionSheetScrollbarThumbRadius = Radius.circular(
  kBorderRadiusChipTight,
);
const double kDoseActionSheetScrollHintIconSize = kIconSizeMedium;
const EdgeInsets kDoseActionSheetScrollHintPadding = EdgeInsets.only(
  bottom: kSpacingXS,
);
const double kReconstitutionDialogScrollHintIconSize = kIconSizeMedium;
const EdgeInsets kReconstitutionDialogScrollHintPadding = EdgeInsets.only(
  bottom: kSpacingXS,
);
const double kWizardScrollHintIconSize = kIconSizeMedium;
const EdgeInsets kWizardScrollHintPadding = EdgeInsets.only(bottom: kSpacingS);
const double kPageScrollHintIconSize = kIconSizeSmall;
const EdgeInsets kPageScrollHintPadding = EdgeInsets.only(bottom: kSpacingS);

/// Fixed width for the status cycle button in DoseActionSheet.
///
/// Keeps the button from resizing as the label changes.
const double kDoseActionSheetStatusButtonWidth = 170;
const EdgeInsets kBottomSheetHeaderPadding = EdgeInsets.fromLTRB(
  kSpacingL,
  kSpacingS,
  kSpacingL,
  kSpacingL,
);
const EdgeInsets kBottomSheetContentPadding = EdgeInsets.all(kSpacingL);

/// Dose action sheet (Take/Snooze/Skip) content padding.
///
/// Slightly tighter than the generic bottom-sheet padding to avoid
/// compressing full-width preview cards.
const EdgeInsets kDoseActionSheetContentPadding = EdgeInsets.fromLTRB(
  kSpacingM,
  kSpacingM,
  kSpacingM,
  kSpacingL,
);
const EdgeInsets kBottomSheetHandleMargin = EdgeInsets.symmetric(
  vertical: kSpacingL,
);

/// Month-view day cell styling
const double kCalendarDayNumberSize = 24;
const EdgeInsets kCalendarDayNumberPadding = EdgeInsets.only(
  left: kSpacingXXS,
  top: kSpacingXXS,
);
const EdgeInsets kCalendarDayCountBadgePadding = EdgeInsets.symmetric(
  horizontal: kSpacingXS,
  vertical: kSpacingXXS / 2,
);
const EdgeInsets kCalendarDayDoseIndicatorPadding = EdgeInsets.all(
  kSpacingXS / 2,
);
const int kCalendarMonthMaxDoseIndicators = 3;
const double kCalendarDayCellBorderRadius = kBorderRadiusSmall / 2;
const double kCalendarTodayButtonBorderRadius = kBorderRadiusSmall / 2;
const double kCalendarDayOverflowTextOpacity = kOpacityMedium;

/// Calendar header padding.
const EdgeInsets kCalendarHeaderPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
  vertical: kSpacingS,
);

/// Calendar header navigation button constraints.
///
/// Matches our standard compact control height.
const BoxConstraints kCalendarHeaderNavButtonConstraints = BoxConstraints(
  minWidth: kFieldHeight,
  minHeight: kFieldHeight,
);

/// Calendar header "Today" button padding.
const EdgeInsets kCalendarTodayButtonPadding = EdgeInsets.symmetric(
  horizontal: kSpacingS,
  vertical: kSpacingXS,
);

/// Calendar header "Today" button minimum size.
const Size kCalendarTodayButtonMinSize = Size(0, 32);

/// In the full-screen calendar, allocate a fixed portion of the available
/// height to the selected-day list panel so the calendar grid remains stable
/// across Day/Week/Month views.
const double kCalendarSelectedDayPanelHeightRatioDay = 0.42;
const double kCalendarSelectedDayPanelHeightRatioWeek = 0.45;
const double kCalendarSelectedDayPanelHeightRatioMonth = 0.42;

// ============================================================================
// SPACING CONSTANTS
// ============================================================================

/// Page-level spacing
const double kPageBottomPadding = 100;
const double kPageHorizontalPadding = 12;
const EdgeInsets kPagePadding = EdgeInsets.fromLTRB(
  kPageHorizontalPadding,
  16,
  kPageHorizontalPadding,
  kPageBottomPadding,
);
const EdgeInsets kPagePaddingNoBottom = EdgeInsets.fromLTRB(
  kPageHorizontalPadding,
  16,
  kPageHorizontalPadding,
  16,
);
const EdgeInsets kNoPadding = EdgeInsets.zero;
const double kPageVerticalPadding = 16;

/// Standard padding for bottom sheets that should respect the on-screen
/// keyboard.
///
/// Use this instead of ad-hoc `EdgeInsets.only/fromLTRB` in feature code.
EdgeInsets buildBottomSheetPagePadding(BuildContext context) {
  final bottomInset = MediaQuery.of(context).viewInsets.bottom;
  return EdgeInsets.fromLTRB(
    kSpacingL,
    kSpacingL,
    kSpacingL,
    kSpacingL + bottomInset,
  );
}

/// Schedule wizard summary header layout
const double kScheduleWizardSummaryIconSize = 36;
const double kScheduleWizardSummaryIconGap = kSpacingS;
const double kScheduleWizardSummaryIndent =
    kScheduleWizardSummaryIconSize + kScheduleWizardSummaryIconGap;

const EdgeInsets kScheduleWizardSummaryPatternPadding = EdgeInsets.only(
  left: kScheduleWizardSummaryIndent,
);

/// Detail pages - padding for the sections list under the header.
const EdgeInsets kDetailPageSectionsPadding = EdgeInsets.fromLTRB(
  kPageHorizontalPadding,
  kSpacingXXS,
  kPageHorizontalPadding,
  kPageBottomPadding,
);

/// Shared widget paddings
const EdgeInsets kUnifiedEmptyStatePadding = EdgeInsets.symmetric(
  horizontal: kSpacingL,
  vertical: kSpacingM,
);

const EdgeInsets kSectionHeaderRowPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
  vertical: kSpacingS,
);

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

/// Standard card padding
const EdgeInsets kStandardCardPadding = EdgeInsets.all(kCardPadding);

/// Compact card spacing
const EdgeInsets kCompactCardPadding = EdgeInsets.all(kSpacingS);

/// Field spacing
const double kFieldSpacing = 6; // Between label-field rows
const double kFieldGroupSpacing = 12; // Between field groups
const double kLabelFieldGap = 8; // Between label and field

/// Compact toolbar padding (e.g. search/sort/filter rows).
const EdgeInsets kCompactToolbarPadding = EdgeInsets.symmetric(
  horizontal: kSpacingS,
  vertical: kFieldSpacing,
);

/// Helper text spacing
const double kHelperTextLeftPadding = kLabelColumnWidth + kLabelFieldGap;
const double kHelperTextTopPadding = 2;
const double kHelperTextBottomPadding = 6;

/// Dose status badge spacing
const double kDoseStatusBadgeVerticalPadding = 1;

/// NextDoseRow layout
const double kNextDoseRowSecondaryIndent = kIconSizeSmall + kSpacingXS;

/// DoseCard status icon sizing
const double kDoseCardStatusIconSize = kIconSizeLarge;
const double kDoseCardStatusIconSizeCompact = kIconSizeMedium;

/// DoseCard status chip sizing
const double kDoseCardStatusChipHeight = 28;
const double kDoseCardStatusChipHeightCompact = 26;
const double kDoseCardStatusChipWidth = 80;
const double kDoseCardStatusChipWidthCompact = 72;

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

/// Dense button padding used for compact button rows (e.g., 3-up action buttons).
const EdgeInsets kDenseButtonContentPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
  vertical: kSpacingXS,
);
const EdgeInsets kCompactButtonPadding = EdgeInsets.zero;

/// Tight padding for inline text buttons (e.g. small in-card actions).
const EdgeInsets kTightTextButtonPadding = EdgeInsets.symmetric(
  horizontal: kSpacingS,
  vertical: kSpacingXXS,
);

/// App snackbar (app-wide) outer padding.
///
/// Used by [showAppSnackBar] to position the app snackbar within safe areas.
const EdgeInsets kAppSnackBarOuterPadding = EdgeInsets.fromLTRB(
  0,
  kSpacingS,
  0,
  kSpacingXS,
);

/// App snackbar top offset below the app header.
const double kAppSnackBarTopOffsetBelowHeader = kToolbarHeight + kSpacingS;

/// Content padding inside the app snackbar container.
const EdgeInsets kAppSnackBarInnerPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
  vertical: kSpacingS,
);

/// App snackbar shape.
const BorderRadius kAppSnackBarBorderRadius = BorderRadius.zero;

/// App snackbar colors.
///
/// Used by [showAppSnackBar] to ensure the snackbar is clearly visible.
///
/// Intentionally light background with dark text for legibility.
const Color kAppSnackBarBackgroundColor = Colors.white;

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
const Color kAppSnackBarForegroundColor = Colors.black87;

// ============================================================================
// BORDER CONSTANTS
// ============================================================================

/// Border widths
const double kBorderWidthThin = kOutlineWidth; // 0.75px
const double kBorderWidthMedium = 1.0;
const double kBorderWidthEmphasis = 1.5;
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

/// Small border radius (used for compact cards/badges).
const Radius kSmallRadius = Radius.circular(kBorderRadiusSmall);
const BorderRadius kSmallBorderRadius = BorderRadius.all(kSmallRadius);

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
const double kStandardCardBorderOpacity = 0.22; // Inner/section card border (visible but not heavy)
const double kHintTextOpacity = kOpacityLow;

/// Frameless card border: noticeably separates cards from the page background.
const double kFramelessCardBorderOpacityLight = 0.25; // Visible in light mode
const double kFramelessCardBorderOpacityDark = 0.35; // Visible in dark mode
/// Frameless card shadow — subtle lift to help cards pop from background.
const double kFramelessCardShadowOpacity = 0.07;
const double kFramelessCardShadowBlur = 10.0;
const Offset kFramelessCardShadowOffset = Offset(0, 3);

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

/// Semantic status colors — light-mode base values (use adaptive helpers in widgets).
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

/// Adaptive dose status color helpers — always use these in widgets.
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

/// Adherence rate colors — adaptive for dark mode.
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
  left: kSpacingXS,
  bottom: kSpacingXS,
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

/// Shadow constants — kept at zero; card separation is done via a faint border.
const double kCardShadowOpacity = 0.04; // Subtle shadow for standard/section cards
const double kCardShadowBlurRadius = 6.0;
const Offset kCardShadowOffset = Offset(0, 2);

const double kDoseCardShadowOpacity = 0.06; // Dose item card shadow
const double kDoseCardShadowBlurRadius = 6.0;
const Offset kDoseCardShadowOffset = Offset(0, 2);

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
    color: useGradient ? null : cs.surfaceContainerLow,
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

  // Use surfaceContainerHighest as fill (M3 spec for filled TextFields)
  // — gives fields a visible tonal background that works inside any card.
  final fill = isDark
      ? Color.alphaBlend(
          cs.onSurface.withValues(alpha: kOpacitySubtleLow),
          cs.surface,
        )
      : cs.surfaceContainerHighest;
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
          ? const TextStyle(fontSize: kFontSizeZero, height: 0)
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
      : cs.surfaceContainerHighest;
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

/// Small helper/support text style.
///
/// Prefer this over `helperTextStyle(...).copyWith(fontSize: kFontSizeSmall)`
/// in feature widgets.
TextStyle? smallHelperTextStyle(BuildContext context, {Color? color}) {
  return helperTextStyle(
    context,
    color: color,
  )?.copyWith(fontSize: kFontSizeSmall, height: kLineHeightTight);
}

/// Hint-sized helper/support text style.
///
/// Use for chart axes, tiny labels, and secondary metadata.
///
/// Prefer this over `helperTextStyle(...).copyWith(fontSize: kFontSizeHint)`
/// in feature widgets.
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

/// White syringe gauge tick label font sizes.
const double kSyringeGaugeTickFontSizeMajor = 10;
const double kSyringeGaugeTickFontSizeMinor = kFontSizeXSmall; // 9
const double kSyringeGaugeTickFontSizeMicro = 7;

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

/// Reconstitution summary emphasis sizes.
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
///
/// Use for section/card headers like Home cards and detail screen cards.
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

/// Muted icon color (e.g. inactive toolbar icons).
Color mutedIconColor(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return cs.onSurfaceVariant.withValues(alpha: kOpacityLow);
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
///
/// Uses an onSurface color with reduced opacity to avoid overly-dark/black text.
TextStyle? calendarHeaderTitleTextStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.titleSmall?.copyWith(
    fontSize: kFontSizeMedium,
    fontWeight: kFontWeightSemiBold,
    color: cs.onSurface.withValues(alpha: kOpacityMediumHigh),
  );
}

/// Standard dialog title text style.
///
/// Use for [AlertDialog.titleTextStyle] to keep dialogs consistent.
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
///
/// Use for [AlertDialog.contentTextStyle] to keep dialogs consistent.
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
