import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_calculation_service.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_day_view.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_header.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_month_view.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_week_view.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';
import 'package:dosifi_v5/src/widgets/dose_summary_row.dart';
import 'package:dosifi_v5/src/widgets/up_next_dose_card.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
    this.showSelectedDayPanel = true,
    this.showUpNextCard = true,
    this.requireHourSelectionInDayView = false,
    super.key,
  });

  final CalendarVariant variant;
  final CalendarView defaultView;
  final String? scheduleId;
  final String? medicationId;
  final double? height;
  final DateTime? startDate;
  final void Function(CalculatedDose dose)? onDoseTap;
  final bool showSelectedDayPanel;
  final bool showUpNextCard;
  final bool requireHourSelectionInDayView;

  @override
  State<DoseCalendarWidget> createState() => _DoseCalendarWidgetState();
}

class _DoseCalendarWidgetState extends State<DoseCalendarWidget> {
  late CalendarView _currentView;
  late DateTime _currentDate;
  DateTime? _selectedDate; // Track selected date for detail panel
  int? _selectedHour;
  List<CalculatedDose> _doses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentView = widget.defaultView;
    _currentDate = widget.startDate ?? DateTime.now();
    // Auto-select today for month/week views to show today's doses
    if (_currentView != CalendarView.day) {
      _selectedDate = widget.startDate ?? DateTime.now();
    } else if (widget.requireHourSelectionInDayView) {
      _selectedHour = DateTime.now().hour;
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
      if (view == CalendarView.day) {
        _currentDate = _selectedDate ?? DateTime.now();
        _selectedDate = null;
        if (widget.requireHourSelectionInDayView) {
          _selectedHour ??= DateTime.now().hour;
        } else {
          _selectedHour = null;
        }
      } else {
        _selectedDate ??= DateTime.now();
        _selectedHour = null;
      }
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
      if (_currentView == CalendarView.day &&
          widget.requireHourSelectionInDayView) {
        _selectedHour = today.hour;
      }
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
    // In Week view, tapping anything on a day should switch to Day view.
    // In Month view, keep the existing behavior: show the selected-day list
    // panel below the calendar.
    final shouldSwitchToDayView = _currentView == CalendarView.week;

    setState(() {
      if (shouldSwitchToDayView) {
        _currentView = CalendarView.day;
        _currentDate = date;
        _selectedDate = null;
        if (widget.requireHourSelectionInDayView) {
          _selectedHour ??= DateTime.now().hour;
        } else {
          _selectedHour = null;
        }
      } else {
        _selectedDate = date;
      }
    });

    if (shouldSwitchToDayView) {
      _loadDoses();
    }
  }

  void _onDoseTapInternal(CalculatedDose dose) {
    if (widget.onDoseTap != null) {
      widget.onDoseTap!(dose);
      return;
    }
    _openDoseActionSheetFor(dose);
  }

  void _openDoseActionSheetFor(
    CalculatedDose dose, {
    DoseStatus? initialStatus,
  }) {
    DoseActionSheet.show(
      context,
      dose: dose,
      initialStatus: initialStatus,
      onMarkTaken: (request) => _markDoseAsTaken(dose, request),
      onSnooze: (request) => _snoozeDose(dose, request),
      onSkip: (request) => _skipDose(dose, request),
      onDelete: (request) => _deleteDoseLog(dose),
    );
  }

  Future<void> _markDoseAsTaken(
    CalculatedDose dose,
    DoseActionSheetSaveRequest request,
  ) async {
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
      actionTime: request.actionTime,
      doseValue: dose.doseValue,
      doseUnit: dose.doseUnit,
      action: DoseAction.taken,
      actualDoseValue: request.actualDoseValue,
      actualDoseUnit: request.actualDoseUnit,
      notes: request.notes?.isEmpty ?? true ? null : request.notes,
    );

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(log);

      // Deduct medication stock
      await _deductStock(
        dose,
        doseValueOverride: request.actualDoseValue,
        doseUnitOverride: request.actualDoseUnit,
        preferDoseValue: request.actualDoseValue != null,
      );

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

  Future<void> _snoozeDose(
    CalculatedDose dose,
    DoseActionSheetSaveRequest request,
  ) async {
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
      actionTime: request.actionTime,
      doseValue: dose.doseValue,
      doseUnit: dose.doseUnit,
      action: DoseAction.snoozed,
      actualDoseValue: request.actualDoseValue,
      actualDoseUnit: request.actualDoseUnit,
      notes: request.notes?.isEmpty ?? true ? null : request.notes,
    );

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsert(log);

      // TODO: Reschedule notification for 15 minutes later

      await _loadDoses();

      if (mounted) {
        final now = DateTime.now();
        final sameDay =
            request.actionTime.year == now.year &&
            request.actionTime.month == now.month &&
            request.actionTime.day == now.day;
        final time = TimeOfDay.fromDateTime(request.actionTime).format(context);
        final label = sameDay
            ? 'Dose snoozed until $time'
            : 'Dose snoozed until ${MaterialLocalizations.of(context).formatMediumDate(request.actionTime)} • $time';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(label)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _skipDose(
    CalculatedDose dose,
    DoseActionSheetSaveRequest request,
  ) async {
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
      actionTime: request.actionTime,
      doseValue: dose.doseValue,
      doseUnit: dose.doseUnit,
      action: DoseAction.skipped,
      actualDoseValue: request.actualDoseValue,
      actualDoseUnit: request.actualDoseUnit,
      notes: request.notes?.isEmpty ?? true ? null : request.notes,
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
        final existing = dose.existingLog!;
        final oldDoseValue = existing.actualDoseValue ?? existing.doseValue;
        final oldDoseUnit = existing.actualDoseUnit ?? existing.doseUnit;
        await _restoreStock(
          dose,
          doseValueOverride: oldDoseValue,
          doseUnitOverride: oldDoseUnit,
          preferDoseValue: existing.actualDoseValue != null,
        );
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
  Future<bool> _deductStock(
    CalculatedDose dose, {
    double? doseValueOverride,
    String? doseUnitOverride,
    bool preferDoseValue = false,
  }) async {
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

      final effectiveDoseValue = doseValueOverride ?? dose.doseValue;
      final effectiveDoseUnit = doseUnitOverride ?? dose.doseUnit;
      final delta = MedicationStockAdjustment.tryCalculateStockDelta(
        medication: med,
        schedule: schedule,
        doseValue: effectiveDoseValue,
        doseUnit: effectiveDoseUnit,
        preferDoseValue: preferDoseValue,
      );

      if (delta == null || delta <= 0) {
        return true; // Can't calculate delta, skip
      }

      await medBox.put(
        med.id,
        MedicationStockAdjustment.deduct(medication: med, delta: delta),
      );

      return true;
    } catch (e) {
      debugPrint('[DoseCalendar] Failed to deduct stock: $e');
      return false;
    }
  }

  /// Restores medication stock when a taken dose is reset
  Future<bool> _restoreStock(
    CalculatedDose dose, {
    double? doseValueOverride,
    String? doseUnitOverride,
    bool preferDoseValue = false,
  }) async {
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

      final effectiveDoseValue = doseValueOverride ?? dose.doseValue;
      final effectiveDoseUnit = doseUnitOverride ?? dose.doseUnit;
      final delta = MedicationStockAdjustment.tryCalculateStockDelta(
        medication: med,
        schedule: schedule,
        doseValue: effectiveDoseValue,
        doseUnit: effectiveDoseUnit,
        preferDoseValue: preferDoseValue,
      );

      if (delta == null || delta <= 0) {
        return true; // Can't calculate delta
      }

      await medBox.put(
        med.id,
        MedicationStockAdjustment.restore(medication: med, delta: delta),
      );

      return true;
    } catch (e) {
      debugPrint('[DoseCalendar] Failed to restore stock: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHeader = widget.variant != CalendarVariant.mini;
    final showViewToggle = widget.variant == CalendarVariant.full;

    CalculatedDose? nextDose;
    if (_doses.isNotEmpty) {
      final attention = _doses
          .where((d) => d.status.requiresAttention)
          .toList();
      attention.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      if (attention.isNotEmpty) {
        nextDose = attention.first;
      } else {
        final pending = _doses
            .where((d) => d.status == DoseStatus.pending)
            .toList();
        pending.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        if (pending.isNotEmpty) nextDose = pending.first;
      }
    }

    Schedule? upNextSchedule;
    Medication? upNextMedication;
    String? upNextStrengthLabel;
    String? upNextDoseMetrics;

    if (nextDose != null) {
      final scheduleBox = Hive.box<Schedule>('schedules');
      upNextSchedule = scheduleBox.get(nextDose.scheduleId);

      final medId = upNextSchedule?.medicationId;
      if (medId != null) {
        final medBox = Hive.box<Medication>('medications');
        upNextMedication = medBox.get(medId);
      }

      final med = upNextMedication;
      final schedule = upNextSchedule;
      if (med != null && schedule != null) {
        upNextStrengthLabel =
            MedicationDisplayHelpers.strengthOrConcentrationLabel(med);
        upNextDoseMetrics = MedicationDisplayHelpers.doseMetricsSummary(
          med,
          doseTabletQuarters: schedule.doseTabletQuarters,
          doseCapsules: schedule.doseCapsules,
          doseSyringes: schedule.doseSyringes,
          doseVials: schedule.doseVials,
          doseMassMcg: schedule.doseMassMcg?.toDouble(),
          doseVolumeMicroliter: schedule.doseVolumeMicroliter?.toDouble(),
          syringeUnits: schedule.doseIU?.toDouble(),
        );
      }
    }

    Widget buildBody({double? panelHeight}) {
      return Column(
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
          if (widget.variant == CalendarVariant.full && widget.showUpNextCard)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kSpacingL,
                kSpacingS,
                kSpacingL,
                kSpacingS,
              ),
              child: UpNextDoseCard(
                dose: nextDose,
                onDoseTap: _onDoseTapInternal,
                onQuickAction: (status) {
                  final d = nextDose;
                  if (d == null) return;
                  if (widget.onDoseTap != null) {
                    widget.onDoseTap!(d);
                    return;
                  }
                  _openDoseActionSheetFor(d, initialStatus: status);
                },
                showMedicationName: true,
                medicationName:
                    upNextMedication?.name ?? nextDose?.medicationName,
                strengthOrConcentrationLabel: upNextStrengthLabel,
                doseMetrics: upNextDoseMetrics,
              ),
            ),
          // Calendar view
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (widget.variant == CalendarVariant.full)
            Expanded(child: _buildCurrentView())
          else if (_currentView == CalendarView.day)
            Expanded(child: _buildCurrentView())
          else
            Flexible(fit: FlexFit.loose, child: _buildCurrentView()),
          if (widget.requireHourSelectionInDayView &&
              _currentView == CalendarView.day)
            if (widget.variant == CalendarVariant.full && panelHeight != null)
              SizedBox(height: panelHeight, child: _buildSelectedHourPanel())
            else
              Expanded(child: _buildSelectedHourPanel()),
          // Selected date schedules (if date selected, only for week/month views)
          if (_selectedDate != null &&
              _currentView != CalendarView.day &&
              widget.showSelectedDayPanel)
            if (widget.variant == CalendarVariant.compact)
              _buildSelectedDayPanel()
            else if (widget.variant == CalendarVariant.full &&
                panelHeight != null)
              SizedBox(height: panelHeight, child: _buildSelectedDayPanel())
            else
              Expanded(child: _buildSelectedDayPanel()),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null;
        final effectiveHeight = widget.height ?? boundedHeight;
        final panelHeight =
            (widget.variant == CalendarVariant.full && effectiveHeight != null)
            ? effectiveHeight * kCalendarSelectedDayPanelHeightRatio
            : null;

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
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  )
                : null,
          ),
          child: buildBody(panelHeight: panelHeight),
        );
      },
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CalendarView.day:
        return CalendarDayView(
          date: _currentDate,
          doses: _doses,
          onDoseTap: widget.requireHourSelectionInDayView
              ? null
              : _onDoseTapInternal,
          selectedHour: _selectedHour,
          onHourTap: widget.requireHourSelectionInDayView
              ? (hour) => setState(() => _selectedHour = hour)
              : null,
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

  Widget _buildSelectedHourPanel() {
    final selectedHour = _selectedHour;
    if (selectedHour == null) return const SizedBox.shrink();

    final dayDoses = _doses.where((dose) {
      return dose.scheduledTime.year == _currentDate.year &&
          dose.scheduledTime.month == _currentDate.month &&
          dose.scheduledTime.day == _currentDate.day &&
          dose.scheduledTime.hour == selectedHour;
    }).toList();

    dayDoses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final listBottomPadding = safeBottom + kSpacingL;

    return Padding(
      padding: const EdgeInsets.only(top: kSpacingS),
      child: Container(
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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingL,
                vertical: kSpacingM,
              ),
              child: Text(
                'Hour: ${_formatSelectedHour(selectedHour)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: dayDoses.isEmpty
                  ? Center(
                      child: Text(
                        'No doses scheduled',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(
                            alpha: kOpacityLow,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: listBottomPadding),
                      itemCount: dayDoses.length,
                      itemBuilder: (context, index) {
                        final dose = dayDoses[index];

                        final schedule = Hive.box<Schedule>(
                          'schedules',
                        ).get(dose.scheduleId);
                        final med = (schedule?.medicationId != null)
                            ? Hive.box<Medication>(
                                'medications',
                              ).get(schedule!.medicationId)
                            : null;

                        if (schedule != null && med != null) {
                          final strengthLabel =
                              MedicationDisplayHelpers.strengthOrConcentrationLabel(
                                med,
                              );

                          final metrics =
                              MedicationDisplayHelpers.doseMetricsSummary(
                                med,
                                doseTabletQuarters: schedule.doseTabletQuarters,
                                doseCapsules: schedule.doseCapsules,
                                doseSyringes: schedule.doseSyringes,
                                doseVials: schedule.doseVials,
                                doseMassMcg: schedule.doseMassMcg?.toDouble(),
                                doseVolumeMicroliter: schedule
                                    .doseVolumeMicroliter
                                    ?.toDouble(),
                                syringeUnits: schedule.doseIU?.toDouble(),
                              );

                          if (strengthLabel.trim().isNotEmpty &&
                              metrics.trim().isNotEmpty) {
                            return DoseCard(
                              dose: dose,
                              medicationName: med.name,
                              strengthOrConcentrationLabel: strengthLabel,
                              doseMetrics: metrics,
                              isActive: schedule.isActive,
                              onQuickAction: (status) {
                                if (widget.onDoseTap != null) {
                                  widget.onDoseTap!(dose);
                                  return;
                                }
                                _openDoseActionSheetFor(
                                  dose,
                                  initialStatus: status,
                                );
                              },
                              onTap: () => _onDoseTapInternal(dose),
                            );
                          }
                        }

                        return DoseSummaryRow(
                          dose: dose,
                          showMedicationName: true,
                          onTap: () => _onDoseTapInternal(dose),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSelectedHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
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

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final listBottomPadding = safeBottom + kSpacingL;

    Widget buildDoseCardFor(CalculatedDose dose) {
      final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
      final med = (schedule?.medicationId != null)
          ? Hive.box<Medication>('medications').get(schedule!.medicationId)
          : null;

      final strengthLabel = med != null
          ? MedicationDisplayHelpers.strengthOrConcentrationLabel(med)
          : '';

      final metrics = med != null && schedule != null
          ? MedicationDisplayHelpers.doseMetricsSummary(
              med,
              doseTabletQuarters: schedule.doseTabletQuarters,
              doseCapsules: schedule.doseCapsules,
              doseSyringes: schedule.doseSyringes,
              doseVials: schedule.doseVials,
              doseMassMcg: schedule.doseMassMcg?.toDouble(),
              doseVolumeMicroliter: schedule.doseVolumeMicroliter?.toDouble(),
              syringeUnits: schedule.doseIU?.toDouble(),
            )
          : '${dose.doseValue} ${dose.doseUnit}';

      return DoseCard(
        dose: dose,
        medicationName: med?.name ?? dose.medicationName,
        strengthOrConcentrationLabel: strengthLabel,
        doseMetrics: metrics,
        isActive: schedule?.isActive ?? true,
        onQuickAction: (status) {
          if (widget.onDoseTap != null) {
            widget.onDoseTap!(dose);
            return;
          }
          _openDoseActionSheetFor(dose, initialStatus: status);
        },
        onTap: () => _onDoseTapInternal(dose),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: kSpacingS),
      child: Container(
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
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingM,
                vertical: kSpacingS,
              ),
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
            Expanded(
              child: dayDoses.isEmpty
                  ? Center(
                      child: Text(
                        'No doses scheduled',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(
                            alpha: kOpacityLow,
                          ),
                        ),
                      ),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: listBottomPadding),
                        itemCount: dayDoses.length,
                        itemBuilder: (context, index) {
                          final dose = dayDoses[index];
                          return buildDoseCardFor(dose);
                        },
                      ),
                    ),
            ),
          ],
        ),
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

    final formatted = MaterialLocalizations.of(
      context,
    ).formatFullDate(_selectedDate!);

    return isToday ? 'Today — $formatted' : formatted;
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
