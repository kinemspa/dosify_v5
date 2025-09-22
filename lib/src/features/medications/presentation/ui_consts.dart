// Shared UI constants for medication editors

import 'package:flutter/material.dart';

const double kFieldWidthFraction = 0.30;
const double kFieldWidthMin = 110.0;
const double kFieldWidthMax = 160.0;

const double kFieldHeight = 36.0; // unified height for text fields and dropdowns (global standard)
const double kBtnSize = 30.0;     // +/- buttons size

// Typography
const double kInputFontSize = 14.0;      // typed text size in fields
const double kDropdownFontSize = 14.0;   // selected item and menu item font size
const double kHintFontSize = 11.0;       // hint/help text

// Shared muted label style
TextStyle kMutedLabelStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.50),
        );

// Layout tweaks
const double kStrengthNudgeMinPx = 20.0;   // minimum extra right nudge for Strength row
const double kStrengthNudgeFrac = 0.03;    // additional nudge as a fraction of available width
