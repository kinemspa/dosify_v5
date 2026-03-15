import 'package:flutter/material.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/utils/datetime_formatter.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';

Widget _wrapPickerMediaQuery(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
    child: child ?? const SizedBox.shrink(),
  );
}

/// Date + time picker button for logging entry time.
///
/// Extracted from [EntryActionSheet._buildLoggedTimeField].
class EntryLoggedTimeField extends StatelessWidget {
  const EntryLoggedTimeField({
    required this.currentTime,
    required this.scheduledTime,
    required this.accentColor,
    required this.onTimeChanged,
    super.key,
  });

  final DateTime currentTime;
  final DateTime scheduledTime;
  final Color accentColor;
  final ValueChanged<DateTime> onTimeChanged;

  Future<void> _showLoggedTimeEditor(BuildContext context) async {
    final scheduledLocal = scheduledTime.toLocal();
    final now = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Time logged'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose the scheduled time, use the current time, or edit it manually.',
              style: helperTextStyle(dialogContext),
            ),
            const SizedBox(height: kSpacingM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onTimeChanged(scheduledLocal);
                },
                icon: Icon(
                  Icons.schedule_rounded,
                  size: kIconSizeSmall,
                  color: accentColor,
                ),
                label: Text(
                  'Scheduled time • ${DateTimeFormatter.formatTime(dialogContext, scheduledLocal)}',
                ),
              ),
            ),
            const SizedBox(height: kSpacingS),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onTimeChanged(DateTime.now());
                },
                icon: Icon(
                  Icons.bolt_rounded,
                  size: kIconSizeSmall,
                  color: accentColor,
                ),
                label: Text(
                  'Now • ${DateTimeFormatter.formatTime(dialogContext, now)}',
                ),
              ),
            ),
            const SizedBox(height: kSpacingS),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showCustomTimePicker(context);
                },
                icon: const Icon(
                  Icons.schedule_rounded,
                  size: kIconSizeSmall,
                ),
                label: const Text('Time'),
              ),
            ),
            const SizedBox(height: kSpacingXS),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showCustomDatePicker(context);
                },
                icon: const Icon(
                  Icons.event_rounded,
                  size: kIconSizeSmall,
                ),
                label: const Text('Date'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomTimePicker(BuildContext context) async {
    try {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentTime),
        builder: (context, child) => _wrapPickerMediaQuery(context, child),
      );
      if (pickedTime == null) return;
      if (!context.mounted) return;

      onTimeChanged(DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        pickedTime.hour,
        pickedTime.minute,
      ));
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Unable to open time picker: $e');
      }
    }
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
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
        builder: (context, child) => _wrapPickerMediaQuery(context, child),
      );
      if (pickedDate == null) return;
      if (!context.mounted) return;

      onTimeChanged(DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        currentTime.hour,
        currentTime.minute,
      ));
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Unable to open time picker: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time logged', style: sectionTitleStyle(context)),
        const SizedBox(height: kSpacingXS),
        buildHelperText(
          context,
          'Tap the time button to use the scheduled time, choose now, or edit it manually.',
          fullWidth: true,
        ),
        const SizedBox(height: kSpacingS),
        SizedBox(
          width: double.infinity,
          height: kStandardFieldHeight,
          child: OutlinedButton.icon(
            onPressed: () => _showLoggedTimeEditor(context),
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
/// Extracted from [EntryActionSheet._buildSnoozeUntilField].
class EntrySnoozeUntilField extends StatelessWidget {
  const EntrySnoozeUntilField({
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

  Future<void> _showPastNextEntryAlert(BuildContext context, DateTime max) async {
    final date = MaterialLocalizations.of(context).formatMediumDate(max);
    final time = DateTimeFormatter.formatTime(context, max);
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Snooze limit'),
        content: Text(
          'Snooze time must be before the next scheduled entry. The latest allowed snooze is $date \u2022 $time.',
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
              return 'Next entry is at $date | $time.';
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
                  builder: (context, child) =>
                      _wrapPickerMediaQuery(context, child),
                );
                if (pickedDate == null) return;
                if (!context.mounted) return;

                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initial),
                  builder: (context, child) =>
                      _wrapPickerMediaQuery(context, child),
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
                  await _showPastNextEntryAlert(context, max);
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
