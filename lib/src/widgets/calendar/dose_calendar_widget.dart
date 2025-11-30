import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_calculation_service.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_day_view.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_header.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_month_view.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_week_view.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

/// Main calendar widget that integrates all calendar views.
///
/// This widget provides a complete calendar experience with:
/// - View switching (Day/Week/Month)
/// - Date navigation
/// - Dose filtering (by schedule or medication)
/// - Auto-refresh when data changes
/// - Multiple variants (full, compact, mini)
///
/// Usage:
/// ```dart
/// // Full calendar with all features
/// DoseCalendarWidget(variant: CalendarVariant.full)
///
/// // Compact calendar for detail pages
/// DoseCalendarWidget(
///   variant: CalendarVariant.compact,
///   defaultView: CalendarView.week,
///   scheduleId: 'schedule-123',
/// )
///
/// // Mini calendar for home page
/// DoseCalendarWidget(
///   variant: CalendarVariant.mini,
///   defaultView: CalendarView.day,
/// )
/// ```
class DoseCalendarWidget extends StatefulWidget {
  const DoseCalendarWidget({
    this.variant = CalendarVariant.full,
    this.defaultView = CalendarView.month,
    this.scheduleId,
    this.medicationId,
    this.height,
    this.startDate,
    this.onDoseTap,
    super.key,
  });

  final CalendarVariant variant;
  final CalendarView defaultView;
  final String? scheduleId;
  final String? medicationId;
  final double? height;
  final DateTime? startDate;
  final void Function(CalculatedDose dose)? onDoseTap;

  @override
  State<DoseCalendarWidget> createState() => _DoseCalendarWidgetState();
}

class _DoseCalendarWidgetState extends State<DoseCalendarWidget> {
  late CalendarView _currentView;
  late DateTime _currentDate;
  DateTime? _selectedDate; // Track selected date for detail panel
  List<CalculatedDose> _doses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentView = widget.defaultView;
    _currentDate = widget.startDate ?? DateTime.now();
    // Auto-select today for month/week views to show today's doses
    if (_currentView != CalendarView.day) {
      _selectedDate = DateTime.now();
    }
    _loadDoses();
  }

  @override
  void didUpdateWidget(DoseCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheduleId != widget.scheduleId ||
        oldWidget.medicationId != widget.medicationId) {
      _loadDoses();
    }
  }

  Future<void> _loadDoses() async {
    setState(() => _isLoading = true);

    try {
      final (startDate, endDate) = _getDateRange();
      final doses = await DoseCalculationService.calculateDoses(
        startDate: startDate,
        endDate: endDate,
        scheduleId: widget.scheduleId,
        medicationId: widget.medicationId,
      );

      if (mounted) {
        setState(() {
          _doses = doses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _doses = [];
          _isLoading = false;
        });
      }
    }
  }

  (DateTime, DateTime) _getDateRange() {
    switch (_currentView) {
      case CalendarView.day:
        final start = DateTime(
          _currentDate.year,
          _currentDate.month,
          _currentDate.day,
        );
        final end = start.add(const Duration(days: 1));
        return (start, end);

      case CalendarView.week:
        // Get start of week (Monday)
        final weekday = _currentDate.weekday;
        final daysToMonday = weekday == 7 ? 6 : weekday - 1;
        final start = _currentDate.subtract(Duration(days: daysToMonday));
        final normalizedStart = DateTime(start.year, start.month, start.day);
        final end = normalizedStart.add(const Duration(days: 7));
        return (normalizedStart, end);

      case CalendarView.month:
        final firstDayOfMonth = DateTime(
          _currentDate.year,
          _currentDate.month,
          1,
        );
        final lastDayOfMonth = DateTime(
          _currentDate.year,
          _currentDate.month + 1,
          0,
        );

        // Extend to include visible dates from other months
        final firstWeekday = firstDayOfMonth.weekday;
        final daysToSubtract = firstWeekday == 7 ? 0 : firstWeekday;
        final start = firstDayOfMonth.subtract(Duration(days: daysToSubtract));

        final lastWeekday = lastDayOfMonth.weekday;
        final daysToAdd = lastWeekday == 7 ? 0 : 7 - lastWeekday;
        final end = lastDayOfMonth.add(Duration(days: daysToAdd + 1));

        return (start, end);
    }
  }

  void _onViewChanged(CalendarView view) {
    setState(() {
      _currentView = view;
    });
    _loadDoses();
  }

  void _onPreviousPressed() {
    setState(() {
      switch (_currentView) {
        case CalendarView.day:
          _currentDate = _currentDate.subtract(const Duration(days: 1));
          break;
        case CalendarView.week:
          _currentDate = _currentDate.subtract(const Duration(days: 7));
          break;
        case CalendarView.month:
          _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
          break;
      }
    });
    _loadDoses();
  }

  void _onNextPressed() {
    setState(() {
      switch (_currentView) {
        case CalendarView.day:
          _currentDate = _currentDate.add(const Duration(days: 1));
          break;
        case CalendarView.week:
          _currentDate = _currentDate.add(const Duration(days: 7));
          break;
        case CalendarView.month:
          _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
          break;
      }
    });
    _loadDoses();
  }

  void _onTodayPressed() {
    final today = DateTime.now();
    setState(() {
      _currentDate = today;
      _selectedDate = today; // Also select today
    });
    _loadDoses();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _currentDate = date;
    });
    _loadDoses();
  }

  void _onDayTap(DateTime date) {
    // Show doses for selected date below calendar (stay on current view)
    setState(() {
      _selectedDate = date;
    });
  }

  void _onDoseTapInternal(CalculatedDose dose) {
    // If external handler provided, use it
    if (widget.onDoseTap != null) {
      widget.onDoseTap!(dose);
      return;
    }

    // Otherwise show bottom sheet with dose details
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DoseDetailBottomSheet(
        dose: dose,
        onMarkTaken: (notes) => _markDoseAsTaken(dose, notes),
        onSnooze: () => _snoozeDose(dose),
        onSkip: () => _skipDose(dose),
        onDelete: () => _deleteDoseLog(dose),
      ),
    );
  }

  Future<void> _markDoseAsTaken(CalculatedDose dose, String? notes) async {
    final logId =
        '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
    final medicationId = dose.existingLog?.medicationId ?? 'unknown';
    final log = DoseLog(
      id: logId,
      scheduleId: dose.scheduleId,
      scheduleName: dose.scheduleName,
      medicationId: medicationId,
      medicationName: dose.medicationName,
      scheduledTime: dose.scheduledTime,
      doseValue: dose.doseValue,
      doseUnit: dose.doseUnit,
      action: DoseAction.taken,
      notes: notes?.isEmpty ?? true ? null : notes,
    );

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(log);

      // Deduct medication stock
      await _deductStock(dose);

      // Cancel the notification for this dose
      await _cancelNotificationForDose(dose);

      // Reload doses to reflect new status
      await _loadDoses();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dose marked as taken')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cancelNotificationForDose(CalculatedDose dose) async {
    try {
      // Calculate notification ID using the same pattern as schedule_scheduler.dart
      final weekday = dose.scheduledTime.weekday;
      final minutes = dose.scheduledTime.hour * 60 + dose.scheduledTime.minute;
      final key = '${dose.scheduleId}|w:$weekday|m:$minutes|o:0';
      final notificationId = _stableHash32(key);

      await NotificationService.cancel(notificationId);
    } catch (e) {
      debugPrint('[DoseCalendar] Failed to cancel notification: $e');
    }
  }

  // Stable 32-bit hash (matches schedule_scheduler.dart)
  static int _stableHash32(String str) {
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
      hash = ((hash << 5) - hash + str.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  Future<void> _snoozeDose(CalculatedDose dose) async {
    final logId =
        '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}_snooze';
    final medicationId = dose.existingLog?.medicationId ?? 'unknown';
    final log = DoseLog(
      id: logId,
      scheduleId: dose.scheduleId,
      scheduleName: dose.scheduleName,
      medicationId: medicationId,
      medicationName: dose.medicationName,
      scheduledTime: dose.scheduledTime,
      doseValue: dose.doseValue,
      doseUnit: dose.doseUnit,
      action: DoseAction.snoozed,
    );

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(log);

      // TODO: Reschedule notification for 15 minutes later

      await _loadDoses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dose snoozed for 15 minutes')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _skipDose(CalculatedDose dose) async {
    final logId =
        '${dose.scheduleId}_${dose.scheduledTime.millisecondsSinceEpoch}';
    final medicationId = dose.existingLog?.medicationId ?? 'unknown';
    final log = DoseLog(
      id: logId,
      scheduleId: dose.scheduleId,
      scheduleName: dose.scheduleName,
      medicationId: medicationId,
      medicationName: dose.medicationName,
      scheduledTime: dose.scheduledTime,
      doseValue: dose.doseValue,
      doseUnit: dose.doseUnit,
      action: DoseAction.skipped,
    );

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(log);

      // Cancel the notification for this dose
      await _cancelNotificationForDose(dose);

      await _loadDoses();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dose skipped')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteDoseLog(CalculatedDose dose) async {
    if (dose.existingLog == null) return;

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.delete(dose.existingLog!.id);

      // Restore stock if the dose was previously taken
      if (dose.existingLog!.action == DoseAction.taken) {
        await _restoreStock(dose);
      }

      await _loadDoses();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dose reset to pending')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Deducts medication stock when a dose is taken
  Future<bool> _deductStock(CalculatedDose dose) async {
    try {
      // Get the schedule to access medication info
      final scheduleBox = Hive.box<Schedule>('schedules');
      final schedule = scheduleBox.get(dose.scheduleId);

      if (schedule == null || schedule.medicationId == null) {
        return true; // No medication linked, skip stock management
      }

      final medBox = Hive.box<Medication>('medications');
      final med = medBox.get(schedule.medicationId);

      if (med == null) {
        return true; // Medication not found, skip
      }

      // Calculate stock delta based on medication and dose type
      final delta = _calculateStockDelta(med, schedule);

      if (delta <= 0) {
        return true; // Can't calculate delta, skip
      }

      final newStock = (med.stockValue - delta).clamp(0.0, double.infinity);
      await medBox.put(med.id, med.copyWith(stockValue: newStock));

      return true;
    } catch (e) {
      debugPrint('[DoseCalendar] Failed to deduct stock: $e');
      return false;
    }
  }

  /// Restores medication stock when a taken dose is reset
  Future<bool> _restoreStock(CalculatedDose dose) async {
    try {
      // Get the schedule to access medication info
      final scheduleBox = Hive.box<Schedule>('schedules');
      final schedule = scheduleBox.get(dose.scheduleId);

      if (schedule == null || schedule.medicationId == null) {
        return true; // No medication linked
      }

      final medBox = Hive.box<Medication>('medications');
      final med = medBox.get(schedule.medicationId);

      if (med == null) {
        return true; // Medication not found
      }

      // Calculate stock delta
      final delta = _calculateStockDelta(med, schedule);

      if (delta <= 0) {
        return true; // Can't calculate delta
      }

      final newStock = med.stockValue + delta;
      await medBox.put(med.id, med.copyWith(stockValue: newStock));

      return true;
    } catch (e) {
      debugPrint('[DoseCalendar] Failed to restore stock: $e');
      return false;
    }
  }

  double _calculateStockDelta(Medication med, Schedule schedule) {
    var delta = 0.0;

    switch (med.stockUnit) {
      case StockUnit.tablets:
        if (schedule.doseTabletQuarters != null) {
          delta = schedule.doseTabletQuarters! / 4.0;
        } else if (schedule.doseMassMcg != null) {
          final perTabMcg = _convertToMcg(med.strengthValue, med.strengthUnit);
          delta = (schedule.doseMassMcg! / perTabMcg).clamp(0, double.infinity);
        }
      case StockUnit.capsules:
        if (schedule.doseCapsules != null) {
          delta = schedule.doseCapsules!.toDouble();
        } else if (schedule.doseMassMcg != null) {
          final perCapMcg = _convertToMcg(med.strengthValue, med.strengthUnit);
          delta = (schedule.doseMassMcg! / perCapMcg).clamp(0, double.infinity);
        }
      case StockUnit.preFilledSyringes:
        if (schedule.doseSyringes != null)
          delta = schedule.doseSyringes!.toDouble();
      case StockUnit.singleDoseVials:
        if (schedule.doseVials != null) delta = schedule.doseVials!.toDouble();
      case StockUnit.multiDoseVials:
        // For MDV: stockValue = active vial mL remaining
        // Deduct the raw mL volume used, NOT a vial fraction
        var usedMl = 0.0;
        if (schedule.doseVolumeMicroliter != null) {
          usedMl = schedule.doseVolumeMicroliter! / 1000.0;
        } else if (schedule.doseMassMcg != null) {
          double? mgPerMl;
          switch (med.strengthUnit) {
            case Unit.mgPerMl:
              mgPerMl = med.perMlValue ?? med.strengthValue;
            case Unit.mcgPerMl:
              mgPerMl = (med.perMlValue ?? med.strengthValue) / 1000.0;
            case Unit.gPerMl:
              mgPerMl = (med.perMlValue ?? med.strengthValue) * 1000.0;
            default:
              mgPerMl = null;
          }
          if (mgPerMl != null)
            usedMl = (schedule.doseMassMcg! / 1000.0) / mgPerMl;
        } else if (schedule.doseIU != null) {
          double? iuPerMl;
          if (med.strengthUnit == Unit.unitsPerMl) {
            iuPerMl = med.perMlValue ?? med.strengthValue;
          }
          if (iuPerMl != null) usedMl = schedule.doseIU! / iuPerMl;
        }
        // Deduct mL directly from active vial stock
        if (usedMl > 0) {
          delta = usedMl;
        }
      case StockUnit.mcg:
        if (schedule.doseMassMcg != null)
          delta = schedule.doseMassMcg!.toDouble();
      case StockUnit.mg:
        if (schedule.doseMassMcg != null)
          delta = schedule.doseMassMcg! / 1000.0;
      case StockUnit.g:
        if (schedule.doseMassMcg != null) delta = schedule.doseMassMcg! / 1e6;
    }

    return delta;
  }

  double _convertToMcg(double value, Unit unit) {
    return switch (unit) {
      Unit.mcg => value,
      Unit.mg => value * 1000,
      Unit.g => value * 1e6,
      Unit.units => value,
      Unit.mcgPerMl => value,
      Unit.mgPerMl => value * 1000,
      Unit.gPerMl => value * 1e6,
      Unit.unitsPerMl => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final showHeader = widget.variant != CalendarVariant.mini;
    final showViewToggle = widget.variant == CalendarVariant.full;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: widget.variant == CalendarVariant.full
            ? null
            : BorderRadius.circular(kBorderRadiusMedium),
        border: widget.variant != CalendarVariant.full
            ? Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withAlpha((0.2 * 255).round()),
              )
            : null,
      ),
      child: Column(
        children: [
          if (showHeader)
            CalendarHeader(
              currentDate: _currentDate,
              currentView: _currentView,
              onPreviousMonth: _onPreviousPressed,
              onNextMonth: _onNextPressed,
              onToday: _onTodayPressed,
              onViewChanged: _onViewChanged,
              showViewToggle: showViewToggle,
            ),
          // Calendar view (Day view needs Expanded, Month/Week use intrinsic height)
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_currentView == CalendarView.day)
            Expanded(child: _buildCurrentView())
          else
            _buildCurrentView(), // Month/Week views size themselves
          // Selected date schedules (if date selected, only for week/month views)
          if (_selectedDate != null && _currentView != CalendarView.day)
            widget.variant == CalendarVariant.compact
                ? _buildSelectedDayPanel()
                : Expanded(child: _buildSelectedDayPanel()),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CalendarView.day:
        return CalendarDayView(
          date: _currentDate,
          doses: _doses,
          onDoseTap: _onDoseTapInternal,
          onDateChanged: _onDateChanged,
        );

      case CalendarView.week:
        // Get start of week
        final weekday = _currentDate.weekday;
        final daysToMonday = weekday == 7 ? 6 : weekday - 1;
        final weekStart = _currentDate.subtract(Duration(days: daysToMonday));
        final normalizedWeekStart = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );

        return CalendarWeekView(
          startDate: normalizedWeekStart,
          doses: _doses,
          selectedDate: _selectedDate,
          onDoseTap: _onDoseTapInternal,
          onDateChanged: _onDateChanged,
          onDayTap: _onDayTap,
        );

      case CalendarView.month:
        // Get system's first day of week preference
        final localizations = MaterialLocalizations.of(context);
        final startOnMonday = localizations.firstDayOfWeekIndex == 1;

        return CalendarMonthView(
          month: _currentDate,
          doses: _doses,
          onDayTap: _onDayTap,
          onDateChanged: _onDateChanged,
          selectedDate: _selectedDate,
          startWeekOnMonday: startOnMonday,
        );
    }
  }

  Widget _buildSelectedDayPanel() {
    if (_selectedDate == null) return const SizedBox.shrink();

    final dayDoses = _doses.where((dose) {
      return dose.scheduledTime.year == _selectedDate!.year &&
          dose.scheduledTime.month == _selectedDate!.month &&
          dose.scheduledTime.day == _selectedDate!.day;
    }).toList();

    // Sort by time
    dayDoses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatSelectedDate(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedDate = null),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // Dose list
          widget.variant == CalendarVariant.compact
              ? (dayDoses.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No doses scheduled',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: dayDoses.length,
                        itemBuilder: (context, index) {
                          final dose = dayDoses[index];
                          return _buildDoseListTile(dose);
                        },
                      ))
              : Expanded(
                  child: dayDoses.isEmpty
                      ? Center(
                          child: Text(
                            'No doses scheduled',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: dayDoses.length,
                          itemBuilder: (context, index) {
                            final dose = dayDoses[index];
                            return _buildDoseListTile(dose);
                          },
                        ),
                ),
        ],
      ),
    );
  }

  String _formatSelectedDate() {
    if (_selectedDate == null) return '';

    final now = DateTime.now();
    final isToday =
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    // Get day name (e.g., "Sunday", "Monday")
    final dayName = DateFormat.EEEE().format(_selectedDate!);

    // Format date using system locale (respects day-month-year vs month-day-year)
    // This will automatically use the correct format for the device locale
    final formattedDate = DateFormat.yMMMd().format(_selectedDate!);

    if (isToday) {
      return 'Today, $dayName — $formattedDate';
    } else {
      return '$dayName, $formattedDate';
    }
  }

  Widget _buildDoseListTile(CalculatedDose dose) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    IconData statusIcon;

    switch (dose.status) {
      case DoseStatus.taken:
        statusColor = colorScheme.primary;
        statusIcon = Icons.check_circle;
        break;
      case DoseStatus.skipped:
        statusColor = colorScheme.error;
        statusIcon = Icons.cancel;
        break;
      case DoseStatus.snoozed:
        statusColor = Colors.orange;
        statusIcon = Icons.snooze;
        break;
      case DoseStatus.overdue:
        statusColor = colorScheme.error;
        statusIcon = Icons.warning;
        break;
      case DoseStatus.pending:
        statusColor = colorScheme.onSurface.withValues(alpha: 0.6);
        statusIcon = Icons.schedule;
        break;
    }

    return ListTile(
      leading: Icon(statusIcon, color: statusColor),
      title: Text(dose.scheduleName),
      subtitle: Text('${dose.medicationName} • ${dose.doseDescription}'),
      trailing: Text(
        dose.timeFormatted,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => _onDoseTapInternal(dose),
    );
  }
}

/// Bottom sheet showing dose details
class _DoseDetailBottomSheet extends StatefulWidget {
  final CalculatedDose dose;
  final void Function(String? notes) onMarkTaken;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final VoidCallback onDelete;

  const _DoseDetailBottomSheet({
    required this.dose,
    required this.onMarkTaken,
    required this.onSnooze,
    required this.onSkip,
    required this.onDelete,
  });

  @override
  State<_DoseDetailBottomSheet> createState() => _DoseDetailBottomSheetState();
}

class _DoseDetailBottomSheetState extends State<_DoseDetailBottomSheet> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.dose.existingLog?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotesOnly() async {
    if (widget.dose.existingLog == null) return;

    try {
      // Update the existing log with new notes
      final updatedLog = DoseLog(
        id: widget.dose.existingLog!.id,
        scheduleId: widget.dose.existingLog!.scheduleId,
        scheduleName: widget.dose.existingLog!.scheduleName,
        medicationId: widget.dose.existingLog!.medicationId,
        medicationName: widget.dose.existingLog!.medicationName,
        scheduledTime: widget.dose.existingLog!.scheduledTime,
        doseValue: widget.dose.existingLog!.doseValue,
        doseUnit: widget.dose.existingLog!.doseUnit,
        action: widget.dose.existingLog!.action,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(updatedLog);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notes saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving notes: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(kBorderRadiusLarge),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.dose.scheduleName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.dose.doseDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoRow(
                      context,
                      'Time',
                      widget.dose.timeFormatted,
                      Icons.access_time,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Date',
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(widget.dose.scheduledTime),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 12),
                    // Compact status section
                    _buildStatusSection(context, widget.dose, colorScheme),
                    const SizedBox(height: 16),
                    // Action buttons - always visible with state-based styling
                    _buildActionButtons(context, widget.dose, colorScheme),
                    const SizedBox(height: 16),
                    // Notes field (always visible)
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add any notes about this dose...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.note_outlined),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    // Save notes button (for doses with existing logs)
                    if (widget.dose.existingLog != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _saveNotesOnly();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save Notes'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    // Note for doses with logs
                    if (widget.dose.existingLog != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tap status above to change',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    CalculatedDose dose,
    ColorScheme colorScheme,
  ) {
    final statusColor = _getStatusColor(dose.status, colorScheme);
    final statusIcon = _getStatusIcon(dose.status);
    final statusText = _getStatusText(dose.status);

    return Row(
      children: [
        Icon(statusIcon, size: 20, color: statusColor),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    CalculatedDose dose,
    ColorScheme colorScheme,
  ) {
    final status = dose.status;

    // Snooze only enabled for pending doses
    final snoozeEnabled = status == DoseStatus.pending;

    // Highlight based on current status
    final takePrimary = status == DoseStatus.taken;
    final skipPrimary = status == DoseStatus.skipped;

    return Row(
      children: [
        // Take button - toggles between taken and pending/overdue
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (status == DoseStatus.taken) {
                // Toggle back to pending/overdue
                widget.onDelete();
              } else {
                // Mark as taken
                widget.onMarkTaken(
                  _notesController.text.isEmpty ? null : _notesController.text,
                );
              }
            },
            icon: Icon(
              Icons.check_circle,
              size: 18,
              color: takePrimary ? Colors.green : null,
            ),
            label: const Text('Take'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: takePrimary ? Colors.green : null,
              foregroundColor: takePrimary ? Colors.white : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Snooze button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: snoozeEnabled
                ? () {
                    Navigator.pop(context);
                    widget.onSnooze();
                  }
                : null,
            icon: const Icon(Icons.snooze, size: 18),
            label: const Text('Snooze'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Skip button - toggles between skipped and pending/overdue
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (status == DoseStatus.skipped) {
                // Toggle back to pending/overdue
                widget.onDelete();
              } else {
                // Mark as skipped
                widget.onSkip();
              }
            },
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Skip'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: skipPrimary ? colorScheme.errorContainer : null,
              foregroundColor: skipPrimary
                  ? colorScheme.onErrorContainer
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(DoseStatus status, ColorScheme colorScheme) {
    switch (status) {
      case DoseStatus.taken:
        return colorScheme.primary; // Blue/Primary
      case DoseStatus.skipped:
        return Colors.grey; // Grey for canceled/skipped
      case DoseStatus.snoozed:
        return Colors.orange; // Orange for snoozed
      case DoseStatus.overdue:
        return colorScheme.error; // Red for missed/overdue
      case DoseStatus.pending:
        return colorScheme.onSurface.withValues(alpha: 0.6); // Muted for pending
    }
  }

  String _getStatusText(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.skipped:
        return 'Skipped';
      case DoseStatus.snoozed:
        return 'Snoozed';
      case DoseStatus.overdue:
        return 'Overdue';
      case DoseStatus.pending:
        return 'Pending';
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Icons.check_circle;
      case DoseStatus.skipped:
        return Icons.cancel;
      case DoseStatus.snoozed:
        return Icons.snooze;
      case DoseStatus.overdue:
        return Icons.warning;
      case DoseStatus.pending:
        return Icons.schedule;
    }
  }
}

/// Variant of the calendar widget.
enum CalendarVariant {
  /// Full-featured calendar with all controls.
  full,

  /// Compact calendar without view toggle (for detail pages).
  compact,

  /// Minimal calendar (today only, for home page).
  mini,
}
