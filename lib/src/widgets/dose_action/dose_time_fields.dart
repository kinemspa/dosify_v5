import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';

/// Date + time picker button for logging dose time.
///
/// Extracted from [DoseActionSheet._buildLoggedTimeField].
class DoseLoggedTimeField extends StatelessWidget {
  const DoseLoggedTimeField({
    required this.currentTime,
    required this.accentColor,
    required this.onTimeChanged,
    super.key,
  });

  final DateTime currentTime;
  final Color accentColor;
  final ValueChanged<DateTime> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time logged', style: sectionTitleStyle(context)),
        const SizedBox(height: kSpacingXS),
        SizedBox(
          width: double.infinity,
          height: kStandardFieldHeight,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final firstDate = DateUtils.dateOnly(DateTime(2000));
                final lastDate = DateUtils.dateOnly(DateTime(2100));
                final initialDate = _clampDate(
                  DateUtils.dateOnly(currentTime),
                  first: firstDate,
                  last: lastDate,
                );
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (pickedDate == null) return;
                if (!context.mounted) return;

                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(currentTime),
                );
                if (pickedTime == null) return;
                if (!context.mounted) return;

                onTimeChanged(DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                ));
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, 'Unable to open time picker: $e');
                }
              }
            },
            icon: Icon(
              Icons.check_circle_rounded,
              size: kIconSizeSmall,
              color: accentColor,
            ),
            label: Text(() {
              final date = MaterialLocalizations.of(
                context,
              ).formatMediumDate(currentTime);
              final time = DateTimeFormatter.formatTime(context, currentTime);
              return '$date | $time';
            }()),
          ),
        ),
      ],
    );
  }

  static DateTime _clampDate(
    DateTime date, {
    required DateTime first,
    required DateTime last,
  }) {
    if (date.isBefore(first)) return first;
    if (date.isAfter(last)) return last;
    return date;
  }
}

/// Date + time picker button for snooze target time.
///
/// Extracted from [DoseActionSheet._buildSnoozeUntilField].
class DoseSnoozeUntilField extends StatelessWidget {
  const DoseSnoozeUntilField({
    required this.selectedSnoozeUntil,
    required this.defaultSnoozeUntil,
    required this.maxSnoozeUntil,
    required this.onSnoozeChanged,
    super.key,
  });

  final DateTime? selectedSnoozeUntil;
  final DateTime defaultSnoozeUntil;
  final DateTime? maxSnoozeUntil;
  final ValueChanged<DateTime> onSnoozeChanged;

  Future<void> _showPastNextDoseAlert(BuildContext context, DateTime max) async {
    final date = MaterialLocalizations.of(context).formatMediumDate(max);
    final time = DateTimeFormatter.formatTime(context, max);
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Snooze limit'),
        content: Text(
          'Snooze time must be before the next scheduled dose. The latest allowed snooze is $date \u2022 $time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final max = maxSnoozeUntil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Snooze until', style: sectionTitleStyle(context)),
        const SizedBox(height: kSpacingS),
        if (max != null) ...[
          Text(
            () {
              final date = MaterialLocalizations.of(context).formatMediumDate(max);
              final time = DateTimeFormatter.formatTime(context, max);
              return 'Next dose is at $date | $time.';
            }(),
            style: helperTextStyle(context),
          ),
          const SizedBox(height: kSpacingS),
        ],
        SizedBox(
          width: double.infinity,
          height: kStandardFieldHeight,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final now = DateTime.now();
                final initial = selectedSnoozeUntil ?? defaultSnoozeUntil;

                final firstDate = DateUtils.dateOnly(now);
                final lastDate = DateUtils.dateOnly(DateTime(2100));
                final initialDate = _clampDate(
                  DateUtils.dateOnly(initial),
                  first: firstDate,
                  last: lastDate,
                );

                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (pickedDate == null) return;
                if (!context.mounted) return;

                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initial),
                );
                if (pickedTime == null) return;
                if (!context.mounted) return;

                var dt = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );

                if (dt.isBefore(now)) dt = now;
                if (max != null && dt.isAfter(max)) {
                  await _showPastNextDoseAlert(context, max);
                  if (!context.mounted) return;
                  dt = max;
                }

                onSnoozeChanged(dt);
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, 'Unable to open snooze picker: $e');
                }
              }
            },
            icon: const Icon(Icons.snooze_rounded, size: kIconSizeSmall),
            label: Text(() {
              final dt = selectedSnoozeUntil ?? defaultSnoozeUntil;
              final date =
                  MaterialLocalizations.of(context).formatMediumDate(dt);
              final time = DateTimeFormatter.formatTime(context, dt);
              return '$date | $time';
            }()),
          ),
        ),
      ],
    );
  }

  static DateTime _clampDate(
    DateTime date, {
    required DateTime first,
    required DateTime last,
  }) {
    if (date.isBefore(first)) return first;
    if (date.isAfter(last)) return last;
    return date;
  }
}
