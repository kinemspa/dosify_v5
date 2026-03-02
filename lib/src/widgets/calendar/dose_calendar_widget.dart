import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/core/notifications/notification_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_calculation_service.dart';
import 'package:dosifi_v5/src/features/schedules/data/dose_log_repository.dart';
import 'package:dosifi_v5/src/features/schedules/data/schedule_scheduler.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log_ids.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_day_view.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_header.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_month_view.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_week_view.dart';
import 'package:dosifi_v5/src/widgets/dose_card.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';

import 'package:dosifi_v5/src/widgets/up_next_dose_card.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_shared.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_stage_panel.dart';
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
    this.showHeaderOverride,
    this.showViewToggleOverride,
    this.embedInParentCard = false,
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

  /// Overrides the default header visibility derived from [variant].
  ///
  /// Useful for embedded contexts like Home where [variant] is [CalendarVariant.mini]
  /// but Month/Week switching is still desired.
  final bool? showHeaderOverride;

  /// Overrides the default view-toggle visibility derived from [variant].
  final bool? showViewToggleOverride;

  /// When true, the widget avoids drawing its own card/border background.
  /// Intended for embedding inside parent cards/sections.
  final bool embedInParentCard;

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
  bool _showSelectedDayStageDownHint = false;

  final ScrollController _selectedDayScrollController = ScrollController();
  final DraggableScrollableController _selectedDayStageController =
      DraggableScrollableController();

  /// Cached from the LayoutBuilder so _snapSelectedDayStageToInitial uses
  /// the exact same geometry as the DraggableScrollableSheet's initialChildSize.
  double? _cachedStageInitialRatio;

  /// Cached locale first-day-of-week preference, updated each build.
  bool _cachedStartWeekOnMonday = false;

  ValueListenable<Box<DoseLog>>? _doseLogsListenable;
  ValueListenable<Box<Schedule>>? _schedulesListenable;
  Timer? _reloadDebounce;

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
    // NOTE: _loadDoses() is deferred to didChangeDependencies so that
    // MaterialLocalizations.of(context) (used by _getDateRange) is safe to call.

    // Auto-refresh calendar when schedules or dose logs change.
    // This keeps the calendar up-to-date when a dose is marked taken/skipped/etc.
    _doseLogsListenable = Hive.box<DoseLog>('dose_logs').listenable();
    _doseLogsListenable!.addListener(_scheduleReload);

    _schedulesListenable = Hive.box<Schedule>('schedules').listenable();
    _schedulesListenable!.addListener(_scheduleReload);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always schedule a reload on dependency changes (including first build and
    // re-navigation). The 120 ms debounce prevents excessive rebuilds from rapid
    // MediaQuery/Theme change notifications. At 120 ms the widget has already
    // completed its first frame so MaterialLocalizations.of(context) is safe.
    _scheduleReload();
  }

  @override
  void didUpdateWidget(DoseCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheduleId != widget.scheduleId ||
        oldWidget.medicationId != widget.medicationId) {
      _loadDoses();
    }
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _doseLogsListenable?.removeListener(_scheduleReload);
    _schedulesListenable?.removeListener(_scheduleReload);
    _selectedDayScrollController.dispose();
    _selectedDayStageController.dispose();
    super.dispose();
  }

  double _selectedDayStageInitialRatio() {
    return switch (_currentView) {
      CalendarView.day => kCalendarSelectedDayPanelHeightRatioDay,
      CalendarView.week => kCalendarSelectedDayPanelHeightRatioWeek,
      CalendarView.month => kCalendarSelectedDayPanelHeightRatioMonth,
    };
  }

  bool _showHeaderForCurrentVariant() {
    return widget.showHeaderOverride ??
        (widget.variant != CalendarVariant.mini);
  }

  double _currentEffectiveHeightForStage() {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final h = renderObject.size.height;
      if (h.isFinite && h > 0) return h;
    }

    final fallbackHeight = switch (widget.variant) {
      CalendarVariant.mini => kHomeMiniCalendarHeight,
      CalendarVariant.compact => kDetailCompactCalendarHeight,
      CalendarVariant.full => MediaQuery.sizeOf(context).height * 0.75,
    };
    return widget.height ?? fallbackHeight;
  }

  void _snapSelectedDayStageToInitial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_selectedDayStageController.isAttached) return;
      // Use the cached ratio from LayoutBuilder to guarantee the same geometry
      // as DraggableScrollableSheet's initialChildSize. Fall back to a fresh
      // computation only when the cache is not yet available.
      final initial =
          _cachedStageInitialRatio ??
          (widget.variant == CalendarVariant.full
              ? _selectedDayStageInitialRatioForFullHeight(
                  _currentEffectiveHeightForStage(),
                  showHeader: _showHeaderForCurrentVariant(),
                  showUpNextCard: widget.showUpNextCard,
                )
              : _selectedDayStageInitialRatio());
      _selectedDayStageController.animateTo(
        initial,
        duration: kAnimationNormal,
        curve: kCurveEmphasized,
      );
    });
  }

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _loadDoses();
    });
  }

  void _updateSelectedDayStageDownHint(ScrollMetrics metrics) {
    final shouldShow = metrics.maxScrollExtent > (metrics.pixels + 0.5);
    if (_showSelectedDayStageDownHint == shouldShow) return;
    if (!mounted) return;
    setState(() => _showSelectedDayStageDownHint = shouldShow);
  }

  Widget _wrapWithCenteredDownScrollHint({
    required Widget child,
    required bool showHint,
    required ValueChanged<ScrollMetrics> onMetrics,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical) {
              onMetrics(notification.metrics);
            }
            return false;
          },
          child: child,
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              opacity: showHint ? 1 : 0,
              duration: kAnimationFast,
              curve: kCurveSnappy,
              child: Padding(
                padding: kCalendarStageScrollHintPadding,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: kCalendarStageScrollHintIconSize,
                  color: cs.onSurfaceVariant.withValues(
                    alpha: kOpacityMediumHigh,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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

        // Match CalendarMonthView: 6-week (42 day) grid, respecting locale
        // first-day-of-week preference.
        final localizations = MaterialLocalizations.of(context);
        final startOnMonday = localizations.firstDayOfWeekIndex == 1;

        final weekday = firstDayOfMonth.weekday; // 1-7 (Mon-Sun)
        final daysToSubtract = startOnMonday
            ? (weekday + 6) % 7
            : weekday % 7;
        final start = firstDayOfMonth.subtract(Duration(days: daysToSubtract));

        final end = start.add(const Duration(days: 42));

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

    // When returning to week/month, ensure the stage snaps back to its
    // initial "hug the calendar" position.
    if (view != CalendarView.day && widget.variant == CalendarVariant.full) {
      _snapSelectedDayStageToInitial();
    }
  }

  void _onPreviousPressed() {
    setState(() {
      switch (_currentView) {
        case CalendarView.day:
          _currentDate = _currentDate.subtract(const Duration(days: 1));
          break;
        case CalendarView.week:
          _currentDate = _currentDate.subtract(const Duration(days: 7));
          if (_selectedDate != null) {
            _selectedDate = _selectedDate!.subtract(const Duration(days: 7));
            _currentDate = _selectedDate!;
          }
          break;
        case CalendarView.month:
          if (_selectedDate != null) {
            final targetMonth = DateTime(
              _currentDate.year,
              _currentDate.month - 1,
              1,
            );
            _selectedDate = _shiftSelectedDateIntoTargetMonth(
              _selectedDate!,
              -1,
              targetMonth,
            );
            _currentDate = _selectedDate ?? targetMonth;
          } else {
            _currentDate = DateTime(
              _currentDate.year,
              _currentDate.month - 1,
              1,
            );
          }
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
          if (_selectedDate != null) {
            _selectedDate = _selectedDate!.add(const Duration(days: 7));
            _currentDate = _selectedDate!;
          }
          break;
        case CalendarView.month:
          if (_selectedDate != null) {
            final targetMonth = DateTime(
              _currentDate.year,
              _currentDate.month + 1,
              1,
            );
            _selectedDate = _shiftSelectedDateIntoTargetMonth(
              _selectedDate!,
              1,
              targetMonth,
            );
            _currentDate = _selectedDate ?? targetMonth;
          } else {
            _currentDate = DateTime(
              _currentDate.year,
              _currentDate.month + 1,
              1,
            );
          }
          break;
      }
    });
    _loadDoses();
  }

  DateTime _shiftMonthKeepingDay(DateTime source, int monthDelta) {
    final targetYear = source.year + ((source.month - 1 + monthDelta) ~/ 12);
    final targetMonth = ((source.month - 1 + monthDelta) % 12) + 1;
    final maxDay = DateUtils.getDaysInMonth(targetYear, targetMonth);
    final targetDay = source.day > maxDay ? maxDay : source.day;
    return DateTime(targetYear, targetMonth, targetDay);
  }

  DateTime? _shiftSelectedDateIntoTargetMonth(
    DateTime selected,
    int monthDelta,
    DateTime targetMonthDate,
  ) {
    final shifted = _shiftMonthKeepingDay(selected, monthDelta);
    final isInTargetMonth =
        shifted.year == targetMonthDate.year &&
        shifted.month == targetMonthDate.month;
    return isInTargetMonth ? shifted : null;
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

    if (_currentView != CalendarView.day &&
        widget.variant == CalendarVariant.full) {
      _snapSelectedDayStageToInitial();
    }
  }

  void _onDateChanged(DateTime date) {
    final previousDate = _currentDate;
    setState(() {
      if (_selectedDate != null) {
        if (_currentView == CalendarView.month) {
          final monthDelta =
              (date.year - previousDate.year) * 12 +
              (date.month - previousDate.month);
          if (monthDelta != 0) {
            _selectedDate = _shiftSelectedDateIntoTargetMonth(
              _selectedDate!,
              monthDelta,
              date,
            );
          }
        } else if (_currentView == CalendarView.week) {
          final previousDay = DateTime(
            previousDate.year,
            previousDate.month,
            previousDate.day,
          );
          final targetDay = DateTime(date.year, date.month, date.day);
          final dayDelta = targetDay.difference(previousDay).inDays;
          if (dayDelta != 0) {
            _selectedDate = _selectedDate!.add(Duration(days: dayDelta));
          }
        }
      }
      _currentDate = date;
    });
    _loadDoses();

    if (_selectedDate != null &&
        _currentView != CalendarView.day &&
        widget.variant == CalendarVariant.full) {
      _snapSelectedDayStageToInitial();
    }
  }

  void _onDayTap(DateTime date) {
    DateTime? nextSelected;
    setState(() {
      // In Week/Month views, tapping a date selects that day.
      // Day view is only entered via explicit view switching.
      final selected = _selectedDate;
      final isSameDay =
          selected != null &&
          selected.year == date.year &&
          selected.month == date.month &&
          selected.day == date.day;

      nextSelected = isSameDay ? null : date;
      _selectedDate = nextSelected;
      _currentDate = date;
    });

    // When selecting a day, snap the stage to the "hug calendar" position.
    if (nextSelected != null && widget.variant == CalendarVariant.full) {
      _snapSelectedDayStageToInitial();
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
      onMarkLogged: (request) => _markDoseAsLogged(dose, request),
      onSnooze: (request) => _snoozeDose(dose, request),
      onSkip: (request) => _skipDose(dose, request),
      onDelete: (request) => _deleteDoseLog(dose),
    );
  }

  Future<void> _markDoseAsLogged(
    CalculatedDose dose,
    DoseActionSheetSaveRequest request,
  ) async {
    final logId = DoseLogIds.occurrenceId(
      scheduleId: dose.scheduleId,
      scheduledTime: dose.scheduledTime,
    );
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
      action: DoseAction.logged,
      actualDoseValue: request.actualDoseValue,
      actualDoseUnit: request.actualDoseUnit,
      notes: request.notes?.isEmpty ?? true ? null : request.notes,
    );

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.upsertOccurrence(log);

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
        showAppSnackBar(context, 'Dose marked as taken');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error: $e');
      }
    }
  }

  Future<void> _cancelNotificationForDose(CalculatedDose dose) async {
    try {
      await NotificationService.cancel(
        ScheduleScheduler.doseNotificationIdFor(
          dose.scheduleId,
          dose.scheduledTime,
        ),
      );
      for (final overdueId in ScheduleScheduler.overdueNotificationIdsFor(
        dose.scheduleId,
        dose.scheduledTime,
      )) {
        await NotificationService.cancel(overdueId);
      }
    } catch (e) {
      debugPrint('[DoseCalendar] Failed to cancel notification: $e');
    }
  }

  Future<void> _snoozeDose(
    CalculatedDose dose,
    DoseActionSheetSaveRequest request,
  ) async {
    final logId = DoseLogIds.occurrenceId(
      scheduleId: dose.scheduleId,
      scheduledTime: dose.scheduledTime,
    );
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
      await repo.upsertOccurrence(log);

      await _cancelNotificationForDose(dose);
      final when = request.actionTime;
      if (when.isAfter(DateTime.now())) {
        final time = DateTimeFormatter.formatTime(context, when);
        await NotificationService.scheduleAtAlarmClock(
          ScheduleScheduler.doseNotificationIdFor(
            dose.scheduleId,
            dose.scheduledTime,
          ),
          when,
          title: dose.medicationName,
          body: 'Snoozed until $time',
          payload:
              'dose:${dose.scheduleId}:${dose.scheduledTime.millisecondsSinceEpoch}',
          actions: NotificationService.upcomingDoseActions,
          expandedLines: <String>['Snoozed until $time'],
        );
      }

      await _loadDoses();

      if (mounted) {
        final now = DateTime.now();
        final sameDay =
            request.actionTime.year == now.year &&
            request.actionTime.month == now.month &&
            request.actionTime.day == now.day;
        final time = DateTimeFormatter.formatTime(context, request.actionTime);
        final label = sameDay
            ? 'Dose snoozed until $time'
            : 'Dose snoozed until ${MaterialLocalizations.of(context).formatMediumDate(request.actionTime)} | $time';
        showAppSnackBar(context, label);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error: $e');
      }
    }
  }

  Future<void> _skipDose(
    CalculatedDose dose,
    DoseActionSheetSaveRequest request,
  ) async {
    final logId = DoseLogIds.occurrenceId(
      scheduleId: dose.scheduleId,
      scheduledTime: dose.scheduledTime,
    );
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
      await repo.upsertOccurrence(log);

      // Cancel the notification for this dose
      await _cancelNotificationForDose(dose);

      await _loadDoses();

      if (mounted) {
        showAppSnackBar(context, 'Dose skipped');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error: $e');
      }
    }
  }

  Future<void> _deleteDoseLog(CalculatedDose dose) async {
    if (dose.existingLog == null) return;

    try {
      final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
      await repo.deleteOccurrence(
        scheduleId: dose.scheduleId,
        scheduledTime: dose.scheduledTime,
      );

      // Cancel any scheduled reminder for this occurrence (best-effort).
      await _cancelNotificationForDose(dose);

      // Restore stock if the dose was previously taken
      if (dose.existingLog!.action == DoseAction.logged) {
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
        showAppSnackBar(context, 'Dose reset to pending');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error: $e');
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

      final updated = MedicationStockAdjustment.deduct(
        medication: med,
        delta: delta,
      );
      await medBox.put(med.id, updated);
      await LowStockNotifier.handleStockChange(before: med, after: updated);

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

      final updated = MedicationStockAdjustment.restore(
        medication: med,
        delta: delta,
      );
      await medBox.put(med.id, updated);
      await LowStockNotifier.handleStockChange(before: med, after: updated);

      return true;
    } catch (e) {
      debugPrint('[DoseCalendar] Failed to restore stock: $e');
      return false;
    }
  }

  Widget _buildSelectDayPrompt(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingM,
        vertical: kSpacingS,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kOpacityMinimal),
          width: kBorderWidthThin,
        ),
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      child: Text(
        'Select a day to view doses.',
        textAlign: TextAlign.center,
        style: helperTextStyle(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cache locale first-day-of-week for helper methods that run outside build.
    _cachedStartWeekOnMonday =
        MaterialLocalizations.of(context).firstDayOfWeekIndex == 1;

    final showHeader = _showHeaderForCurrentVariant();
    final showViewToggle =
        widget.showViewToggleOverride ??
        (widget.variant == CalendarVariant.full);

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
        upNextDoseMetrics = schedule.displayMetrics(med);
      }
    }

    Widget buildBody({double? panelHeight, required double effectiveHeight}) {
      final showSelectedDayStage =
          widget.showSelectedDayPanel &&
          _selectedDate != null &&
          _currentView != CalendarView.day;
      final showSelectDayPrompt =
          widget.showSelectedDayPanel &&
          _selectedDate == null &&
          _currentView != CalendarView.day;

      final stageInitialRatio = widget.variant == CalendarVariant.full
          ? _selectedDayStageInitialRatioForFullHeight(
              effectiveHeight,
              showHeader: showHeader,
              showUpNextCard:
                  widget.variant == CalendarVariant.full &&
                  widget.showUpNextCard,
            )
          : null;

      // Keep the cached ratio in sync so _snapSelectedDayStageToInitial uses
      // the same geometry as initialChildSize (no double-calculation drift).
      if (stageInitialRatio != null && stageInitialRatio != _cachedStageInitialRatio) {
        // Schedule as post-frame to avoid setState during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _cachedStageInitialRatio = stageInitialRatio;
        });
      }

      Widget buildCalendarArea() {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildCurrentView();
      }

      // Whether the layout requires bounded vertical space:
      // - full variant always uses Expanded children.
      // - day view with hour-selection panel needs Expanded for the panel.
      // For mini/compact month and week views the child widgets are already
      // intrinsically sized (mainAxisSize.min + fixed SizedBox grids), so a
      // min-size Column lets the card shrink-wrap instead of wasting space.
      final needsBoundedLayout =
          widget.variant == CalendarVariant.full ||
          (widget.requireHourSelectionInDayView &&
              _currentView == CalendarView.day);

      // Pre-compute day-view height for the non-Expanded path.
      final dayViewHeight =
          effectiveHeight - (showHeader ? kCalendarHeaderHeight : 0.0);

      final bodyColumn = Column(
        mainAxisSize:
            needsBoundedLayout ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (showHeader)
            CalendarHeader(
              currentDate: _currentDate,
              currentView: _currentView,
              selectedDate: _selectedDate,
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
                medicationFormIcon: upNextMedication == null
                    ? null
                    : MedicationDisplayHelpers.medicationFormIcon(
                        upNextMedication.form,
                      ),
              ),
            ),
          if (widget.variant == CalendarVariant.full)
            Expanded(child: buildCalendarArea())
          else if (_currentView == CalendarView.day)
            // requireHourSelectionInDayView uses Expanded; otherwise use a
            // fixed-height SizedBox so the Column can stay mainAxisSize.min.
            if (widget.requireHourSelectionInDayView)
              Expanded(child: buildCalendarArea())
            else
              SizedBox(height: dayViewHeight, child: buildCalendarArea())
          else
            // Month / week views are intrinsically sized — no flex wrapper.
            buildCalendarArea(),
          if (widget.requireHourSelectionInDayView &&
              _currentView == CalendarView.day &&
              _selectedHour != null)
            if (widget.variant == CalendarVariant.full && panelHeight != null)
              SizedBox(
                height: panelHeight,
                child: CalendarSelectedHourPanel(
                  doses: _doses,
                  currentDate: _currentDate,
                  selectedHour: _selectedHour!,
                  isFullVariant: true,
                  onDoseTap: _onDoseTapInternal,
                  onOpenDoseActionSheet: _openDoseActionSheetFor,
                ),
              )
            else
              Expanded(
                child: CalendarSelectedHourPanel(
                  doses: _doses,
                  currentDate: _currentDate,
                  selectedHour: _selectedHour!,
                  isFullVariant: widget.variant == CalendarVariant.full,
                  onDoseTap: _onDoseTapInternal,
                  onOpenDoseActionSheet: _openDoseActionSheetFor,
                ),
              ),
        ],
      );

      // Non-full variants: render the selected-day panel as an overlay so the
      // calendar grid doesn't get squashed to make room.
      if ((showSelectedDayStage || showSelectDayPrompt) &&
          widget.variant != CalendarVariant.full) {
        // Anchor the panel top exactly to the bottom of the calendar grid so
        // day / week cells are never obscured (day view never reaches this path
        // since showSelectedDayStage is false in day view).
        if (_currentView != CalendarView.day) {
          final gridTop = showHeader ? kCalendarHeaderHeight : 0.0;
          final calendarContentHeight = gridTop +
              switch (_currentView) {
                CalendarView.month =>
                  kCalendarMonthDayHeaderHeight +
                      _computeMonthRowCount() * kCalendarDayHeight,
                CalendarView.week =>
                  kCalendarWeekHeaderHeight + kCalendarWeekGridHeight,
                CalendarView.day => 0.0,
              };

          return Stack(
            children: [
              Positioned.fill(child: bodyColumn),
              Positioned(
                left: 0,
                right: 0,
                top: calendarContentHeight,
                bottom: 0,
                child: showSelectedDayStage
                    ? _buildSelectedDayPanel()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(
                          kSpacingS,
                          0,
                          kSpacingS,
                          kSpacingS,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildSelectDayPrompt(context),
                        ),
                      ),
              ),
            ],
          );
        }

        // Week / day: ratio-based overlay.
        final ratio = switch (_currentView) {
          CalendarView.day => kCalendarSelectedDayPanelHeightRatioDay,
          CalendarView.week => kCalendarSelectedDayPanelHeightRatioWeek,
          CalendarView.month => kCalendarSelectedDayPanelHeightRatioMonth,
        };
        final overlayHeight = effectiveHeight * ratio;

        return Stack(
          children: [
            Positioned.fill(child: bodyColumn),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: overlayHeight,
              child: showSelectedDayStage
                  ? _buildSelectedDayPanel()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        kSpacingS,
                        0,
                        kSpacingS,
                        kSpacingS,
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildSelectDayPrompt(context),
                      ),
                    ),
            ),
          ],
        );
      }

      // Full variant: selected-day panel becomes a draggable stage that hugs
      // the bottom and can expand to full screen (covering header + calendar).
      if (widget.variant == CalendarVariant.full &&
          (showSelectedDayStage || showSelectDayPrompt)) {
        return Stack(
          children: [
            Positioned.fill(child: bodyColumn),
            if (showSelectedDayStage)
              _buildSelectedDayStageSheet(
                initialRatio:
                    stageInitialRatio ??
                    kCalendarSelectedDayPanelHeightRatioMonth,
              )
            else
              Positioned(
                left: kSpacingM,
                right: kSpacingM,
                bottom: kSpacingM,
                child: _buildSelectDayPrompt(context),
              ),
          ],
        );
      }

      return bodyColumn;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeBoundedHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null;

        final fallbackHeight = switch (widget.variant) {
          CalendarVariant.mini => kHomeMiniCalendarHeight,
          CalendarVariant.compact => kDetailCompactCalendarHeight,
          CalendarVariant.full => MediaQuery.sizeOf(context).height * 0.75,
        };

        final effectiveHeight =
            widget.height ?? safeBoundedHeight ?? fallbackHeight;

        final selectedDayPanelRatio = switch (_currentView) {
          CalendarView.day => kCalendarSelectedDayPanelHeightRatioDay,
          CalendarView.week => kCalendarSelectedDayPanelHeightRatioWeek,
          CalendarView.month => kCalendarSelectedDayPanelHeightRatioMonth,
        };
        final panelHeight = widget.variant == CalendarVariant.full
            ? effectiveHeight * selectedDayPanelRatio
            : null;

        final body = buildBody(
          panelHeight: panelHeight,
          effectiveHeight: effectiveHeight,
        );

        if (widget.embedInParentCard) {
          // When there is no dose-stage panel the body is already
          // intrinsically sized via mainAxisSize.min — don't force it into a
          // fixed-height SizedBox or the card will reserve unused space.
          if (!widget.showSelectedDayPanel &&
              widget.variant != CalendarVariant.full) {
            return body;
          }
          return SizedBox(height: effectiveHeight, child: body);
        }

        return SizedBox(height: effectiveHeight, child: body);
      },
    );
  }

  Widget _buildSelectedDayStageSheet({required double initialRatio}) {
    final selectedDate = _selectedDate;
    if (selectedDate == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final peekRatio = kCalendarSelectedDayStagePeekRatio;
    final minRatio = peekRatio < initialRatio ? peekRatio : initialRatio;

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final listBottomPadding = safeBottom + kPageBottomPadding;

    return DraggableScrollableSheet(
      controller: _selectedDayStageController,
      initialChildSize: initialRatio,
      minChildSize: minRatio,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: {minRatio, initialRatio, 1.0}.toList(),
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: kBorderWidthMedium,
              ),
            ),
          ),
          child: _buildSelectedDayStageList(
            selectedDate: selectedDate,
            scrollController: scrollController,
            listBottomPadding: listBottomPadding,
            includeHandle: true,
            includeHeader: true,
          ),
        );
      },
    );
  }

  Widget _buildSelectedDayStageList({
    required DateTime selectedDate,
    required ScrollController scrollController,
    required double listBottomPadding,
    required bool includeHandle,
    required bool includeHeader,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!scrollController.hasClients) return;
      _updateSelectedDayStageDownHint(scrollController.position);
    });

    final dayDoses = _doses.where((dose) {
      return dose.scheduledTime.year == selectedDate.year &&
          dose.scheduledTime.month == selectedDate.month &&
          dose.scheduledTime.day == selectedDate.day;
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    final dosesByHour = <int, List<CalculatedDose>>{};
    for (final dose in dayDoses) {
      dosesByHour.putIfAbsent(dose.scheduledTime.hour, () => []).add(dose);
    }
    final hours = dosesByHour.keys.toList()..sort();

    Widget buildHandle(BuildContext context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      return Center(
        child: Container(
          width: kBottomSheetHandleWidth,
          height: kBottomSheetHandleHeight,
          margin: kCalendarSelectedDayStageHandleMargin,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: kOpacityVeryLow),
            borderRadius: BorderRadius.circular(kBottomSheetHandleRadius),
          ),
        ),
      );
    }

    Widget buildHeader(BuildContext context) {
      return Padding(
        padding: kCalendarSelectedDayStageHeaderPadding,
        child: Text(
          _formatSelectedDate(),
          style: calendarSelectedDayHeaderTextStyle(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Scrollable dose list — the handle/header are rendered OUTSIDE this widget
    // so they stay fixed (pinned) while the doses scroll underneath.
    Widget buildDoseList() {
      if (dayDoses.isEmpty) {
        return _wrapWithCenteredDownScrollHint(
          showHint: _showSelectedDayStageDownHint,
          onMetrics: _updateSelectedDayStageDownHint,
          child: ListView(
            controller: scrollController,
            padding: calendarStageListPadding(listBottomPadding),
            children: [
              const SizedBox(height: kSpacingS),
              const CalendarNoDosesState(showIcon: false, compact: true),
            ],
          ),
        );
      }

      return _wrapWithCenteredDownScrollHint(
        showHint: _showSelectedDayStageDownHint,
        onMetrics: _updateSelectedDayStageDownHint,
        child: ListView.builder(
          controller: scrollController,
          padding: calendarStageListPadding(listBottomPadding),
          itemCount: hours.length,
          itemBuilder: (context, index) {
            final hour = hours[index];
            final hourDoses = dosesByHour[hour] ?? const [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (index == 0) const SizedBox(height: kSpacingS),
                if (index != 0)
                  Divider(
                    height: kSpacingM,
                    thickness: kBorderWidthThin,
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: kOpacityVeryLow),
                  ),
                _buildHourDoseSection(hour: hour, hourDoses: hourDoses),
              ],
            );
          },
        ),
      );
    }

    // Compose: fixed (pinned) handle + header above the scrollable dose list.
    // Using Column + Expanded ensures the header never scrolls away.
    if (includeHandle || includeHeader) {
      return Column(
        children: [
          if (includeHandle) buildHandle(context),
          if (includeHeader) buildHeader(context),
          Expanded(child: buildDoseList()),
        ],
      );
    }

    return buildDoseList();
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CalendarView.day:
        if (!widget.requireHourSelectionInDayView) {
          return CalendarDayStagePanel(
            doses: _doses,
            currentDate: _currentDate,
            isFullVariant: widget.variant == CalendarVariant.full,
            onDoseTap: _onDoseTapInternal,
            onOpenDoseActionSheet: _openDoseActionSheetFor,
            onDateChanged: _onDateChanged,
          );
        }

        return CalendarDayView(
          date: _currentDate,
          doses: _doses,
          onDoseTap: null,
          selectedHour: _selectedHour,
          onHourTap: (hour) => setState(() => _selectedHour = hour),
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

  double _selectedDayStageInitialRatioForFullHeight(
    double effectiveHeight, {
    required bool showHeader,
    required bool showUpNextCard,
  }) {
    final peekRatio = kCalendarSelectedDayStagePeekRatio;
    final maxInitialRatio = kCalendarSelectedDayStageMaxInitialRatio;

    if (_currentView == CalendarView.day) {
      return kCalendarSelectedDayPanelHeightRatioDay;
    }

    final headerHeight = showHeader ? kCalendarHeaderHeight : 0.0;

    // Reserve height for Up Next card in full view so the selected-day stage
    // starts from the true bottom of visible calendar content.
    final upNextReservedHeight = showUpNextCard
        ? kCalendarUpNextReservedHeight
        : 0.0;

    final viewHeight = switch (_currentView) {
      CalendarView.week => kCalendarWeekHeaderHeight + kCalendarWeekGridHeight,
      CalendarView.month => _monthViewIntrinsicHeight(),
      CalendarView.day => 0.0,
    };

    final visibleTopHeight = headerHeight + upNextReservedHeight + viewHeight;
    final computed = 1.0 - (visibleTopHeight / effectiveHeight);

    final fallback = switch (_currentView) {
      CalendarView.week => kCalendarSelectedDayPanelHeightRatioWeek,
      CalendarView.month => kCalendarSelectedDayPanelHeightRatioMonth,
      CalendarView.day => kCalendarSelectedDayPanelHeightRatioDay,
    };

    return computed.isFinite
        ? computed.clamp(peekRatio, maxInitialRatio).toDouble()
        : fallback;
  }

  /// Computes the actual number of week rows needed for the current month.
  /// Mirrors the logic in CalendarMonthView._datesToDisplay.
  int _computeMonthRowCount() {
    final month = _currentDate;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final swm = _cachedStartWeekOnMonday;

    final lastDayColumnIndex = swm
        ? (lastDayOfMonth.weekday + 6) % 7 // Mon=0 … Sun=6
        : lastDayOfMonth.weekday % 7; // Sun=0, Mon=1 … Sat=6
    final paddingAfter =
        lastDayColumnIndex == 6 ? 0 : (6 - lastDayColumnIndex);
    final last = lastDayOfMonth.add(Duration(days: paddingAfter));

    final weekday = firstDayOfMonth.weekday;
    final daysToSubtract = swm ? (weekday + 6) % 7 : weekday % 7;
    final first = firstDayOfMonth.subtract(Duration(days: daysToSubtract));

    final totalDays = last.difference(first).inDays + 1;
    return totalDays ~/ 7;
  }

  double _monthViewIntrinsicHeight() {
    // Uses the dynamically-computed row count so Feb (4 rows) is shorter
    // than July (6 rows), etc.
    return kCalendarMonthDayHeaderHeight +
        (_computeMonthRowCount() * kCalendarDayHeight);
  }

  Widget _buildDoseCardFor(CalculatedDose dose) {
    final schedule = Hive.box<Schedule>('schedules').get(dose.scheduleId);
    final med = (schedule?.medicationId != null)
        ? Hive.box<Medication>('medications').get(schedule!.medicationId)
        : null;

    final strengthLabel = med != null
        ? MedicationDisplayHelpers.strengthOrConcentrationLabel(med)
        : '';

    final metrics = med != null && schedule != null
        ? schedule.displayMetrics(med)
        : '${dose.doseValue} ${dose.doseUnit}';

    return DoseCard(
      dose: dose,
      medicationName: med?.name ?? dose.medicationName,
      strengthOrConcentrationLabel: strengthLabel,
      doseMetrics: metrics,
      isActive: schedule?.isActive ?? true,
      medicationFormIcon: med == null
          ? null
          : MedicationDisplayHelpers.medicationFormIcon(med.form),
      doseNumber: schedule == null
          ? null
          : ScheduleOccurrenceService.occurrenceNumber(
              schedule,
              dose.scheduledTime,
            ),
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

  Widget _buildSelectedDayPanel() {
    if (_selectedDate == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final listBottomPadding = widget.variant == CalendarVariant.full
        ? safeBottom + kPageBottomPadding
        : safeBottom + kSpacingXXL + kSpacingXL;

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
        child: _buildSelectedDayStageList(
          selectedDate: _selectedDate!,
          scrollController: _selectedDayScrollController,
          listBottomPadding: listBottomPadding,
          includeHandle: false,
          includeHeader: true,
        ),
      ),
    );
  }

  Widget _buildHourDoseSection({
    required int hour,
    required List<CalculatedDose> hourDoses,
  }) {
    return Padding(
      padding: kCalendarStageHourRowPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: kCalendarStageHourLabelPadding,
            child: Text(
              formatCalendarHour(hour),
              textAlign: TextAlign.left,
              style: calendarStageHourLabelTextStyle(context),
            ),
          ),
          for (final dose in hourDoses)
            Padding(
              padding: kCalendarStageDoseCardPadding,
              child: _buildDoseCardFor(dose),
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

    final formatted = DateTimeFormatter.formatFullDate(context, _selectedDate!);

    return isToday ? 'Today — $formatted' : formatted;
  }
}