// Shared UI constants for medication editors

// Flutter imports:
import 'package:flutter/material.dart';

const double kFieldWidthFraction = 0.30;
const double kFieldWidthMin = 110;
const double kFieldWidthMax = 160;

const double kFieldHeight =
    36; // unified height for text fields and dropdowns (global standard)
const double kBtnSize = 30; // +/- buttons size

// Outline widths for inputs (keep these consistent to avoid layout shifts)
const double kOutlineWidth = 0.75; // enabled/normal/error
const double kFocusedOutlineWidth = 2; // focused/focusedError

// Typography
const double kInputFontSize = 13; // typed text size in fields (compact)
const double kDropdownFontSize =
    13; // selected item and menu item font size (compact)
const double kHintFontSize = 10.5; // hint/help text (compact)

// Standardized text colors
Color kTextPrimary(BuildContext c) => Theme.of(c).colorScheme.primary;
Color kTextDark(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color kTextGrey(BuildContext c) =>
    Theme.of(c).colorScheme.onSurfaceVariant.withValues(alpha: 0.85);
Color kTextLightGrey(BuildContext c) =>
    Theme.of(c).colorScheme.onSurfaceVariant.withValues(alpha: 0.75);
Color kTextLighterGrey(BuildContext c) =>
    Theme.of(c).colorScheme.onSurfaceVariant.withValues(alpha: 0.60);
Color kTextLightestGrey(BuildContext c) =>
    Theme.of(c).colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
Color kTextError(BuildContext c) => Theme.of(c).colorScheme.error;
Color kTextWarning(BuildContext c) => Colors.orange;

// Shared muted label style
TextStyle kMutedLabelStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: Theme.of(
        context,
      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.50),
    );

// Checkbox label style: darker than support text but lighter than primary label
TextStyle kCheckboxLabelStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: Theme.of(
        context,
      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
    );

// Layout tweaks
const double kStrengthNudgeMinPx =
    20; // minimum extra right nudge for Strength row
const double kStrengthNudgeFrac =
    0.03; // additional nudge as a fraction of available width
