// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart' as intl;

// Project imports:
import 'package:dosifi_v5/src/core/utils/datetime_format_settings.dart';

/// Centralized date/time formatting utility that respects user preferences.
///
/// This replaces direct calls to DateFormat and TimeOfDay.format() throughout
/// the app to ensure consistent formatting based on user settings.
class DateTimeFormatter {
  const DateTimeFormatter._();

  /// Format a DateTime as a time string (e.g., "3:45 PM" or "15:45").
  ///
  /// Respects the user's time format preference (12h/24h/system).
  static String formatTime(BuildContext context, DateTime dateTime) {
    final config = DateTimeFormatSettings.value.value;

    switch (config.timeFormat) {
      case TimeFormat.system:
        // Use Flutter's localized time formatting
        return TimeOfDay.fromDateTime(dateTime).format(context);

      case TimeFormat.hour12:
        // 12-hour format with AM/PM
        return intl.DateFormat('h:mm a').format(dateTime);

      case TimeFormat.hour24:
        // 24-hour format
        return intl.DateFormat('HH:mm').format(dateTime);
    }
  }

  /// Format a DateTime as a short time string for compact displays.
  ///
  /// This is used in badges and other space-constrained UI elements.
  static String formatTimeCompact(BuildContext context, DateTime dateTime) {
    final config = DateTimeFormatSettings.value.value;

    switch (config.timeFormat) {
      case TimeFormat.system:
        // Use Flutter's localized time formatting
        final formatted = TimeOfDay.fromDateTime(dateTime).format(context);
        // Try to extract just the time part (some locales might include extra text)
        return formatted;

      case TimeFormat.hour12:
        // Compact 12-hour format
        return intl.DateFormat('h:mm a').format(dateTime);

      case TimeFormat.hour24:
        // 24-hour format is already compact
        return intl.DateFormat('HH:mm').format(dateTime);
    }
  }

  /// Format a DateTime as a full date string (e.g., "12/31/2024").
  ///
  /// Respects the user's date format preference (MDY/DMY/YMD/system).
  static String formatDate(DateTime dateTime) {
    final config = DateTimeFormatSettings.value.value;

    switch (config.dateFormat) {
      case DateFormat.system:
        // Use system locale default
        return intl.DateFormat.yMd().format(dateTime);

      case DateFormat.mdy:
        // MM/DD/YYYY
        return intl.DateFormat('MM/dd/yyyy').format(dateTime);

      case DateFormat.dmy:
        // DD/MM/YYYY
        return intl.DateFormat('dd/MM/yyyy').format(dateTime);

      case DateFormat.ymd:
        // YYYY-MM-DD
        return intl.DateFormat('yyyy-MM-dd').format(dateTime);
    }
  }

  /// Format a DateTime as a short date (e.g., "12/31").
  ///
  /// Useful for compact displays where year is not needed.
  static String formatDateShort(DateTime dateTime) {
    final config = DateTimeFormatSettings.value.value;

    switch (config.dateFormat) {
      case DateFormat.system:
        // Use system locale default without year
        return intl.DateFormat.Md().format(dateTime);

      case DateFormat.mdy:
        // MM/DD
        return intl.DateFormat('MM/dd').format(dateTime);

      case DateFormat.dmy:
        // DD/MM
        return intl.DateFormat('dd/MM').format(dateTime);

      case DateFormat.ymd:
        // MM-DD
        return intl.DateFormat('MM-dd').format(dateTime);
    }
  }

  /// Format a DateTime as a date and time (e.g., "12/31/2024 3:45 PM").
  static String formatDateTime(BuildContext context, DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(context, dateTime)}';
  }

  /// Format day number (e.g., "31" or "5").
  ///
  /// Used in calendar badges and date displays.
  static String formatDay(DateTime dateTime) {
    return intl.DateFormat('d').format(dateTime);
  }

  /// Format month abbreviation (e.g., "JAN", "DEC").
  ///
  /// Used in calendar badges and compact date displays.
  static String formatMonthAbbr(DateTime dateTime) {
    return intl.DateFormat('MMM').format(dateTime).toUpperCase();
  }

  /// Format month name (e.g., "January", "December").
  static String formatMonthName(DateTime dateTime) {
    return intl.DateFormat('MMMM').format(dateTime);
  }

  /// Format year (e.g., "2024").
  static String formatYear(DateTime dateTime) {
    return intl.DateFormat('yyyy').format(dateTime);
  }

  /// Format a date with month name (e.g., "January 31, 2024").
  static String formatDateLong(DateTime dateTime) {
    return intl.DateFormat('MMMM d, yyyy').format(dateTime);
  }

  /// Check if time format is 12-hour based on current settings.
  ///
  /// Returns true for 12-hour format or system (when system uses 12h).
  /// Note: For system default, we assume 12-hour for safety unless we can
  /// detect otherwise. In practice, formatTime handles this correctly.
  static bool is12HourFormat() {
    final config = DateTimeFormatSettings.value.value;
    // For system, we can't easily detect without context, but formatTime handles it
    return config.timeFormat == TimeFormat.hour12 ||
        config.timeFormat == TimeFormat.system;
  }
}
