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
            height: 220, // Fixed height for week grid
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

          return Expanded(
            child: InkWell(
              onTap: onDayTap != null ? () => onDayTap!(day) : null,
              child: Container(
                decoration: isToday
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                        ),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.E().format(day),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withAlpha(
                                (0.6 * 255).round(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.day.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
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
    switch (dose.status) {
      case DoseStatus.taken:
        return Theme.of(
          context,
        ).colorScheme.primary.withAlpha((0.1 * 255).round());
      case DoseStatus.skipped:
        return Theme.of(
          context,
        ).colorScheme.error.withAlpha((0.1 * 255).round());
      case DoseStatus.snoozed:
        return Colors.orange.withAlpha((0.1 * 255).round());
      case DoseStatus.overdue:
        return Theme.of(
          context,
        ).colorScheme.error.withAlpha((0.1 * 255).round());
      case DoseStatus.pending:
        return Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round());
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (dose.status) {
      case DoseStatus.taken:
        return Theme.of(context).colorScheme.primary;
      case DoseStatus.skipped:
        return Theme.of(context).colorScheme.error;
      case DoseStatus.snoozed:
        return Colors.orange;
      case DoseStatus.overdue:
        return Theme.of(context).colorScheme.error;
      case DoseStatus.pending:
        return Theme.of(
          context,
        ).colorScheme.outline.withAlpha((0.3 * 255).round());
    }
  }

  String _getInitials() {
    final words = dose.scheduleName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return dose.scheduleName.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(
          horizontal: kListItemSpacing,
          vertical: 4,
        ),
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
                _getInitials(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                dose.timeFormatted,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
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
