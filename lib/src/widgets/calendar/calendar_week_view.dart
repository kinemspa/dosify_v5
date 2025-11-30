import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A week view showing a 7-column grid with doses.
///
/// Displays 7 days (Mon-Sun) with hourly rows (major hours only).
/// Features:
/// - 7-column grid layout
/// - Day headers with dates
/// - Compact dose indicators
/// - Current day highlight
/// - Tap day header → switch to Day view
/// - Tap dose → detail callback
/// - Swipe left/right → navigate weeks
class CalendarWeekView extends StatelessWidget {
  const CalendarWeekView({
    required this.startDate,
    required this.doses,
    this.selectedDate,
    this.onDoseTap,
    this.onDateChanged,
    this.onDayTap,
    super.key,
  });

  final DateTime startDate;
  final List<CalculatedDose> doses;
  final DateTime? selectedDate;
  final void Function(CalculatedDose dose)? onDoseTap;
  final void Function(DateTime date)? onDateChanged;
  final void Function(DateTime date)? onDayTap;

  DateTime get endDate => startDate.add(const Duration(days: 6));

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    if (selectedDate == null) return false;
    return date.year == selectedDate!.year &&
        date.month == selectedDate!.month &&
        date.day == selectedDate!.day;
  }

  List<CalculatedDose> _getDosesForDay(DateTime day) {
    return doses.where((dose) {
      return dose.scheduledTime.year == day.year &&
          dose.scheduledTime.month == day.month &&
          dose.scheduledTime.day == day.day;
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  @override
  Widget build(BuildContext context) {
    final hasDoses = doses.isNotEmpty;

    if (!hasDoses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: kSectionSpacing),
            Text(
              'No doses scheduled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
              ),
            ),
            const SizedBox(height: kCardInnerSpacing),
            Text(
              '${DateFormat.MMMd().format(startDate)} - ${DateFormat.MMMd().format(endDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.4 * 255).round()),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (onDateChanged == null) return;

        // Swipe left = next week, swipe right = previous week
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -500) {
            // Swipe left
            onDateChanged!(startDate.add(const Duration(days: 7)));
          } else if (details.primaryVelocity! > 500) {
            // Swipe right
            onDateChanged!(startDate.subtract(const Duration(days: 7)));
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day headers
          _WeekHeader(startDate: startDate, onDayTap: onDayTap),
          // Week grid
          SizedBox(
            height: 160, // Reduced height for week grid
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (index) {
                final day = startDate.add(Duration(days: index));
                final dayDoses = _getDosesForDay(day);
                final isToday = _isToday(day);
                final isSelected = _isSelected(day);

                return Expanded(
                  child: _DayColumn(
                    date: day,
                    doses: dayDoses,
                    isToday: isToday,
                    isSelected: isSelected,
                    onDoseTap: onDoseTap,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.startDate, this.onDayTap});

  final DateTime startDate;
  final void Function(DateTime date)? onDayTap;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outline.withAlpha((0.2 * 255).round()),
          ),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final day = startDate.add(Duration(days: index));
          final isToday = _isToday(day);
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Expanded(
            child: InkWell(
              onTap: onDayTap != null ? () => onDayTap!(day) : null,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: isToday
                    ? BoxDecoration(
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.E().format(day),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isToday
                            ? colorScheme.primary
                            : colorScheme.onSurface.withAlpha(
                                (0.6 * 255).round(),
                              ),
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.day.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isToday
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.doses,
    required this.isToday,
    required this.isSelected,
    this.onDoseTap,
  });

  final DateTime date;
  final List<CalculatedDose> doses;
  final bool isToday;
  final bool isSelected;
  final void Function(CalculatedDose dose)? onDoseTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primaryContainer.withAlpha((0.1 * 255).round())
            : null,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withAlpha((0.1 * 255).round()),
          ),
          // Add top border for selected date
          top: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2.5)
              : BorderSide.none,
        ),
      ),
      child: doses.isEmpty
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: kListItemSpacing,
                vertical: kCardInnerSpacing,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: doses.map((dose) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: kListItemSpacing),
                    child: _CompactDoseIndicator(
                      dose: dose,
                      onTap: onDoseTap != null ? () => onDoseTap!(dose) : null,
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

class _CompactDoseIndicator extends StatelessWidget {
  const _CompactDoseIndicator({required this.dose, this.onTap});

  final CalculatedDose dose;
  final VoidCallback? onTap;

  Color _getBackgroundColor(BuildContext context) {
    final now = DateTime.now();
    final isFuture = dose.scheduledTime.isAfter(now);
    final isToday =
        dose.scheduledTime.year == now.year &&
        dose.scheduledTime.month == now.month &&
        dose.scheduledTime.day == now.day;

    switch (dose.status) {
      case DoseStatus.taken:
        return Colors.green;
      case DoseStatus.skipped:
        return Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      case DoseStatus.snoozed:
        return Colors.orange.withValues(alpha: 0.2);
      case DoseStatus.overdue:
        return Theme.of(context).colorScheme.error;
      case DoseStatus.pending:
        if (isToday) {
          // Highlight today's pending doses
          return Theme.of(context).colorScheme.primary;
        }
        // Future doses unfilled
        return Colors.transparent;
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (dose.status) {
      case DoseStatus.taken:
        return Colors.green;
      case DoseStatus.skipped:
        return Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
      case DoseStatus.snoozed:
        return Colors.orange;
      case DoseStatus.overdue:
        return Theme.of(context).colorScheme.error;
      case DoseStatus.pending:
        return Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
    }
  }

  Color _getTextColor(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        dose.scheduledTime.year == now.year &&
        dose.scheduledTime.month == now.month &&
        dose.scheduledTime.day == now.day;

    switch (dose.status) {
      case DoseStatus.taken:
        return Colors.white;
      case DoseStatus.overdue:
        return Theme.of(context).colorScheme.onError;
      case DoseStatus.pending:
        if (isToday) {
          return Theme.of(context).colorScheme.onPrimary;
        }
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  String _getDisplayText() {
    // Try to show dose value (e.g. "10", "0.5") if it's short
    if (dose.doseValue > 0) {
      String val = dose.doseValue == dose.doseValue.roundToDouble()
          ? dose.doseValue.toInt().toString()
          : dose.doseValue.toString();
      if (val.length <= 3) return val;
    }

    // Fallback to 1 letter of schedule name
    if (dose.scheduleName.isNotEmpty) {
      return dose.scheduleName[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: Container(
        height: 36, // Reduced height
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          border: Border.all(color: _getBorderColor(context), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _getDisplayText(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: _getTextColor(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                DateFormat('h:mm a').format(dose.scheduledTime).toLowerCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  color: _getTextColor(context).withValues(alpha: 0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
