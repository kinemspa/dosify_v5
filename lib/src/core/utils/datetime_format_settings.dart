// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

/// Available time format options
enum TimeFormat {
  system, // Use OS default
  hour12, // 12-hour format (e.g., 3:45 PM)
  hour24, // 24-hour format (e.g., 15:45)
}

/// Available date format options
enum DateFormat {
  system, // Use OS default
  mdy, // MM/DD/YYYY (e.g., 12/31/2024)
  dmy, // DD/MM/YYYY (e.g., 31/12/2024)
  ymd, // YYYY-MM-DD (e.g., 2024-12-31)
}

@immutable
class DateTimeFormatConfig {
  const DateTimeFormatConfig({
    required this.timeFormat,
    required this.dateFormat,
  });

  final TimeFormat timeFormat;
  final DateFormat dateFormat;

  DateTimeFormatConfig copyWith({
    TimeFormat? timeFormat,
    DateFormat? dateFormat,
  }) {
    return DateTimeFormatConfig(
      timeFormat: timeFormat ?? this.timeFormat,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}

class DateTimeFormatSettings {
  const DateTimeFormatSettings._();

  static const String _prefsKeyTimeFormat = 'datetime_format.time_format_v1';
  static const String _prefsKeyDateFormat = 'datetime_format.date_format_v1';

  static const TimeFormat defaultTimeFormat = TimeFormat.system;
  static const DateFormat defaultDateFormat = DateFormat.system;

  static final ValueNotifier<DateTimeFormatConfig> value = ValueNotifier(
    const DateTimeFormatConfig(
      timeFormat: defaultTimeFormat,
      dateFormat: defaultDateFormat,
    ),
  );

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeFormatIndex = prefs.getInt(_prefsKeyTimeFormat);
      final dateFormatIndex = prefs.getInt(_prefsKeyDateFormat);

      value.value = DateTimeFormatConfig(
        timeFormat: timeFormatIndex != null &&
                timeFormatIndex >= 0 &&
                timeFormatIndex < TimeFormat.values.length
            ? TimeFormat.values[timeFormatIndex]
            : defaultTimeFormat,
        dateFormat: dateFormatIndex != null &&
                dateFormatIndex >= 0 &&
                dateFormatIndex < DateFormat.values.length
            ? DateFormat.values[dateFormatIndex]
            : defaultDateFormat,
      );
    } catch (_) {
      // Best-effort; keep defaults.
    }
  }

  static Future<void> setTimeFormat(TimeFormat format) async {
    value.value = value.value.copyWith(timeFormat: format);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyTimeFormat, format.index);
    } catch (_) {
      // Best-effort.
    }
  }

  static Future<void> setDateFormat(DateFormat format) async {
    value.value = value.value.copyWith(dateFormat: format);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyDateFormat, format.index);
    } catch (_) {
      // Best-effort.
    }
  }
}
