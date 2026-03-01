/// ============================================================================
/// DESIGN TOKENS — BORDER RADIUS & WIDTH
/// ============================================================================
///
/// All border width and border radius constants.
///
/// Import this file directly, or just import `design_system.dart` (which
/// re-exports everything).
/// ============================================================================

// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

// ============================================================================
// BORDER WIDTHS
// ============================================================================

const double kBorderWidthThin = kOutlineWidth; // 0.75px
const double kBorderWidthMedium = 1.0;
const double kBorderWidthEmphasis = 1.5;
const double kBorderWidthThick = kFocusedOutlineWidth; // 2px

// ============================================================================
// BORDER RADII
// ============================================================================

const double kBorderRadiusSmall = 8;
const double kBorderRadiusMedium = 12;
const double kBorderRadiusLarge = 16;
const double kBorderRadiusXLarge = 20;
const double kBorderRadiusXXLarge = 24;
const double kBorderRadiusFull = 999; // Pill shape
const double kBorderRadiusChip = 6; // Less rounded for chips
const double kBorderRadiusChipTight = 4; // Even less rounded for small badges

/// Standard border radius for fields, buttons, cards.
const Radius kStandardRadius = Radius.circular(kBorderRadiusMedium);
const BorderRadius kStandardBorderRadius = BorderRadius.all(kStandardRadius);

/// Small border radius (used for compact cards/badges).
const Radius kSmallRadius = Radius.circular(kBorderRadiusSmall);
const BorderRadius kSmallBorderRadius = BorderRadius.all(kSmallRadius);
