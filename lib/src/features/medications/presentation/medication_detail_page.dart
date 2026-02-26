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
import 'package:dosifi_v5/src/widgets/app_snackbar.dart';
import 'package:dosifi_v5/src/core/notifications/low_stock_notifier.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/core/utils/id.dart';
import 'package:dosifi_v5/src/features/medications/data/medication_repository.dart';
import 'package:dosifi_v5/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/inventory_log.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication_stock_adjustment.dart';
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_header_widget.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_detail_header_identity.dart';
import 'package:dosifi_v5/src/features/medications/presentation/widgets/medication_sealed_vials_editor_card.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/reports/domain/report_time_range.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/dose_action_sheet.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';
import 'package:dosifi_v5/src/widgets/reconstitution_summary_card.dart';
import 'package:dosifi_v5/src/widgets/selection_cards.dart';
import 'package:dosifi_v5/src/widgets/smart_expiry_picker.dart';
import 'package:dosifi_v5/src/widgets/compact_storage_line.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:dosifi_v5/src/widgets/status_pill.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/medication_schedules_section.dart';
import 'package:dosifi_v5/src/widgets/cards/activity_card.dart';
import 'package:dosifi_v5/src/widgets/cards/today_doses_card.dart';

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

double? _inferDoseAmountFromReconCalc(SavedReconstitutionCalculation recon) {
  if (recon.perMlConcentration <= 0) return null;
  if (recon.calculatedUnits <= 0) return null;

  final unitsPerMl = SyringeType.ml_1_0.unitsPerMl;
  if (unitsPerMl <= 0) return null;

  final doseVolumeMl = recon.calculatedUnits / unitsPerMl;
  if (doseVolumeMl <= 0) return null;

  return recon.perMlConcentration * doseVolumeMl;
}

double? _inferInitialDesiredDoseAmount(Medication med) {
  final savedRecon = SavedReconstitutionRepository().ownedForMedication(med.id);
  final savedDose = savedRecon?.calculatedDose;
  if (savedDose != null && savedDose > 0) return savedDose;

  final inferredFromSaved = savedRecon != null
      ? _inferDoseAmountFromReconCalc(savedRecon)
      : null;
  return inferredFromSaved ?? _inferDoseAmountFromSavedRecon(med);
}

String _inferInitialDesiredDoseUnit(Medication med) {
  final savedRecon = SavedReconstitutionRepository().ownedForMedication(med.id);
  final unit = savedRecon?.doseUnit?.trim();
  if (unit != null && unit.isNotEmpty) return unit;
  return med.strengthUnit.name;
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
  bool _showDownScrollHint = false;
  bool _isDetailsExpanded = true; // Collapsible state for details card
  bool _isScheduleExpanded = true; // Collapsible state for schedule card
  bool _isReconstitutionExpanded = true; // Collapsible state for reconstitution
  bool _isTodayExpanded = true; // Collapsible state for today card
  bool _isActivityExpanded = true; // Collapsible state for activity card

  ReportTimeRangePreset _activityRangePreset = ReportTimeRangePreset.allTime;

  late final List<String> _cardOrder;

  static const String _kCardSchedule = 'schedule';
  static const String _kCardDetails = 'details';
  static const String _kCardReconstitution = 'reconstitution';
  static const String _kCardToday = 'today';
  static const String _kCardActivity = 'activity';

  double _measuredExpandedHeaderHeight = _kDetailHeaderExpandedHeight;
  final GlobalKey _headerMeasureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateDownScrollHint);
    _cardOrder = <String>[
      _kCardToday,
      _kCardActivity,
      _kCardReconstitution,
      _kCardSchedule,
      _kCardDetails,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateDownScrollHint();
    });

    final medId = widget.initial?.id ?? widget.medicationId;
    if (medId != null && medId.isNotEmpty) {
      unawaited(_restoreCardOrder(medId));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateDownScrollHint);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateDownScrollHint() {
    if (!_scrollController.hasClients) return;
    final metrics = _scrollController.position;
    const epsilon = 1.0;
    final shouldShow =
        metrics.maxScrollExtent > epsilon &&
        metrics.pixels < (metrics.maxScrollExtent - epsilon);
    if (_showDownScrollHint == shouldShow) return;
    if (!mounted) return;
    setState(() => _showDownScrollHint = shouldShow);
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
                size: kEmptyStateIconSizeLarge,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: kSpacingL),
              Text('Medication not found', style: cardTitleStyle(context)),
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
                    backgroundColor: kColorTransparent,
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
                                top +
                                    kMedicationDetailHeaderIdentityExpandedTopOffset,
                                top +
                                    (_kDetailHeaderCollapsedHeight -
                                            kMedicationDetailHeaderIdentityCollapsedVisualHeight) /
                                        2,
                                t,
                              ),
                              left: kPageHorizontalPadding,
                              right: lerpDouble(
                                // Reserve space for the right-side stock gauge/card when expanded.
                                (constraints.maxWidth *
                                            kMedicationDetailHeaderIdentityRightReservedExpandedFraction) <
                                        kMedicationDetailHeaderIdentityRightReservedMinWidth
                                    ? kMedicationDetailHeaderIdentityRightReservedMinWidth
                                    : (constraints.maxWidth *
                                          kMedicationDetailHeaderIdentityRightReservedExpandedFraction),
                                0,
                                t,
                              ),
                              child: MedicationDetailHeaderIdentity(
                                name: updatedMed.name,
                                formLabel: _formLabel(updatedMed.form),
                                manufacturer: updatedMed.manufacturer,
                                headerForeground: headerForeground,
                                onPrimary: onPrimary,
                                t: t,
                                onTapName: () => _editName(context, updatedMed),
                                onTapManufacturer: () =>
                                    _editManufacturer(context, updatedMed),
                              ),
                            ),
                            // Keep the same title-fade behavior without rebuilding the whole page on scroll.
                            Positioned(
                              top: top,
                              left:
                                  kDetailHeaderCollapsedHeight +
                                  kSpacingS, // Account for back button (48px) + spacing
                              right:
                                  kDetailHeaderCollapsedHeight +
                                  kSpacingS, // Account for menu button symmetrically
                              height: _kDetailHeaderCollapsedHeight,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: (1.0 - t * 3).clamp(0.0, 1.0),
                                  child: Center(
                                    child: Text(
                                      'Medication Details',
                                      style:
                                          medicationDetailCollapsedTitleTextStyle(
                                            context,
                                            color: onPrimary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedOpacity(
                      duration: kAnimationFast,
                      curve: Curves.easeOut,
                      opacity: _showDownScrollHint ? 1 : 0,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: kPageScrollHintPadding,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: kPageScrollHintIconSize,
                            color: colorScheme.onSurface.withValues(
                              alpha: kOpacityMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
                        onRestock:
                            updatedMed.form == MedicationForm.multiDoseVial
                            ? () {}
                            : null,
                        onAdHocDose: () {},
                        hasSchedules: hasSchedules,
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
      _kCardToday: TodayDosesCard(
        scope: TodayDosesScope.medication(med.id),
        isExpanded: _isTodayExpanded,
        onExpandedChanged: (expanded) {
          if (!mounted) return;
          setState(() => _isTodayExpanded = expanded);
        },
        reserveReorderHandleGutterWhenCollapsed: true,
      ),
      _kCardActivity: ActivityCard(
        medications: [med],
        includedMedicationIds: {med.id},
        rangePreset: _activityRangePreset,
        onRangePresetChanged: (next) {
          if (!mounted) return;
          setState(() => _activityRangePreset = next);
        },
        isExpanded: _isActivityExpanded,
        reserveReorderHandleGutterWhenCollapsed: true,
        onExpandedChanged: (expanded) {
          if (!mounted) return;
          setState(() => _isActivityExpanded = expanded);
        },
      ),
      _kCardSchedule: _buildScheduleCard(
        context,
        med,
      ),
      _kCardDetails: _buildUnifiedDetailsCard(context, med),
    };

    final hasReconstitutionCard = cards.containsKey(_kCardReconstitution);

    final allCardsCollapsed =
        !_isTodayExpanded &&
        !_isActivityExpanded &&
        !_isScheduleExpanded &&
        !_isDetailsExpanded &&
        (!hasReconstitutionCard || !_isReconstitutionExpanded);

    bool isExpandedForCardId(String id) {
      switch (id) {
        case _kCardToday:
          return _isTodayExpanded;
        case _kCardActivity:
          return _isActivityExpanded;
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
      showAppSnackBar(
        context,
        'Collapse all cards first to rearrange them.',
        duration: kAppSnackBarDurationShort,
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
                const SizedBox(height: 48),

                // Description & Notes
                if (med.description != null && med.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: kSpacingXS),
                    child: Text(
                      med.description!,
                      style: helperTextStyle(
                        context,
                        color: onPrimary.withValues(alpha: 0.9),
                      )?.copyWith(fontStyle: FontStyle.italic),
                      maxLines: 2, // Reduced from 3
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                if (med.notes != null && med.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: kSpacingS),
                    child: Text(
                      med.notes!,
                      style: hintTextStyle(context)?.copyWith(
                        color: onPrimary.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
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
                    style: smallHelperTextStyle(
                      context,
                      color: onPrimary.withValues(alpha: kOpacityMediumHigh),
                    ),
                    children: [
                      TextSpan(
                        text: _formatNumber(med.stockValue),
                        style:
                            smallHelperTextStyle(
                              context,
                              color: onPrimary.withValues(
                                alpha: kOpacityMediumHigh,
                              ),
                            )?.copyWith(
                              fontWeight: kFontWeightExtraBold,
                              color: gaugeLabelColor,
                            ),
                      ),
                      const TextSpan(text: ' / '),
                      TextSpan(
                        text: _formatNumber(initial),
                        style: smallHelperTextStyle(
                          context,
                          color: onPrimary,
                        )?.copyWith(fontWeight: kFontWeightExtraBold),
                      ),
                      TextSpan(text: ' $unit'),
                    ],
                  ),
                ),
                Text(
                  helperLabel,
                  style: smallHelperTextStyle(
                    context,
                    color: onPrimary.withValues(alpha: kOpacityMediumLow),
                  ),
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
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                      border: Border.all(
                        color: onPrimary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: kColorTransparent,
                      child: InkWell(
                        onTap: () => _showRefillDialog(context, med),
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kSpacingM,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 14,
                                color: onPrimary,
                              ),
                              const SizedBox(width: kSpacingXS + kSpacingXXS),
                              Text(
                                'Refill',
                                style: helperTextStyle(
                                  context,
                                  color: onPrimary,
                                )?.copyWith(fontWeight: kFontWeightBold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (med.form == MedicationForm.multiDoseVial) ...[
                    const SizedBox(width: kSpacingS),
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: onPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        border: Border.all(
                          color: onPrimary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: kColorTransparent,
                        child: InkWell(
                          onTap: () =>
                              _showRestockSealedVialsDialog(context, med),
                          borderRadius: BorderRadius.circular(
                            kBorderRadiusSmall,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpacingM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 14,
                                  color: onPrimary,
                                ),
                                const SizedBox(width: kSpacingXS + kSpacingXXS),
                                Text(
                                  'Restock',
                                  style: helperTextStyle(
                                    context,
                                    color: onPrimary,
                                  )?.copyWith(fontWeight: kFontWeightBold),
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
    final baseStyle = microHelperTextStyle(
      context,
      color: onPrimary.withValues(alpha: kOpacityMediumHigh),
    )?.copyWith(fontWeight: kFontWeightSemiBold);

    return RichText(
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: fmt2(currentMl),
            style: baseStyle?.copyWith(
              fontWeight: kFontWeightExtraBold,
              color: colored,
            ),
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
    final baseStyle = microHelperTextStyle(
      context,
      color: onPrimary.withValues(alpha: kOpacityMediumHigh),
    )?.copyWith(fontWeight: kFontWeightSemiBold);

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
            style: baseStyle?.copyWith(
              fontWeight: kFontWeightExtraBold,
              color: colored,
            ),
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
                        style: bodyTextStyle(
                          context,
                        )?.copyWith(color: colorScheme.error),
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

  Widget _buildScheduleCard(BuildContext context, Medication med) {
    final scheduleBox = Hive.box<Schedule>('schedules');
    final hasSchedules = scheduleBox.values.any(
      (s) => s.medicationId == med.id,
    );

    return CollapsibleSectionFormCard(
      neutral: true,
      frameless: true,
      title: 'Schedules',
      leading: Icon(
        Icons.calendar_month_rounded,
        size: kIconSizeMedium,
        color: Theme.of(context).colorScheme.primary,
      ),
      reserveReorderHandleGutterWhenCollapsed: true,
      isExpanded: _isScheduleExpanded,
      onExpandedChanged: (expanded) {
        if (!mounted) return;
        setState(() => _isScheduleExpanded = expanded);
      },
      children: [
        if (!hasSchedules)
          buildHelperText(context, 'No schedules')
        else
          MedicationSchedulesSection(medication: med, showNextDoseCard: false),
      ],
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
          const SizedBox(width: kSpacingS),
          Text(title, style: sectionTitleStyle(context)),
        ],
      );
    }
    return Text(title, style: sectionTitleStyle(context));
  }

  Widget divvyIcon(IconData icon, {Color? color, double? size}) {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final base = color ?? cs.primary;
        return Container(
          padding: const EdgeInsets.all(kSpacingS),
          decoration: BoxDecoration(
            color: base.withValues(alpha: kOpacityVeryLow),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: base, size: size),
        );
      },
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

        // DESCRIPTION & NOTES (immediately after Manufacturer)
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

    final labelStyle = smallHelperTextStyle(
      context,
      color: colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
    )?.copyWith(fontWeight: kFontWeightSemiBold);

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
            width: kMedicationDetailInlineLabelWidth,
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
              width: kMedicationDetailInlineLabelWidth,
              child: Text(
                'Conditions',
                style: smallHelperTextStyle(
                  context,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Wrap(spacing: kFieldSpacing, children: conditions),
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
    final cs = Theme.of(context).colorScheme;

    return StatusPill(label: label, color: cs.primary, icon: icon, dense: true);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Storage Conditions',
              style: smallHelperTextStyle(
                context,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingXXS),
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
            style: smallHelperTextStyle(
              context,
              color: isEnabled
                  ? colorScheme.onSurface
                  : colorScheme.outlineVariant,
            ),
          ),
          const Spacer(),
          Text(
            isEnabled ? 'On' : 'Off',
            style: smallHelperTextStyle(
              context,
              color: isEnabled
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            )?.copyWith(fontWeight: kFontWeightMedium),
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
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacingL,
              vertical: kSpacingS + kSpacingXXS,
            ),
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
                  size: kIconSizeSmall,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: kSpacingS),
                Expanded(
                  child: Text(
                    'Vial currently in use for injections',
                    style: helperTextStyle(
                      context,
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
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingL,
                vertical: kSpacingM,
              ),
              child: Row(
                children: [
                  Text(
                    'Volume',
                    style: helperTextStyle(
                      context,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_formatNumber(med.activeVialVolume ?? med.containerVolumeMl!)} / ${_formatNumber(med.containerVolumeMl!)} mL',
                    style: cardTitleStyle(context)?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: kFontWeightBold,
                    ),
                  ),
                ],
              ),
            ),

          Divider(
            height: 1,
            indent: kSpacingL,
            endIndent: kSpacingL,
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
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingL,
          vertical: kSpacingS,
        ),
        child: Row(
          children: [
            SizedBox(
              width: kMedicationDetailInlineLabelWidth,
              child: Text(
                'Conditions',
                style: smallHelperTextStyle(
                  context,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Wrap(spacing: kFieldSpacing, children: conditions),
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
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingL,
          vertical: kSpacingS,
        ),
        child: Row(
          children: [
            SizedBox(
              width: kMedicationDetailInlineLabelWidth,
              child: Text(
                'Conditions',
                style: smallHelperTextStyle(
                  context,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Wrap(spacing: kFieldSpacing, children: conditions),
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
    return MedicationSealedVialsEditorCard(
      sealedVialsCountLabel:
          '${_formatNumber(med.stockValue).split('.')[0]} sealed vials',
      batchNumberValue: med.backupVialsBatchNumber ?? 'Not set',
      batchNumberIsPlaceholder: med.backupVialsBatchNumber == null,
      onEditBatchNumber: () => _editBackupVialBatch(context, med),
      expiryValue: med.backupVialsExpiry != null
          ? _formatExpiry(med.backupVialsExpiry!)
          : 'Not set',
      expiryIsPlaceholder: med.backupVialsExpiry == null,
      expiryIsWarning:
          med.backupVialsExpiry != null &&
          _isExpiringSoon(med.backupVialsExpiry!),
      onEditExpiry: () => _editBackupVialExpiry(context, med),
      locationValue: med.backupVialsStorageLocation ?? 'Not set',
      locationIsPlaceholder: med.backupVialsStorageLocation == null,
      onEditLocation: () => _editBackupVialLocation(context, med),
      conditionsRow: _buildBackupStockConditionsRow(context, med),
    );
  }

  Widget _buildReconstitutionCard(BuildContext context, Medication med) {
    if (med.form != MedicationForm.multiDoseVial ||
        med.strengthValue <= 0 ||
        (med.containerVolumeMl == null && med.perMlValue == null)) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    final savedRecon = SavedReconstitutionRepository().ownedForMedication(
      med.id,
    );
    final actualDoseStrengthValue =
        (savedRecon?.calculatedDose != null &&
            savedRecon!.calculatedDose! > 0)
        ? savedRecon.calculatedDose
        : _inferDoseAmountFromSavedRecon(med);
    final actualDoseStrengthUnit =
        savedRecon?.doseUnit?.trim().isNotEmpty == true
        ? savedRecon!.doseUnit!.trim()
        : _unitLabel(med.strengthUnit);
    final syringeSizeMl = (savedRecon != null && savedRecon.syringeSizeMl > 0)
        ? savedRecon.syringeSizeMl
        : 3.0;
    final diluentName = savedRecon?.diluentName ?? med.diluentName;

    return GlassCardSurface(
      useGradient: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _editReconstitution(context, med),
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
                    child: ConstrainedBox(
                      constraints: kTightIconButtonConstraints,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(
                            () => _isReconstitutionExpanded =
                                !_isReconstitutionExpanded,
                          );
                        },
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: kIconSizeLarge,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
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
                  doseStrengthValue: actualDoseStrengthValue,
                  doseStrengthUnit: actualDoseStrengthUnit,
                  reconFluidName: diluentName ?? 'Bacteriostatic Water',
                  syringeSizeMl: syringeSizeMl,
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

    final savedRecon = SavedReconstitutionRepository().ownedForMedication(
      latest.id,
    );

    final initialDoseAmount = _inferInitialDesiredDoseAmount(latest);
    final initialDoseUnit = _inferInitialDesiredDoseUnit(latest);

    SyringeSizeMl initialSyringe;
    if (savedRecon != null && savedRecon.syringeSizeMl > 0) {
      initialSyringe = _inferSyringeSizeFromDoseVolumeMl(
        savedRecon.syringeSizeMl,
      );
    } else if (latest.volumePerDose != null && latest.volumePerDose! > 0) {
      initialSyringe = _inferSyringeSizeFromDoseVolumeMl(latest.volumePerDose!);
    } else {
      initialSyringe = SyringeSizeMl.ml1;
    }

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
          initialVialSize:
              savedRecon?.solventVolumeMl ?? latest.containerVolumeMl,
          initialDiluentName: savedRecon?.diluentName ?? latest.diluentName,
        ),
      ),
    );

    if (result == null) return;

    final savedReconRepo = SavedReconstitutionRepository();

    await box.put(
      latest.id,
      latest.copyWith(
        perMlValue: result.perMlConcentration,
        containerVolumeMl: result.solventVolumeMl,
        volumePerDose: result.calculatedUnits / SyringeType.ml_1_0.unitsPerMl,
        diluentName: result.diluentName ?? latest.diluentName,
        activeVialVolume: result.solventVolumeMl,
        reconstitutedAt: DateTime.now(),
      ),
    );

    // Persist/update the medication-owned saved reconstitution so other flows
    // (like schedule defaults) can reuse it.
    try {
      final ownedId = SavedReconstitutionRepository.ownedIdForMedication(
        latest.id,
      );
      final existing = savedReconRepo.get(ownedId);
      final ownedName = savedReconRepo.buildOwnedDisplayName(
        medicationName: latest.name,
        strengthValue: latest.strengthValue,
        strengthUnit: latest.strengthUnit.name,
        solventVolumeMl: result.solventVolumeMl,
        calculatedDose: result.calculatedDose,
        doseUnit: result.doseUnit,
      );

      await savedReconRepo.upsert(
        SavedReconstitutionCalculation(
          id: ownedId,
          name: ownedName,
          ownerMedicationId: latest.id,
          medicationName: latest.name,
          strengthValue: latest.strengthValue,
          strengthUnit: latest.strengthUnit.name,
          solventVolumeMl: result.solventVolumeMl,
          perMlConcentration: result.perMlConcentration,
          calculatedUnits: result.calculatedUnits,
          syringeSizeMl: result.syringeSizeMl,
          diluentName: result.diluentName,
          calculatedDose: result.calculatedDose,
          doseUnit: result.doseUnit,
          maxVialSizeMl: result.maxVialSizeMl,
          createdAt: existing?.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // Best-effort; editing the medication should still succeed.
    }

    if (!mounted) return;
    showAppSnackBar(context, 'Reconstitution updated');
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
          width: kMedicationDetailCompactInfoLabelWidth,
          child: Text(
            label,
            style: bodyTextStyle(context)?.copyWith(
              color: theme.colorScheme.onSurface.withValues(
                alpha: kOpacityMedium,
              ),
              fontWeight: kFontWeightMedium,
            ),
          ),
        ),
        // Value
        Expanded(
          child: Text(
            value,
            style: bodyTextStyle(context)?.copyWith(
              fontWeight: highlighted ? kFontWeightBold : kFontWeightMedium,
              fontStyle: (isItalic || isPlaceholder)
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: warning
                  ? theme.colorScheme.error
                  : isPlaceholder
                  ? theme.colorScheme.onSurface.withValues(alpha: kOpacityLow)
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
            color: theme.colorScheme.onSurface.withValues(
              alpha: kOpacityVeryLow,
            ),
          ),
      ],
    );

    if (isEditable) {
      return Material(
        color: kColorTransparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: kSpacingM,
              horizontal: kSpacingS,
            ),
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kSpacingM,
        horizontal: kSpacingS,
      ),
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
    final color = textColor ?? Theme.of(context).colorScheme.onPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: medicationDetailHeaderTileLabelTextStyle(
            context,
            color: color.withValues(alpha: 0.7),
          ),
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
              style: medicationDetailHeaderTileValueTextStyle(
                context,
                color: color,
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
                'Add stock when you receive a new supply. "Add" will increase the stock by a specific amount (and update your maximum if it exceeds the current max). "Fill to Max" restores stock to your original maximum level.',
                style: helperTextStyle(stateContext),
              ),
              const SizedBox(height: kSpacingL),

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
                          style: bodyTextStyle(
                            stateContext,
                          )?.copyWith(fontWeight: kFontWeightBold),
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
                          style: bodyTextStyle(stateContext)?.copyWith(
                            fontWeight: kFontWeightBold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSpacingL),

              // Mode selection - Radio buttons instead of chips
              Text('Refill Method:', style: fieldLabelStyle(stateContext)),
              const SizedBox(height: kSpacingS),
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
                const SizedBox(height: kSpacingS),
                Text('Amount to Add:', style: fieldLabelStyle(stateContext)),
                const SizedBox(height: kSpacingS),
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
              const SizedBox(height: kSpacingL),

              // Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kSpacingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: kOpacityVeryLow,
                  ),
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Total:'),
                    Text(
                      '${_formatNumber(previewTotal)} $unit',
                      style: bodyTextStyle(stateContext)?.copyWith(
                        fontWeight: kFontWeightBold,
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
      id: IdGen.newId(prefix: 'inv_refill'),
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

    showAppSnackBar(context, message);
  }
}

/// MDV Refill dialog - Use a new vial with sealed vial management
void _showMdvRefillDialog(BuildContext context, Medication med) async {
  final currentVolume = med.activeVialVolume ?? 0;
  final vialSize = med.containerVolumeMl ?? 5.0;

  // Initialize from latest saved settings (in case the page is stale).
  final box = Hive.box<Medication>('medications');
  final latest = box.get(med.id) ?? med;

  // Check if a saved reconstitution exists for this medication
  final savedRecon = SavedReconstitutionRepository().ownedForMedication(med.id);
  final hasSavedRecon = savedRecon != null;

  // Step 1: Choose between Recalculate or Same Recon
  final reconChoice = await showDialog<String>(
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
        title: Text('Reconstitute a new vial of ${med.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how to prepare the new vial:',
              style: helperTextStyle(dialogContext),
            ),
            const SizedBox(height: kSpacingM),
            SelectableOptionCard(
              icon: Icons.calculate_outlined,
              title: 'Recalculate',
              subtitle:
                  'Open the Reconstitution Calculator to create a new calculation.',
              selected: false,
              onTap: () => Navigator.of(dialogContext).pop('recalculate'),
            ),
            const SizedBox(height: kSpacingS),
            SelectableOptionCard(
              icon: Icons.history,
              title: 'Same Recon Calculation',
              subtitle: hasSavedRecon
                  ? 'Use the previously saved reconstitution for this medication.'
                  : 'No saved reconstitution exists for this medication.',
              selected: false,
              enabled: hasSavedRecon,
              onTap: () => Navigator.of(dialogContext).pop('sameRecon'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );

  if (reconChoice == null || !context.mounted) return;

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

  double? selectedcalculatedUnits;
  String? selectedReconLabel;

  final topUpVolumeCtrl = TextEditingController(text: fmt2(vialSize));
  var topUpVolumeSetBy = latest.containerVolumeMl != null
      ? 'From previous reconstitution'
      : null;

  double? topUpPerMl = latest.perMlValue;
  String? topUpDiluentName = latest.diluentName;
  String? topUpReconLabel;

  // If user chose 'sameRecon', load the saved reconstitution immediately
  if (reconChoice == 'sameRecon' && savedRecon != null) {
    selectedPerMl = savedRecon.perMlConcentration;
    selectedDiluentName = savedRecon.diluentName;
    selectedcalculatedUnits = savedRecon.calculatedUnits;
    replaceVolumeCtrl.text = fmt2(savedRecon.solventVolumeMl);
    replaceVolumeSetBy = 'From saved reconstitution';

    final diluent = savedRecon.diluentName?.trim();
    selectedReconLabel = diluent == null || diluent.isEmpty
        ? '${savedRecon.solventVolumeMl.toStringAsFixed(2)} mL'
        : '${savedRecon.solventVolumeMl.toStringAsFixed(2)} mL $diluent';

    topUpPerMl = savedRecon.perMlConcentration;
    topUpDiluentName = savedRecon.diluentName;
  }

  // If user chose 'recalculate', open the calculator first
  if (reconChoice == 'recalculate') {
    final initialDoseAmount = _inferInitialDesiredDoseAmount(latest);
    final initialDoseUnit = _inferInitialDesiredDoseUnit(latest);
    final initialSyringe =
        (latest.volumePerDose != null && latest.volumePerDose! > 0)
        ? _inferSyringeSizeFromDoseVolumeMl(latest.volumePerDose!)
        : SyringeSizeMl.ml1;

    final result = await showModalBottomSheet<ReconstitutionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.0),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => ReconstitutionCalculatorDialog(
          initialStrengthValue: med.strengthValue,
          unitLabel: med.strengthUnit.name,
          initialDoseValue: initialDoseAmount,
          initialDoseUnit: initialDoseUnit,
          initialSyringeSize: initialSyringe,
          initialVialSize: latest.containerVolumeMl ?? vialSize,
          initialDiluentName: selectedDiluentName,
        ),
      ),
    );

    if (result == null || !context.mounted) {
      replaceVolumeCtrl.dispose();
      topUpVolumeCtrl.dispose();
      return;
    }

    selectedPerMl = result.perMlConcentration;
    selectedDiluentName = result.diluentName;
    selectedcalculatedUnits = result.calculatedUnits;
    replaceVolumeCtrl.text = fmt2(result.solventVolumeMl);
    replaceVolumeSetBy = 'From new reconstitution';

    final diluent = result.diluentName?.trim();
    selectedReconLabel = diluent == null || diluent.isEmpty
        ? '${result.solventVolumeMl.toStringAsFixed(2)} mL'
        : '${result.solventVolumeMl.toStringAsFixed(2)} mL $diluent';

    topUpPerMl = result.perMlConcentration;
    topUpDiluentName = result.diluentName;
  }

  Future<void> pickReconstitution(BuildContext dialogContext) async {
    final initialDoseAmount = _inferInitialDesiredDoseAmount(latest);
    final initialDoseUnit = _inferInitialDesiredDoseUnit(latest);
    final initialSyringe =
        (latest.volumePerDose != null && latest.volumePerDose! > 0)
        ? _inferSyringeSizeFromDoseVolumeMl(latest.volumePerDose!)
        : SyringeSizeMl.ml1;

    Future<void> setRecon({
      required double perMl,
      required double volumeMl,
      String? diluentName,
      double? calculatedUnits,
      required String label,
    }) async {
      selectedPerMl = perMl;
      selectedDiluentName = diluentName;
      selectedcalculatedUnits = calculatedUnits;
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
          initialVialSize: (double.tryParse(replaceVolumeCtrl.text) ?? 0) > 0
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
      calculatedUnits: result.calculatedUnits,
      label: label,
    );
  }

  Future<void> pickTopUpStrength(BuildContext dialogContext) async {
    final initialDoseAmount = _inferInitialDesiredDoseAmount(latest);
    final initialDoseUnit = _inferInitialDesiredDoseUnit(latest);
    final initialSyringe =
        (latest.volumePerDose != null && latest.volumePerDose! > 0)
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
        final previewNewPerMl =
            canPreviewTopUpConc &&
                currentVolume > 0 &&
                topUpAddVolume > 0 &&
                (currentVolume + topUpAddVolume) > 0
            ? ((currentPerMl * currentVolume) +
                      (effectiveTopUpPerMl * topUpAddVolume)) /
                  (currentVolume + topUpAddVolume)
            : null;

        String fmtPerMl(double? value) {
          if (value == null) return '(Not set)';
          return '${fmt2(value)} $unit/mL';
        }

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
                        'Concentration change',
                        style: helperTextStyle(
                          context,
                          color: cs.primary,
                        )?.copyWith(fontWeight: kFontWeightSemiBold),
                      ),
                      const SizedBox(height: kSpacingXS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Current', style: helperTextStyle(context)),
                          Text(
                            fmtPerMl(currentPerMl),
                            style: helperTextStyle(context),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('New', style: helperTextStyle(context)),
                          Text(
                            fmtPerMl(previewNewPerMl),
                            style: helperTextStyle(
                              context,
                              color: cs.primary,
                            )?.copyWith(fontWeight: kFontWeightSemiBold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: kSpacingS),
            ],
            if (selectedMode == 'replace') ...[
              const SizedBox(height: kSpacingXS),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kSpacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Concentration change',
                      style: helperTextStyle(
                        context,
                        color: cs.primary,
                      )?.copyWith(fontWeight: kFontWeightSemiBold),
                    ),
                    const SizedBox(height: kSpacingXS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current', style: helperTextStyle(context)),
                        Text(
                          fmtPerMl(currentPerMl),
                          style: helperTextStyle(context),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('New', style: helperTextStyle(context)),
                        Text(
                          fmtPerMl(selectedPerMl),
                          style: helperTextStyle(
                            context,
                            color: cs.primary,
                          )?.copyWith(fontWeight: kFontWeightSemiBold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                        'calculatedUnits': selectedcalculatedUnits,
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
      final newPerMl =
          (currentPerMl != null &&
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
        id: IdGen.newId(prefix: 'inv_vial'),
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
      showAppSnackBar(
        context,
        'Topped up vial - ${_formatNumber(newVolume)} mL$stockText',
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
    final calculatedUnits = result['calculatedUnits'] as double?;

    box.put(
      med.id,
      med.copyWith(
        containerVolumeMl: reconVolume,
        perMlValue: perMl,
        volumePerDose: calculatedUnits != null && calculatedUnits > 0
            ? (calculatedUnits / SyringeType.ml_1_0.unitsPerMl)
            : med.volumePerDose,
        diluentName: diluentName,
        activeVialVolume: reconVolume,
        reconstitutedAt: now,
        stockValue: newSealedCount,
      ),
    );

    final inventoryLog = InventoryLog(
      id: IdGen.newId(prefix: 'inv_vial'),
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
    showAppSnackBar(
      context,
      'Replaced vial - ${_formatNumber(reconVolume)} mL$stockText',
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
                padding: kInsetSectionPadding,
                decoration: buildInsetSectionDecoration(context: context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Sealed Vials:',
                      style: helperTextStyle(context),
                    ),
                    Text(
                      '$currentStock',
                      style: bodyTextStyle(
                        context,
                      )?.copyWith(fontWeight: kFontWeightBold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSpacingM),

              // Amount input
              Text(
                'Add vials:',
                style: bodyTextStyle(
                  context,
                )?.copyWith(fontWeight: kFontWeightMedium),
              ),
              const SizedBox(height: kSpacingS),
              Center(
                child: StepperRow36(
                  controller: controller,
                  fixedFieldWidth: kDialogStepperFieldWidth,
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
                padding: kInsetSectionPadding,
                decoration: buildInsetSectionDecoration(
                  context: context,
                  backgroundOpacity: 0.9,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Total:', style: helperTextStyle(context)),
                    Text(
                      '$previewTotal vials',
                      style: bodyTextStyle(context)?.copyWith(
                        fontWeight: kFontWeightBold,
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
      id: IdGen.newId(prefix: 'inv_restock'),
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

    showAppSnackBar(
      context,
      'Added ${result.toInt()} sealed vials (${newStock.toInt()} total)',
    );
  }
}

void _showAdHocDoseDialog(BuildContext context, Medication med) async {
  final now = DateTime.now();
  final isMdv = med.form == MedicationForm.multiDoseVial;
  final doseUnit = isMdv ? 'mL' : _stockUnitLabel(med.stockUnit);
  final defaultAmount = isMdv ? 0.5 : 1.0;

  final id = IdGen.newId(prefix: 'dose_adhoc');
  final draftLog = DoseLog(
    id: id,
    scheduleId: 'ad_hoc',
    scheduleName: 'Ad-hoc Dose',
    medicationId: med.id,
    medicationName: med.name,
    scheduledTime: now.toUtc(),
    actionTime: now,
    doseValue: defaultAmount,
    doseUnit: doseUnit,
    action: DoseAction.taken,
  );

  final dose = CalculatedDose(
    scheduleId: 'ad_hoc',
    scheduleName: 'Ad-hoc Dose',
    medicationName: med.name,
    scheduledTime: draftLog.scheduledTime,
    doseValue: defaultAmount,
    doseUnit: doseUnit,
    existingLog: draftLog,
  );

  await DoseActionSheet.show(
    context,
    dose: dose,
    initialStatus: DoseStatus.taken,
    onMarkTaken: (_) async {
      // Ad-hoc persistence is handled inside DoseActionSheet.
    },
    onSnooze: (_) async {
      // Not applicable for ad-hoc entries.
    },
    onSkip: (_) async {
      // Not applicable for ad-hoc entries.
    },
    onDelete: (_) async {
      final logBox = Hive.box<DoseLog>('dose_logs');
      final existing = logBox.get(draftLog.id);
      if (existing == null) return;

      if (existing.action == DoseAction.taken) {
        final medBox = Hive.box<Medication>('medications');
        final currentMed = medBox.get(existing.medicationId);
        if (currentMed != null) {
          final value = existing.actualDoseValue ?? existing.doseValue;
          final unit = existing.actualDoseUnit ?? existing.doseUnit;
          final delta = MedicationStockAdjustment.tryCalculateStockDelta(
            medication: currentMed,
            schedule: null,
            doseValue: value,
            doseUnit: unit,
            preferDoseValue: true,
          );
          if (delta != null && delta > 0) {
            final restored = MedicationStockAdjustment.restore(
              medication: currentMed,
              delta: delta,
            );
            await medBox.put(currentMed.id, restored);
            await LowStockNotifier.handleStockChange(
              before: currentMed,
              after: restored,
            );
          }
        }
      }

      await Hive.box<InventoryLog>('inventory_logs').delete(existing.id);
      await logBox.delete(existing.id);

      if (context.mounted) {
        showAppSnackBar(context, 'Ad-hoc dose deleted');
      }
    },
  );
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
          textCapitalization: kTextCapitalizationDefault,
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
  void Function(DateTime) onSave, {
  int defaultOffsetDays = kDefaultMedicationExpiryDays,
}) async {
  final picked = await SmartExpiryPicker.show(
    context,
    initialDate: initialDate ?? DateTime.now().add(Duration(days: defaultOffsetDays)),
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
            padding: const EdgeInsets.symmetric(vertical: kSpacingS),
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
  final defaultDays = switch (med.form) {
    MedicationForm.tablet || MedicationForm.capsule => kDefaultTabletCapsuleExpiryDays,
    MedicationForm.multiDoseVial ||
    MedicationForm.singleDoseVial ||
    MedicationForm.prefilledSyringe =>
      kDefaultInjectionExpiryDays,
  };
  _editDate(context, med, 'Expiry Date', med.expiry, (val) {
    final box = Hive.box<Medication>('medications');
    box.put(med.id, med.copyWith(expiry: val));
  }, defaultOffsetDays: defaultDays);
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
        style: helperTextStyle(
          context,
        )?.copyWith(color: color.withValues(alpha: 0.7)),
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
        style: medicationDetailStockForecastLabelTextStyle(
          context,
          color: color.withValues(alpha: 0.7),
        ),
        textAlign: TextAlign.right,
      ),
      const SizedBox(height: 2),
      Text(
        'Based on current schedule',
        style: medicationDetailStockForecastSubLabelTextStyle(
          context,
          color: color.withValues(alpha: 0.5),
        )?.copyWith(fontStyle: FontStyle.italic),
        textAlign: TextAlign.right,
      ),
      Text(
        'Expected to last until',
        style: medicationDetailStockForecastLabelTextStyle(
          context,
          color: color.withValues(alpha: 0.5),
        )?.copyWith(fontStyle: FontStyle.italic),
        textAlign: TextAlign.right,
      ),
      Text(
        dateStr,
        style: medicationDetailStockForecastDateTextStyle(
          context,
          color: color,
        ),
        textAlign: TextAlign.right,
      ),
      Text(
        '${daysRemaining.floor()} days',
        style: medicationDetailStockForecastDaysTextStyle(
          context,
          color: color.withValues(alpha: 0.9),
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
              style: medicationDetailStockForecastExpiryTextStyle(
                context,
                color: expiresBeforeStockout
                    ? Theme.of(context).colorScheme.errorContainer
                    : color.withValues(alpha: 0.7),
                emphasized: expiresBeforeStockout,
              ),
            ),
          ],
        ),
      ],
    ],
  );
}
