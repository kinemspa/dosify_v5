// Dart imports:

import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_header.dart';
import 'package:dosifi_v5/src/widgets/calendar/dose_calendar_widget.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/reconstitution_summary_card.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';

/// Modern, revolutionized medication detail screen with:
/// - Hero header with gradient and key stats
/// - Interactive quick action cards
/// - Visual stock progress indicators
/// - Clean sectioned information display
/// - Responsive layout for all screen sizes
const double _kDetailHeaderExpandedHeight = 300;
const double _kDetailHeaderCollapsedHeight = 56;

class MedicationDetailPage extends StatefulWidget {
  const MedicationDetailPage({super.key, this.medicationId, this.initial});
  final String? medicationId;
  final Medication? initial;

  @override
  State<MedicationDetailPage> createState() => _MedicationDetailPageState();
}

class _MedicationDetailPageState extends State<MedicationDetailPage> {
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        final offset = _scrollController.offset;
        final maxOffset =
            _kDetailHeaderExpandedHeight - _kDetailHeaderCollapsedHeight;
        setState(() {
          _scrollProgress = (offset / maxOffset).clamp(0.0, 1.0);
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');
    final med =
        widget.initial ??
        (widget.medicationId != null ? box.get(widget.medicationId) : null);

    if (med == null) {
      return Scaffold(
        appBar: const GradientAppBar(
          title: 'Medication',
          forceBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Medication not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Medication> box, _) {
          final updatedMed = box.get(med.id) ?? med;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final onPrimary = colorScheme.onPrimary;
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Combined AppBar and Stats Banner in one SliverAppBar
              SliverAppBar(
                toolbarHeight: _kDetailHeaderCollapsedHeight,
                expandedHeight: _kDetailHeaderExpandedHeight,
                collapsedHeight: _kDetailHeaderCollapsedHeight,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                foregroundColor: onPrimary,
                iconTheme: IconThemeData(color: onPrimary),
                actionsIconTheme: IconThemeData(color: onPrimary),
                elevation: 0,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = MediaQuery.of(context).padding.top;
                    final collapsedHeight = _kDetailHeaderCollapsedHeight + top;
                    final expandedHeight = _kDetailHeaderExpandedHeight;
                    final currentHeight = constraints.maxHeight;
                    final scrollOffset = expandedHeight - currentHeight;

                    // t goes from 0.0 (expanded) to 1.0 (collapsed)
                    final t =
                        (1.0 -
                                (currentHeight - collapsedHeight) /
                                    (expandedHeight - collapsedHeight))
                            .clamp(0.0, 1.0);

                    return Stack(
                      children: [
                        // Gradient Background
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF09A8BD), Color(0xFF18537D)],
                            ),
                          ),
                        ),
                        // Content (minus Name)
                        Positioned(
                          top: -scrollOffset,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: (1.0 - t * 2.0).clamp(0.0, 1.0),
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  kPageHorizontalPadding,
                                  4, // Reduced from 12
                                  kPageHorizontalPadding,
                                  kSpacingS,
                                ),
                                child: _buildStatsBannerContent(
                                  context,
                                  updatedMed,
                                  hideName: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Animated Name
                        Positioned(
                          top: lerpDouble(
                            top + 48,
                            top + (_kDetailHeaderCollapsedHeight - 26) / 2,
                            t,
                          ),
                          left: lerpDouble(kPageHorizontalPadding, 0, t),
                          right: lerpDouble(
                            120,
                            0,
                            t,
                          ), // Constrain width when expanded
                          child: Align(
                            alignment: Alignment.lerp(
                              Alignment.centerLeft,
                              Alignment.center,
                              t,
                            )!,
                            child: Text(
                              updatedMed.name,
                              style: TextStyle(
                                color: onPrimary,
                                fontSize: lerpDouble(22, 17, t),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                title: Opacity(
                  opacity: (1.0 - _scrollProgress * 3).clamp(0.0, 1.0),
                  child: Text(
                    'Medication Details',
                    style: TextStyle(
                      color: onPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                centerTitle: true,
                actions: [
                  // Menu button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu),
                    onSelected: (value) {
                      switch (value) {
                        case 'home':
                          context.go('/');
                        case 'medications':
                          context.go('/medications');
                        case 'supplies':
                          context.go('/supplies');
                        case 'schedules':
                          context.go('/schedules');
                        case 'calendar':
                          context.go('/calendar');
                        case 'reconstitution':
                          context.push('/medications/reconstitution');
                        case 'analytics':
                          context.go('/analytics');
                        case 'settings':
                          context.go('/settings');
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'home', child: Text('Home')),
                      PopupMenuItem(
                        value: 'medications',
                        child: Text('Medications'),
                      ),
                      PopupMenuItem(value: 'supplies', child: Text('Supplies')),
                      PopupMenuItem(
                        value: 'schedules',
                        child: Text('Schedules'),
                      ),
                      PopupMenuItem(value: 'calendar', child: Text('Calendar')),
                      PopupMenuItem(
                        value: 'reconstitution',
                        child: Text('Reconstitution Calculator'),
                      ),
                      PopupMenuItem(
                        value: 'analytics',
                        child: Text('Analytics'),
                      ),
                      PopupMenuItem(value: 'settings', child: Text('Settings')),
                    ],
                  ),
                ],
              ),
              // Gauge and Next Dose Section
              _buildGaugeAndNextDoseSection(context, updatedMed),
              // Schedule calendar
              SliverToBoxAdapter(
                child: _buildScheduleCalendar(context, updatedMed),
              ),
              // Active Vial Card (for MDV only) - moved higher
              if (updatedMed.form == MedicationForm.multiDoseVial)
                SliverToBoxAdapter(
                  child: _buildActiveVialCard(context, updatedMed),
                ),
              // Main content sections
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildModernSections(context, updatedMed),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Stats banner content (without outer container/gradient, used inside FlexibleSpace)
  Widget _buildStatsBannerContent(
    BuildContext context,
    Medication med, {
    bool hideName = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final manufacturer = med.manufacturer;
    final stockRatio = _stockFillRatio(med);
    final storageLabel = med.storageLocation;

    // Gauge logic
    final isMdv = med.form == MedicationForm.multiDoseVial;

    // For MDV, we want to show Volume % in the main gauge if possible
    // Otherwise fall back to stock count
    double pct = 0;
    String primaryLabel = '';
    String helperLabel = '';
    String? extraStockLabel;
    double initial = med.initialStockValue ?? med.stockValue;
    String unit = _stockUnitLabel(med.stockUnit);

    if (isMdv) {
      // MDV Logic:
      // Primary Gauge: Active Vial Volume % (if available)
      // Secondary/Text: Total Vials Count

      if (med.containerVolumeMl != null && med.containerVolumeMl! > 0) {
        final currentVol = med.activeVialVolume ?? med.containerVolumeMl!;
        pct = (currentVol / med.containerVolumeMl!) * 100;
        primaryLabel = '${pct.round()}%';

        initial = med.containerVolumeMl!;
        unit = 'mL';

        helperLabel = 'Remaining of Active Vial';
        extraStockLabel =
            '${_formatNumber(med.stockValue)} sealed vials in stock';
      } else {
        // Fallback if no volume info
        pct = stockRatio * 100;
        primaryLabel = '${pct.round()}%';
        helperLabel = 'Remaining';
      }
    } else {
      // Standard Logic (Tablets, etc)
      pct = stockRatio * 100;
      primaryLabel = '${pct.round()}%';
      helperLabel = 'Remaining';
    }

    final hasBackup =
        isMdv &&
        med.stockUnit == StockUnit.multiDoseVials &&
        med.stockValue > 0;

    double backupPct = 0;
    if (hasBackup) {
      final baseline =
          med.lowStockVialsThresholdCount != null &&
              med.lowStockVialsThresholdCount! > 0
          ? med.lowStockVialsThresholdCount!
          : med.stockValue; // Fallback to current if no threshold/baseline
      backupPct = baseline > 0 ? (med.stockValue / baseline) * 100.0 : 0.0;
    }

    // Strength per X label
    String strengthPerLabel = 'Strength';
    switch (med.form) {
      case MedicationForm.tablet:
        strengthPerLabel = 'Strength per Tablet';
      case MedicationForm.capsule:
        strengthPerLabel = 'Strength per Capsule';
      case MedicationForm.prefilledSyringe:
        strengthPerLabel = 'Strength per Syringe';
      case MedicationForm.singleDoseVial:
      case MedicationForm.multiDoseVial:
        strengthPerLabel = 'Strength per Vial';
    }

    // Determine gauge color based on percentage
    Color gaugeColor = onPrimary;
    if (pct <= 10) {
      gaugeColor = theme.colorScheme.errorContainer;
    } else if (pct <= 25) {
      gaugeColor = theme.colorScheme.tertiaryContainer;
    } else {
      gaugeColor = onPrimary.withValues(alpha: 0.9);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space for the animated Name (which is positioned absolutely)
                const SizedBox(height: 36),

                // Manufacturer (Moved below Name)
                if (manufacturer != null && manufacturer.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _editManufacturer(context, med),
                    child: Text(
                      manufacturer,
                      style: helperTextStyle(context)?.copyWith(
                        color: onPrimary.withValues(alpha: kOpacityMediumHigh),
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dotted,
                        decorationColor: onPrimary.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Description (Smaller, Higher)
                if (med.description != null && med.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      med.description!,
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                        fontSize: 10, // Reduced from 11
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpacingM,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: onPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(kBorderRadiusChip),
                        border: Border.all(
                          color: onPrimary.withValues(alpha: 0.2),
                          width: kBorderWidthThin,
                        ),
                      ),
                      child: Text(
                        _formLabel(med.form),
                        style: helperTextStyle(context)?.copyWith(
                          color: onPrimary,
                          fontWeight: kFontWeightSemiBold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Strength moved here
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strengthPerLabel,
                          style: TextStyle(
                            color: onPrimary.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
                          style: TextStyle(
                            color: onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Storage
                if (storageLabel != null && storageLabel.isNotEmpty) ...[
                  _HeaderInfoTile(
                    icon: med.activeVialRequiresFreezer
                        ? Icons.ac_unit
                        : (med.requiresRefrigeration
                              ? Icons.ac_unit
                              : Icons.location_on),
                    label: med.activeVialRequiresFreezer
                        ? 'Storage (Frozen)'
                        : (med.requiresRefrigeration
                              ? 'Storage (Cold)'
                              : 'Storage'),
                    value: storageLabel,
                    textColor: onPrimary,
                    trailingIcon: med.activeVialLightSensitive
                        ? Icons.dark_mode_outlined
                        : null,
                  ),
                  const SizedBox(height: 8),
                ],

                const Spacer(),
                // Adherence Graph (Moved to Left Column)
                _buildAdherenceGraph(context, onPrimary, med),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: hasBackup
                    ? DualStockDonutGauge(
                        outerPercentage: pct,
                        innerPercentage: backupPct,
                        primaryLabel: primaryLabel,
                        color: gaugeColor,
                        backgroundColor: onPrimary.withValues(
                          alpha: 0.05,
                        ), // Almost invisible
                        textColor: onPrimary,
                        showGlow: false,
                        isOutline: false,
                      )
                    : StockDonutGauge(
                        percentage: pct,
                        primaryLabel: primaryLabel,
                        color: gaugeColor,
                        backgroundColor: onPrimary.withValues(
                          alpha: 0.05,
                        ), // Almost invisible
                        textColor: onPrimary,
                        showGlow: false,
                        isOutline: false,
                      ),
              ),
              const SizedBox(height: 4),
              RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  style: TextStyle(
                    color: onPrimary,
                    fontSize: 10,
                  ), // Reduced from 12
                  children: [
                    TextSpan(
                      text: _formatNumber(
                        (isMdv &&
                                med.containerVolumeMl != null &&
                                med.containerVolumeMl! > 0)
                            ? (med.activeVialVolume ?? med.containerVolumeMl!)
                            : med.stockValue,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primaryContainer,
                      ),
                    ),
                    const TextSpan(text: ' / '),
                    TextSpan(
                      text: _formatNumber(initial),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' $unit'),
                  ],
                ),
              ),
              Text(
                helperLabel,
                style: TextStyle(
                  color: onPrimary.withValues(alpha: 0.7),
                  fontSize: 9, // Reduced
                ),
                textAlign: TextAlign.right,
              ),
              if (extraStockLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  extraStockLabel,
                  style: TextStyle(
                    color: onPrimary.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
              const SizedBox(height: 8),

              // Stock Forecast (Moved Here)
              _buildStockForecastCard(context, onPrimary, med),

              const SizedBox(height: 8),

              // Custom Refill Button
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: onPrimary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showRefillDialog(context, med),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 14,
                            color: onPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Refill',
                            style: TextStyle(
                              color: onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeAndNextDoseSection(BuildContext context, Medication med) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nextDose = _nextDoseForMedication(med.id);
    final adherencePercent = _estimateAdherencePercent(med);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            if (nextDose != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NEXT DOSE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatRelativeTimeUntil(nextDose.dateTime),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(nextDose.dateTime),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            DateFormat('EEEE, MMM d').format(nextDose.dateTime),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Adherence',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(adherencePercent * 100).round()}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSpacingL),
            ],
          ],
        ),
      ),
    );
  }

  /// Schedule calendar row showing active schedules
  Widget _buildScheduleCalendar(BuildContext context, Medication med) {
    final schedulesBox = Hive.box<Schedule>('schedules');
    final relatedSchedules = schedulesBox.values
        .where((s) => s.medicationId == med.id)
        .toList();

    if (relatedSchedules.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    // Build a set of days that have schedules
    final Set<int> activeDays = {};
    final Map<int, int> earliestMinutePerDay = {};

    for (final schedule in relatedSchedules) {
      activeDays.addAll(schedule.daysOfWeek);

      // Find earliest time for each day
      final minutesToCheck = schedule.hasMultipleTimes
          ? schedule.timesOfDay!
          : [schedule.minutesOfDay];

      final earliestMinute = minutesToCheck.reduce((a, b) => a < b ? a : b);

      for (final dayNum in schedule.daysOfWeek) {
        final currentEarliest = earliestMinutePerDay[dayNum];
        if (currentEarliest == null || earliestMinute < currentEarliest) {
          earliestMinutePerDay[dayNum] = earliestMinute;
        }
      }
    }

    // Day labels: Sun(7), Mon(1), Tue(2), Wed(3), Thu(4), Fri(5), Sat(6)
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final dayNums = [7, 1, 2, 3, 4, 5, 6];
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scheduled Days',
                    style: bodyTextStyle(
                      context,
                    )?.copyWith(fontWeight: kFontWeightSemiBold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Horizontal day boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final dayLabel = dayLabels[index];
                  final dayNum = dayNums[index];
                  final hasSchedule = activeDays.contains(dayNum);
                  final isToday = dayNum == today;
                  final earliestMinute = earliestMinutePerDay[dayNum];

                  // Format time compactly (e.g., "9a" or "12p")
                  String? timeText;
                  if (earliestMinute != null) {
                    final hour = earliestMinute ~/ 60;
                    final isPm = hour >= 12;
                    final displayHour = hour == 0
                        ? 12
                        : (hour > 12 ? hour - 12 : hour);
                    timeText = '$displayHour${isPm ? 'pm' : 'am'}';
                  }

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 48,
                      decoration: BoxDecoration(
                        color: hasSchedule
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isToday
                              ? theme.colorScheme.primary
                              : (hasSchedule
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.transparent),
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: bodyTextStyle(context)?.copyWith(
                              color: hasSchedule
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isToday
                                  ? kFontWeightBold
                                  : (hasSchedule
                                        ? kFontWeightSemiBold
                                        : kFontWeightMedium),
                              fontSize: 14,
                            ),
                          ),
                          if (timeText != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              timeText,
                              style: helperTextStyle(context)?.copyWith(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 10,
                                fontWeight: kFontWeightMedium,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Active Vial Card for Multi-Dose Vials
  Widget _buildActiveVialCard(BuildContext context, Medication med) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildGlassSection(
        context,
        title: 'Active Vial (Current Dose Tracking)',
        icon: Icons.science_outlined,
        children: [
          // Info banner explaining active vial
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Medicine being drawn from for each injection',
                    style: helperTextStyle(context),
                  ),
                ),
              ],
            ),
          ),
          // Show current volume remaining in active vial
          if (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
            buildDetailInfoRow(
              context,
              label: 'Volume Remaining',
              value:
                  '${_formatNumber(med.activeVialVolume ?? med.containerVolumeMl!)} / ${_formatNumber(med.containerVolumeMl!)} mL',
              highlighted: true,
              onTap: null,
            ),
          if (med.activeVialBatchNumber != null &&
              med.activeVialBatchNumber!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Batch Number',
              value: med.activeVialBatchNumber!,
              onTap: null,
            ),
          if (med.activeVialStorageLocation != null &&
              med.activeVialStorageLocation!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Storage Location',
              value: med.activeVialStorageLocation!,
              onTap: null,
            ),
          if (med.activeVialRequiresRefrigeration)
            buildDetailInfoRow(
              context,
              label: 'Storage Condition',
              value: 'Refrigerated (2-8°C)',
              onTap: null,
            ),
          if (med.activeVialRequiresFreezer)
            buildDetailInfoRow(
              context,
              label: 'Storage Condition',
              value: 'Frozen',
              onTap: null,
            ),
          if (med.activeVialLightSensitive)
            buildDetailInfoRow(
              context,
              label: 'Light Protection',
              value: 'Protect from light',
              onTap: null,
            ),
          if (med.activeVialLowStockMl != null && med.activeVialLowStockMl! > 0)
            buildDetailInfoRow(
              context,
              label: 'Low Stock Threshold',
              value: '${_formatNumber(med.activeVialLowStockMl!)} mL',
              onTap: null,
            ),
        ],
      ),
    );
  }

  /// Quick action cards for common tasks
  /// Modern information sections
  List<Widget> _buildModernSections(BuildContext context, Medication med) {
    final sections = <Widget>[];

    // Multi-Dose Vial: Reconstitution Information (Wizard-style summary)
    // MOVED UP as requested
    if (med.form == MedicationForm.multiDoseVial &&
        med.strengthValue > 0 &&
        (med.containerVolumeMl != null || med.perMlValue != null)) {
      sections.add(
        Center(
          child: Stack(
            children: [
              ReconstitutionSummaryCard(
                strengthValue: med.strengthValue,
                strengthUnit: _unitLabel(med.strengthUnit),
                medicationName: med.name,
                containerVolumeMl: med.containerVolumeMl,
                perMlValue: med.perMlValue,
                volumePerDose: med.volumePerDose,
                reconFluidName:
                    'Bacteriostatic Water', // TODO: Add to medication model
                syringeSizeMl: 3.0, // TODO: Add to medication model
              ),
              // Edit button positioned at top-right
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    // Open reconstitution calculator dialog
                    final result =
                        await showModalBottomSheet<ReconstitutionResult>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ReconstitutionCalculatorDialog(
                            initialStrengthValue: med.strengthValue,
                            unitLabel: _unitLabel(med.strengthUnit),
                            initialDoseValue: med.volumePerDose,
                            initialVialSize: med.containerVolumeMl,
                          ),
                        );

                    if (result != null && context.mounted) {
                      // Update medication with new reconstitution values
                      final updatedMed = med.copyWith(
                        containerVolumeMl: result.solventVolumeMl,
                        perMlValue: result.perMlConcentration,
                        volumePerDose:
                            result.recommendedUnits /
                            100, // Convert units back to mL
                      );

                      // Save directly to Hive
                      final box = await Hive.openBox<Medication>('medications');
                      await box.put(updatedMed.id, updatedMed);
                    }
                  },
                  tooltip: 'Edit Reconstitution',
                ),
              ),
            ],
          ),
        ),
      );
      sections.add(const SizedBox(height: 16));
    }

    // Medication Information (Removed Name/Manufacturer)
    sections.add(
      _buildGlassSection(
        context,
        title: 'Medication Information',
        icon: Icons.info_outline,
        children: [
          if (med.batchNumber != null && med.batchNumber!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Batch Number',
              value: med.batchNumber!,
              onTap: () => _editBatchNumber(context, med),
            ),
          if (med.description != null && med.description!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Description',
              value: med.description!,
              maxLines: 3,
              onTap: () => _editDescription(context, med),
            ),
        ],
      ),
    );
    sections.add(const SizedBox(height: 16));

    // Storage & Handling
    sections.add(
      _buildGlassSection(
        context,
        title: 'Storage & Handling',
        icon: Icons.inventory_2_outlined,
        children: [
          if (med.expiry != null)
            buildDetailInfoRow(
              context,
              label: 'Expiry Date',
              value: DateFormat('MMMM d, y').format(med.expiry!),
              warning: _isExpiringSoon(med.expiry!),
              onTap: () => _editExpiry(context, med),
            ),
          if (med.storageLocation != null && med.storageLocation!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Location',
              value: med.storageLocation!,
              onTap: () => _editStorageLocation(context, med),
            ),
          if (med.requiresRefrigeration)
            buildDetailInfoRow(
              context,
              label: 'Temperature',
              value: 'Refrigerated (2-8°C)',
              onTap: null,
            ),
          // MDV-specific storage conditions for active vial
          if (med.form == MedicationForm.multiDoseVial ||
              med.form == MedicationForm.singleDoseVial) ...[
            if (med.activeVialRequiresFreezer)
              buildDetailInfoRow(
                context,
                label: 'Active Vial',
                value: 'Frozen (Active Vial)',
                onTap: null,
              ),
            if (med.activeVialLightSensitive)
              buildDetailInfoRow(
                context,
                label: 'Light (Active)',
                value: 'Protect from light',
                onTap: null,
              ),
          ],
          if (med.storageInstructions != null &&
              med.storageInstructions!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Special Instructions',
              value: med.storageInstructions!,
              maxLines: 3,
              onTap: () => _editStorageInstructions(context, med),
            ),
        ],
      ),
    );

    // Multi-Dose Vial: Backup Vials (Sealed Stock - can be reconstituted)
    if (med.form == MedicationForm.multiDoseVial) {
      sections.add(const SizedBox(height: 16));
      sections.add(
        _buildGlassSection(
          context,
          title: 'Sealed Vials in Stock',
          icon: Icons.inventory_outlined,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Backup stock that can be reconstituted to become active vial',
                      style: helperTextStyle(context),
                    ),
                  ),
                ],
              ),
            ),
            // Show count of sealed vials
            buildDetailInfoRow(
              context,
              label: 'Vials in Stock',
              value: '${_formatNumber(med.stockValue)} vials',
              highlighted: true,
              onTap: null,
            ),
            if (med.backupVialsExpiry != null)
              buildDetailInfoRow(
                context,
                label: 'Expiry Date',
                value: DateFormat('MMMM d, y').format(med.backupVialsExpiry!),
                warning: _isExpiringSoon(med.backupVialsExpiry!),
                onTap: null,
              ),
            if (med.backupVialsBatchNumber != null &&
                med.backupVialsBatchNumber!.isNotEmpty)
              buildDetailInfoRow(
                context,
                label: 'Batch Number',
                value: med.backupVialsBatchNumber!,
                onTap: null,
              ),
            if (med.backupVialsStorageLocation != null &&
                med.backupVialsStorageLocation!.isNotEmpty)
              buildDetailInfoRow(
                context,
                label: 'Storage Location',
                value: med.backupVialsStorageLocation!,
                onTap: null,
              ),
            if (med.backupVialsRequiresRefrigeration)
              buildDetailInfoRow(
                context,
                label: 'Storage Condition',
                value: 'Refrigerated (2-8°C)',
                onTap: null,
              ),
            if (med.backupVialsRequiresFreezer)
              buildDetailInfoRow(
                context,
                label: 'Storage Condition',
                value: 'Frozen',
                onTap: null,
              ),
            if (med.backupVialsLightSensitive)
              buildDetailInfoRow(
                context,
                label: 'Light Protection',
                value: 'Protect from light',
                onTap: null,
              ),
          ],
        ),
      );
    }

    // Dose Calendar Section
    // Only show if schedules exist, otherwise show "Add Schedule" button
    final schedulesBox = Hive.box<Schedule>('schedules');
    final hasSchedules = schedulesBox.values.any(
      (s) => s.medicationId == med.id,
    );

    sections.add(const SizedBox(height: 16));
    if (hasSchedules) {
      sections.add(
        _buildGlassSection(
          context,
          title: 'Dose Calendar',
          icon: Icons.calendar_month_outlined,
          children: [
            DoseCalendarWidget(
              variant: CalendarVariant.compact,
              defaultView: CalendarView.week,
              medicationId: med.id,
            ),
          ],
        ),
      );
    } else {
      sections.add(
        _buildGlassSection(
          context,
          title: 'Schedule',
          icon: Icons.calendar_today_outlined,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'No schedules set for this medication',
                    style: helperTextStyle(context),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/schedules'),
                    icon: const Icon(Icons.add_alarm),
                    label: const Text('Add Schedule'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (med.notes != null && med.notes!.isNotEmpty) {
      sections.add(const SizedBox(height: 16));
      sections.add(
        _buildGlassSection(
          context,
          title: 'Notes',
          icon: Icons.note_outlined,
          children: [
            buildDetailInfoRow(
              context,
              label: '',
              value: med.notes!,
              maxLines: 10,
              onTap: null,
            ),
          ],
        ),
      );
    }

    sections.add(const SizedBox(height: 32));
    sections.add(
      Center(
        child: TextButton.icon(
          onPressed: () => _deleteMedication(context, med),
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          label: Text(
            'Delete Medication',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );

    return sections;
  }

  Widget _buildGlassSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    Widget? trailing,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: sectionTitleStyle(
                      context,
                    )?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: kSpacingM),
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper methods

  bool _isExpiringSoon(DateTime expiry) {
    final now = DateTime.now();
    return expiry.isBefore(now.add(const Duration(days: 30)));
  }

  String _formLabel(MedicationForm form) => switch (form) {
    MedicationForm.tablet => 'Tablet',
    MedicationForm.capsule => 'Capsule',
    MedicationForm.prefilledSyringe => 'Pre-filled Syringe',
    MedicationForm.singleDoseVial => 'Single Dose Vial',
    MedicationForm.multiDoseVial => 'Multi Dose Vial',
  };

  String _unitLabel(Unit unit) => switch (unit) {
    Unit.mcg => 'mcg',
    Unit.mg => 'mg',
    Unit.g => 'g',
    Unit.units => 'units',
    Unit.mcgPerMl => 'mcg/mL',
    Unit.mgPerMl => 'mg/mL',
    Unit.gPerMl => 'g/mL',
    Unit.unitsPerMl => 'units/mL',
  };

  String _stockUnitLabel(StockUnit unit) => switch (unit) {
    StockUnit.tablets => 'tablets',
    StockUnit.capsules => 'capsules',
    StockUnit.preFilledSyringes => 'syringes',
    StockUnit.singleDoseVials => 'vials',
    StockUnit.multiDoseVials => 'vials',
    StockUnit.mcg => 'mcg',
    StockUnit.mg => 'mg',
    StockUnit.g => 'g',
  };

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  double _stockFillRatio(Medication med) {
    if (med.initialStockValue == null || med.initialStockValue == 0) {
      return med.stockValue > 0 ? 1.0 : 0.0;
    }
    return (med.stockValue / med.initialStockValue!).clamp(0.0, 1.0);
  }

  ScheduledDose? _nextDoseForMedication(String medId) {
    final schedulesBox = Hive.box<Schedule>('schedules');
    final schedules = schedulesBox.values
        .where((s) => s.medicationId == medId && s.active)
        .toList();

    if (schedules.isEmpty) return null;

    final now = DateTime.now();
    DateTime? nextTime;

    for (final schedule in schedules) {
      // Simple next occurrence logic
      // This is a simplified version. For full logic, use DoseCalculationService
      // but that is async. Here we do a quick check for display.
      final times = schedule.hasMultipleTimes
          ? schedule.timesOfDay!
          : [schedule.minutesOfDay];

      for (final minutes in times) {
        final hour = minutes ~/ 60;
        final minute = minutes % 60;
        var candidate = DateTime(now.year, now.month, now.day, hour, minute);

        if (candidate.isBefore(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }

        // Check if day matches schedule (simplified: assume daily for now or check daysOfWeek)
        // If not today/tomorrow, we'd need to iterate days.
        // For UI responsiveness, we'll just show the next time today/tomorrow.
        if (nextTime == null || candidate.isBefore(nextTime)) {
          nextTime = candidate;
        }
      }
    }

    return nextTime != null ? ScheduledDose(nextTime) : null;
  }

  String _formatRelativeTimeUntil(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }

  double _estimateAdherencePercent(Medication med) {
    return 0.95;
  }

  void _showRefillDialog(BuildContext context, Medication med) {
    // TODO: Implement refill dialog
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Medication med,
    String title,
    String initialValue,
    void Function(String) onSave, {
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: buildFieldDecoration(context, hint: 'Enter $title'),
          maxLines: maxLines,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != initialValue) {
      onSave(result);
    }
  }

  void _editManufacturer(BuildContext context, Medication med) {
    _showEditDialog(context, med, 'Manufacturer', med.manufacturer ?? '', (
      val,
    ) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(manufacturer: val));
    });
  }

  void _editBatchNumber(BuildContext context, Medication med) {
    _showEditDialog(context, med, 'Batch Number', med.batchNumber ?? '', (val) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(batchNumber: val));
    });
  }

  void _editDescription(BuildContext context, Medication med) {
    _showEditDialog(context, med, 'Description', med.description ?? '', (val) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(description: val));
    }, maxLines: 3);
  }

  void _editExpiry(BuildContext context, Medication med) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: med.expiry ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(expiry: picked));
    }
  }

  void _editStorageLocation(BuildContext context, Medication med) {
    _showEditDialog(
      context,
      med,
      'Storage Location',
      med.storageLocation ?? '',
      (val) {
        final box = Hive.box<Medication>('medications');
        box.put(med.id, med.copyWith(storageLocation: val));
      },
    );
  }

  void _editStorageInstructions(BuildContext context, Medication med) {
    _showEditDialog(
      context,
      med,
      'Storage Instructions',
      med.storageInstructions ?? '',
      (val) {
        final box = Hive.box<Medication>('medications');
        box.put(med.id, med.copyWith(storageInstructions: val));
      },
      maxLines: 3,
    );
  }

  void _deleteMedication(BuildContext context, Medication med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text(
          'Are you sure you want to delete ${med.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final box = Hive.box<Medication>('medications');
      await box.delete(med.id);
      if (context.mounted) {
        context.pop(); // Go back to list
      }
    }
  }

  Widget _buildAdherenceGraph(
    BuildContext context,
    Color color,
    Medication med,
  ) {
    // Real data from Hive
    final doseBox = Hive.box<DoseLog>('dose_logs');
    final scheduleBox = Hive.box<Schedule>('schedules');

    // Get last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final data = <double>[];

    // Find schedules for this med
    final schedules = scheduleBox.values
        .where((s) => s.medicationId == med.id && s.active)
        .toList();

    // If no schedules, we can't really calculate adherence, so show empty or full?
    // Let's show empty/grey if no schedule.
    if (schedules.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7 Day Adherence',
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          ),
          const SizedBox(height: 8),
          Container(
            height: 40,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'No schedule set',
              style: TextStyle(
                color: color.withValues(alpha: 0.5),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      // Check if any schedule was active on this day
      // Simplified: check if day of week matches any schedule
      // (In a real app, we'd check start/end dates of schedules too)
      final dayOfWeek = date.weekday; // 1=Mon, 7=Sun
      final isScheduledDay = schedules.any(
        (s) => s.daysOfWeek.contains(dayOfWeek),
      );

      if (!isScheduledDay) {
        data.add(-1.0); // Not scheduled
        continue;
      }

      // Check if dose was taken on this day
      final taken = doseBox.values.any((log) {
        final localScheduled = log.scheduledTime.toLocal();
        return log.medicationId == med.id &&
            log.action == DoseAction.taken &&
            localScheduled.year == date.year &&
            localScheduled.month == date.month &&
            localScheduled.day == date.day;
      });

      data.add(taken ? 1.0 : 0.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7 Day Adherence',
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          width: double.infinity,
          child: CustomPaint(
            painter: _AdherenceBarPainter(data: data, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildStockForecastCard(
    BuildContext context,
    Color color,
    Medication med,
  ) {
    // Calculate days remaining based on schedule
    final scheduleBox = Hive.box<Schedule>('schedules');
    final schedules = scheduleBox.values
        .where((s) => s.medicationId == med.id && s.active)
        .toList();

    if (schedules.isEmpty || med.stockValue <= 0) {
      return const SizedBox.shrink();
    }

    // Calculate average daily consumption
    double weeklyConsumption = 0;
    for (final schedule in schedules) {
      final dosesPerDay = schedule.hasMultipleTimes
          ? schedule.timesOfDay!.length
          : 1;
      // How many times per week does this schedule run?
      final daysPerWeek = schedule.daysOfWeek.length;

      // Dose amount (if we had it in schedule, but schedule just triggers a dose)
      // We assume 1 unit per dose unless specified otherwise.
      // The Medication model has `strengthValue` but that's concentration.
      // Usually a dose is 1 "unit" (tablet, etc) or a specific volume.
      // For now, assume 1 stock unit per dose.
      // TODO: Use actual dose amount from schedule if available in future
      double amountPerDose = 1.0;
      if (med.form == MedicationForm.tablet ||
          med.form == MedicationForm.capsule) {
        if (schedule.doseValue > 0) {
          amountPerDose = schedule.doseValue;
        }
      }
      // For MDV, we need to be careful. If volumePerDose is set, we use that logic later.
      // But here we are calculating "doses per week".

      weeklyConsumption += dosesPerDay * daysPerWeek * amountPerDose;
    }

    if (weeklyConsumption == 0) return const SizedBox.shrink();

    final dailyConsumption = weeklyConsumption / 7.0;

    // Total stock in doses
    double totalStockDoses = med.stockValue; // Default for tablets/capsules

    if (med.form == MedicationForm.multiDoseVial) {
      // For MDV:
      // Active vial volume + (Stock vials * Container Volume)
      // Divided by Volume Per Dose
      if (med.containerVolumeMl != null &&
          med.volumePerDose != null &&
          med.volumePerDose! > 0) {
        final activeVol = med.activeVialVolume ?? med.containerVolumeMl!;
        final sealedVol = med.stockValue * med.containerVolumeMl!;
        final totalVol = activeVol + sealedVol;
        totalStockDoses = totalVol / med.volumePerDose!;
      }
    }

    final daysRemaining = totalStockDoses / dailyConsumption;
    final date = DateTime.now().add(Duration(days: daysRemaining.floor()));
    final dateStr = DateFormat('MMM d, y').format(date);

    // Check expiry
    final expiry = med.expiry;
    bool expiresBeforeStockout = false;
    if (expiry != null && expiry.isBefore(date)) {
      expiresBeforeStockout = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Stock Forecast',
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 2),
        Text(
          'Expected to last until',
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.right,
        ),
        Text(
          dateStr,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.right,
        ),
        Text(
          '${daysRemaining.floor()} days',
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
        ),
        if (expiry != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.event,
                size: 12,
                color: expiresBeforeStockout
                    ? Theme.of(context).colorScheme.errorContainer
                    : color.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Expires: ${DateFormat('MMM d, y').format(expiry)}',
                style: TextStyle(
                  color: expiresBeforeStockout
                      ? Theme.of(context).colorScheme.errorContainer
                      : color.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: expiresBeforeStockout
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AdherenceBarPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _AdherenceBarPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final barWidth = size.width / (data.length * 2 - 1);
    final spacing = barWidth;

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final x = i * (barWidth + spacing);

      if (value < 0) {
        // Future / No Data - Draw a dot or small line
        paint.color = color.withValues(alpha: 0.2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - 2, barWidth, 2),
            const Radius.circular(1),
          ),
          paint,
        );
      } else {
        // Draw bar
        // Height based on value (0.0 to 1.0)
        // If 0.0 (missed), draw a small red indicator or just a small bar
        final barHeight = value == 0 ? 4.0 : size.height * value;
        final y = size.height - barHeight;

        // Color: Full opacity for taken, lower for partial, maybe warning color for missed?
        // Since we only have one color passed in (onPrimary usually white), we use opacity.
        if (value == 0) {
          paint.color = color.withValues(alpha: 0.3); // Missed
        } else if (value < 1.0) {
          paint.color = color.withValues(alpha: 0.6); // Partial
        } else {
          paint.color = color; // Taken
        }

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barWidth, barHeight),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AdherenceBarPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

class ScheduledDose {
  final DateTime dateTime;
  ScheduledDose(this.dateTime);
}

class _HeaderInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? textColor;
  final IconData? trailingIcon;

  const _HeaderInfoTile({
    required this.label,
    required this.value,
    this.icon,
    this.textColor,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, color: color, size: 14),
            ],
          ],
        ),
      ],
    );
  }
}
