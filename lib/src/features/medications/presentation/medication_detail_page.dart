// ignore_for_file: unnecessary_null_comparison, unused_element, unused_element_parameter, unused_local_variable

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
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_header_widget.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/next_dose_card.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/widgets/enhanced_schedule_card.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_reports_widget.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/reconstitution_summary_card.dart';
import 'package:dosifi_v5/src/widgets/smart_expiry_picker.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';
// DoseHistoryWidget replaced by MedicationReportsWidget

/// Modern, revolutionized medication detail screen with:
/// - Hero header with gradient and key stats
/// - Interactive quick action cards
/// - Visual stock progress indicators
/// - Clean sectioned information display
/// - Responsive layout for all screen sizes
const double _kDetailHeaderExpandedHeight =
    224; // Keep header size consistent (reduced empty space)
const double _kDetailHeaderCollapsedHeight = 56;

class MedicationDetailPage extends ConsumerStatefulWidget {
  const MedicationDetailPage({super.key, this.medicationId, this.initial});
  final String? medicationId;
  final Medication? initial;

  @override
  ConsumerState<MedicationDetailPage> createState() =>
      _MedicationDetailPageState();
}

class _MedicationDetailPageState extends ConsumerState<MedicationDetailPage> {
  late ScrollController _scrollController;
  bool _isDetailsExpanded = true; // Collapsible state for details card

  double _measuredExpandedHeaderHeight = _kDetailHeaderExpandedHeight;
  final GlobalKey _headerMeasureKey = GlobalKey();

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

  void _scheduleHeaderHeightMeasurement(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderObject = _headerMeasureKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;

      final measuredHeight = renderObject.size.height;
      final desired = measuredHeight.clamp(
        _kDetailHeaderExpandedHeight,
        double.infinity,
      );

      if ((desired - _measuredExpandedHeaderHeight).abs() > 1.0) {
        setState(() {
          _measuredExpandedHeaderHeight = desired;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleHeaderHeightMeasurement(context);

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

          // Check if we have schedules for schedule-specific header content
          final scheduleBox = Hive.box<Schedule>('schedules');
          final hasSchedules = scheduleBox.values.any(
            (s) => s.medicationId == updatedMed.id && s.active,
          );
          final headerHeight = _measuredExpandedHeaderHeight;

          // Calculate scroll progress for title opacity
          final offset = _scrollController.hasClients
              ? _scrollController.offset
              : 0.0;
          final maxOffset = headerHeight - _kDetailHeaderCollapsedHeight;
          final scrollProgress = (offset / maxOffset).clamp(0.0, 1.0);

          return Stack(
            children: [
              CustomScrollView(
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
                        final collapsedHeight =
                            _kDetailHeaderCollapsedHeight + top;
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
                              height:
                                  expandedHeight, // Ensure header has finite height for layout
                              child: Opacity(
                                opacity: (1.0 - t * 2.0).clamp(0.0, 1.0),
                                child: SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      kPageHorizontalPadding,
                                      4, // Reduced from 12
                                      kPageHorizontalPadding,
                                      kSpacingXS,
                                    ),
                                    child: MedicationHeaderWidget(
                                      medication: updatedMed,
                                      onRefill: () => _showRefillDialog(
                                        context,
                                        updatedMed,
                                      ),
                                      onAdHocDose: () => _showAdHocDoseDialog(
                                        context,
                                        updatedMed,
                                      ),
                                      hasSchedules: hasSchedules,
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
                                      onTap: () =>
                                          _editName(context, updatedMed),
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                        onTap: () => _editManufacturer(
                                          context,
                                          updatedMed,
                                        ),
                                        child: Opacity(
                                          opacity: (1.0 - t * 2.0).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 1,
                                            ),
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
                          PopupMenuItem(
                            value: 'supplies',
                            child: Text('Supplies'),
                          ),
                          PopupMenuItem(
                            value: 'schedules',
                            child: Text('Schedules'),
                          ),
                          PopupMenuItem(
                            value: 'calendar',
                            child: Text('Calendar'),
                          ),
                          PopupMenuItem(
                            value: 'reconstitution',
                            child: Text('Reconstitution Calculator'),
                          ),
                          PopupMenuItem(
                            value: 'analytics',
                            child: Text('Analytics'),
                          ),
                          PopupMenuItem(
                            value: 'settings',
                            child: Text('Settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Reconstitution Card (if applicable)
                  if (updatedMed.form == MedicationForm.multiDoseVial)
                    SliverToBoxAdapter(
                      child: _buildReconstitutionCard(context, updatedMed),
                    ),

                  // Medication Reports Widget (History + Adherence tabs)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                      child: MedicationReportsWidget(medication: updatedMed),
                    ),
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
              ),

              // Offstage measurement to make SliverAppBar height match content.
              Offstage(
                offstage: true,
                child: SafeArea(
                  child: Padding(
                    key: _headerMeasureKey,
                    padding: const EdgeInsets.fromLTRB(
                      kPageHorizontalPadding,
                      4,
                      kPageHorizontalPadding,
                      kSpacingXS,
                    ),
                    child: MedicationHeaderWidget(
                      medication: updatedMed,
                      onRefill: () {},
                      onAdHocDose: () {},
                      hasSchedules: hasSchedules,
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
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

    return Container(
      decoration: buildStandardCardDecoration(context: context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header
          InkWell(
            onTap: () =>
                setState(() => _isDetailsExpanded = !_isDetailsExpanded),
            child: Padding(
              padding: const EdgeInsets.all(kCardPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: kSpacingS),
                  Text(
                    'Medication Details',
                    style: cardTitleStyle(
                      context,
                    )?.copyWith(color: colorScheme.primary),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isDetailsExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isDetailsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                kCardPadding,
                0,
                kCardPadding,
                kCardPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Schedule & Next Dose
                  if (hasSchedules) ...[
                    _buildScheduleSection(context, med, nextDose),
                    const Divider(height: kSpacingXL),
                  ],

                  // 2. Merged Medication Details
                  _buildMergedDetailsSection(context, med),
                  const Divider(height: kSpacingXL),

                  // Sealed Vials (MDV Only) - separate card for backup stock
                  if (med.form == MedicationForm.multiDoseVial) ...[
                    _buildBackupStockSection(context, med),
                    const SizedBox(height: kSpacingM),
                  ],

                  const SizedBox(height: kSpacingL),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _deleteMedication(context, med),
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      label: Text(
                        'Delete Medication',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        .where((s) => s.medicationId == med.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (schedules.isNotEmpty) ...[
          // Scheduled Doses Section Heading with Icon
          Row(
            children: [
              Icon(
                Icons.medication_rounded,
                size: kIconSizeMedium,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: kSpacingS),
              Text('Scheduled Doses', style: sectionTitleStyle(context)),
            ],
          ),
          const SizedBox(height: kSpacingM),
          // Show doses for active schedules only
          NextDoseCard(
            medication: med,
            schedules: schedules.where((s) => s.active).toList(),
          ),
          const SizedBox(height: kSpacingL),
        ],

        // Schedules Section - show ALL schedules (including paused)
        if (schedules.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: kIconSizeMedium,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: kSpacingS),
              Text('Schedules', style: sectionTitleStyle(context)),
            ],
          ),
          const SizedBox(height: kSpacingM),
          // Show ALL schedules including paused ones
          ...schedules.map(
            (schedule) =>
                EnhancedScheduleCard(schedule: schedule, medication: med),
          ),
          const SizedBox(height: kSpacingL),
          // Adherence now moved to MedicationReportsWidget tabs
        ],
      ],
    );
  }

  Widget divvyIcon(IconData icon, {Color? color, double? size}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  Widget _buildMergedDetailsSection(BuildContext context, Medication med) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMdv = med.form == MedicationForm.multiDoseVial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IDENTITY
        _buildDetailTile(
          context,
          'Name',
          med.name,
          onTap: () => _editName(context, med),
        ),
        _buildDetailTile(context, 'Type', _formLabel(med.form)),
        _buildDetailTile(
          context,
          'Strength',
          '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
          onTap: () => _editStrength(context, med),
        ),
        _buildDetailTile(
          context,
          'Manufacturer',
          med.manufacturer ?? 'Not set',
          isPlaceholder: med.manufacturer == null,
          onTap: () => _editManufacturer(context, med),
        ),

        const SizedBox(height: 8), // Section spacing (divider removed)
        // ACTIVE VIAL (MDV only) - merged into this card since it's the tracked medicine for dosing
        if (isMdv) ...[
          // Section header for Active Vial
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Active Vial',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Volume remaining
          if (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
            _buildDetailTile(
              context,
              'Volume',
              '${_formatNumber(med.activeVialVolume ?? med.containerVolumeMl!)} / ${_formatNumber(med.containerVolumeMl!)} mL',
            ),
          // Diluent
          if (med.diluentName != null && med.diluentName!.isNotEmpty)
            _buildDetailTile(context, 'Diluent', med.diluentName!),
          // Active vial batch & location
          _buildDetailTile(
            context,
            'Batch #',
            med.activeVialBatchNumber ?? 'Not set',
            isPlaceholder: med.activeVialBatchNumber == null,
            onTap: () => _editActiveVialBatch(context, med),
          ),
          _buildDetailTile(
            context,
            'Location',
            med.activeVialStorageLocation ?? 'Not set',
            isPlaceholder: med.activeVialStorageLocation == null,
            onTap: () => _editActiveVialLocation(context, med),
          ),
          _buildDetailTile(
            context,
            'Low Alert',
            med.activeVialLowStockMl != null
                ? '${_formatNumber(med.activeVialLowStockMl!)} mL'
                : 'Not set',
            isPlaceholder: med.activeVialLowStockMl == null,
            onTap: () => _editActiveVialLowStock(context, med),
          ),
          // Active vial storage conditions
          _buildActiveVialConditionsRow(context, med),

          const SizedBox(height: 8), // Section spacing (divider removed)
        ],

        // INVENTORY (for non-MDV or general inventory info)
        if (!isMdv) ...[
          _buildDetailTile(
            context,
            'Batch #',
            med.batchNumber ?? 'Not set',
            isPlaceholder: med.batchNumber == null,
            onTap: () => _editBatchNumber(context, med),
          ),
          _buildDetailTile(
            context,
            'Expiry',
            med.expiry != null ? _formatExpiry(med.expiry!) : 'Not set',
            isPlaceholder: med.expiry == null,
            isWarning: med.expiry != null && _isExpiringSoon(med.expiry!),
            onTap: () => _editExpiry(context, med),
          ),
          _buildDetailTile(
            context,
            'Low Stock',
            med.lowStockEnabled
                ? '${_formatNumber(med.lowStockThreshold ?? 0)} ${_stockUnitLabel(med.stockUnit)}'
                : 'Disabled',
            onTap: () => _editLowStockThreshold(context, med),
          ),

          const SizedBox(height: 8), // Section spacing (divider removed)
          // STORAGE (for non-MDV)
          _buildDetailTile(
            context,
            'Location',
            med.storageLocation ?? 'Not set',
            isPlaceholder: med.storageLocation == null,
            onTap: () => _editStorageLocation(context, med),
          ),
          _buildConditionsRow(context, med),
        ],

        // NOTES (optional)
        if (med.description != null && med.description!.isNotEmpty) ...[
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          _buildDetailTile(
            context,
            'Description',
            med.description!,
            onTap: () => _editDescription(context, med),
          ),
        ],
        if (med.notes != null && med.notes!.isNotEmpty)
          _buildDetailTile(
            context,
            'Notes',
            med.notes!,
            isItalic: true,
            onTap: () => _editNotes(context, med),
          ),
      ],
    );
  }

  Widget _buildDetailTile(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
    bool isPlaceholder = false,
    bool isWarning = false,
    bool isItalic = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontStyle: isItalic || isPlaceholder ? FontStyle.italic : null,
                color: isWarning
                    ? colorScheme.error
                    : isPlaceholder
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                    : colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _buildConditionsRow(BuildContext context, Medication med) {
    final colorScheme = Theme.of(context).colorScheme;
    final conditions = <Widget>[];

    if (med.requiresRefrigeration) {
      conditions.add(_buildMiniChip(context, 'Fridge', icon: Icons.ac_unit));
    }
    if (med.requiresFreezer) {
      conditions.add(
        _buildMiniChip(context, 'Freeze', icon: Icons.severe_cold),
      );
    }
    if (med.lightSensitive) {
      conditions.add(
        _buildMiniChip(context, 'Light', icon: Icons.dark_mode_outlined),
      );
    }
    if (conditions.isEmpty) {
      conditions.add(
        _buildMiniChip(context, 'Room', icon: Icons.thermostat_outlined),
      );
    }

    return InkWell(
      onTap: () => _showStorageConditionsDialog(context, med),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                'Conditions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Wrap(spacing: 6, children: conditions),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(BuildContext context, String label, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingS,
        vertical: kSpacingXS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(kBorderRadiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colorScheme.onPrimary),
            const SizedBox(width: kSpacingXS),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: kFontSizeSmall,
              fontWeight: kFontWeightSemiBold,
              color: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getStorageConditionsLabel(Medication med) {
    final conditions = <String>[];
    if (med.requiresRefrigeration) conditions.add('Refrigerate');
    if (med.requiresFreezer) conditions.add('Freeze');
    if (med.lightSensitive) conditions.add('Light Sensitive');

    if (conditions.isEmpty) return 'None specified';
    return conditions.join(', ');
  }

  Widget _buildStorageConditionsDisplay(BuildContext context, Medication med) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Storage Conditions',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            GestureDetector(
              onTap: () => _showStorageConditionsDialog(context, med),
              child: Icon(
                Icons.edit_rounded,
                size: kIconSizeSmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: kSpacingXS),
        // Show each condition with icon
        _buildStorageConditionRow(
          context,
          icon: Icons.ac_unit,
          label: 'Refrigerate',
          isEnabled: med.requiresRefrigeration,
        ),
        _buildStorageConditionRow(
          context,
          icon: Icons.severe_cold,
          label: 'Freeze',
          isEnabled: med.requiresFreezer,
        ),
        _buildStorageConditionRow(
          context,
          icon: Icons.dark_mode_outlined,
          label: 'Protect from Light',
          isEnabled: med.lightSensitive,
        ),
      ],
    );
  }

  Widget _buildStorageConditionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isEnabled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: kIconSizeSmall,
            color: isEnabled ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          const SizedBox(width: kSpacingS),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isEnabled
                  ? colorScheme.onSurface
                  : colorScheme.outlineVariant,
            ),
          ),
          const Spacer(),
          Text(
            isEnabled ? 'On' : 'Off',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isEnabled
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              fontWeight: kFontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showStorageConditionsDialog(BuildContext context, Medication med) {
    bool refrigerate = med.requiresRefrigeration;
    bool freeze = med.requiresFreezer;
    bool light = med.lightSensitive;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Storage Conditions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  value: refrigerate,
                  onChanged: (v) {
                    setState(() {
                      refrigerate = v ?? false;
                      if (refrigerate) freeze = false;
                    });
                  },
                  title: const Text('Refrigerate (2-8°C)'),
                ),
                CheckboxListTile(
                  value: freeze,
                  onChanged: (v) {
                    setState(() {
                      freeze = v ?? false;
                      if (freeze) refrigerate = false;
                    });
                  },
                  title: const Text('Freeze'),
                ),
                CheckboxListTile(
                  value: light,
                  onChanged: (v) {
                    setState(() {
                      light = v ?? false;
                    });
                  },
                  title: const Text('Protect from Light'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final box = Hive.box<Medication>('medications');
                  box.put(
                    med.id,
                    med.copyWith(
                      requiresRefrigeration: refrigerate,
                      requiresFreezer: freeze,
                      lightSensitive: light,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveVialSection(BuildContext context, Medication med) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(kBorderRadiusLarge),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vial currently in use for injections',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Volume remaining (prominent display)
          if (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Volume',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_formatNumber(med.activeVialVolume ?? med.containerVolumeMl!)} / ${_formatNumber(med.containerVolumeMl!)} mL',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),

          // Details
          if (med.diluentName != null && med.diluentName!.isNotEmpty)
            _buildDetailTile(context, 'Diluent', med.diluentName!),
          _buildDetailTile(
            context,
            'Batch #',
            med.activeVialBatchNumber ?? 'Not set',
            isPlaceholder: med.activeVialBatchNumber == null,
            onTap: () => _editActiveVialBatch(context, med),
          ),
          _buildDetailTile(
            context,
            'Location',
            med.activeVialStorageLocation ?? 'Not set',
            isPlaceholder: med.activeVialStorageLocation == null,
            onTap: () => _editActiveVialLocation(context, med),
          ),
          _buildDetailTile(
            context,
            'Low Alert',
            med.activeVialLowStockMl != null
                ? '${_formatNumber(med.activeVialLowStockMl!)} mL'
                : 'Not set',
            isPlaceholder: med.activeVialLowStockMl == null,
            onTap: () => _editActiveVialLowStock(context, med),
          ),

          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),

          // Storage conditions as tappable chips
          _buildActiveVialConditionsRow(context, med),
        ],
      ),
    );
  }

  Widget _buildActiveVialConditionsRow(BuildContext context, Medication med) {
    final colorScheme = Theme.of(context).colorScheme;
    final conditions = <Widget>[];

    // Only show chips for active conditions
    if (med.activeVialRequiresRefrigeration) {
      conditions.add(_buildMiniChip(context, 'Fridge', icon: Icons.ac_unit));
    }
    if (med.activeVialRequiresFreezer) {
      conditions.add(
        _buildMiniChip(context, 'Freeze', icon: Icons.severe_cold),
      );
    }
    if (med.activeVialLightSensitive) {
      conditions.add(
        _buildMiniChip(context, 'Light', icon: Icons.dark_mode_outlined),
      );
    }
    if (conditions.isEmpty) {
      conditions.add(
        _buildMiniChip(context, 'Room', icon: Icons.thermostat_outlined),
      );
    }

    return InkWell(
      onTap: () => _showActiveVialConditionsDialog(context, med),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                'Conditions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Wrap(spacing: 6, children: conditions),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog for editing Active Vial storage conditions
  void _showActiveVialConditionsDialog(BuildContext context, Medication med) {
    bool fridge = med.activeVialRequiresRefrigeration;
    bool freezer = med.activeVialRequiresFreezer;
    bool light = med.activeVialLightSensitive;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          return AlertDialog(
            title: Text(
              'Active Vial Conditions',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('❄️ Requires Refrigeration'),
                  value: fridge,
                  onChanged: (v) => setState(() {
                    fridge = v ?? false;
                    if (fridge) freezer = false;
                  }),
                ),
                CheckboxListTile(
                  title: const Text('🧊 Requires Freezer'),
                  value: freezer,
                  onChanged: (v) => setState(() {
                    freezer = v ?? false;
                    if (freezer) fridge = false;
                  }),
                ),
                CheckboxListTile(
                  title: const Text('☀️ Light Sensitive'),
                  value: light,
                  onChanged: (v) => setState(() => light = v ?? false),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final box = Hive.box<Medication>('medications');
                  box.put(
                    med.id,
                    med.copyWith(
                      activeVialRequiresRefrigeration: fridge,
                      activeVialRequiresFreezer: freezer,
                      activeVialLightSensitive: light,
                    ),
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackupStockConditionsRow(BuildContext context, Medication med) {
    final colorScheme = Theme.of(context).colorScheme;
    final conditions = <Widget>[];

    // Only show chips for active conditions
    if (med.backupVialsRequiresRefrigeration) {
      conditions.add(_buildMiniChip(context, 'Fridge', icon: Icons.ac_unit));
    }
    if (med.backupVialsRequiresFreezer) {
      conditions.add(
        _buildMiniChip(context, 'Freeze', icon: Icons.severe_cold),
      );
    }
    if (med.backupVialsLightSensitive) {
      conditions.add(
        _buildMiniChip(context, 'Light', icon: Icons.dark_mode_outlined),
      );
    }
    if (conditions.isEmpty) {
      conditions.add(
        _buildMiniChip(context, 'Room', icon: Icons.thermostat_outlined),
      );
    }

    return InkWell(
      onTap: () => _showBackupStockConditionsDialog(context, med),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                'Conditions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Wrap(spacing: 6, children: conditions),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog for editing Backup Stock storage conditions
  void _showBackupStockConditionsDialog(BuildContext context, Medication med) {
    bool fridge = med.backupVialsRequiresRefrigeration;
    bool freezer = med.backupVialsRequiresFreezer;
    bool light = med.backupVialsLightSensitive;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          return AlertDialog(
            title: Text(
              'Sealed Vials Conditions',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('❄️ Requires Refrigeration'),
                  value: fridge,
                  onChanged: (v) => setState(() {
                    fridge = v ?? false;
                    if (fridge) freezer = false;
                  }),
                ),
                CheckboxListTile(
                  title: const Text('🧊 Requires Freezer'),
                  value: freezer,
                  onChanged: (v) => setState(() {
                    freezer = v ?? false;
                    if (freezer) fridge = false;
                  }),
                ),
                CheckboxListTile(
                  title: const Text('☀️ Light Sensitive'),
                  value: light,
                  onChanged: (v) => setState(() => light = v ?? false),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final box = Hive.box<Medication>('medications');
                  box.put(
                    med.id,
                    med.copyWith(
                      backupVialsRequiresRefrigeration: fridge,
                      backupVialsRequiresFreezer: freezer,
                      backupVialsLightSensitive: light,
                    ),
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackupStockSection(BuildContext context, Medication med) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Backup Stock', style: sectionTitleStyle(context)),
              const Spacer(),
              Text(
                '${_formatNumber(med.stockValue).split('.')[0]} vials',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Restock button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () => _showRestockSealedVialsDialog(context, med),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Restock'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Details
        _buildDetailTile(
          context,
          'Batch #',
          med.backupVialsBatchNumber ?? 'Not set',
          isPlaceholder: med.backupVialsBatchNumber == null,
          onTap: () => _editBackupVialBatch(context, med),
        ),
        _buildDetailTile(
          context,
          'Expiry',
          med.backupVialsExpiry != null
              ? _formatExpiry(med.backupVialsExpiry!)
              : 'Not set',
          isPlaceholder: med.backupVialsExpiry == null,
          isWarning:
              med.backupVialsExpiry != null &&
              _isExpiringSoon(med.backupVialsExpiry!),
          onTap: () => _editBackupVialExpiry(context, med),
        ),
        _buildDetailTile(
          context,
          'Location',
          med.backupVialsStorageLocation ?? 'Not set',
          isPlaceholder: med.backupVialsStorageLocation == null,
          onTap: () => _editBackupVialLocation(context, med),
        ),

        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),

        // Storage conditions
        _buildBackupStockConditionsRow(context, med),
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
    final isEditable = onTap != null;
    final isPlaceholder = value.startsWith('Tap to');

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with fixed width for alignment
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Value
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
              fontStyle: isItalic || isPlaceholder
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: warning
                  ? theme.colorScheme.error
                  : isPlaceholder
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Subtle chevron for editable items
        if (isEditable)
          Icon(
            Icons.chevron_right,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
      ],
    );

    if (isEditable) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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

  if (isMdv) {
    _showMdvRefillDialog(context, med);
  } else {
    _showSimpleRefillDialog(context, med);
  }
}

/// Refill dialog for Tablets, Capsules, SDV, Syringes
void _showSimpleRefillDialog(BuildContext context, Medication med) async {
  final unit = _stockUnitLabel(med.stockUnit);
  final controller = TextEditingController(text: '1');
  final currentStock = med.stockValue;
  final maxStock = med.initialStockValue ?? med.stockValue;

  // Track selected mode: 'add' or 'fillToMax'
  String selectedMode = 'add';

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (stateContext, setState) {
        final theme = Theme.of(stateContext);
        final addAmount = double.tryParse(controller.text) ?? 0;
        final previewTotal = selectedMode == 'add'
            ? currentStock + addAmount
            : maxStock;

        return AlertDialog(
          title: Text(
            'Refill ${med.name}',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Helper text
              Text(
                'Add stock after receiving a new prescription or restocking. "Add" will increase the stock by a specific amount (and update your maximum if it exceeds the current max). "Fill to Max" restores stock to your original maximum level.',
                style: helperTextStyle(stateContext),
              ),
              const SizedBox(height: 16),

              // Current stock info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Stock:'),
                        Text(
                          '${_formatNumber(currentStock)} $unit',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Maximum Stock:'),
                        Text(
                          '${_formatNumber(maxStock)} $unit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mode selection - Radio buttons instead of chips
              Text(
                'Refill Method:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Add to current stock'),
                subtitle: const Text('Specify amount to add'),
                value: 'add',
                groupValue: selectedMode,
                onChanged: (v) => setState(() => selectedMode = v ?? 'add'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('Fill to maximum'),
                subtitle: Text('Set stock to ${_formatNumber(maxStock)} $unit'),
                value: 'fillToMax',
                groupValue: selectedMode,
                onChanged: (v) => setState(() => selectedMode = v ?? 'add'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),

              // Amount input (only for Add mode)
              if (selectedMode == 'add') ...[
                const SizedBox(height: 8),
                Text(
                  'Amount to Add:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Center(
                  child: StepperRow36(
                    controller: controller,
                    fixedFieldWidth: 80, // Required for dialog use
                    onDec: () {
                      final v = double.tryParse(controller.text) ?? 0;
                      if (v > 0) {
                        controller.text = (v - 1).toStringAsFixed(0);
                        setState(() {});
                      }
                    },
                    onInc: () {
                      final v = double.tryParse(controller.text) ?? 0;
                      controller.text = (v + 1).toStringAsFixed(0);
                      setState(() {});
                    },
                    decoration: buildCompactFieldDecoration(
                      context: stateContext,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(child: Text(unit, style: helperTextStyle(stateContext))),
              ],
              const SizedBox(height: 16),

              // Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Total:'),
                    Text(
                      '${_formatNumber(previewTotal)} $unit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedMode == 'add') {
                  final val = double.tryParse(controller.text);
                  if (val != null && val > 0) {
                    Navigator.pop(dialogContext, {
                      'mode': 'add',
                      'amount': val,
                    });
                  }
                } else {
                  Navigator.pop(dialogContext, {'mode': 'fillToMax'});
                }
              },
              child: const Text('Refill'),
            ),
          ],
        );
      },
    ),
  );

  if (result != null && context.mounted) {
    final box = Hive.box<Medication>('medications');
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');
    final now = DateTime.now();
    double newStock;
    String message;
    InventoryChangeType changeType;
    double changeAmount;

    if (result['mode'] == 'add') {
      final amount = result['amount'] as double;
      newStock = med.stockValue + amount;
      message = 'Added ${_formatNumber(amount)} $unit';
      changeType = InventoryChangeType.refillAdd;
      changeAmount = amount;
    } else {
      newStock = maxStock;
      message = 'Refilled to max (${_formatNumber(newStock)} $unit)';
      changeType = InventoryChangeType.refillToMax;
      changeAmount = newStock - med.stockValue;
    }

    // Update stock
    box.put(med.id, med.copyWith(stockValue: newStock));

    // Log the refill for reporting
    final inventoryLog = InventoryLog(
      id: 'refill_${med.id}_${now.millisecondsSinceEpoch}',
      medicationId: med.id,
      medicationName: med.name,
      changeType: changeType,
      previousStock: med.stockValue,
      newStock: newStock,
      changeAmount: changeAmount,
      notes: message,
      timestamp: now,
    );
    inventoryLogBox.put(inventoryLog.id, inventoryLog);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// MDV Refill dialog - Open new vial with sealed vial management
void _showMdvRefillDialog(BuildContext context, Medication med) async {
  final controller = TextEditingController(text: '1');
  final currentVolume = med.activeVialVolume ?? 0;
  final vialSize = med.containerVolumeMl ?? 5.0;
  final sealedVials = med.stockValue.toInt();

  // Track options
  String selectedMode = 'replace'; // 'replace' or 'topUp'
  bool useFromStock = sealedVials > 0;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        final previewVolume = selectedMode == 'replace'
            ? vialSize
            : currentVolume + vialSize;

        return AlertDialog(
          title: Text(
            'Open New Vial',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Helper text
              Text(
                'Open a new vial from your sealed stock. Choose to replace the current vial or add to existing volume.',
                style: helperTextStyle(context),
              ),
              const SizedBox(height: 16),

              // Current state
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Active Vial:'),
                        Text(
                          '${_formatNumber(currentVolume)} mL remaining',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sealed Vials:'),
                        Text(
                          '$sealedVials in stock',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sealedVials == 0 ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mode selection
              const Text(
                'Action:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ChoiceChip(
                label: Text(
                  'Replace (discard ${_formatNumber(currentVolume)} mL)',
                ),
                selected: selectedMode == 'replace',
                onSelected: (_) => setState(() => selectedMode = 'replace'),
              ),
              const SizedBox(height: 4),
              ChoiceChip(
                label: Text('Top Up (add ${_formatNumber(vialSize)} mL)'),
                selected: selectedMode == 'topUp',
                onSelected: (_) => setState(() => selectedMode = 'topUp'),
              ),
              const SizedBox(height: 16),

              // Use from stock checkbox
              CheckboxListTile(
                title: const Text('Use sealed vial from stock'),
                subtitle: sealedVials == 0
                    ? Text(
                        'No sealed vials available',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    : Text('Will deduct 1 vial (${sealedVials - 1} remaining)'),
                value: useFromStock,
                onChanged: (v) => setState(() => useFromStock = v ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 12),

              // Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Volume:'),
                    Text(
                      '${_formatNumber(previewVolume)} mL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'mode': selectedMode,
                  'useFromStock': useFromStock,
                });
              },
              child: const Text('Open Vial'),
            ),
          ],
        );
      },
    ),
  );

  if (result != null && context.mounted) {
    final box = Hive.box<Medication>('medications');
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');
    final now = DateTime.now();
    final mode = result['mode'] as String;
    final useStock = result['useFromStock'] as bool;

    double newVolume;
    double newSealedCount = med.stockValue;
    final previousSealedCount = med.stockValue;

    if (mode == 'replace') {
      newVolume = vialSize;
    } else {
      newVolume = currentVolume + vialSize;
    }

    if (useStock && sealedVials > 0) {
      newSealedCount = med.stockValue - 1;
    }

    box.put(
      med.id,
      med.copyWith(activeVialVolume: newVolume, stockValue: newSealedCount),
    );

    // Log the vial opening for reporting
    final inventoryLog = InventoryLog(
      id: 'vial_${med.id}_${now.millisecondsSinceEpoch}',
      medicationId: med.id,
      medicationName: med.name,
      changeType: InventoryChangeType.vialOpened,
      previousStock: previousSealedCount,
      newStock: newSealedCount,
      changeAmount: useStock ? -1 : 0,
      notes:
          '${mode == 'replace' ? 'Replaced' : 'Topped up'} vial to ${_formatNumber(newVolume)} mL',
      timestamp: now,
    );
    inventoryLogBox.put(inventoryLog.id, inventoryLog);

    final actionText = mode == 'replace' ? 'Replaced' : 'Topped up';
    final stockText = useStock ? ' (1 sealed vial used)' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$actionText vial - ${_formatNumber(newVolume)} mL$stockText',
        ),
      ),
    );
  }
}

/// Dialog to add sealed vials to MDV reserve stock
void _showRestockSealedVialsDialog(BuildContext context, Medication med) async {
  final controller = TextEditingController(text: '1');
  final currentStock = med.stockValue.toInt();

  final result = await showDialog<double>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        final addAmount = int.tryParse(controller.text) ?? 0;
        final previewTotal = currentStock + addAmount;

        return AlertDialog(
          title: Text(
            'Restock Sealed Vials',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Helper text
              Text(
                'Add new sealed vials to your backup stock inventory.',
                style: helperTextStyle(context),
              ),
              const SizedBox(height: 16),

              // Current stock
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Sealed Vials:'),
                    Text(
                      '$currentStock',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount input
              Text('Add vials:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Center(
                child: StepperRow36(
                  controller: controller,
                  fixedFieldWidth: 80, // Required for dialog use
                  onDec: () {
                    final v = int.tryParse(controller.text) ?? 0;
                    if (v > 0) {
                      controller.text = (v - 1).toString();
                      setState(() {});
                    }
                  },
                  onInc: () {
                    final v = int.tryParse(controller.text) ?? 0;
                    controller.text = (v + 1).toString();
                    setState(() {});
                  },
                  decoration: buildCompactFieldDecoration(context: context),
                ),
              ),
              const SizedBox(height: 16),

              // Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Total:'),
                    Text(
                      '$previewTotal vials',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
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
              child: const Text('Add Vials'),
            ),
          ],
        );
      },
    ),
  );

  if (result != null && context.mounted) {
    final box = Hive.box<Medication>('medications');
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');
    final now = DateTime.now();
    final previousStock = med.stockValue;
    final newStock = previousStock + result;

    box.put(med.id, med.copyWith(stockValue: newStock));

    // Log the restock for reporting
    final inventoryLog = InventoryLog(
      id: 'restock_${med.id}_${now.millisecondsSinceEpoch}',
      medicationId: med.id,
      medicationName: med.name,
      changeType: InventoryChangeType.vialRestocked,
      previousStock: previousStock,
      newStock: newStock,
      changeAmount: result,
      notes: 'Added ${result.toInt()} sealed vials',
      timestamp: now,
    );
    inventoryLogBox.put(inventoryLog.id, inventoryLog);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${result.toInt()} sealed vials (${newStock.toInt()} total)',
        ),
      ),
    );
  }
}

void _showAdHocDoseDialog(BuildContext context, Medication med) async {
  final isMdv = med.form == MedicationForm.multiDoseVial;

  // For MDV, use mL; for others, use stock unit
  final String unit = isMdv ? 'mL' : _stockUnitLabel(med.stockUnit);
  double syringeSize = 1.0; // Default to 1mL syringe
  String selectedUnit = 'mL'; // Default to mL for input
  final double maxVolume = med.activeVialVolume ?? med.containerVolumeMl ?? 3.0;

  // Calculate concentration for strength-to-volume conversion
  // concentration = mg per mL (or mcg per mL depending on strengthUnit)
  final double? concentration =
      (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
      ? med.strengthValue / med.containerVolumeMl!
      : null;
  final String strengthUnit = _unitLabel(med.strengthUnit);

  final volumeController = TextEditingController(text: isMdv ? '0.5' : '1');
  final strengthController = TextEditingController();
  final notesController = TextEditingController();

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (stateContext, setState) {
        final theme = Theme.of(stateContext);
        final colorScheme = theme.colorScheme;

        // Get input value and convert to mL based on selected unit
        final inputValue = double.tryParse(volumeController.text) ?? 0;
        double volumeInMl;
        double doseInStrengthUnit;

        if (selectedUnit == 'mL') {
          // Input is in mL
          volumeInMl = inputValue;
          doseInStrengthUnit = concentration != null
              ? volumeInMl * concentration
              : 0;
        } else if (selectedUnit == 'mg' || selectedUnit == 'mcg') {
          // Input is in mg/mcg - convert to mL
          doseInStrengthUnit = inputValue;
          volumeInMl = concentration != null && concentration > 0
              ? inputValue / concentration
              : 0;
        } else {
          // Input is in units (IU) - assume 1 unit = 0.01mL or use concentration
          volumeInMl = inputValue / 100; // 100 units = 1 mL
          doseInStrengthUnit = concentration != null
              ? volumeInMl * concentration
              : 0;
        }

        final clampedVolume = volumeInMl.clamp(0.0, maxVolume);
        final displayStrength = doseInStrengthUnit;

        return AlertDialog(
          title: Text(
            'Record Ad-Hoc Dose',
            style: TextStyle(color: colorScheme.primary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Helper text
                Text(
                  'Record a dose taken outside of your regular schedule.',
                  style: helperTextStyle(stateContext),
                ),
                const SizedBox(height: 12),

                // Medication info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (isMdv && concentration != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_formatNumber(med.strengthValue)} $strengthUnit / ${_formatNumber(med.containerVolumeMl!)} mL',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // MDV: Enhanced syringe input with size and unit selection
                if (isMdv) ...[
                  // Syringe size selection (compact)
                  Row(
                    children: [
                      Text(
                        'Syringe:',
                        style: helperTextStyle(
                          stateContext,
                        )?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: kCardBorderOpacity,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: syringeSize,
                            isDense: true,
                            style: inputTextStyle(stateContext),
                            items: [0.3, 0.5, 1.0, 3.0, 5.0].map((size) {
                              return DropdownMenuItem<double>(
                                value: size,
                                child: Text('$size mL'),
                              );
                            }).toList(),
                            onChanged: (newSize) {
                              if (newSize != null) {
                                syringeSize = newSize;
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dose unit selection toggle buttons
                  Row(
                    children: [
                      Text(
                        'Input As:',
                        style: helperTextStyle(
                          stateContext,
                        )?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ToggleButtons(
                          isSelected: [
                            selectedUnit == 'mL',
                            selectedUnit == 'mcg' || selectedUnit == 'mg',
                            selectedUnit == 'units',
                          ],
                          onPressed: (index) {
                            setState(() {
                              if (index == 0)
                                selectedUnit = 'mL';
                              else if (index == 1)
                                selectedUnit = strengthUnit.contains('mcg')
                                    ? 'mcg'
                                    : 'mg';
                              else
                                selectedUnit = 'units';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          constraints: const BoxConstraints(
                            minHeight: 32,
                            minWidth: 50,
                          ),
                          textStyle: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                          children: [
                            const Text('mL'),
                            Text(strengthUnit.contains('mcg') ? 'mcg' : 'mg'),
                            const Text('units'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Usage helper text
                  Text(
                    'Enter dose value or drag the syringe indicator.',
                    style: helperTextStyle(stateContext),
                  ),
                  const SizedBox(height: 12),

                  // Incremental input field (ABOVE syringe)
                  Row(
                    children: [
                      Text(
                        '$selectedUnit:',
                        style: helperTextStyle(
                          stateContext,
                        )?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StepperRow36(
                          controller: volumeController,
                          fixedFieldWidth: 80,
                          onDec: () {
                            final v =
                                double.tryParse(volumeController.text) ?? 0;
                            if (v > 0.01) {
                              volumeController.text = (v - 0.1).toStringAsFixed(
                                2,
                              );
                              setState(() {});
                            }
                          },
                          onInc: () {
                            final v =
                                double.tryParse(volumeController.text) ?? 0;
                            // Limit to min of syringe size and remaining volume
                            final maxInputValue = selectedUnit == 'mL'
                                ? syringeSize.clamp(0.0, maxVolume)
                                : (selectedUnit == 'mg' ||
                                          selectedUnit == 'mcg') &&
                                      concentration != null
                                ? syringeSize.clamp(0.0, maxVolume) *
                                      concentration
                                : syringeSize * 100;
                            if (v < maxInputValue) {
                              volumeController.text = (v + 0.1).toStringAsFixed(
                                2,
                              );
                              setState(() {});
                            }
                          },
                          decoration: buildCompactFieldDecoration(
                            context: stateContext,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Show empty vial warning if applicable
                  if (maxVolume <= 0)
                    Text(
                      '⚠️ Vial appears empty. You can still record doses to account for measurement variance.',
                      style: helperTextStyle(
                        stateContext,
                      )?.copyWith(color: Colors.orange),
                    )
                  else
                    Text(
                      'Available: ${_formatNumber(maxVolume)} mL in active vial',
                      style: helperTextStyle(stateContext),
                    ),
                  const SizedBox(height: 16),

                  // Syringe visualization (clean - no text overlay)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kReconBackgroundActive,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Syringe size label
                        Text(
                          '${_formatNumber(syringeSize)} mL Syringe',
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: kReconTextMediumOpacity,
                            ),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Syringe gauge (single label only)
                        WhiteSyringeGauge(
                          totalUnits: syringeSize * 100,
                          fillUnits: clampedVolume * 100,
                          color: colorScheme.primary,
                          interactive: true,
                          maxConstraint: maxVolume * 100,
                          showValueLabel: false, // Remove double label
                          onChanged: (newValue) {
                            volumeController.text = (newValue / 100)
                                .toStringAsFixed(2);
                            setState(() {});
                          },
                          onMaxConstraintHit: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dose summary sentence
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: helperTextStyle(stateContext),
                      children: [
                        TextSpan(
                          text: '${_formatNumber(clampedVolume)} mL',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' is equal to '),
                        TextSpan(
                          text: '${_formatNumber(clampedVolume * 100)} units',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' on a ${_formatNumber(syringeSize)} mL syringe',
                        ),
                        if (displayStrength != null) ...[
                          const TextSpan(text: ' for a dose of '),
                          TextSpan(
                            text:
                                '${_formatNumber(displayStrength)} $strengthUnit',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        TextSpan(text: ' of ${med.name}.'),
                      ],
                    ),
                  ),
                ] else ...[
                  // Non-MDV: Standard stepper input - in same row as unit
                  Row(
                    children: [
                      Text(
                        'Dose:',
                        style: helperTextStyle(
                          stateContext,
                        )?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StepperRow36(
                          controller: volumeController,
                          fixedFieldWidth: 80,
                          onDec: () {
                            final v =
                                double.tryParse(volumeController.text) ?? 0;
                            if (v > 0) {
                              volumeController.text = (v - 1).toStringAsFixed(
                                0,
                              );
                              setState(() {});
                            }
                          },
                          onInc: () {
                            final v =
                                double.tryParse(volumeController.text) ?? 0;
                            volumeController.text = (v + 1).toStringAsFixed(0);
                            setState(() {});
                          },
                          decoration: buildCompactFieldDecoration(
                            context: stateContext,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        unit,
                        style: helperTextStyle(
                          stateContext,
                        )?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Notes section
                Text(
                  'Notes (optional):',
                  style: helperTextStyle(
                    stateContext,
                  )?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: helperTextStyle(stateContext), // Smaller font
                  decoration: InputDecoration(
                    hintText: 'e.g., Taken for breakthrough pain',
                    hintStyle: helperTextStyle(stateContext),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final val = double.tryParse(volumeController.text);
                if (val != null && val > 0) {
                  Navigator.pop(dialogContext, {
                    'amount': val,
                    'unit': unit,
                    'notes': notesController.text.trim(),
                  });
                }
              },
              child: const Text('Record Dose'),
            ),
          ],
        );
      },
    ),
  );

  if (result != null && context.mounted) {
    final now = DateTime.now();
    final amount = result['amount'] as double;
    final doseUnit = result['unit'] as String;
    final notes = result['notes'] as String?;

    if (isMdv) {
      // For MDV: deduct from active vial volume
      final previousVolume = med.activeVialVolume ?? med.containerVolumeMl ?? 0;
      final newVolume = (previousVolume - amount).clamp(0.0, double.infinity);

      // Create DoseLog
      final doseLog = DoseLog(
        id: 'adhoc_${med.id}_${now.millisecondsSinceEpoch}',
        scheduleId: 'ad_hoc',
        scheduleName: 'Ad-hoc Dose',
        medicationId: med.id,
        medicationName: med.name,
        scheduledTime: now,
        actionTime: now,
        doseValue: amount,
        doseUnit: doseUnit,
        action: DoseAction.taken,
        notes: notes?.isNotEmpty == true ? notes : null,
      );
      Hive.box<DoseLog>('dose_logs').put(doseLog.id, doseLog);

      // Log inventory change
      final inventoryLog = InventoryLog(
        id: 'adhoc_${med.id}_${now.millisecondsSinceEpoch}',
        medicationId: med.id,
        medicationName: med.name,
        changeType: InventoryChangeType.adHocDose,
        previousStock: previousVolume,
        newStock: newVolume,
        changeAmount: -amount,
        notes: notes?.isNotEmpty == true ? notes : 'Ad-hoc dose',
        timestamp: now,
      );
      Hive.box<InventoryLog>(
        'inventory_logs',
      ).put(inventoryLog.id, inventoryLog);

      // Update medication - deduct from activeVialVolume
      Hive.box<Medication>(
        'medications',
      ).put(med.id, med.copyWith(activeVialVolume: newVolume));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recorded ${_formatNumber(amount)} mL dose')),
      );
    } else {
      // Non-MDV: deduct from stockValue
      final previousStock = med.stockValue;
      final newStock = (previousStock - amount).clamp(0.0, double.infinity);

      final doseLog = DoseLog(
        id: 'adhoc_${med.id}_${now.millisecondsSinceEpoch}',
        scheduleId: 'ad_hoc',
        scheduleName: 'Ad-hoc Dose',
        medicationId: med.id,
        medicationName: med.name,
        scheduledTime: now,
        actionTime: now,
        doseValue: amount,
        doseUnit: doseUnit,
        action: DoseAction.taken,
        notes: notes?.isNotEmpty == true ? notes : null,
      );
      Hive.box<DoseLog>('dose_logs').put(doseLog.id, doseLog);

      final inventoryLog = InventoryLog(
        id: 'adhoc_${med.id}_${now.millisecondsSinceEpoch}',
        medicationId: med.id,
        medicationName: med.name,
        changeType: InventoryChangeType.adHocDose,
        previousStock: previousStock,
        newStock: newStock,
        changeAmount: -amount,
        notes: notes?.isNotEmpty == true ? notes : 'Ad-hoc dose',
        timestamp: now,
      );
      Hive.box<InventoryLog>(
        'inventory_logs',
      ).put(inventoryLog.id, inventoryLog);

      Hive.box<Medication>(
        'medications',
      ).put(med.id, med.copyWith(stockValue: newStock));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recorded ${_formatNumber(amount)} $doseUnit dose'),
        ),
      );
    }
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
    useRootNavigator: true,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: Text(title, style: TextStyle(color: theme.colorScheme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (stateContext, setState) {
                return StepperRow36(
                  controller: controller,
                  fixedFieldWidth: 80, // Required for dialog use
                  onDec: () {
                    final v = double.tryParse(controller.text) ?? 0;
                    final step = isInt ? 1.0 : 0.1;
                    final newVal = (v - step).clamp(0.0, 1000000.0);
                    controller.text = isInt
                        ? newVal.toInt().toString()
                        : newVal.toStringAsFixed(1);
                    setState(() {});
                  },
                  onInc: () {
                    final v = double.tryParse(controller.text) ?? 0;
                    final step = isInt ? 1.0 : 0.1;
                    final newVal = (v + step).clamp(0.0, 1000000.0);
                    controller.text = isInt
                        ? newVal.toInt().toString()
                        : newVal.toStringAsFixed(1);
                    setState(() {});
                  },
                  decoration: buildCompactFieldDecoration(
                    context: stateContext,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                );
              },
            ),
            if (unit != null) ...[
              const SizedBox(height: 8),
              Text(unit, style: helperTextStyle(dialogContext)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                Navigator.pop(dialogContext, val);
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
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
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: i));
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
