// Dart imports:

import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/medication_stock_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/expiry_tracking_service.dart';
import 'package:dosifi_v5/src/features/medications/presentation/controllers/medication_detail_controller.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_header_widget.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/next_dose_card.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/reconstitution_summary_card.dart';
import 'package:dosifi_v5/src/widgets/smart_expiry_picker.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// Modern, revolutionized medication detail screen with:
/// - Hero header with gradient and key stats
/// - Interactive quick action cards
/// - Visual stock progress indicators
/// - Clean sectioned information display
/// - Responsive layout for all screen sizes
const double _kDetailHeaderExpandedHeight = 325;
const double _kDetailHeaderCompactHeight = 245;
const double _kDetailHeaderCollapsedHeight = 56;

class MedicationDetailPage extends ConsumerStatefulWidget {
  const MedicationDetailPage({super.key, this.medicationId, this.initial});
  final String? medicationId;
  final Medication? initial;

  @override
  ConsumerState<MedicationDetailPage> createState() => _MedicationDetailPageState();
}

class _MedicationDetailPageState extends ConsumerState<MedicationDetailPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
      body: AnimatedBuilder(
        animation: Listenable.merge([
          box.listenable(),
          Hive.box<Schedule>('schedules').listenable(),
          Hive.box<DoseLog>('dose_logs').listenable(),
          _scrollController,
        ]),
        builder: (context, _) {
          final updatedMed = box.get(med.id) ?? med;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final onPrimary = colorScheme.onPrimary;

          // Check if we have schedules to determine header height
          final scheduleBox = Hive.box<Schedule>('schedules');
          final hasSchedules = scheduleBox.values.any(
            (s) => s.medicationId == updatedMed.id && s.active,
          );
          final headerHeight = hasSchedules
              ? _kDetailHeaderExpandedHeight
              : _kDetailHeaderCompactHeight;

          // Calculate scroll progress for title opacity
          final offset = _scrollController.hasClients
              ? _scrollController.offset
              : 0.0;
          final maxOffset = headerHeight - _kDetailHeaderCollapsedHeight;
          final scrollProgress = (offset / maxOffset).clamp(0.0, 1.0);

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Combined AppBar and Stats Banner in one SliverAppBar
              SliverAppBar(
                toolbarHeight: _kDetailHeaderCollapsedHeight,
                expandedHeight: headerHeight,
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
                    final expandedHeight = headerHeight;
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
                              colors: [
                                kMedicationDetailGradientStart,
                                kMedicationDetailGradientEnd,
                              ],
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
                                child: MedicationHeaderWidget(
                                  medication: updatedMed,
                                  onRefill: () => _showRefillDialog(context, updatedMed),
                                  daysRemaining: MedicationStockService.calculateDaysRemaining(
                                    updatedMed,
                                    Hive.box<Schedule>('schedules')
                                        .values
                                        .where((s) => s.medicationId == updatedMed.id && s.active)
                                        .toList(),
                                  ),
                                  stockoutDate: MedicationStockService.calculateStockoutDate(
                                    updatedMed,
                                    Hive.box<Schedule>('schedules')
                                        .values
                                        .where((s) => s.medicationId == updatedMed.id && s.active)
                                        .toList(),
                                  ),
                                  adherenceData: _calculateAdherenceData(updatedMed),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Animated Name & Manufacturer
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _editName(context, updatedMed),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
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
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: onPrimary.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: onPrimary.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          _formLabel(updatedMed.form),
                                          style: TextStyle(
                                            color: onPrimary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (updatedMed.manufacturer != null &&
                                    updatedMed.manufacturer!.isNotEmpty &&
                                    t < 0.5)
                                  GestureDetector(
                                    onTap: () =>
                                        _editManufacturer(context, updatedMed),
                                    child: Opacity(
                                      opacity: (1.0 - t * 2.0).clamp(0.0, 1.0),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: Text(
                                          updatedMed.manufacturer!,
                                          style: TextStyle(
                                            color: onPrimary.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
                  opacity: (1.0 - scrollProgress * 3).clamp(0.0, 1.0),
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
              // Reconstitution Card (if applicable)
              if (updatedMed.form == MedicationForm.multiDoseVial)
                SliverToBoxAdapter(
                  child: _buildReconstitutionCard(context, updatedMed),
                ),

              // Unified Details Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100),
                  child: _buildUnifiedDetailsCard(
                    context,
                    updatedMed,
                    _nextDoseForMedication(updatedMed.id),
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
                const SizedBox(height: 60),

                // Description & Notes
                if (med.description != null && med.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      med.description!,
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.9),
                        fontSize: 11, // Reduced from 12
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2, // Reduced from 3
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                if (med.notes != null && med.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      med.notes!,
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                        fontSize: 10, // Reduced from 11
                      ),
                      maxLines: 1, // Reduced from 2
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(height: 8),

                // Strength with Icon (Standardized)
                _HeaderInfoTile(
                  icon: Icons.fitness_center,
                  label: strengthPerLabel,
                  value:
                      '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
                  textColor: onPrimary,
                ),
                const SizedBox(height: 8),

                // Storage
                if (storageLabel != null && storageLabel.isNotEmpty) ...[
                  _HeaderInfoTile(
                    icon: med.activeVialRequiresFreezer
                        ? Icons.severe_cold
                        : (med.requiresRefrigeration
                              ? Icons.ac_unit
                              : Icons.inventory_2_outlined),
                    label: 'Storage',
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: onPrimary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showRefillDialog(context, med),
                    borderRadius: BorderRadius.circular(8),
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

  Widget _buildUnifiedDetailsCard(
    BuildContext context,
    Medication med,
    ScheduledDose? nextDose,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check for schedules
    final scheduleBox = Hive.box<Schedule>('schedules');
    final hasSchedules = scheduleBox.values.any(
      (s) => s.medicationId == med.id && s.active,
    );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: kCardBorderOpacity),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Schedule & Next Dose
            if (hasSchedules) ...[
              _buildSectionTitle(
                context,
                'Schedule',
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              _buildScheduleSection(context, med, nextDose),
              const Divider(height: 32),
            ],

            // 2. Merged Medication Details
            _buildSectionTitle(
              context,
              'Medication Details',
              icon: Icons.medication,
            ),
            const SizedBox(height: 16),
            _buildMergedDetailsSection(context, med),
            const Divider(height: 32),

            // 3. Active Vial (MDV Only)
            if (med.form == MedicationForm.multiDoseVial) ...[
              _buildSectionTitle(
                context,
                'Active Vial (In Use)',
                icon: Icons.science,
              ),
              const SizedBox(height: 16),
              _buildActiveVialSection(context, med),
              const Divider(height: 32),
            ],

            // 4. Backup Stock (MDV Only)
            if (med.form == MedicationForm.multiDoseVial) ...[
              _buildSectionTitle(
                context,
                'Backup Stock (Sealed)',
                icon: Icons.inventory_2,
              ),
              const SizedBox(height: 16),
              _buildBackupStockSection(context, med),
              const Divider(height: 32),
            ],

            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () => _deleteMedication(context, med),
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                label: Text(
                  'Delete Medication',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    IconData? icon,
  }) {
    if (icon != null) {
      return Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: sectionTitleStyle(context)),
        ],
      );
    }
    return Text(title, style: sectionTitleStyle(context));
  }

  Widget _buildScheduleSection(
    BuildContext context,
    Medication med,
    ScheduledDose? nextDose,
  ) {
    final scheduleBox = Hive.box<Schedule>('schedules');
    final schedules = scheduleBox.values
        .where((s) => s.medicationId == med.id && s.active)
        .toList();
    final count = schedules.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (schedules.isNotEmpty) ...[
          NextDoseCard(medication: med, schedules: schedules),
          const SizedBox(height: 16),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$count Schedule${count == 1 ? '' : 's'} Configured',
                  style: sectionTitleStyle(context)?.copyWith(fontSize: 14),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go('/schedules'),
              child: const Text('Manage'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMergedDetailsSection(BuildContext context, Medication med) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactGrid(context, [
          _buildCompactInfoItem(
            context,
            label: 'Name',
            value: med.name,
            onTap: () => _editName(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Manufacturer',
            value: med.manufacturer ?? 'Tap to add',
            onTap: () => _editManufacturer(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Strength',
            value:
                '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
            onTap: () => _editStrength(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Type',
            value: _formLabel(med.form),
            onTap: () => _editForm(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Batch Number',
            value: med.batchNumber ?? 'Tap to add',
            onTap: () => _editBatchNumber(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Expiry Date',
            value: med.expiry != null
                ? _formatExpiry(med.expiry!)
                : 'Tap to set',
            warning: med.expiry != null && _isExpiringSoon(med.expiry!),
            onTap: () => _editExpiry(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Low Stock Alert',
            value: med.lowStockEnabled
                ? '${_formatNumber(med.lowStockThreshold ?? 0)} ${_stockUnitLabel(med.stockUnit)}'
                : 'Disabled',
            onTap: () => _editLowStockThreshold(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Storage Location',
            value: med.storageLocation ?? 'Tap to add',
            onTap: () => _editStorageLocation(context, med),
          ),
        ]),
        const SizedBox(height: 16),
        if (med.description != null && med.description!.isNotEmpty) ...[
          _buildCompactInfoItem(
            context,
            label: 'Description',
            value: med.description!,
            onTap: () => _editDescription(context, med),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Storage Condition',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        _buildStorageSwitches(context, med),
        if (med.notes != null && med.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCompactInfoItem(
            context,
            label: 'Notes',
            value: med.notes!,
            isItalic: true,
            onTap: () => _editNotes(context, med),
          ),
        ],
      ],
    );
  }

  Widget _buildStorageSwitches(BuildContext context, Medication med) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: med.requiresRefrigeration,
              onChanged: (v) {
                final box = Hive.box<Medication>('medications');
                box.put(
                  med.id,
                  med.copyWith(
                    requiresRefrigeration: v ?? false,
                    requiresFreezer: (v ?? false) ? false : med.requiresFreezer,
                  ),
                );
              },
            ),
            Expanded(
              child: Text(
                'Refrigerate (2-8°C)',
                style: checkboxLabelStyle(context),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: med.requiresFreezer,
              onChanged: (v) {
                final box = Hive.box<Medication>('medications');
                box.put(
                  med.id,
                  med.copyWith(
                    requiresFreezer: v ?? false,
                    requiresRefrigeration: (v ?? false)
                        ? false
                        : med.requiresRefrigeration,
                  ),
                );
              },
            ),
            Expanded(child: Text('Freeze', style: checkboxLabelStyle(context))),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: med.lightSensitive,
              onChanged: (v) {
                final box = Hive.box<Medication>('medications');
                box.put(med.id, med.copyWith(lightSensitive: v ?? false));
              },
            ),
            Expanded(
              child: Text(
                'Protect from Light',
                style: checkboxLabelStyle(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveVialSection(BuildContext context, Medication med) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  style: bodyTextStyle(context)?.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        if (med.diluentName != null && med.diluentName!.isNotEmpty)
          buildDetailInfoRow(
            context,
            label: 'Reconstitution Fluid',
            value: med.diluentName!,
            onTap: null,
          ),
        if (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
          buildDetailInfoRow(
            context,
            label: 'Volume Remaining',
            value:
                '${_formatNumber(med.activeVialVolume ?? med.containerVolumeMl!)} / ${_formatNumber(med.containerVolumeMl!)} mL',
            highlighted: true,
            onTap: null,
          ),
        _buildCompactGrid(context, [
          _buildCompactInfoItem(
            context,
            label: 'Batch Number',
            value: med.activeVialBatchNumber ?? 'Tap to add',
            onTap: () => _editActiveVialBatch(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Location',
            value: med.activeVialStorageLocation ?? 'Tap to add',
            onTap: () => _editActiveVialLocation(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Low Stock Alert',
            value: med.activeVialLowStockMl != null
                ? '${_formatNumber(med.activeVialLowStockMl!)} mL'
                : 'Tap to set',
            onTap: () => _editActiveVialLowStock(context, med),
          ),
        ]),
        const SizedBox(height: 8),
        Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: med.activeVialRequiresRefrigeration,
                  onChanged: (bool? v) {
                    final box = Hive.box<Medication>('medications');
                    box.put(
                      med.id,
                      med.copyWith(
                        activeVialRequiresRefrigeration: v ?? false,
                        activeVialRequiresFreezer: (v ?? false)
                            ? false
                            : med.activeVialRequiresFreezer,
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Text(
                    'Refrigerated',
                    style: checkboxLabelStyle(context),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: med.activeVialRequiresFreezer,
                  onChanged: (bool? v) {
                    final box = Hive.box<Medication>('medications');
                    box.put(
                      med.id,
                      med.copyWith(
                        activeVialRequiresFreezer: v ?? false,
                        activeVialRequiresRefrigeration: (v ?? false)
                            ? false
                            : med.activeVialRequiresRefrigeration,
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Text('Frozen', style: checkboxLabelStyle(context)),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: med.activeVialLightSensitive,
                  onChanged: (bool? v) {
                    final box = Hive.box<Medication>('medications');
                    box.put(
                      med.id,
                      med.copyWith(activeVialLightSensitive: v ?? false),
                    );
                  },
                ),
                Expanded(
                  child: Text(
                    'Light Sensitive',
                    style: checkboxLabelStyle(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackupStockSection(BuildContext context, Medication med) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactGrid(context, [
          _buildCompactInfoItem(
            context,
            label: 'Quantity',
            value: '${_formatNumber(med.stockValue)} vials',
            highlighted: true,
            onTap: null,
          ),
          _buildCompactInfoItem(
            context,
            label: 'Batch Number',
            value: med.backupVialsBatchNumber ?? 'Tap to add',
            onTap: () => _editBackupVialBatch(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Expiry Date',
            value: med.backupVialsExpiry != null
                ? _formatExpiry(med.backupVialsExpiry!)
                : 'Tap to set',
            warning:
                med.backupVialsExpiry != null &&
                _isExpiringSoon(med.backupVialsExpiry!),
            onTap: () => _editBackupVialExpiry(context, med),
          ),
          _buildCompactInfoItem(
            context,
            label: 'Location',
            value: med.backupVialsStorageLocation ?? 'Tap to add',
            onTap: () => _editBackupVialLocation(context, med),
          ),
        ]),
        const SizedBox(height: 8),
        Column(
          children: [
            SwitchListTile(
              title: const Text('Refrigerated'),
              value: med.backupVialsRequiresRefrigeration,
              onChanged: (bool v) {
                final box = Hive.box<Medication>('medications');
                box.put(
                  med.id,
                  med.copyWith(
                    backupVialsRequiresRefrigeration: v,
                    backupVialsRequiresFreezer: v
                        ? false
                        : med.backupVialsRequiresFreezer,
                  ),
                );
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Frozen'),
              value: med.backupVialsRequiresFreezer,
              onChanged: (bool v) {
                final box = Hive.box<Medication>('medications');
                box.put(
                  med.id,
                  med.copyWith(
                    backupVialsRequiresFreezer: v,
                    backupVialsRequiresRefrigeration: v
                        ? false
                        : med.backupVialsRequiresRefrigeration,
                  ),
                );
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Light Sensitive'),
              value: med.backupVialsLightSensitive,
              onChanged: (bool v) {
                final box = Hive.box<Medication>('medications');
                box.put(med.id, med.copyWith(backupVialsLightSensitive: v));
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReconstitutionCard(BuildContext context, Medication med) {
    if (med.form != MedicationForm.multiDoseVial ||
        med.strengthValue <= 0 ||
        (med.containerVolumeMl == null && med.perMlValue == null)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Stack(
        children: [
          ReconstitutionSummaryCard(
            strengthValue: med.strengthValue,
            strengthUnit: _unitLabel(med.strengthUnit),
            medicationName: med.name,
            containerVolumeMl: med.containerVolumeMl,
            perMlValue: med.perMlValue,
            volumePerDose: med.volumePerDose,
            reconFluidName: med.diluentName ?? 'Bacteriostatic Water',
            syringeSizeMl: 3.0,
            compact: true,
          ),
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
                final result = await showModalBottomSheet<ReconstitutionResult>(
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
                  final updatedMed = med.copyWith(
                    containerVolumeMl: result.solventVolumeMl,
                    perMlValue: result.perMlConcentration,
                    volumePerDose: result.recommendedUnits / 100,
                  );
                  final box = await Hive.openBox<Medication>('medications');
                  await box.put(updatedMed.id, updatedMed);
                }
              },
              tooltip: 'Edit Reconstitution',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactGrid(BuildContext context, List<Widget> children) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[i]),
            const SizedBox(width: 12),
            if (i + 1 < children.length)
              Expanded(child: children[i + 1])
            else
              const Spacer(),
          ],
        ),
      );
      if (i + 2 < children.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }

  Widget _buildCompactInfoItem(
    BuildContext context, {
    required String label,
    required String value,
    VoidCallback? onTap,
    bool highlighted = false,
    bool warning = false,
    bool isItalic = false,
  }) {
    final theme = Theme.of(context);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            color: warning
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface.withValues(
                    alpha: kOpacityMediumHigh,
                  ),
            fontSize: 13,
          ),
          maxLines: 2, // Increased from 1
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Expanded(child: content),
              Icon(
                Icons.edit_outlined,
                size: 14,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: content,
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
  final Schedule? schedule;
  ScheduledDose(this.dateTime, {this.schedule});
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

String _formatExpiry(DateTime date) {
  final now = DateTime.now();
  final diff = date.difference(now).inDays;
  final dateStr = DateFormat('d MMM y').format(date);
  if (diff < 0) {
    return '$dateStr (Expired)';
  }
  return '$dateStr ($diff days)';
}

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

bool _isIntegerStock(StockUnit unit) {
  return unit == StockUnit.tablets ||
      unit == StockUnit.capsules ||
      unit == StockUnit.preFilledSyringes ||
      unit == StockUnit.singleDoseVials ||
      unit == StockUnit.multiDoseVials;
}

ScheduledDose? _nextDoseForMedication(String medId) {
  final schedulesBox = Hive.box<Schedule>('schedules');
  final doseLogBox = Hive.box<DoseLog>('dose_logs');
  final schedules = schedulesBox.values
      .where((s) => s.medicationId == medId && s.active)
      .toList();

  if (schedules.isEmpty) return null;

  final now = DateTime.now();
  DateTime? nextTime;
  Schedule? nextSchedule;

  for (final schedule in schedules) {
    final times = schedule.hasMultipleTimes
        ? schedule.timesOfDay!
        : [schedule.minutesOfDay];

    for (final minutes in times) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      // Start checking from today
      var candidate = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time has already passed for today, start checking from tomorrow
      // UNLESS it's today and we haven't taken it yet?
      // Actually, if it's in the past, it's either missed or taken.
      // "Next Dose" usually implies future or "due now".
      // If it's 5 mins ago and not taken, is it "Next Dose"? Yes, it's overdue.
      // But the original logic skipped past times.
      // Let's stick to "future" or "very recent past" logic, but for now,
      // let's just find the next *valid* slot that isn't taken.

      // We'll check up to 14 days
      for (int i = 0; i < 14; i++) {
        // Check if this candidate is in the past (with a small buffer, e.g. 1 hour ago is still "next" if missed?)
        // For simplicity, let's say "Next Dose" is strictly in the future OR today.
        // If it's in the past, we skip it unless we want to show overdue.
        // The user said "I marked that dose as taken and it should refresh as taken, or show the next dose."
        // This implies if I take the 9am dose at 9am, it should show the 1pm dose.

        if (candidate.isBefore(now.subtract(const Duration(minutes: 15)))) {
          // If it's more than 15 mins in the past, assume we missed it or it's done, move to next day/time
          // But wait, we need to check if it was taken.
          // If it wasn't taken, it's overdue.
          // For this specific "Next Dose" card, let's just show the next *future* one for now to satisfy "refresh as taken".
          // If we want to show overdue, we need more complex logic.
          // Let's stick to the original "isBefore(now)" check but add the log check.
        }

        if (candidate.isBefore(now)) {
          candidate = candidate.add(const Duration(days: 1));
          continue; // This specific time slot is past, try tomorrow (or next loop iteration will handle it)
          // Actually, the inner loop iterates days.
          // Wait, the original logic:
          // if (candidate.isBefore(now)) candidate = candidate.add(Duration(days: 1));
          // This only added 1 day. It didn't loop.
          // The loop below `for (int i = 0; i < 8; i++)` adds days.
        }

        // Check if this specific slot is taken
        final logId = '${schedule.id}_${candidate.millisecondsSinceEpoch}';
        final isTaken = doseLogBox.containsKey(logId);

        if (schedule.daysOfWeek.contains(candidate.weekday) && !isTaken) {
          // Found a valid, untaken slot
          if (nextTime == null || candidate.isBefore(nextTime)) {
            nextTime = candidate;
            nextSchedule = schedule;
          }
          break; // Found the next slot for this specific time-of-day rule
        }
        candidate = candidate.add(const Duration(days: 1));
      }
    }
  }

  return nextTime != null
      ? ScheduledDose(nextTime, schedule: nextSchedule)
      : null;
}

void _showRefillDialog(BuildContext context, Medication med) async {
  final isMdv = med.form == MedicationForm.multiDoseVial;
  final unit = isMdv ? 'vials' : _stockUnitLabel(med.stockUnit);
  final controller = TextEditingController(text: '1');

  final result = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Refill ${med.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add stock to your inventory.', style: bodyTextStyle(context)),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder: (context, setState) {
              return StepperRow36(
                controller: controller,
                onDec: () {
                  final v = double.tryParse(controller.text) ?? 0;
                  if (v > 0) {
                    controller.text = (v - 1).toStringAsFixed(0);
                  }
                },
                onInc: () {
                  final v = double.tryParse(controller.text) ?? 0;
                  controller.text = (v + 1).toStringAsFixed(0);
                },
                decoration: buildCompactFieldDecoration(context: context),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(unit, style: helperTextStyle(context)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final val = double.tryParse(controller.text);
            if (val != null && val > 0) {
              Navigator.pop(context, val);
            }
          },
          child: const Text('Add Stock'),
        ),
      ],
    ),
  );

  if (result != null && context.mounted) {
    final box = Hive.box<Medication>('medications');
    final newStock = med.stockValue + result;

    box.put(med.id, med.copyWith(stockValue: newStock));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${_formatNumber(result)} $unit')),
    );
  }
}

Future<void> _showStepperEditDialog(
  BuildContext context,
  Medication med,
  String title,
  double initialValue,
  void Function(double) onSave, {
  bool isInt = false,
  String? unit,
}) async {
  final controller = TextEditingController(
    text: isInt ? initialValue.toInt().toString() : initialValue.toString(),
  );

  final result = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatefulBuilder(
            builder: (context, setState) {
              return StepperRow36(
                controller: controller,
                onDec: () {
                  final v = double.tryParse(controller.text) ?? 0;
                  final step = isInt ? 1.0 : 0.1;
                  final newVal = (v - step).clamp(0.0, 1000000.0);
                  controller.text = isInt
                      ? newVal.toInt().toString()
                      : newVal.toStringAsFixed(1);
                },
                onInc: () {
                  final v = double.tryParse(controller.text) ?? 0;
                  final step = isInt ? 1.0 : 0.1;
                  final newVal = (v + step).clamp(0.0, 1000000.0);
                  controller.text = isInt
                      ? newVal.toInt().toString()
                      : newVal.toStringAsFixed(1);
                },
                decoration: buildCompactFieldDecoration(context: context),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              );
            },
          ),
          if (unit != null) ...[
            const SizedBox(height: 8),
            Text(unit, style: helperTextStyle(context)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final val = double.tryParse(controller.text);
            if (val != null) {
              Navigator.pop(context, val);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (result != null && result != initialValue) {
    onSave(result);
  }
}

Future<void> _showEditDialog(
  BuildContext context,
  Medication med,
  String title,
  String initialValue,
  void Function(String) onSave, {
  int maxLines = 1,
  TextInputType? keyboardType,
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
        keyboardType: keyboardType,
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

Future<void> _editDate(
  BuildContext context,
  Medication med,
  String title,
  DateTime? initialDate,
  void Function(DateTime) onSave,
) async {
  final picked = await SmartExpiryPicker.show(
    context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
  );
  if (picked != null) {
    onSave(picked);
  }
}

void _editName(BuildContext context, Medication med) {
  _showEditDialog(context, med, 'Medication Name', med.name, (val) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(name: val));
  });
}

void _editManufacturer(BuildContext context, Medication med) {
  _showEditDialog(context, med, 'Manufacturer', med.manufacturer ?? '', (val) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(manufacturer: val));
  });
}

void _editStrength(BuildContext context, Medication med) {
  _showStepperEditDialog(
    context,
    med,
    'Strength Value',
    med.strengthValue,
    (val) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(strengthValue: val));
    },
    unit: _unitLabel(med.strengthUnit),
  );
}

void _editForm(BuildContext context, Medication med) async {
  final result = await showDialog<MedicationForm>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Select Medication Type'),
      children: MedicationForm.values.map((form) {
        return SimpleDialogOption(
          onPressed: () => Navigator.pop(context, form),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(_formLabel(form)),
          ),
        );
      }).toList(),
    ),
  );

  if (result != null) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(form: result));
  }
}

void _editDescription(BuildContext context, Medication med) {
  _showEditDialog(context, med, 'Description', med.description ?? '', (val) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(description: val));
  }, maxLines: 3);
}

void _editNotes(BuildContext context, Medication med) {
  _showEditDialog(context, med, 'Notes', med.notes ?? '', (val) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(notes: val));
  }, maxLines: 3);
}

void _editBatchNumber(BuildContext context, Medication med) {
  _showEditDialog(context, med, 'Batch Number', med.batchNumber ?? '', (val) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(batchNumber: val));
  });
}

void _editExpiry(BuildContext context, Medication med) {
  _editDate(context, med, 'Expiry Date', med.expiry, (val) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(expiry: val));
  });
}

void _editStorageLocation(BuildContext context, Medication med) {
  _showEditDialog(context, med, 'Storage Location', med.storageLocation ?? '', (
    val,
  ) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(storageLocation: val));
  });
}

void _editStorageConditions(BuildContext context, Medication med) async {
  final result = await showDialog<Map<String, bool>>(
    context: context,
    builder: (context) {
      bool refrigerated = med.requiresRefrigeration;
      bool frozen = med.requiresFreezer;
      bool lightSensitive = med.lightSensitive;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Storage Conditions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Refrigerated'),
                  secondary: const Icon(Icons.ac_unit),
                  value: refrigerated,
                  onChanged: (val) {
                    setState(() {
                      refrigerated = val;
                      if (val) frozen = false;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Frozen'),
                  secondary: const Icon(Icons.severe_cold),
                  value: frozen,
                  onChanged: (val) {
                    setState(() {
                      frozen = val;
                      if (val) refrigerated = false;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Light Sensitive'),
                  secondary: const Icon(Icons.light_mode_outlined),
                  value: lightSensitive,
                  onChanged: (val) {
                    setState(() {
                      lightSensitive = val;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, {
                  'refrigerated': refrigerated,
                  'frozen': frozen,
                  'lightSensitive': lightSensitive,
                }),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != null) {
    final box = Hive.box<Medication>('medications');
    box.put(
      med.id,
      med.copyWith(
        requiresRefrigeration: result['refrigerated']!,
        requiresFreezer: result['frozen']!,
        lightSensitive: result['lightSensitive']!,
      ),
    );
  }
}

void _editLowStockThreshold(BuildContext context, Medication med) {
  _showStepperEditDialog(
    context,
    med,
    'Low Stock Threshold',
    med.lowStockThreshold ?? 0,
    (val) {
      final box = Hive.box<Medication>('medications');
      box.put(
        med.id,
        med.copyWith(lowStockThreshold: val, lowStockEnabled: true),
      );
    },
    isInt: _isIntegerStock(med.stockUnit),
    unit: _stockUnitLabel(med.stockUnit),
  );
}

// MDV Specific Edits
void _editActiveVialBatch(BuildContext context, Medication med) {
  _showEditDialog(
    context,
    med,
    'Active Vial Batch',
    med.activeVialBatchNumber ?? '',
    (val) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(activeVialBatchNumber: val));
    },
  );
}

void _editActiveVialLocation(BuildContext context, Medication med) {
  _showEditDialog(
    context,
    med,
    'Active Vial Location',
    med.activeVialStorageLocation ?? '',
    (val) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(activeVialStorageLocation: val));
    },
  );
}

void _editActiveVialLowStock(BuildContext context, Medication med) {
  _showStepperEditDialog(
    context,
    med,
    'Active Vial Low Stock (mL)',
    med.activeVialLowStockMl ?? 0,
    (val) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(activeVialLowStockMl: val));
    },
    unit: 'mL',
  );
}

void _editBackupVialBatch(BuildContext context, Medication med) {
  _showEditDialog(
    context,
    med,
    'Backup Vial Batch',
    med.backupVialsBatchNumber ?? '',
    (val) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(backupVialsBatchNumber: val));
    },
  );
}

void _editBackupVialLocation(BuildContext context, Medication med) {
  _showEditDialog(
    context,
    med,
    'Backup Vial Location',
    med.backupVialsStorageLocation ?? '',
    (val) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(backupVialsStorageLocation: val));
    },
  );
}

void _editBackupVialExpiry(BuildContext context, Medication med) {
  _editDate(context, med, 'Backup Vial Expiry', med.backupVialsExpiry, (val) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(backupVialsExpiry: val));
  });
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

  // Calculate adherence data for the last 7 days
  List<double> _calculateAdherenceData(Medication med) {
    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final now = DateTime.now();
    final data = <double>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final nextDay = day.add(const Duration(days: 1));

      final logsForDay = doseLogBox.values.where((log) {
        return log.medicationId == med.id &&
            log.actionTime.isAfter(day) &&
            log.actionTime.isBefore(nextDay);
      }).toList();

      if (logsForDay.isEmpty) {
        data.add(-1); // No data
      } else {
        data.add(1.0); // Taken (simplified - could calculate partial adherence)
      }
    }

    return data;
  }

Widget _buildAdherenceGraph(BuildContext context, Color color, Medication med) {
  final doseBox = Hive.box<DoseLog>('dose_logs');
  final scheduleBox = Hive.box<Schedule>('schedules');

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final data = <double>[];

  final schedules = scheduleBox.values
      .where((s) => s.medicationId == med.id && s.active)
      .toList();

  if (schedules.isEmpty) {
    return const SizedBox.shrink();
  }

  for (int i = 6; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final dayOfWeek = date.weekday;
    final isScheduledDay = schedules.any(
      (s) => s.daysOfWeek.contains(dayOfWeek),
    );

    if (!isScheduledDay) {
      data.add(-1.0);
      continue;
    }

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
  final scheduleBox = Hive.box<Schedule>('schedules');
  final schedules = scheduleBox.values
      .where((s) => s.medicationId == med.id && s.active)
      .toList();

  if (schedules.isEmpty || med.stockValue <= 0) {
    return const SizedBox.shrink();
  }

  double weeklyConsumption = 0;
  for (final schedule in schedules) {
    final dosesPerDay = schedule.hasMultipleTimes
        ? schedule.timesOfDay!.length
        : 1;
    final daysPerWeek = schedule.daysOfWeek.length;

    double amountPerDose = 1.0;
    if (med.form == MedicationForm.tablet ||
        med.form == MedicationForm.capsule) {
      if (schedule.doseValue > 0) {
        amountPerDose = schedule.doseValue;
      }
    }

    weeklyConsumption += dosesPerDay * daysPerWeek * amountPerDose;
  }

  if (weeklyConsumption == 0) return const SizedBox.shrink();

  final dailyConsumption = weeklyConsumption / 7.0;

  double totalStockDoses = med.stockValue;

  if (med.form == MedicationForm.multiDoseVial) {
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
  final dateStr = DateFormat('d MMM y').format(date);

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
        'Based on current schedule',
        style: TextStyle(
          color: color.withValues(alpha: 0.5),
          fontSize: 9,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.right,
      ),
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
              'Expires: ${DateFormat('d MMM y').format(expiry)}',
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
