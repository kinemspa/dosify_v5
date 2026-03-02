/// ============================================================================
/// DESIGN TOKENS — SPACING & LAYOUT
/// ============================================================================
///
/// All spacing-scale values, page/card/field padding, and layout constants.
///
/// Import this file directly, or just import `design_system.dart` (which
/// re-exports everything).
/// ============================================================================

// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/core/design_tokens_radius.dart';

// ============================================================================
// SPACING SCALE
// ============================================================================

/// Generic spacing scale (apply everywhere before creating new values).
const double kSpacingXXS = 2;
const double kSpacingXS = 4;
const double kSpacingS = 8;
const double kSpacingM = 12;
const double kSpacingL = 16;
const double kSpacingXL = 20;
const double kSpacingXXL = 24;

// ============================================================================
// CARD SPACING
// ============================================================================

/// Section/card spacing
const double kSectionSpacing = kSpacingM;
const double kCardPadding = kSpacingM;
const double kCardInnerSpacing = kSpacingS;

/// Standard card padding
const EdgeInsets kStandardCardPadding = EdgeInsets.all(kCardPadding);

/// Compact card spacing
const EdgeInsets kCompactCardPadding = EdgeInsets.all(kSpacingS);

/// Padding used for inset/section surfaces inside larger cards.
const EdgeInsets kInsetSectionPadding = EdgeInsets.all(kSpacingS);

// ============================================================================
// LAYOUT SIZING
// ============================================================================

/// Label column width in label-field rows
const double kLabelColumnWidth = 120;

// ============================================================================
// FIELD / FORM SPACING
// ============================================================================

/// Field spacing
const double kFieldSpacing = 6; // Between label-field rows
const double kFieldGroupSpacing = 12; // Between field groups
const double kLabelFieldGap = 8; // Between label and field

/// Helper text spacing
const double kHelperTextLeftPadding = kLabelColumnWidth + kLabelFieldGap;
const double kHelperTextTopPadding = 2;
const double kHelperTextBottomPadding = 6;

/// Dose status badge spacing
const double kDoseStatusBadgeVerticalPadding = 1;

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

/// Button spacing
const double kButtonSpacing = 8;
const double kStepperButtonSpacing = 4; // Between stepper buttons

/// List item spacing
const double kListItemSpacing = 4;
const double kListItemPadding = 8;

/// Compact toolbar padding (e.g. search/sort/filter rows).
const EdgeInsets kCompactToolbarPadding = EdgeInsets.symmetric(
  horizontal: kSpacingS,
  vertical: kFieldSpacing,
);

// ============================================================================
// PAGE PADDING
// ============================================================================

/// Page-level spacing
const double kPageBottomPadding = 100;
const double kPageHorizontalPadding = 12;
const double kPageVerticalPadding = 16;
const EdgeInsets kNoPadding = EdgeInsets.zero;
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

// ============================================================================
// SNACKBAR SPACING & COLORS
// ============================================================================

/// App snackbar (app-wide) outer padding.
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

/// App snackbar colors (const; use theme-aware helpers for dynamic theming).
const Color kAppSnackBarBackgroundColor = Colors.white;
const Color kAppSnackBarForegroundColor = Colors.black87;

// ============================================================================
// BOTTOM SHEET SPACING
// ============================================================================

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

/// Dose action sheet (Take/Snooze/Skip) content padding.
const EdgeInsets kDoseActionSheetContentPadding = EdgeInsets.fromLTRB(
  kSpacingM,
  kSpacingM,
  kSpacingM,
  kSpacingL,
);
const EdgeInsets kBottomSheetHandleMargin = EdgeInsets.symmetric(
  vertical: kSpacingL,
);

/// DoseActionSheet dialog inset
const EdgeInsets kDoseActionSheetDialogInsetPadding = EdgeInsets.symmetric(
  horizontal: kSpacingM,
  vertical: kSpacingM,
);

// ============================================================================
// SCHEDULE WIZARD SPACING
// ============================================================================

/// Schedule wizard summary header layout
const double kScheduleWizardSummaryIconSize = 36;
const double kScheduleWizardSummaryIconGap = kSpacingS;
const double kScheduleWizardSummaryIndent =
    kScheduleWizardSummaryIconSize + kScheduleWizardSummaryIconGap;
const EdgeInsets kScheduleWizardSummaryPatternPadding = EdgeInsets.only(
  left: kScheduleWizardSummaryIndent,
);

const String kPrimaryLogoAssetPath = 'assets/logo/logo_001_primary.png';
const String kWhiteLogoAssetPath = 'assets/logo/logo_001_white.png';
const String kSplashLogoAssetPath = kWhiteLogoAssetPath;
const String kAndroidLegacyIconAssetPath =
    'assets/logo/logo_001_android_icon.png';
const String kPrimaryBrandTagline = 'Track Smarter Every Day';

/// Branded app-launch hold timing.
const Duration kBrandedLaunchHoldDuration = Duration(milliseconds: 2800);

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
const double kOnboardingCoachPointerSize = 16; // Arrow tip height (px); width is 2├ù this
const double kOnboardingCoachPointerOverlap = 1;
const double kOnboardingCoachPointerClamp = 0.88;
const double kOnboardingCoachTitleFontSize = 17;
const double kOnboardingCoachMessageFontSize = 15;
const double kOnboardingCoachMetaFontSize = 13;
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
/// 6 ├ù kCalendarDayHeight 52 = 396) PLUS a dose-stage panel below it
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
const double kDoseTimePillMinWidth = 48.0;
const double kDoseTimePillMaxWidth = 64.0;
const double kDoseTimePillBorderRadius = 8.0;
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
/// NOT text-scaled ΓÇö the overlay is positioned in absolute dp.
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
const EdgeInsets kCalendarStageDoseCardPadding = EdgeInsets.fromLTRB(
  kSpacingM, 0, kSpacingM, kSpacingS,
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

/// Dose action sheet (Take/Snooze/Skip) content padding.
///
/// Slightly tighter than the generic bottom-sheet padding to avoid
/// compressing full-width preview cards.

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
const double kCalendarDayOverflowTextOpacity = 0.60; // = kOpacityMedium

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
// DOSE CARD SIZING (from spacing section)
// ============================================================================

/// NextDoseRow layout
const double kNextDoseRowSecondaryIndent = kIconSizeSmall + kSpacingXS;

/// DoseCard status icon sizing
const double kDoseCardStatusIconSize = kIconSizeLarge;
const double kDoseCardStatusIconSizeCompact = kIconSizeMedium;

/// DoseCard status chip sizing
const double kDoseCardStatusChipHeight = 28;
const double kDoseCardStatusChipHeightCompact = 26;
const double kDoseCardStatusChipWidth = 84;
const double kDoseCardStatusChipWidthCompact = 76;
