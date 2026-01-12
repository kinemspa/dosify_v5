// ignore_for_file: unnecessary_null_comparison, unused_element, unused_element_parameter, unused_local_variable

// Dart imports:

import 'dart:async';
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/data/medication_repository.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_header_widget.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_reports_widget.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';
import 'package:dosifi_v5/src/widgets/reconstitution_summary_card.dart';
import 'package:dosifi_v5/src/widgets/selection_cards.dart';
import 'package:dosifi_v5/src/widgets/smart_expiry_picker.dart';
import 'package:dosifi_v5/src/widgets/compact_storage_line.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/medication_schedules_section.dart';
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

SyringeSizeMl _inferSyringeSizeFromDoseVolumeMl(double volumeMl) {
  if (volumeMl <= 0.3) return SyringeSizeMl.ml0_3;
  if (volumeMl <= 0.5) return SyringeSizeMl.ml0_5;
  if (volumeMl <= 1.0) return SyringeSizeMl.ml1;
  if (volumeMl <= 3.0) return SyringeSizeMl.ml3;
  return SyringeSizeMl.ml5;
}

/// Reconstitution calculator expects a *dose amount* (mass/units), not volume.
/// If we have a saved concentration (per mL) and dose volume (mL), compute:
/// doseAmount = concentrationPerMl * doseVolumeMl.
double? _inferDoseAmountFromSavedRecon(Medication med) {
  final perMl = med.perMlValue;
  final doseVolumeMl = med.volumePerDose;
  if (perMl == null || doseVolumeMl == null) return null;
  if (perMl <= 0 || doseVolumeMl <= 0) return null;
  return perMl * doseVolumeMl;
}

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
  bool _isScheduleExpanded = true; // Collapsible state for schedule card
  bool _isReportsExpanded = true; // Collapsible state for reports card
  bool _isReconstitutionExpanded = true; // Collapsible state for reconstitution

  late final List<String> _cardOrder;

  static const String _kCardReports = 'reports';
  static const String _kCardSchedule = 'schedule';
  static const String _kCardDetails = 'details';
  static const String _kCardReconstitution = 'reconstitution';

  double _measuredExpandedHeaderHeight = _kDetailHeaderExpandedHeight;
  final GlobalKey _headerMeasureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _cardOrder = <String>[
      _kCardReconstitution,
      _kCardReports,
      _kCardSchedule,
      _kCardDetails,
    ];

    final medId = widget.initial?.id ?? widget.medicationId;
    if (medId != null && medId.isNotEmpty) {
      unawaited(_restoreCardOrder(medId));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _prefsKeyCardOrder(String medicationId) {
    return 'med_detail_card_order_$medicationId';
  }

  Future<void> _restoreCardOrder(String medicationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKeyCardOrder(medicationId));
      if (stored == null || stored.isEmpty) return;
      if (!mounted) return;

      setState(() {
        _cardOrder
          ..clear()
          ..addAll(stored);
      });
    } catch (_) {
      // Ignore preference failures; default order will be used.
    }
  }

  Future<void> _persistCardOrder(
    String medicationId,
    List<String> orderedIds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKeyCardOrder(medicationId), orderedIds);
    } catch (_) {
      // Ignore preference failures.
    }
  }

  void _scheduleHeaderHeightMeasurement(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderObject = _headerMeasureKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;

      final measuredHeight = renderObject.size.height;
      final topInset = MediaQuery.of(context).padding.top;
      // Leave a small safety margin so content doesn't hug the gradient edge
      // (helps on compact screens and near-limit text scaling).
      final baseChildMax = _kDetailHeaderExpandedHeight - topInset - kSpacingS;
      final desired = measuredHeight <= baseChildMax
          ? _kDetailHeaderExpandedHeight
          : (measuredHeight + topInset + kSpacingM);

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
        ]),
        builder: (context, _) {
          final updatedMed = box.get(med.id) ?? med;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final onPrimary = colorScheme.onPrimary;
          final headerForeground = medicationDetailHeaderForegroundColor(
            context,
          );

          // Check if we have schedules for schedule-specific header content
          final scheduleBox = Hive.box<Schedule>('schedules');
          final hasSchedules = scheduleBox.values.any(
            (s) => s.medicationId == updatedMed.id,
          );
          final headerHeight = _measuredExpandedHeaderHeight;

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
                    foregroundColor: headerForeground,
                    iconTheme: IconThemeData(color: headerForeground),
                    actionsIconTheme: IconThemeData(color: headerForeground),
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
                              child: Builder(
                                builder: (context) {
                                  final headerOpacity = (1.0 - t * 2.0).clamp(
                                    0.0,
                                    1.0,
                                  );
                                  if (headerOpacity <= 0.0) {
                                    return const SizedBox.shrink();
                                  }

                                  return Opacity(
                                    opacity: headerOpacity,
                                    child: SafeArea(
                                      bottom: false,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          kPageHorizontalPadding,
                                          4, // Reduced from 12
                                          kPageHorizontalPadding,
                                          0,
                                        ),
                                        child: MedicationHeaderWidget(
                                          medication: updatedMed,
                                          foregroundColor: headerForeground,
                                          onRefill: () => _showRefillDialog(
                                            context,
                                            updatedMed,
                                          ),
                                          onRestock:
                                              updatedMed.form ==
                                                  MedicationForm.multiDoseVial
                                              ? () =>
                                                    _showRestockSealedVialsDialog(
                                                      context,
                                                      updatedMed,
                                                    )
                                              : null,
                                          onAdHocDose: () =>
                                              _showAdHocDoseDialog(
                                                context,
                                                updatedMed,
                                              ),
                                          hasSchedules: hasSchedules,
                                        ),
                                      ),
                                    ),
                                  );
                                },
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
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            updatedMed.name,
                                            style: TextStyle(
                                              color: headerForeground,
                                              fontSize: lerpDouble(22, 17, t),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (t < 0.8) ...[
                                            const SizedBox(height: kSpacingXS),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                  color: headerForeground,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
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
                            // Keep the same title-fade behavior without rebuilding the whole page on scroll.
                            Positioned(
                              top: top,
                              left: 0,
                              right: 0,
                              height: _kDetailHeaderCollapsedHeight,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: (1.0 - t * 3).clamp(0.0, 1.0),
                                  child: Center(
                                    child: Text(
                                      'Medication Details',
                                      style: TextStyle(
                                        color: onPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
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
                    title: const SizedBox.shrink(),
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
                            case 'inventory':
                              context.go('/inventory');
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
                            value: 'inventory',
                            child: Text('Inventory'),
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
                  // Detail page cards (reorderable when minimized)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        kPageHorizontalPadding,
                        kPageHorizontalPadding,
                        kPageHorizontalPadding,
                        100,
                      ),
                      child: _buildDetailCardsList(context, updatedMed),
                    ),
                  ),
                ],
              ),

              // Offstage measurement to make SliverAppBar height match content.
              Offstage(
                offstage: true,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      key: _headerMeasureKey,
                      padding: const EdgeInsets.fromLTRB(
                        kPageHorizontalPadding,
                        4,
                        kPageHorizontalPadding,
                        0,
                      ),
                      child: MedicationHeaderWidget(
                        medication: updatedMed,
                        foregroundColor: medicationDetailHeaderForegroundColor(
                          context,
                        ),
                        onRefill: () {},
                        onAdHocDose: () {},
                        hasSchedules: hasSchedules,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
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

  Widget _buildDetailCardsList(BuildContext context, Medication med) {
    final cs = Theme.of(context).colorScheme;

    final cards = <String, Widget>{
      if (med.form == MedicationForm.multiDoseVial)
        _kCardReconstitution: _buildReconstitutionCard(context, med),
      _kCardReports: MedicationReportsWidget(
        medication: med,
        isExpanded: _isReportsExpanded,
        onExpandedChanged: (expanded) {
          if (!mounted) return;
          setState(() => _isReportsExpanded = expanded);
        },
      ),
      _kCardSchedule: _buildScheduleCard(
        context,
        med,
        _nextDoseForMedication(med.id),
      ),
      _kCardDetails: _buildUnifiedDetailsCard(context, med),
    };

    final hasReconstitutionCard = cards.containsKey(_kCardReconstitution);

    final allCardsCollapsed =
        !_isReportsExpanded &&
        !_isScheduleExpanded &&
        !_isDetailsExpanded &&
        (!hasReconstitutionCard || !_isReconstitutionExpanded);

    bool isExpandedForCardId(String id) {
      switch (id) {
        case _kCardReports:
          return _isReportsExpanded;
        case _kCardSchedule:
          return _isScheduleExpanded;
        case _kCardDetails:
          return _isDetailsExpanded;
        case _kCardReconstitution:
          return _isReconstitutionExpanded;
        default:
          return true;
      }
    }

    final orderedIds = _cardOrder.where(cards.containsKey).toList();
    for (final id in cards.keys) {
      if (!orderedIds.contains(id)) {
        orderedIds.add(id);
      }
    }

    void showCollapseAllInstruction() {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Collapse all cards first to rearrange them.'),
            duration: Duration(seconds: 2),
          ),
        );
    }

    final children = <Widget>[
      for (final entry in orderedIds.asMap().entries)
        Padding(
          key: ValueKey<String>('detail_card_${entry.value}'),
          padding: EdgeInsets.only(
            bottom: entry.key == orderedIds.length - 1 ? 0 : kSpacingM,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              cards[entry.value]!,
              if (!isExpandedForCardId(entry.value))
                Positioned(
                  left: kSpacingS,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: allCardsCollapsed
                        ? ReorderableDelayedDragStartListener(
                            index: entry.key,
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: kIconSizeMedium,
                              color: cs.onSurfaceVariant.withValues(
                                alpha: kOpacityMedium,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onLongPress: showCollapseAllInstruction,
                            onTap: showCollapseAllInstruction,
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: kIconSizeMedium,
                              color: cs.onSurfaceVariant.withValues(
                                alpha: kOpacityMedium,
                              ),
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
    ];

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;

          final moved = orderedIds.removeAt(oldIndex);
          orderedIds.insert(newIndex, moved);

          _cardOrder
            ..clear()
            ..addAll(orderedIds);
        });

        unawaited(_persistCardOrder(med.id, orderedIds));
      },
      children: children,
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

    // Determine gauge + label colors based on percentage.
    // Requirement: 0% should be red; 20% should be orange.
    // On the gradient header, keep the arc `onPrimary` and only color-code
    // the label/values (blended toward onPrimary for readability).
    final Color gaugeColor = onPrimary.withValues(alpha: kOpacityEmphasis);
    final Color gaugeLabelColor;
    if (pct <= 0) {
      gaugeLabelColor = statusColorOnPrimary(context, theme.colorScheme.error);
    } else if (pct <= 20) {
      gaugeLabelColor = statusColorOnPrimary(
        context,
        theme.colorScheme.tertiary,
      );
    } else {
      gaugeLabelColor = onPrimary;
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

                // Storage + expiry (match Large Cards compact storage rows)
                if (isMdv) ...[
                  _buildHeaderMdvStorageSection(
                    context,
                    med,
                    onPrimary: onPrimary,
                  ),
                  const SizedBox(height: 8),
                ] else if (storageLabel != null && storageLabel.isNotEmpty) ...[
                  CompactStorageLine(
                    icons: [
                      if (med.requiresFreezer)
                        Icons.severe_cold
                      else if (med.requiresRefrigeration)
                        Icons.ac_unit
                      else
                        Icons.inventory_2_outlined,
                      if (med.lightSensitive) Icons.dark_mode,
                    ],
                    label: 'Storage',
                    location: storageLabel,
                    createdAt: med.createdAt,
                    expiry: med.expiry,
                    iconColor: onPrimary.withValues(alpha: kOpacityEmphasis),
                    textColor: onPrimary,
                    onPrimaryBackground: true,
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
                height: kMedicationDetailDonutSize,
                width: kMedicationDetailDonutSize,
                child: hasBackup
                    ? DualStockDonutGauge(
                        outerPercentage: pct,
                        innerPercentage: backupPct,
                        primaryLabel: primaryLabel,
                        size: kMedicationDetailDonutSize,
                        color: gaugeColor,
                        backgroundColor: onPrimary.withValues(
                          alpha: kOpacityFaint,
                        ), // Almost invisible
                        textColor: gaugeLabelColor,
                        showGlow: false,
                        isOutline: false,
                        outerStrokeWidth: kMedicationDetailDonutStrokeWidth,
                        innerStrokeWidth:
                            kMedicationDetailDonutInnerStrokeWidth,
                      )
                    : StockDonutGauge(
                        percentage: pct,
                        primaryLabel: primaryLabel,
                        size: kMedicationDetailDonutSize,
                        color: gaugeColor,
                        backgroundColor: onPrimary.withValues(
                          alpha: kOpacityFaint,
                        ), // Almost invisible
                        textColor: gaugeLabelColor,
                        showGlow: false,
                        isOutline: false,
                        strokeWidth: kMedicationDetailDonutStrokeWidth,
                      ),
              ),
              const SizedBox(height: 4),
              if (!isMdv) ...[
                RichText(
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: helperTextStyle(
                      context,
                      color: onPrimary.withValues(alpha: kOpacityMediumHigh),
                    )?.copyWith(fontSize: kFontSizeSmall),
                    children: [
                      TextSpan(
                        text: _formatNumber(med.stockValue),
                        style:
                            helperTextStyle(
                              context,
                              color: onPrimary.withValues(
                                alpha: kOpacityMediumHigh,
                              ),
                            )?.copyWith(
                              fontSize: kFontSizeSmall,
                              fontWeight: FontWeight.w800,
                              color: gaugeLabelColor,
                            ),
                      ),
                      const TextSpan(text: ' / '),
                      TextSpan(
                        text: _formatNumber(initial),
                        style: helperTextStyle(context, color: onPrimary)
                            ?.copyWith(
                              fontSize: kFontSizeSmall,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      TextSpan(text: ' $unit'),
                    ],
                  ),
                ),
                Text(
                  helperLabel,
                  style: helperTextStyle(
                    context,
                    color: onPrimary.withValues(alpha: kOpacityMediumLow),
                  )?.copyWith(fontSize: kFontSizeSmall),
                  textAlign: TextAlign.right,
                ),
              ],
              const SizedBox(height: 8),

              // Stock Forecast (Moved Here)
              _buildStockForecastCard(context, onPrimary, med),

              const SizedBox(height: 8),

              // Custom Refill Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  if (med.form == MedicationForm.multiDoseVial) ...[
                    const SizedBox(width: 8),
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
                          onTap: () =>
                              _showRestockSealedVialsDialog(context, med),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 14,
                                  color: onPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Restock',
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
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMdvStorageSection(
    BuildContext context,
    Medication med, {
    required Color onPrimary,
  }) {
    String? clean(String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return null;
      return v;
    }

    String? pickLocation(String? primary, String? fallback) {
      return clean(primary) ?? clean(fallback);
    }

    final activeCreatedAt = med.reconstitutedAt ?? med.createdAt;
    final activeExpiry = med.reconstitutedVialExpiry;
    final activeLocation = pickLocation(
      med.activeVialStorageLocation,
      med.storageLocation,
    );

    final sealedCreatedAt = med.createdAt;
    final sealedExpiry = med.backupVialsExpiry ?? med.expiry;
    final sealedLocation = pickLocation(
      med.backupVialsStorageLocation,
      med.storageLocation,
    );

    final hasAny =
        activeLocation != null ||
        sealedLocation != null ||
        activeExpiry != null ||
        sealedExpiry != null;
    if (!hasAny) return const SizedBox.shrink();

    final iconColor = onPrimary.withValues(alpha: kOpacityEmphasis);

    final activeIcons = <IconData>[];
    if (med.activeVialRequiresFreezer) activeIcons.add(Icons.severe_cold);
    if (med.activeVialRequiresRefrigeration) activeIcons.add(Icons.ac_unit);
    if (med.activeVialLightSensitive) {
      activeIcons.add(Icons.dark_mode);
    }

    final sealedIcons = <IconData>[];
    if (med.backupVialsRequiresFreezer) sealedIcons.add(Icons.severe_cold);
    if (med.backupVialsRequiresRefrigeration) sealedIcons.add(Icons.ac_unit);
    if (med.backupVialsLightSensitive) {
      sealedIcons.add(Icons.dark_mode);
    }

    final activeTrailing = _headerMdvRemainingMl(context, med, onPrimary);
    final sealedTrailing = _headerMdvRemainingVials(context, med, onPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompactStorageLine(
          icons: activeIcons,
          label: 'Active',
          location: activeLocation,
          createdAt: activeCreatedAt,
          expiry: activeExpiry,
          trailing: activeTrailing,
          iconColor: iconColor,
          textColor: onPrimary,
          onPrimaryBackground: true,
        ),
        const SizedBox(height: kSpacingXS),
        CompactStorageLine(
          icons: sealedIcons,
          label: 'Sealed',
          location: sealedLocation,
          createdAt: sealedCreatedAt,
          expiry: sealedExpiry,
          trailing: sealedTrailing,
          iconColor: iconColor,
          textColor: onPrimary,
          onPrimaryBackground: true,
        ),
      ],
    );
  }

  Widget? _headerMdvRemainingMl(
    BuildContext context,
    Medication med,
    Color onPrimary,
  ) {
    final totalMl = (med.containerVolumeMl ?? 0).toDouble();
    final currentRaw = (med.activeVialVolume ?? totalMl).toDouble();
    final currentMl = totalMl > 0 ? currentRaw.clamp(0.0, totalMl) : 0.0;
    if (totalMl <= 0) return null;

    final stockInfo = MedicationDisplayHelpers.calculateStock(med);
    final colored = statusColorOnPrimary(
      context,
      stockStatusColorFromPercentage(context, percentage: stockInfo.percentage),
    );
    final baseStyle = helperTextStyle(
      context,
      color: onPrimary.withValues(alpha: kOpacityMediumHigh),
    )?.copyWith(fontSize: kFontSizeXSmall, fontWeight: FontWeight.w600);

    return RichText(
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: fmt2(currentMl),
            style: TextStyle(fontWeight: FontWeight.w800, color: colored),
          ),
          TextSpan(text: '/${fmt2(totalMl)} mL'),
        ],
      ),
    );
  }

  Widget? _headerMdvRemainingVials(
    BuildContext context,
    Medication med,
    Color onPrimary,
  ) {
    if (med.stockUnit != StockUnit.multiDoseVials) return null;

    final count = med.stockValue.floor();
    if (count <= 0) return null;

    final stockInfo = MedicationDisplayHelpers.calculateStock(med);
    final colored = statusColorOnPrimary(
      context,
      stockStatusColorFromPercentage(context, percentage: stockInfo.percentage),
    );
    final baseStyle = helperTextStyle(
      context,
      color: onPrimary.withValues(alpha: kOpacityMediumHigh),
    )?.copyWith(fontSize: kFontSizeXSmall, fontWeight: FontWeight.w600);

    final label = count == 1 ? 'vial' : 'vials';
    return RichText(
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: '$count',
            style: TextStyle(fontWeight: FontWeight.w800, color: colored),
          ),
          TextSpan(text: ' $label'),
        ],
      ),
    );
  }

  Widget _buildUnifiedDetailsCard(BuildContext context, Medication med) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCardSurface(
      useGradient: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header
          InkWell(
            onTap: () =>
                setState(() => _isDetailsExpanded = !_isDetailsExpanded),
            child: Padding(
              padding: kDetailCardCollapsedHeaderPadding,
              child: Row(
                children: [
                  if (!_isDetailsExpanded)
                    const SizedBox(width: kDetailCardReorderHandleGutterWidth),
                  Icon(
                    Icons.info_outline,
                    size: kIconSizeMedium,
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
                      size: kIconSizeLarge,
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
                  Container(
                    decoration: buildInsetSectionDecoration(
                      context: context,
                      showBorder: false,
                    ),
                    padding: kInsetSectionPadding,
                    child: _buildMergedDetailsSection(context, med),
                  ),

                  if (med.form == MedicationForm.multiDoseVial) ...[
                    const SizedBox(height: kSpacingM),
                    _buildBackupStockSection(context, med),
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

  Widget _buildScheduleCard(
    BuildContext context,
    Medication med,
    ScheduledDose? nextDose,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final scheduleBox = Hive.box<Schedule>('schedules');
    final hasSchedules = scheduleBox.values.any(
      (s) => s.medicationId == med.id,
    );

    if (!hasSchedules) {
      return GlassCardSurface(
        useGradient: false,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: kDetailCardCollapsedHeaderPadding,
          child: Row(
            children: [
              const SizedBox(width: kDetailCardReorderHandleGutterWidth),
              Icon(
                Icons.calendar_month_rounded,
                size: kIconSizeMedium,
                color: colorScheme.primary,
              ),
              const SizedBox(width: kSpacingS),
              Text(
                'Schedule',
                style: cardTitleStyle(
                  context,
                )?.copyWith(color: colorScheme.primary),
              ),
              const Spacer(),
              Text(
                'No schedules',
                style: helperTextStyle(
                  context,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCardSurface(
      useGradient: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _isScheduleExpanded = !_isScheduleExpanded),
            child: Padding(
              padding: kDetailCardCollapsedHeaderPadding,
              child: Row(
                children: [
                  if (!_isScheduleExpanded)
                    const SizedBox(width: kDetailCardReorderHandleGutterWidth),
                  Icon(
                    Icons.calendar_month_rounded,
                    size: kIconSizeMedium,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: kSpacingS),
                  Text(
                    'Schedule',
                    style: cardTitleStyle(
                      context,
                    )?.copyWith(color: colorScheme.primary),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isScheduleExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: kIconSizeLarge,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isScheduleExpanded
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
              child: Container(
                decoration: buildInsetSectionDecoration(
                  context: context,
                  showBorder: false,
                ),
                padding: kInsetSectionPadding,
                child: MedicationSchedulesSection(medication: med),
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
          emphasized: true,
          onTap: () => _editName(context, med),
        ),
        _buildDetailTile(
          context,
          'Type',
          _formLabel(med.form),
          emphasized: true,
        ),
        _buildDetailTile(
          context,
          'Strength',
          '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
          emphasized: true,
          onTap: () => _editStrength(context, med),
        ),
        _buildDetailTile(
          context,
          'Manufacturer',
          med.manufacturer ?? 'Not set',
          isPlaceholder: med.manufacturer == null,
          onTap: () => _editManufacturer(context, med),
        ),

        const SizedBox(height: kSpacingS), // Section spacing (divider removed)
        // ACTIVE VIAL (MDV only) - merged into this card since it's the tracked medicine for dosing
        if (isMdv) ...[
          // Section header for Active Vial
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacingL,
              vertical: kSpacingS,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: kIconSizeSmall,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: kSpacingXS),
                Text(
                  'Active Vial',
                  style: fieldLabelStyle(
                    context,
                  )?.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
          ),
          buildSectionHelperText(
            context,
            'This is the tracked vial used for dosing and inventory.',
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
          _buildDetailTile(
            context,
            'Expiry',
            med.reconstitutedVialExpiry != null
                ? _formatExpiry(med.reconstitutedVialExpiry!)
                : 'Not set',
            isPlaceholder: med.reconstitutedVialExpiry == null,
            isWarning:
                med.reconstitutedVialExpiry != null &&
                _isExpiringSoon(med.reconstitutedVialExpiry!),
            onTap: () => _editActiveVialExpiry(context, med),
          ),
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

          const SizedBox(
            height: kSpacingS,
          ), // Section spacing (divider removed)
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

          const SizedBox(
            height: kSpacingS,
          ), // Section spacing (divider removed)
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
            maxLines: null,
            showEllipsis: false,
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
    bool emphasized = false,
    int? maxLines = 2,
    bool showEllipsis = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final labelStyle = helperTextStyle(
      context,
      color: colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
    )?.copyWith(fontSize: kFontSizeSmall, fontWeight: kFontWeightSemiBold);

    final valueBaseStyle = bodyTextStyle(context)?.copyWith(
      fontWeight: emphasized ? kFontWeightSemiBold : kFontWeightNormal,
      color: emphasized
          ? colorScheme.onSurface.withValues(alpha: kOpacityHigh)
          : colorScheme.onSurface.withValues(alpha: kOpacityMediumHigh),
    );

    final placeholderStyle = mutedTextStyle(
      context,
    )?.copyWith(fontStyle: FontStyle.italic);

    final warningStyle = valueBaseStyle?.copyWith(color: colorScheme.secondary);

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingL,
        vertical: kSpacingS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isWarning
                  ? warningStyle
                  : isPlaceholder
                  ? placeholderStyle
                  : valueBaseStyle?.copyWith(
                      fontStyle: isItalic ? FontStyle.italic : null,
                    ),
              maxLines: maxLines,
              overflow: showEllipsis ? TextOverflow.ellipsis : null,
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: kIconSizeSmall,
              color: colorScheme.onSurfaceVariant.withValues(
                alpha: kOpacityLow,
              ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingL,
          vertical: kSpacingS,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                'Conditions',
                style: helperTextStyle(
                  context,
                  color: colorScheme.onSurfaceVariant,
                )?.copyWith(fontSize: kFontSizeSmall),
              ),
            ),
            Wrap(spacing: 6, children: conditions),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: kIconSizeSmall,
              color: colorScheme.onSurfaceVariant.withValues(
                alpha: kOpacityLow,
              ),
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
            style: helperTextStyle(context, color: colorScheme.onPrimary)
                ?.copyWith(
                  fontSize: kFontSizeSmall,
                  fontWeight: kFontWeightSemiBold,
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
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            titleTextStyle: cardTitleStyle(
              context,
            )?.copyWith(color: cs.primary),
            contentTextStyle: bodyTextStyle(context),
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
          final cs = theme.colorScheme;
          return AlertDialog(
            titleTextStyle: cardTitleStyle(ctx)?.copyWith(color: cs.primary),
            contentTextStyle: bodyTextStyle(ctx),
            title: const Text('Active Vial Conditions'),
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

  /// Dialog for editing sealed vial storage conditions
  void _showBackupStockConditionsDialog(BuildContext context, Medication med) {
    bool fridge = med.backupVialsRequiresRefrigeration;
    bool freezer = med.backupVialsRequiresFreezer;
    bool light = med.backupVialsLightSensitive;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;
          return AlertDialog(
            titleTextStyle: cardTitleStyle(ctx)?.copyWith(color: cs.primary),
            contentTextStyle: bodyTextStyle(ctx),
            title: const Text('Sealed Vial Storage Conditions'),
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
              Text(
                'Sealed Vials',
                style: sectionTitleStyle(
                  context,
                )?.copyWith(color: colorScheme.primary),
              ),
              const Spacer(),
              Text(
                '${_formatNumber(med.stockValue).split('.')[0]} sealed vials',
                style: bodyTextStyle(
                  context,
                )?.copyWith(fontWeight: kFontWeightBold),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Used for reconstitution.',
            style: helperTextStyle(context),
          ),
        ),

        const SizedBox(height: 8),

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

    final cs = Theme.of(context).colorScheme;

    return GlassCardSurface(
      useGradient: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(
              () => _isReconstitutionExpanded = !_isReconstitutionExpanded,
            ),
            child: Padding(
              padding: kDetailCardCollapsedHeaderPadding,
              child: Row(
                children: [
                  if (!_isReconstitutionExpanded)
                    const SizedBox(width: kDetailCardReorderHandleGutterWidth),
                  Icon(
                    Icons.science_outlined,
                    size: kIconSizeMedium,
                    color: cs.primary,
                  ),
                  const SizedBox(width: kSpacingS),
                  Text(
                    'Reconstitution',
                    style: cardTitleStyle(context)?.copyWith(color: cs.primary),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isReconstitutionExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: kIconSizeLarge,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isReconstitutionExpanded
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
              child: InkWell(
                onTap: () => _editReconstitution(context, med),
                child: ReconstitutionSummaryCard(
                  strengthValue: med.strengthValue,
                  strengthUnit: _unitLabel(med.strengthUnit),
                  medicationName: med.name,
                  containerVolumeMl: med.containerVolumeMl,
                  perMlValue: med.perMlValue,
                  volumePerDose: med.volumePerDose,
                  reconFluidName: med.diluentName ?? 'Bacteriostatic Water',
                  syringeSizeMl: 3.0,
                  compact: true,
                  showCardSurface: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editReconstitution(BuildContext context, Medication med) async {
    if (med.form != MedicationForm.multiDoseVial) return;
    if (med.strengthValue <= 0) return;

    final box = Hive.box<Medication>('medications');
    final latest = box.get(med.id) ?? med;

    final initialDoseAmount = _inferDoseAmountFromSavedRecon(latest);
    final initialDoseUnit = med.strengthUnit.name;
    final initialSyringe = (latest.volumePerDose != null &&
        latest.volumePerDose! > 0)
      ? _inferSyringeSizeFromDoseVolumeMl(latest.volumePerDose!)
      : SyringeSizeMl.ml1;

    final result = await showModalBottomSheet<ReconstitutionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.0),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ReconstitutionCalculatorDialog(
          initialStrengthValue: med.strengthValue,
          unitLabel: med.strengthUnit.name,
          initialDoseValue: initialDoseAmount,
          initialDoseUnit: initialDoseUnit,
          initialSyringeSize: initialSyringe,
          initialVialSize: latest.containerVolumeMl,
          initialDiluentName: latest.diluentName,
        ),
      ),
    );

    if (result == null) return;

    await box.put(
      latest.id,
      latest.copyWith(
        perMlValue: result.perMlConcentration,
        containerVolumeMl: result.solventVolumeMl,
        volumePerDose: result.recommendedUnits / 100,
        diluentName: result.diluentName ?? latest.diluentName,
        activeVialVolume: result.solventVolumeMl,
        reconstitutedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Reconstitution updated')));
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
          titleTextStyle: cardTitleStyle(
            stateContext,
          )?.copyWith(color: theme.colorScheme.primary),
          contentTextStyle: bodyTextStyle(stateContext),
          title: Text('Refill ${med.name}'),
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
                padding: const EdgeInsets.all(kSpacingM),
                decoration: buildInsetSectionDecoration(context: stateContext),
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

/// MDV Refill dialog - Use a new vial with sealed vial management
void _showMdvRefillDialog(BuildContext context, Medication med) async {
  final currentVolume = med.activeVialVolume ?? 0;
  final vialSize = med.containerVolumeMl ?? 5.0;

  // Initialize from latest saved settings (in case the page is stale).
  final box = Hive.box<Medication>('medications');
  final latest = box.get(med.id) ?? med;

  // Single-page dialog state
  var selectedMode = 'replace'; // 'replace' | 'topUp'
  var selectedSource = 'fromStock'; // 'fromStock' | 'otherSource'

  double? selectedPerMl = latest.perMlValue;
  String? selectedDiluentName = latest.diluentName;

  final replaceVolumeCtrl = TextEditingController(
    text: fmt2(latest.containerVolumeMl ?? vialSize),
  );
  var replaceVolumeSetBy = latest.containerVolumeMl != null
      ? 'From previous reconstitution'
      : null;

  double? selectedRecommendedUnits;
  String? selectedReconLabel;

  final topUpVolumeCtrl = TextEditingController(text: fmt2(vialSize));
  var topUpVolumeSetBy = latest.containerVolumeMl != null
      ? 'From previous reconstitution'
      : null;

  double? topUpPerMl = latest.perMlValue;
  String? topUpDiluentName = latest.diluentName;
  String? topUpReconLabel;

  Future<void> pickReconstitution(BuildContext dialogContext) async {
    final initialDoseAmount = _inferDoseAmountFromSavedRecon(latest);
    final initialDoseUnit = med.strengthUnit.name;
    final initialSyringe = (latest.volumePerDose != null &&
            latest.volumePerDose! > 0)
        ? _inferSyringeSizeFromDoseVolumeMl(latest.volumePerDose!)
        : SyringeSizeMl.ml1;

    Future<void> setRecon({
      required double perMl,
      required double volumeMl,
      String? diluentName,
      double? recommendedUnits,
      required String label,
    }) async {
      selectedPerMl = perMl;
      selectedDiluentName = diluentName;
      selectedRecommendedUnits = recommendedUnits;
      selectedReconLabel = label;

      replaceVolumeCtrl.text = fmt2(volumeMl);
      replaceVolumeSetBy = 'From new reconstitution';
    }

    final result = await showModalBottomSheet<ReconstitutionResult>(
      context: dialogContext,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        dialogContext,
      ).colorScheme.surface.withValues(alpha: 0.0),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ReconstitutionCalculatorDialog(
          initialStrengthValue: med.strengthValue,
          unitLabel: med.strengthUnit.name,
          initialDoseValue: initialDoseAmount,
          initialDoseUnit: initialDoseUnit,
          initialSyringeSize: initialSyringe,
          initialVialSize:
              (double.tryParse(replaceVolumeCtrl.text) ?? 0) > 0
                  ? (double.tryParse(replaceVolumeCtrl.text) ?? vialSize)
                  : (latest.containerVolumeMl ?? vialSize),
          initialDiluentName: selectedDiluentName,
        ),
      ),
    );

    if (result == null) return;
    final diluent = (result.diluentName ?? selectedDiluentName)?.trim();
    final label = diluent == null || diluent.isEmpty
        ? '${result.solventVolumeMl.toStringAsFixed(2)} mL'
        : '${result.solventVolumeMl.toStringAsFixed(2)} mL $diluent';
    await setRecon(
      perMl: result.perMlConcentration,
      volumeMl: result.solventVolumeMl,
      diluentName: result.diluentName,
      recommendedUnits: result.recommendedUnits,
      label: label,
    );
  }

  Future<void> pickTopUpStrength(BuildContext dialogContext) async {
    final initialDoseAmount = _inferDoseAmountFromSavedRecon(latest);
    final initialDoseUnit = med.strengthUnit.name;
    final initialSyringe = (latest.volumePerDose != null &&
            latest.volumePerDose! > 0)
        ? _inferSyringeSizeFromDoseVolumeMl(latest.volumePerDose!)
        : SyringeSizeMl.ml1;

    final result = await showModalBottomSheet<ReconstitutionResult>(
      context: dialogContext,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        dialogContext,
      ).colorScheme.surface.withValues(alpha: 0.0),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ReconstitutionCalculatorDialog(
          initialStrengthValue: med.strengthValue,
          unitLabel: med.strengthUnit.name,
          initialDoseValue: initialDoseAmount,
          initialDoseUnit: initialDoseUnit,
          initialSyringeSize: initialSyringe,
          initialVialSize: latest.containerVolumeMl ?? vialSize,
          initialDiluentName: topUpDiluentName,
        ),
      ),
    );

    if (result == null) return;
    topUpPerMl = result.perMlConcentration;
    topUpDiluentName = result.diluentName;

    final diluent = (result.diluentName ?? topUpDiluentName)?.trim();
    topUpReconLabel = diluent == null || diluent.isEmpty
        ? '${result.perMlConcentration.toStringAsFixed(2)} ${MedicationDisplayHelpers.unitLabel(med.strengthUnit)}/mL'
        : '${result.perMlConcentration.toStringAsFixed(2)} ${MedicationDisplayHelpers.unitLabel(med.strengthUnit)}/mL • $diluent';
  }

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final sealedVials = med.stockValue.toInt();

        final canUseFromStock = sealedVials > 0;
        final willUseFromStock =
            selectedSource == 'fromStock' && canUseFromStock;

        final replaceVolume = (double.tryParse(replaceVolumeCtrl.text) ?? 0)
          .clamp(0.0, double.infinity);
        final topUpAddVolume = (double.tryParse(topUpVolumeCtrl.text) ?? 0)
          .clamp(0.0, double.infinity);

        final previewVolume = selectedMode == 'replace'
          ? (replaceVolume > 0 ? replaceVolume : vialSize)
          : currentVolume + topUpAddVolume;

        final unit = MedicationDisplayHelpers.unitLabel(med.strengthUnit);
        final currentPerMl = med.perMlValue;
        final effectiveTopUpPerMl = topUpPerMl ?? currentPerMl;
        final canPreviewTopUpConc =
          currentPerMl != null && effectiveTopUpPerMl != null;
        final previewNewPerMl = canPreviewTopUpConc &&
            currentVolume > 0 &&
            topUpAddVolume > 0 &&
            (currentVolume + topUpAddVolume) > 0
          ? ((currentPerMl * currentVolume) +
              (effectiveTopUpPerMl * topUpAddVolume)) /
            (currentVolume + topUpAddVolume)
          : null;

        final canSave = selectedMode == 'replace'
          ? (selectedPerMl != null &&
            selectedPerMl! > 0 &&
            (replaceVolume > 0 || vialSize > 0))
          : (topUpAddVolume > 0 &&
            (effectiveTopUpPerMl == null || effectiveTopUpPerMl > 0));

        Widget buildHeaderCard() {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kSpacingM),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active Vial:'),
                    Text(
                      '${_formatNumber(currentVolume)} mL remaining',
                      style: bodyTextStyle(
                        context,
                      )?.copyWith(fontWeight: kFontWeightSemiBold),
                    ),
                  ],
                ),
                const SizedBox(height: kSpacingXS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sealed Vials:',
                      style: helperTextStyle(
                        context,
                        color: cs.primary,
                      )?.copyWith(fontWeight: kFontWeightSemiBold),
                    ),
                    Text(
                      '$sealedVials in stock',
                      style: bodyTextStyle(context)?.copyWith(
                        fontWeight: kFontWeightSemiBold,
                        color: sealedVials == 0 ? cs.error : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update your active vial using one dialog.',
              style: helperTextStyle(context),
            ),
            const SizedBox(height: kSpacingM),
            buildHeaderCard(),
            const SizedBox(height: kSpacingM),
            Text(
              'Action:',
              style: helperTextStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary),
            ),
            const SizedBox(height: kSpacingXS),
            SelectableOptionCard(
              icon: Icons.swap_horiz,
              title: 'Replace',
              subtitle:
                  'Discard ${_formatNumber(currentVolume)} mL and start a new vial.',
              selected: selectedMode == 'replace',
              onTap: () => setState(() => selectedMode = 'replace'),
            ),
            const SizedBox(height: kSpacingS),
            SelectableOptionCard(
              icon: Icons.add,
              title: 'Top Up',
              subtitle: 'Add ${_formatNumber(vialSize)} mL to the active vial.',
              selected: selectedMode == 'topUp',
              onTap: () => setState(() => selectedMode = 'topUp'),
            ),
            const SizedBox(height: kSpacingS),
            Text(
              'Source:',
              style: helperTextStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary),
            ),
            const SizedBox(height: kSpacingXS),
            SelectableOptionCard(
              icon: Icons.inventory_2_outlined,
              title: 'Use sealed vial from stock',
              subtitle: canUseFromStock
                  ? 'Deducts 1 vial (${sealedVials - 1} remaining)'
                  : 'No sealed vials available',
              selected: selectedSource == 'fromStock',
              enabled: canUseFromStock,
              onTap: () => setState(() => selectedSource = 'fromStock'),
            ),
            const SizedBox(height: kSpacingS),
            SelectableOptionCard(
              icon: Icons.local_shipping_outlined,
              title: 'Use other source',
              subtitle: 'Does not change sealed vial stock.',
              selected: selectedSource == 'otherSource',
              onTap: () => setState(() => selectedSource = 'otherSource'),
            ),
            const SizedBox(height: kSpacingS),
            if (selectedMode == 'replace') ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reconstitution'),
                subtitle: Text(
                  selectedReconLabel ??
                      (latest.containerVolumeMl != null &&
                              latest.perMlValue != null
                          ? 'Using previous reconstitution'
                          : 'Not selected'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await pickReconstitution(dialogContext);
                  if (!dialogContext.mounted) return;
                  setState(() {});
                },
              ),
              const SizedBox(height: kSpacingXS),
              Text(
                'Volume (mL):',
                style: helperTextStyle(
                  context,
                )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary),
              ),
              const SizedBox(height: kSpacingXS),
              Center(
                child: StepperRow36(
                  controller: replaceVolumeCtrl,
                  fixedFieldWidth: 96,
                  onDec: () {
                    final v = double.tryParse(replaceVolumeCtrl.text) ?? 0;
                    final next = (v - 0.1).clamp(0.0, 9999.0);
                    replaceVolumeCtrl.text = fmt2(next);
                    replaceVolumeSetBy = 'Manually set';
                    setState(() {});
                  },
                  onInc: () {
                    final v = double.tryParse(replaceVolumeCtrl.text) ?? 0;
                    final next = (v + 0.1).clamp(0.0, 9999.0);
                    replaceVolumeCtrl.text = fmt2(next);
                    replaceVolumeSetBy = 'Manually set';
                    setState(() {});
                  },
                  onChanged: (_) {
                    replaceVolumeSetBy = 'Manually set';
                    setState(() {});
                  },
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: buildCompactFieldDecoration(context: context),
                ),
              ),
              if (replaceVolumeSetBy != null) ...[
                const SizedBox(height: kSpacingXS),
                Center(
                  child: Text(
                    replaceVolumeSetBy!,
                    style: helperTextStyle(context),
                  ),
                ),
              ],
              const SizedBox(height: kSpacingXS),
            ],
            if (selectedMode == 'topUp') ...[
              Text(
                'Add Volume (mL):',
                style: helperTextStyle(
                  context,
                )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary),
              ),
              const SizedBox(height: kSpacingXS),
              Center(
                child: StepperRow36(
                  controller: topUpVolumeCtrl,
                  fixedFieldWidth: 96,
                  onDec: () {
                    final v = double.tryParse(topUpVolumeCtrl.text) ?? 0;
                    final next = (v - 0.1).clamp(0.0, 9999.0);
                    topUpVolumeCtrl.text = fmt2(next);
                    topUpVolumeSetBy = 'Manually set';
                    setState(() {});
                  },
                  onInc: () {
                    final v = double.tryParse(topUpVolumeCtrl.text) ?? 0;
                    final next = (v + 0.1).clamp(0.0, 9999.0);
                    topUpVolumeCtrl.text = fmt2(next);
                    topUpVolumeSetBy = 'Manually set';
                    setState(() {});
                  },
                  onChanged: (_) {
                    topUpVolumeSetBy = 'Manually set';
                    setState(() {});
                  },
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: buildCompactFieldDecoration(context: context),
                ),
              ),
              if (topUpVolumeSetBy != null) ...[
                const SizedBox(height: kSpacingXS),
                Center(
                  child: Text(
                    topUpVolumeSetBy!,
                    style: helperTextStyle(context),
                  ),
                ),
              ],
              const SizedBox(height: kSpacingS),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Top-up Strength'),
                subtitle: Text(
                  topUpReconLabel ??
                      (topUpPerMl != null
                          ? '${fmt2(topUpPerMl!)} $unit/mL'
                          : 'Not set'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await pickTopUpStrength(dialogContext);
                  if (!dialogContext.mounted) return;
                  setState(() {});
                },
              ),
              if (canPreviewTopUpConc) ...[
                const SizedBox(height: kSpacingXS),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(kSpacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current: ${fmt2(currentPerMl)} $unit/mL',
                        style: helperTextStyle(context),
                      ),
                      Text(
                        'Top-up: ${fmt2(effectiveTopUpPerMl)} $unit/mL',
                        style: helperTextStyle(context),
                      ),
                      if (previewNewPerMl != null)
                        Text(
                          'New: ${fmt2(previewNewPerMl)} $unit/mL',
                          style: helperTextStyle(
                            context,
                            color: cs.primary,
                          )?.copyWith(fontWeight: kFontWeightSemiBold),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: kSpacingS),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kSpacingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Volume:'),
                  Text(
                    '${_formatNumber(previewVolume)} mL',
                    style: bodyTextStyle(context)?.copyWith(
                      fontWeight: kFontWeightSemiBold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return AlertDialog(
          titleTextStyle: cardTitleStyle(context)?.copyWith(color: cs.primary),
          contentTextStyle: bodyTextStyle(context),
          title: const Text('Refill Active Vial'),
          content: SingleChildScrollView(child: content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: canSave
                  ? () {
                      Navigator.of(dialogContext).pop({
                        'mode': selectedMode,
                        'source': selectedSource,
                        'useFromStock': willUseFromStock,
                        'reconVolume':
                            (double.tryParse(replaceVolumeCtrl.text) ?? 0),
                        'perMl': selectedPerMl,
                        'diluentName': selectedDiluentName,
                        'recommendedUnits': selectedRecommendedUnits,
                        'reconLabel': selectedReconLabel,
                        'topUpVolume':
                            (double.tryParse(topUpVolumeCtrl.text) ?? 0),
                        'topUpPerMl': topUpPerMl,
                        'topUpDiluentName': topUpDiluentName,
                        'topUpReconLabel': topUpReconLabel,
                      });
                    }
                  : null,
              child: Text(
                selectedMode == 'replace' ? 'Replace Vial' : 'Top Up',
              ),
            ),
          ],
        );
      },
    ),
  );

  replaceVolumeCtrl.dispose();
  topUpVolumeCtrl.dispose();

  if (result != null && context.mounted) {
    final box = Hive.box<Medication>('medications');
    final inventoryLogBox = Hive.box<InventoryLog>('inventory_logs');
    final now = DateTime.now();
    final mode = result['mode'] as String;
    final useStock = (result['useFromStock'] as bool?) ?? false;
    final previousSealedCount = med.stockValue;
    var newSealedCount = med.stockValue;
    final usedSealedVial = useStock && previousSealedCount.toInt() > 0;
    if (usedSealedVial) {
      newSealedCount = med.stockValue - 1;
    }

    if (mode == 'topUp') {
      final addVolume = (result['topUpVolume'] as double?) ?? vialSize;
      final newVolume = currentVolume + addVolume;

      final unit = MedicationDisplayHelpers.unitLabel(med.strengthUnit);
      final currentPerMl = med.perMlValue;
      final topPerMl = (result['topUpPerMl'] as double?) ?? currentPerMl;
      final newPerMl = (currentPerMl != null &&
              topPerMl != null &&
              currentPerMl > 0 &&
              topPerMl > 0 &&
              currentVolume > 0 &&
              addVolume > 0 &&
              (currentVolume + addVolume) > 0)
          ? ((currentPerMl * currentVolume) + (topPerMl * addVolume)) /
              (currentVolume + addVolume)
          : null;

      final topUpDiluent = result['topUpDiluentName'] as String?;
      box.put(
        med.id,
        med.copyWith(
          activeVialVolume: newVolume,
          containerVolumeMl: newVolume,
          perMlValue: newPerMl ?? med.perMlValue,
          diluentName: topUpDiluent ?? med.diluentName,
          stockValue: newSealedCount,
          reconstitutedAt: now,
        ),
      );

      final inventoryLog = InventoryLog(
        id: 'vial_${med.id}_${now.millisecondsSinceEpoch}',
        medicationId: med.id,
        medicationName: med.name,
        changeType: InventoryChangeType.vialOpened,
        previousStock: previousSealedCount,
        newStock: newSealedCount,
        changeAmount: usedSealedVial ? -1 : 0,
        notes:
            'Topped up +${_formatNumber(addVolume)} mL to ${_formatNumber(newVolume)} mL'
            '${usedSealedVial ? ' • used 1 sealed vial' : ''}'
            '${(currentPerMl != null && topPerMl != null) ? ' • ${fmt2(currentPerMl)}→${fmt2(newPerMl ?? currentPerMl)} $unit/mL' : ''}',
        timestamp: now,
      );
      inventoryLogBox.put(inventoryLog.id, inventoryLog);

      final stockText = usedSealedVial ? ' (1 sealed vial used)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Topped up vial - ${_formatNumber(newVolume)} mL$stockText',
          ),
        ),
      );
      return;
    }

    final reconVolume = result['reconVolume'] as double?;
    final perMl = result['perMl'] as double?;
    if (reconVolume == null ||
        perMl == null ||
        reconVolume <= 0 ||
        perMl <= 0) {
      return;
    }

    final diluentName = result['diluentName'] as String?;
    final reconLabel = result['reconLabel'] as String?;
    final recommendedUnits = result['recommendedUnits'] as double?;

    box.put(
      med.id,
      med.copyWith(
        containerVolumeMl: reconVolume,
        perMlValue: perMl,
        volumePerDose: recommendedUnits != null && recommendedUnits > 0
            ? (recommendedUnits / 100)
            : med.volumePerDose,
        diluentName: diluentName,
        activeVialVolume: reconVolume,
        reconstitutedAt: now,
        stockValue: newSealedCount,
      ),
    );

    final inventoryLog = InventoryLog(
      id: 'vial_${med.id}_${now.millisecondsSinceEpoch}',
      medicationId: med.id,
      medicationName: med.name,
      changeType: InventoryChangeType.vialOpened,
      previousStock: previousSealedCount,
      newStock: newSealedCount,
      changeAmount: usedSealedVial ? -1 : 0,
      notes:
          'Replaced to ${_formatNumber(reconVolume)} mL'
          '${usedSealedVial ? ' • used 1 sealed vial' : ''}'
          '${reconLabel != null ? ' • $reconLabel' : ''}',
      timestamp: now,
    );
    inventoryLogBox.put(inventoryLog.id, inventoryLog);

    final stockText = usedSealedVial ? ' (1 sealed vial used)' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Replaced vial - ${_formatNumber(reconVolume)} mL$stockText',
        ),
      ),
    );
  }
}

/// Dialog to add sealed vials to sealed vial stock
Future<void> _showRestockSealedVialsDialog(
  BuildContext context,
  Medication med,
) async {
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
          titleTextStyle: cardTitleStyle(
            context,
          )?.copyWith(color: theme.colorScheme.primary),
          contentTextStyle: bodyTextStyle(context),
          title: const Text('Restock Sealed Vials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Helper text
              Text(
                'Add new sealed vials to your sealed vial stock.',
                style: helperTextStyle(context),
              ),
              const SizedBox(height: 16),

              // Current stock
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kSpacingM),
                decoration: buildInsetSectionDecoration(context: context),
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
  final double? concentration = switch (med.strengthUnit) {
    Unit.mcgPerMl ||
    Unit.mgPerMl ||
    Unit.gPerMl ||
    Unit.unitsPerMl => (med.perMlValue ?? med.strengthValue),
    _ =>
      (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
          ? (med.strengthValue / med.containerVolumeMl!)
          : null,
  };
  final Unit strengthDoseUnit = switch (med.strengthUnit) {
    Unit.mcgPerMl => Unit.mcg,
    Unit.mgPerMl => Unit.mg,
    Unit.gPerMl => Unit.g,
    Unit.unitsPerMl => Unit.units,
    _ => med.strengthUnit,
  };
  final String strengthUnit = _unitLabel(med.strengthUnit);
  final String strengthDoseUnitLabel = _unitLabel(strengthDoseUnit);

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

        void setInputFromVolumeMl(double volumeMl) {
          final clamped = volumeMl.clamp(0.0, maxVolume);
          if (selectedUnit == 'mL') {
            volumeController.text = fmt2(clamped);
            return;
          }
          if (selectedUnit == 'units') {
            volumeController.text = (clamped * 100).round().toString();
            return;
          }

          // Strength input (mg/mcg)
          final strength = concentration != null ? clamped * concentration : 0;
          volumeController.text = fmt2(strength);
        }

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
          titleTextStyle: cardTitleStyle(
            stateContext,
          )?.copyWith(color: colorScheme.primary),
          contentTextStyle: bodyTextStyle(stateContext),
          title: const Text('Record Ad-Hoc Dose'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Helper text
                Text(
                  'Record an adhoc (unscheduled) dose — an extra dose taken outside your regular schedule.',
                  style: helperTextStyle(stateContext),
                ),
                const SizedBox(height: 12),

                // Medication info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(kSpacingM),
                  decoration: buildInsetSectionDecoration(
                    context: stateContext,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: cardTitleStyle(
                          stateContext,
                        )?.copyWith(fontWeight: kFontWeightExtraBold),
                      ),
                      if (isMdv && concentration != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          switch (med.strengthUnit) {
                            Unit.mcgPerMl ||
                            Unit.mgPerMl ||
                            Unit.gPerMl ||
                            Unit.unitsPerMl =>
                              '${_formatNumber(med.perMlValue ?? med.strengthValue)} $strengthUnit',
                            _ when med.containerVolumeMl != null =>
                              '${_formatNumber(med.strengthValue)} $strengthUnit / ${_formatNumber(med.containerVolumeMl!)} mL',
                            _ =>
                              '${_formatNumber(med.strengthValue)} $strengthUnit',
                          },
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
                            final previousVolumeMl = clampedVolume.toDouble();
                            setState(() {
                              if (index == 0) {
                                selectedUnit = 'mL';
                              } else if (index == 1) {
                                selectedUnit = strengthUnit.contains('mcg')
                                    ? 'mcg'
                                    : 'mg';
                              } else {
                                selectedUnit = 'units';
                              }
                              setInputFromVolumeMl(previousVolumeMl);
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

                            if (selectedUnit == 'units') {
                              final maxUnits =
                                  (syringeSize.clamp(0.0, maxVolume) * 100)
                                      .round();
                              final nv = (v - 1)
                                  .clamp(0, maxUnits)
                                  .round()
                                  .toString();
                              volumeController.text = nv;
                              setState(() {});
                              return;
                            }

                            if (selectedUnit == 'mL') {
                              final maxMl = syringeSize.clamp(0.0, maxVolume);
                              volumeController.text = fmt2(
                                (v - 0.1).clamp(0.0, maxMl),
                              );
                              setState(() {});
                              return;
                            }

                            // Strength mode
                            final maxStrength = concentration != null
                                ? syringeSize.clamp(0.0, maxVolume) *
                                      concentration
                                : 0.0;
                            volumeController.text = fmt2(
                              (v - 0.1).clamp(0.0, maxStrength),
                            );
                            setState(() {});
                          },
                          onInc: () {
                            final v =
                                double.tryParse(volumeController.text) ?? 0;

                            if (selectedUnit == 'units') {
                              final maxUnits =
                                  (syringeSize.clamp(0.0, maxVolume) * 100)
                                      .round();
                              final nv = (v + 1)
                                  .clamp(0, maxUnits)
                                  .round()
                                  .toString();
                              volumeController.text = nv;
                              setState(() {});
                              return;
                            }

                            final maxInputValue = selectedUnit == 'mL'
                                ? syringeSize.clamp(0.0, maxVolume)
                                : (selectedUnit == 'mg' ||
                                          selectedUnit == 'mcg') &&
                                      concentration != null
                                ? syringeSize.clamp(0.0, maxVolume) *
                                      concentration
                                : syringeSize * 100;

                            if (v < maxInputValue) {
                              volumeController.text = fmt2(v + 0.1);
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
                            final newVolumeMl = (newValue / 100).clamp(
                              0.0,
                              maxVolume,
                            );
                            if (selectedUnit == 'units') {
                              volumeController.text = newValue
                                  .round()
                                  .toString();
                            } else if (selectedUnit == 'mL') {
                              volumeController.text = fmt2(newVolumeMl);
                            } else {
                              final strength = concentration != null
                                  ? newVolumeMl * concentration
                                  : 0;
                              volumeController.text = fmt2(strength);
                            }
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
                        if (concentration != null) ...[
                          const TextSpan(text: ' for a dose of '),
                          TextSpan(
                            text:
                                '${_formatNumber(displayStrength)} $strengthDoseUnitLabel',
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
                  style: bodyTextStyle(stateContext),
                  decoration: buildFieldDecoration(
                    stateContext,
                    hint: 'e.g., Taken for breakthrough pain',
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
                if (isMdv) {
                  final amountMl = clampedVolume.toDouble();
                  if (amountMl > 0) {
                    Navigator.pop(dialogContext, {
                      'amount': amountMl,
                      'unit': 'mL',
                      'notes': notesController.text.trim(),
                    });
                  }
                  return;
                }

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
      final cs = theme.colorScheme;
      return AlertDialog(
        titleTextStyle: cardTitleStyle(
          dialogContext,
        )?.copyWith(color: cs.primary),
        contentTextStyle: bodyTextStyle(dialogContext),
        title: Text(title),
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
    builder: (dialogContext) {
      final cs = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        titleTextStyle: cardTitleStyle(
          dialogContext,
        )?.copyWith(color: cs.primary),
        contentTextStyle: bodyTextStyle(dialogContext),
        title: Text(title),
        content: TextField(
          controller: controller,
          style: bodyTextStyle(dialogContext),
          decoration: buildFieldDecoration(dialogContext, hint: 'Enter $title'),
          maxLines: maxLines,
          keyboardType: keyboardType,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
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
  _showStepperEditWithUnitDialog(
    context,
    title: 'Strength',
    initialValue: med.strengthValue,
    initialUnit: med.strengthUnit,
    allowedUnits: Unit.values,
    onSave: (value, unit) {
      final box = Hive.box<Medication>('medications');
      box.put(med.id, med.copyWith(strengthValue: value, strengthUnit: unit));
    },
  );
}

Future<void> _showStepperEditWithUnitDialog(
  BuildContext context, {
  required String title,
  required double initialValue,
  required Unit initialUnit,
  required void Function(double value, Unit unit) onSave,
  List<Unit>? allowedUnits,
  bool isInt = false,
}) async {
  final controller = TextEditingController(
    text: isInt ? initialValue.toInt().toString() : initialValue.toString(),
  );
  var selectedUnit = initialUnit;
  final units = (allowedUnits ?? Unit.values).toList();

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final cs = theme.colorScheme;

      return AlertDialog(
        titleTextStyle: cardTitleStyle(
          dialogContext,
        )?.copyWith(color: cs.primary),
        contentTextStyle: bodyTextStyle(dialogContext),
        title: Text(title),
        content: StatefulBuilder(
          builder: (stateContext, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Value',
                  style: helperTextStyle(
                    stateContext,
                  )?.copyWith(fontWeight: kFontWeightSemiBold),
                ),
                const SizedBox(height: kSpacingS),
                Center(
                  child: StepperRow36(
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
                  ),
                ),
                const SizedBox(height: kSpacingL),
                Text(
                  'Unit',
                  style: helperTextStyle(
                    stateContext,
                  )?.copyWith(fontWeight: kFontWeightSemiBold),
                ),
                const SizedBox(height: kSpacingS),
                Center(
                  child: SmallDropdown36<Unit>(
                    width: kMinCompactControlWidth,
                    value: selectedUnit,
                    items: units
                        .map(
                          (u) => DropdownMenuItem<Unit>(
                            value: u,
                            child: Text(_unitLabel(u)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => selectedUnit = v);
                    },
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(dialogContext, {
                  'value': val,
                  'unit': selectedUnit,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  if (result == null) return;
  final value = result['value'] as double?;
  final unit = result['unit'] as Unit?;
  if (value == null || unit == null) return;
  if (value == initialValue && unit == initialUnit) return;
  onSave(value, unit);
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
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            titleTextStyle: cardTitleStyle(
              context,
            )?.copyWith(color: cs.primary),
            contentTextStyle: bodyTextStyle(context),
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

void _editActiveVialExpiry(BuildContext context, Medication med) {
  _editDate(context, med, 'Active Vial Expiry', med.reconstitutedVialExpiry, (
    val,
  ) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(reconstitutedVialExpiry: val));
  });
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
    builder: (dialogContext) {
      final cs = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        titleTextStyle: cardTitleStyle(
          dialogContext,
        )?.copyWith(color: cs.primary),
        contentTextStyle: bodyTextStyle(dialogContext),
        title: const Text('Delete Medication'),
        content: Text(
          'Deleting ${med.name} will delete all associated schedules and cancel their notifications. Historical dose and inventory data will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    final repo = MedicationRepository(Hive.box<Medication>('medications'));
    await repo.delete(med.id);
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
