import 'dart:math';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WideCardSamplesPage extends StatelessWidget {
  const WideCardSamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ConceptGalleryView(
      title: 'Card Design Mockups',
      intro:
          'Exploratory concepts for future card refreshes. Toggle between wide canvases and compact tiles to compare tone, density, and visual systems.',
      conceptIndices: _standardConceptIndices,
    );
  }
}

class FinalCardDecisionsPage extends StatelessWidget {
  const FinalCardDecisionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final medicationsBox = Hive.box<Medication>('medications');
    final schedulesBox = Hive.box<Schedule>('schedules');
    final doseLogsBox = Hive.box<DoseLog>('dose_logs');

    return ValueListenableBuilder<Box<Medication>>(
      valueListenable: medicationsBox.listenable(),
      builder: (context, medBox, _) {
        final meds = medBox.values.toList(growable: false);
        return ValueListenableBuilder<Box<Schedule>>(
          valueListenable: schedulesBox.listenable(),
          builder: (context, scheduleBox, __) {
            final schedules = scheduleBox.values.toList(growable: false);
            return ValueListenableBuilder<Box<DoseLog>>(
              valueListenable: doseLogsBox.listenable(),
              builder: (context, doseBox, ___) {
                final doses = doseBox.values.toList(growable: false);
                final conceptData = _buildConceptContexts(
                  count: _finalConceptIndices.length,
                  meds: meds,
                  schedules: schedules,
                  doses: doses,
                );
                return _ConceptGalleryView(
                  title: 'Final Card Decisions',
                  intro:
                      'These concepts are locked for the upcoming release. Any tweaks should originate here before propagating elsewhere.',
                  conceptIndices: _finalConceptIndices,
                  layoutLabelBuilder: (layout) => layout == _SampleLayout.list
                      ? 'List production candidates'
                      : layout == _SampleLayout.wide
                      ? 'Wide production candidates'
                      : 'Compact production candidates',
                  conceptData: conceptData,
                );
              },
            );
          },
        );
      },
    );
  }
}

enum _SampleLayout { wide, compact, list }

class _ConceptContext {
  const _ConceptContext({
    required this.medication,
    this.schedule,
    this.doseLog,
  });

  final Medication medication;
  final Schedule? schedule;
  final DoseLog? doseLog;
}

class _ConceptGalleryView extends StatefulWidget {
  const _ConceptGalleryView({
    required this.title,
    required this.conceptIndices,
    this.intro,
    this.layoutLabelBuilder,
    this.conceptData,
  });

  final String title;
  final List<int> conceptIndices;
  final String? intro;
  final String Function(_SampleLayout layout)? layoutLabelBuilder;
  final List<_ConceptContext>? conceptData;

  @override
  State<_ConceptGalleryView> createState() => _ConceptGalleryViewState();
}

class _ConceptGalleryViewState extends State<_ConceptGalleryView> {
  _SampleLayout _layout = _SampleLayout.wide;

  void _cycleLayout() {
    setState(() {
      final layouts = _SampleLayout.values;
      final current = layouts.indexOf(_layout);
      _layout = layouts[(current + 1) % layouts.length];
    });
  }

  void _setLayout(_SampleLayout layout) {
    if (layout == _layout) return;
    setState(() => _layout = layout);
  }

  IconData _layoutIcon(_SampleLayout layout) {
    return layout == _SampleLayout.wide
        ? Icons.view_agenda_outlined
        : layout == _SampleLayout.compact
        ? Icons.grid_view_rounded
        : Icons.view_list_rounded;
  }

  String _layoutLabel(_SampleLayout layout) {
    if (widget.layoutLabelBuilder != null) {
      return widget.layoutLabelBuilder!(layout);
    }
    switch (layout) {
      case _SampleLayout.wide:
        return 'Wide concept canvases';
      case _SampleLayout.compact:
        return 'Compact composition tiles';
      case _SampleLayout.list:
        return 'List view experiments';
    }
  }

  _ConceptContext _contextForIndex(int index, int conceptIndex) {
    final contextualData = widget.conceptData;
    if (contextualData != null && index < contextualData.length) {
      return contextualData[index];
    }
    final med = _sampleMedications[conceptIndex % _sampleMedications.length];
    return _ConceptContext(medication: med);
  }

  @override
  Widget build(BuildContext context) {
    final layout = _layout;
    final theme = Theme.of(context);
    final conceptIndices = widget.conceptIndices;
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.title,
        forceBackButton: true,
        actions: [
          IconButton(
            tooltip: 'Toggle layout',
            icon: Icon(_layoutIcon(layout)),
            onPressed: _cycleLayout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.intro != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kCardPadding * 1.5,
                kCardPadding,
                kCardPadding * 1.5,
                kFieldSpacing,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.intro!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kCardPadding * 1.5,
              0,
              kCardPadding * 1.5,
              kFieldSpacing,
            ),
            child: Row(
              children: [
                Icon(_layoutIcon(layout), color: theme.colorScheme.primary),
                const SizedBox(width: kLabelFieldGap),
                Expanded(
                  child: Text(
                    _layoutLabel(layout),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: kFontWeightSemiBold,
                    ),
                  ),
                ),
                SegmentedButton<_SampleLayout>(
                  segments: const [
                    ButtonSegment(
                      value: _SampleLayout.wide,
                      label: Text('Wide'),
                      icon: Icon(Icons.view_agenda_outlined),
                    ),
                    ButtonSegment(
                      value: _SampleLayout.compact,
                      label: Text('Compact'),
                      icon: Icon(Icons.grid_view_rounded),
                    ),
                    ButtonSegment(
                      value: _SampleLayout.list,
                      label: Text('List'),
                      icon: Icon(Icons.view_list_rounded),
                    ),
                  ],
                  showSelectedIcon: false,
                  selected: <_SampleLayout>{layout},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      _setLayout(selection.first);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: kAnimationFast,
              switchInCurve: kCurveEmphasized,
              switchOutCurve: kCurveDefault,
              child: ListView.separated(
                key: ValueKey('${widget.title}_${layout.name}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: kCardPadding * 1.5,
                  vertical: kCardPadding,
                ),
                itemBuilder: (context, index) {
                  final conceptIndex = conceptIndices[index];
                  final contextData = _contextForIndex(index, conceptIndex);
                  return _SampleCard(
                    title: 'Concept ${conceptIndex + 1}'.padLeft(2, '0'),
                    description: _conceptDescriptions[conceptIndex],
                    child: layout == _SampleLayout.wide
                        ? _buildWideCardVariant(conceptIndex, contextData)
                        : layout == _SampleLayout.compact
                        ? _buildCompactCardVariant(conceptIndex, contextData)
                        : _buildListCardVariant(conceptIndex, contextData),
                  );
                },
                separatorBuilder: (_, __) =>
                    const SizedBox(height: kFieldGroupSpacing * 2),
                itemCount: conceptIndices.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: kFieldSpacing / 2),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: kFieldGroupSpacing),
        child,
      ],
    );
  }
}

Widget _buildWideCardVariant(int index, _ConceptContext context) {
  final med = context.medication;
  switch (index) {
    case 0:
      return _ConceptCardNova(med: med);
    case 1:
      return _ConceptCardWave(med: med);
    case 2:
      return _ConceptCardPassport(med: med);
    case 3:
      return _ConceptCardNotebook(med: med);
    case 4:
      return _ConceptCardTicker(
        med: med,
        schedule: context.schedule,
        doseLog: context.doseLog,
      );
    case 5:
      return _ConceptCardPulse(
        med: med,
        schedule: context.schedule,
        doseLog: context.doseLog,
      );
    case 6:
      return _ConceptCardDuplex(med: med);
    case 7:
      return _ConceptCardBadgeGrid(med: med);
    case 8:
      return _ConceptCardFocus(
        med: med,
        schedule: context.schedule,
        doseLog: context.doseLog,
      );
    case 9:
      return _ConceptCardHalo(
        med: med,
        schedule: context.schedule,
        doseLog: context.doseLog,
      );
    default:
      return const SizedBox.shrink();
  }
}

Widget _buildCompactCardVariant(int index, _ConceptContext context) {
  final builder = _compactCardBuilders[index % _compactCardBuilders.length];
  return builder(context);
}

Widget _buildListCardVariant(int index, _ConceptContext context) {
  final builder = _listCardBuilders[index % _listCardBuilders.length];
  return builder(context);
}

final _compactCardBuilders = <Widget Function(_ConceptContext)>[
  (context) => _CompactCardVitals(med: context.medication),
  (context) => _CompactCardInventory(med: context.medication),
  (context) => _CompactCardTimeline(med: context.medication),
  (context) => _CompactCardChecklist(med: context.medication),
  (context) => _CompactCardReminder(med: context.medication),
  (context) => _CompactCardTherapy(med: context.medication),
  (context) => _CompactCardStatus(med: context.medication),
  (context) => _CompactCardQuickActions(med: context.medication),
  (context) => _CompactCardSignal(med: context.medication),
  (context) => _CompactCardGlass(med: context.medication),
];

final _listCardBuilders = <Widget Function(_ConceptContext)>[
  (concept) => _ListCardInventoryPulse(concept: concept),
  (concept) => _ListCardScheduleLine(concept: concept),
  (concept) => _ListCardDoseStatus(concept: concept),
  (concept) => _ListCardQuickAction(concept: concept),
  (concept) => _ListCardTemperature(concept: concept),
  (concept) => _ListCardTimeline(concept: concept),
  (concept) => _ListCardMinimalStats(concept: concept),
  (concept) => _ListCardReorder(concept: concept),
  (concept) => _ListCardNextDose(concept: concept),
  (concept) => _ListCardChecklist(concept: concept),
];

const _conceptDescriptions = [
  'Aurora gradient hero with orbiting dosage orbit and stock arc.',
  'Sparkline waveform card broadcasting adherence cadence.',
  'Passport-style layout with vertical color band and travel tone.',
  'Notebook sketch feel with lined paper and sticky priorities.',
  'Digital ticker showcasing countdown digits and milestones.',
  'Dark pulse card with luminous core reminder and CTA.',
  'Split duplex comparing therapy plan versus logistics.',
  'Badge grid of regimen vitals and quick semantic tiles.',
  'Focus card with supportive copy and decisive CTA.',
  'Glass halo panel with floating segmented gauge.',
];

const _finalConceptIndices = [4, 5, 8, 9];

final _standardConceptIndices = List<int>.unmodifiable(
  List<int>.generate(
    _conceptDescriptions.length,
    (index) => index,
  ).where((index) => !_finalConceptIndices.contains(index)).toList(),
);

final _sampleMedications = <Medication>[
  Medication(
    id: 'med01',
    name: 'Sample MDV A',
    form: MedicationForm.multiDoseVial,
    strengthValue: 2.4,
    strengthUnit: Unit.mg,
    stockValue: 6,
    stockUnit: StockUnit.multiDoseVials,
    initialStockValue: 10,
    requiresRefrigeration: true,
    expiry: DateTime(2026, 1, 15),
    createdAt: DateTime(2024, 1, 20),
  ),
  Medication(
    id: 'med02',
    name: 'Sample Tablet A',
    form: MedicationForm.tablet,
    strengthValue: 125,
    strengthUnit: Unit.mcg,
    stockValue: 42,
    stockUnit: StockUnit.tablets,
    initialStockValue: 90,
    expiry: DateTime(2025, 11, 4),
    createdAt: DateTime(2023, 12, 1),
  ),
  Medication(
    id: 'med03',
    name: 'Sample Capsule A',
    form: MedicationForm.capsule,
    strengthValue: 5000,
    strengthUnit: Unit.units,
    stockValue: 28,
    stockUnit: StockUnit.capsules,
    initialStockValue: 60,
    expiry: DateTime(2026, 3, 1),
    createdAt: DateTime(2024, 2, 14),
  ),
  Medication(
    id: 'med04',
    name: 'Sample Syringe A',
    form: MedicationForm.prefilledSyringe,
    strengthValue: 1.5,
    strengthUnit: Unit.mg,
    stockValue: 3,
    stockUnit: StockUnit.preFilledSyringes,
    initialStockValue: 4,
    requiresRefrigeration: true,
    expiry: DateTime(2025, 7, 1),
    createdAt: DateTime(2024, 5, 6),
  ),
  Medication(
    id: 'med05',
    name: 'Sample Vial A',
    form: MedicationForm.singleDoseVial,
    strengthValue: 5,
    strengthUnit: Unit.mg,
    stockValue: 9,
    stockUnit: StockUnit.singleDoseVials,
    initialStockValue: 12,
    requiresRefrigeration: true,
    expiry: DateTime(2026, 5, 28),
    createdAt: DateTime(2024, 8, 12),
  ),
  Medication(
    id: 'med06',
    name: 'Sample Tablet B',
    form: MedicationForm.tablet,
    strengthValue: 25,
    strengthUnit: Unit.mg,
    stockValue: 16,
    stockUnit: StockUnit.tablets,
    initialStockValue: 30,
    expiry: DateTime(2025, 9, 2),
    createdAt: DateTime(2024, 3, 20),
  ),
  Medication(
    id: 'med07',
    name: 'Sample Capsule B',
    form: MedicationForm.capsule,
    strengthValue: 400,
    strengthUnit: Unit.mg,
    stockValue: 10,
    stockUnit: StockUnit.capsules,
    initialStockValue: 30,
    expiry: DateTime(2025, 6, 12),
    createdAt: DateTime(2024, 6, 10),
  ),
  Medication(
    id: 'med08',
    name: 'Sample Injection A',
    form: MedicationForm.multiDoseVial,
    strengthValue: 30,
    strengthUnit: Unit.units,
    stockValue: 40,
    stockUnit: StockUnit.multiDoseVials,
    initialStockValue: 60,
    expiry: DateTime(2026, 9, 12),
    createdAt: DateTime(2024, 4, 9),
  ),
  Medication(
    id: 'med09',
    name: 'Sample Capsule C',
    form: MedicationForm.capsule,
    strengthValue: 200,
    strengthUnit: Unit.mg,
    stockValue: 18,
    stockUnit: StockUnit.capsules,
    initialStockValue: 30,
    expiry: DateTime(2025, 12, 23),
    createdAt: DateTime(2024, 7, 22),
  ),
  Medication(
    id: 'med10',
    name: 'Sample Tablet C',
    form: MedicationForm.tablet,
    strengthValue: 50,
    strengthUnit: Unit.mg,
    stockValue: 25,
    stockUnit: StockUnit.tablets,
    initialStockValue: 90,
    expiry: DateTime(2025, 12, 15),
    createdAt: DateTime(2024, 3, 15),
  ),
];

class _ConceptCardNova extends StatelessWidget {
  const _ConceptCardNova({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = med.initialStockValue ?? med.stockValue;
    final ratio = total > 0 ? (med.stockValue / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(kCardPadding * 1.2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: kFieldSpacing / 3),
                    Text(
                      'Cadence oversight • inventory',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _PillChip(
                label: med.requiresRefrigeration ? '2-8°C' : 'Room temp',
                tone: _PillChipTone.vibrant,
              ),
            ],
          ),
          const SizedBox(height: kFieldSpacing * 1.4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _strengthLabel(med),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: kFieldSpacing / 2),
                    Text(
                      'Every Monday & Thursday',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ArcPainter(
                          progress: ratio,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: .08,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(ratio * 100).round()}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text('stocked', style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: kFieldSpacing * 1.4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Protocol'),
                ),
              ),
              const SizedBox(width: kFieldSpacing),
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Log dose'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConceptCardWave extends StatelessWidget {
  const _ConceptCardWave({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = med.initialStockValue ?? med.stockValue;
    final ratio = total > 0 ? (med.stockValue / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(kCardPadding * 1.2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: .1),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: kFieldSpacing / 3),
                    Text(
                      _strengthLabel(med),
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              _PillChip(
                label: med.requiresRefrigeration
                    ? 'Cold-chain'
                    : 'Shelf stable',
                tone: _PillChipTone.soft,
              ),
            ],
          ),
          const SizedBox(height: kFieldGroupSpacing),
          SizedBox(
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kBorderRadiusMedium),
              child: CustomPaint(
                painter: _WavePainter(
                  progress: ratio,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: kFieldSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${med.stockValue} vials',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${(ratio * 100).round()}% filled',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConceptCardPassport extends StatelessWidget {
  const _ConceptCardPassport({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final stamps = [
      med.requiresRefrigeration ? 'Cold-chain cleared' : 'Ambient cleared',
      'Batch QA-204',
      'Expires ${_formatDate(med.expiry)}',
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
          ),
          const SizedBox(width: kFieldSpacing),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(kCardPadding * 1.2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: .9),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: .06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.public, color: accent),
                      const SizedBox(width: kLabelFieldGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: .4,
                              ),
                            ),
                            Text(
                              _formLabel(med.form),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _PillChip(
                        tone: _PillChipTone.vibrant,
                        label: med.stockValue > 20 ? 'Travel ready' : 'Reorder',
                      ),
                    ],
                  ),
                  const SizedBox(height: kFieldSpacing),
                  Divider(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: .4,
                    ),
                  ),
                  const SizedBox(height: kFieldSpacing),
                  Wrap(
                    spacing: kFieldSpacing,
                    runSpacing: kFieldSpacing,
                    children: [
                      for (final stamp in stamps)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kFieldSpacing,
                            vertical: kFieldSpacing / 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              kBorderRadiusMedium,
                            ),
                            border: Border.all(
                              color: accent.withValues(alpha: .5),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            stamp,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: kFieldGroupSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Issued ${_formatDate(med.expiry?.subtract(const Duration(days: 180)))}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        'Stock ${med.stockValue}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptCardNotebook extends StatelessWidget {
  const _ConceptCardNotebook({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget line(String label, String detail, {bool highlight = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: kFieldSpacing / 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .25),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              highlight ? Icons.check_circle : Icons.radio_button_unchecked,
              size: kIconSizeSmall,
              color: highlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: kLabelFieldGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    detail,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: kCardBorderOpacity,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NotebookLinesPainter(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          Positioned(
            left: 48,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: theme.colorScheme.primary.withValues(alpha: .25),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kCardPadding * 1.3,
              vertical: kCardPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        med.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.push_pin_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: kFieldSpacing / 2),
                Text(
                  'Clinic notes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: kFieldSpacing),
                Expanded(
                  child: Column(
                    children: [
                      line(
                        'Mix 0.9% saline first',
                        'Ready by 08:00',
                        highlight: true,
                      ),
                      line('Dose at 14:00', 'Document vitals before push'),
                      line(
                        'Inventory check',
                        '${med.stockValue} vials recorded',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptCardTicker extends StatelessWidget {
  const _ConceptCardTicker({required this.med, this.schedule, this.doseLog});

  final Medication med;
  final Schedule? schedule;
  final DoseLog? doseLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = this.schedule;
    final dose = doseLog;

    Widget segment(String label, String value, {String? helper}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: kFieldSpacing / 2,
                horizontal: kFieldSpacing,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(kBorderRadiusMedium),
              ),
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (helper != null) ...[
              const SizedBox(height: 4),
              Text(
                helper,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(kCardPadding * 1.2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: kCardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  med.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _PillChip(tone: _PillChipTone.soft, label: 'Ticker feed'),
            ],
          ),
          const SizedBox(height: kFieldSpacing),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kCardPadding,
              vertical: kFieldSpacing,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(kBorderRadiusMedium),
            ),
            child: Row(
              children: [
                segment(
                  'Next dose',
                  _scheduleTimeLabel(context, schedule),
                  helper: _scheduleDoseLabel(schedule),
                ),
                const SizedBox(width: kFieldSpacing),
                segment(
                  'Stock',
                  med.stockValue.toStringAsFixed(0),
                  helper:
                      'Goal ${(med.initialStockValue ?? med.stockValue).toStringAsFixed(0)}',
                ),
                const SizedBox(width: kFieldSpacing),
                segment(
                  'Last log',
                  _doseActionLabel(dose?.action),
                  helper: dose == null
                      ? 'No entry'
                      : _formatRelativeTime(dose.actionTime.toLocal()),
                ),
              ],
            ),
          ),
          const SizedBox(height: kFieldSpacing),
          Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: kLabelFieldGap),
              Expanded(
                child: Text(
                  schedule == null
                      ? 'Link a schedule to stream adherence updates.'
                      : 'Feed streaming from ${schedule.name} — ${_scheduleDaysLabel(schedule)}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConceptCardPulse extends StatelessWidget {
  const _ConceptCardPulse({required this.med, this.schedule, this.doseLog});

  final Medication med;
  final Schedule? schedule;
  final DoseLog? doseLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = med.initialStockValue ?? med.stockValue;
    final ratio = total > 0 ? (med.stockValue / total).clamp(0.0, 1.0) : 0.0;
    final schedule = this.schedule;
    final dose = doseLog;
    final cadence = schedule == null
        ? 'No schedule linked'
        : '${schedule.name} · ${_scheduleDaysLabel(schedule)}';

    return Container(
      padding: const EdgeInsets.all(kCardPadding * 1.4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.primary.withValues(alpha: .15),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(kBorderRadiusLarge * 1.1),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: kCardBorderOpacity,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: kFieldSpacing / 2),
                Text(
                  'Pulse reminder',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: kFieldSpacing),
                Text(
                  'Next dose ${_scheduleTimeLabel(context, schedule)} — $cadence.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: kFieldSpacing / 2),
                Text(
                  'Last log: ${_doseLogSummary(dose)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: kFieldGroupSpacing),
                FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('Log dose'),
                ),
              ],
            ),
          ),
          const SizedBox(width: kFieldGroupSpacing),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ArcPainter(
                      progress: ratio,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: .15),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: .25),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: theme.colorScheme.primary),
                    Text(
                      '${(ratio * 100).round()}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('stock stable', style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptCardDuplex extends StatelessWidget {
  const _ConceptCardDuplex({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = med.initialStockValue ?? med.stockValue;
    final ratio = total > 0 ? (med.stockValue / total).clamp(0.0, 1.0) : 0.0;

    Widget pane(String title, List<Widget> children) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kBorderRadiusMedium),
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(
                alpha: kCardBorderOpacity,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: kFieldSpacing / 2),
              ...children,
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            med.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: kFieldSpacing),
          Row(
            children: [
              pane('Therapy plan', [
                Text(
                  _strengthLabel(med),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kFieldSpacing / 2),
                Text(
                  'Infuse Monday & Thursday',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: kFieldSpacing),
                _MiniVerticalMeter(
                  label: 'Week',
                  value: .6,
                  color: theme.colorScheme.primary,
                ),
              ]),
              const SizedBox(width: kFieldSpacing),
              pane('Logistics', [
                Text(
                  '${med.stockValue}/${med.initialStockValue ?? med.stockValue} vials',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kFieldSpacing / 2),
                Text(
                  'Lead time 5 days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: kFieldSpacing),
                SizedBox(width: 90, child: _StockProgressBar(value: ratio)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConceptCardBadgeGrid extends StatelessWidget {
  const _ConceptCardBadgeGrid({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeData = [
      {'icon': Icons.schedule, 'label': 'Next dose 14:00'},
      {
        'icon': Icons.inventory_2_outlined,
        'label': '${med.stockValue} stocked',
      },
      {
        'icon': Icons.ac_unit,
        'label': med.requiresRefrigeration ? 'Cold-chain' : 'Shelf',
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Expires ${_formatDate(med.expiry)}',
      },
      {'icon': Icons.local_pharmacy, 'label': _formLabel(med.form)},
      {'icon': Icons.check_circle, 'label': 'QA clearance'},
    ];

    Widget badge(Map<String, Object> data) {
      final icon = data['icon'] as IconData;
      final label = data['label'] as String;
      return Container(
        width: 150,
        padding: const EdgeInsets.all(kFieldSpacing),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(kBorderRadiusMedium),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: kCardBorderOpacity,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: kFieldSpacing / 2),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(kCardPadding * 1.2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  med.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.grid_view_rounded),
              ),
            ],
          ),
          const SizedBox(height: kFieldSpacing),
          Wrap(
            spacing: kFieldSpacing,
            runSpacing: kFieldSpacing,
            children: [for (final entry in badgeData) badge(entry)],
          ),
        ],
      ),
    );
  }
}

class _ConceptCardFocus extends StatelessWidget {
  const _ConceptCardFocus({required this.med, this.schedule, this.doseLog});

  final Medication med;
  final Schedule? schedule;
  final DoseLog? doseLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = this.schedule;
    final dose = doseLog;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kCardPadding * 1.4,
        vertical: kCardPadding * 1.6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge * 1.1),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: kCardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: kFieldSpacing / 2),
          Text(
            med.name,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: kFieldSpacing),
          Text(_strengthLabel(med), style: theme.textTheme.titleMedium),
          Text(
            schedule == null
                ? 'No schedule linked'
                : '${schedule.name} · ${_scheduleDoseLabel(schedule)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: kFieldGroupSpacing),
          Text(
            'Protect this run — inventory locks at ${med.stockValue} units. ${_doseLogSummary(dose)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: kFieldGroupSpacing),
          FilledButton(onPressed: () {}, child: const Text('Record infusion')),
        ],
      ),
    );
  }
}

class _ConceptCardHalo extends StatelessWidget {
  const _ConceptCardHalo({required this.med, this.schedule, this.doseLog});

  final Medication med;
  final Schedule? schedule;
  final DoseLog? doseLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = med.initialStockValue ?? med.stockValue;
    final ratio = total > 0 ? (med.stockValue / total).clamp(0.0, 1.0) : 0.0;
    final schedule = this.schedule;
    final dose = doseLog;

    return Container(
      padding: const EdgeInsets.all(kCardPadding * 1.4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.primary.withValues(alpha: .08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kBorderRadiusLarge * 1.1),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: kCardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: kFieldSpacing / 2),
                    Text(
                      'Halo monitor',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _PillChip(tone: _PillChipTone.soft, label: 'Glass gauge'),
            ],
          ),
          const SizedBox(height: kFieldGroupSpacing),
          SizedBox(
            height: 56,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                final height = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 56.0;
                return SizedBox(
                  width: width,
                  height: height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                    child: CustomPaint(
                      painter: _WavePainter(
                        progress: ratio,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: kFieldSpacing),
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: .15),
                          theme.colorScheme.surface.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: _SegmentedRingPainter(
                      progress: ratio,
                      baseColor: theme.colorScheme.outlineVariant.withValues(
                        alpha: .2,
                      ),
                      primary: theme.colorScheme.primary,
                      warning: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${med.stockValue}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('units ready', style: theme.textTheme.labelLarge),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: kFieldSpacing),
          Row(
            children: [
              Icon(Icons.timelapse, color: theme.colorScheme.primary),
              const SizedBox(width: kLabelFieldGap),
              Expanded(
                child: Text(
                  schedule == null
                      ? 'Link a schedule to enable Halo notifications.'
                      : 'Next ${schedule.name} at ${_scheduleTimeLabel(context, schedule)} · ${_doseLogSummary(dose)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactCardVitals extends StatelessWidget {
  const _CompactCardVitals({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: .08),
                  cs.primary.withValues(alpha: .2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(Icons.scatter_plot, color: cs.primary),
          ),
          const SizedBox(width: kFieldSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _strengthLabel(med),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: kFieldSpacing,
                  runSpacing: kFieldSpacing / 2,
                  children: [
                    _PillChip(
                      label: med.requiresRefrigeration
                          ? 'Cold-chain'
                          : 'Ambient',
                      tone: _PillChipTone.soft,
                    ),
                    _PillChip(
                      label: '${med.stockValue} stocked',
                      tone: _PillChipTone.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: kFieldSpacing),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Exp',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                _formatDate(med.expiry),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactCardInventory extends StatelessWidget {
  const _CompactCardInventory({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = med.initialStockValue ?? med.stockValue;
    final ratio = total > 0 ? (med.stockValue / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            med.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inventory monitoring',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: ratio,
              backgroundColor: cs.outlineVariant.withValues(alpha: .2),
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${med.stockValue} remaining',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(ratio * 100).round()}% stocked',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lead time 5 days · review buffer weekly',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCardTimeline extends StatelessWidget {
  const _CompactCardTimeline({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final timeline = <Map<String, String>>[
      {'label': 'Prep', 'detail': 'Mix at 08:00'},
      {'label': 'Dose', 'detail': 'Push at 14:00'},
      {'label': 'Log', 'detail': 'Vitals due 10m post'},
    ];

    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            med.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kFieldSpacing),
          for (var i = 0; i < timeline.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: kLabelFieldGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeline[i]['label']!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeline[i]['detail']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i < timeline.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(color: cs.outlineVariant.withValues(alpha: .3)),
              ),
          ],
        ],
      ),
    );
  }
}

class _CompactCardChecklist extends StatelessWidget {
  const _CompactCardChecklist({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget item(String label, {required bool complete}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              complete ? Icons.check_circle : Icons.circle_outlined,
              size: kIconSizeSmall,
              color: complete ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: kLabelFieldGap),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: complete ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${med.name} checklist',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          item('Fridge logged at 4°C', complete: med.requiresRefrigeration),
          item('Batch QA cleared', complete: true),
          item('Stock recount scheduled', complete: false),
        ],
      ),
    );
  }
}

class _CompactCardReminder extends StatelessWidget {
  const _CompactCardReminder({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(kFieldSpacing),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              color: cs.primary.withValues(alpha: .12),
            ),
            child: Icon(Icons.alarm, color: cs.primary),
          ),
          const SizedBox(width: kFieldSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Log ${med.name} dose before 14:00.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Vitals capture follows immediately.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: kFieldSpacing),
          FilledButton.tonal(
            onPressed: () {},
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }
}

class _CompactCardTherapy extends StatelessWidget {
  const _CompactCardTherapy({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        color: cs.surface,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Therapy cadence',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  _strengthLabel(med),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Mon & Thu · 6 week cycle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: kFieldSpacing),
          Container(
            padding: const EdgeInsets.all(kFieldSpacing),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kBorderRadiusMedium),
              color: cs.surfaceContainerHighest,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reorder',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Buffer 30%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('Lead time 5d', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCardStatus extends StatelessWidget {
  const _CompactCardStatus({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final expirySoon =
        med.expiry != null &&
        med.expiry!.isBefore(DateTime.now().add(const Duration(days: 45)));

    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Expires ${_formatDate(med.expiry)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: expirySoon ? cs.error : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stock ${med.stockValue} · goal ${med.initialStockValue ?? med.stockValue}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                expirySoon ? 'Action' : 'Status',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                expirySoon ? 'Review' : 'Stable',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: expirySoon ? cs.error : cs.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactCardQuickActions extends StatelessWidget {
  const _CompactCardQuickActions({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            med.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: kFieldSpacing,
            runSpacing: kFieldSpacing,
            children: [
              OutlinedButton(onPressed: () {}, child: const Text('Protocol')),
              FilledButton.tonal(
                onPressed: () {},
                child: const Text('Log dose'),
              ),
              TextButton(onPressed: () {}, child: const Text('Notes')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactCardSignal extends StatelessWidget {
  const _CompactCardSignal({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = med.initialStockValue ?? med.stockValue;
    final ratio = total > 0 ? (med.stockValue / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        gradient: LinearGradient(
          colors: [cs.surface, cs.primary.withValues(alpha: .06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation(
                    cs.outlineVariant.withValues(alpha: .2),
                  ),
                ),
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                ),
                Center(
                  child: Text(
                    '${(ratio * 100).round()}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: kFieldSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signal',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  med.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Notify under 30% buffer.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCardGlass extends StatelessWidget {
  const _CompactCardGlass({required this.med});

  final Medication med;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        gradient: LinearGradient(
          colors: [
            cs.surface.withValues(alpha: .9),
            cs.primary.withValues(alpha: .08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: kCardBorderOpacity),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Glass halo',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            med.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: kFieldSpacing),
          Text(
            '${med.stockValue} units ready · ${_strengthLabel(med)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: kFieldSpacing),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Halo watches the buffer and pings supply under 30%.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: kFieldSpacing),
              FilledButton(onPressed: () {}, child: const Text('Focus')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListCardInventoryPulse extends StatelessWidget {
  const _ListCardInventoryPulse({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final med = concept.medication;
    final schedule = concept.schedule;
    final cs = Theme.of(context).colorScheme;
    final total = med.initialStockValue ?? med.stockValue;
    final ratio = total > 0 ? (med.stockValue / total).clamp(0.0, 1.0) : 0.0;

    return _ListBlock(
      title: 'Inventory signal',
      caption: 'Live buffers',
      rows: [
        _ListRowSpec(
          leadingIcon: Icons.medication_liquid,
          leadingColor: cs.primary,
          title: med.name,
          subtitle:
              '${_scheduleDoseLabel(schedule)} · ${_scheduleDaysLabel(schedule)}',
          trailingWidget: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ),
        _ListRowSpec(
          leadingIcon: Icons.inventory_2_outlined,
          leadingColor: cs.tertiary,
          title: '${med.stockValue.toStringAsFixed(0)} units on hand',
          subtitle: '${(ratio * 100).round()}% stocked',
          trailingLabel: _scheduleTimeLabel(context, schedule),
          footer: ClipRRect(
            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: ratio,
              backgroundColor: cs.outlineVariant.withValues(alpha: .2),
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          forceDivider: false,
        ),
      ],
    );
  }
}

class _ListCardScheduleLine extends StatelessWidget {
  const _ListCardScheduleLine({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final schedule = concept.schedule;
    final med = concept.medication;
    final cs = Theme.of(context).colorScheme;
    return _ListBlock(
      title: '${med.name} cadence',
      rows: [
        _ListRowSpec(
          leadingIcon: Icons.schedule,
          leadingColor: cs.primary,
          title: _scheduleTimeLabel(context, schedule),
          subtitle: _scheduleDaysLabel(schedule),
          trailingLabel: schedule?.name ?? 'Routine',
          emphasis: true,
        ),
        _ListRowSpec(
          leadingIcon: Icons.medication_outlined,
          leadingColor: cs.tertiary,
          title: _scheduleDoseLabel(schedule),
          subtitle: '${med.stockValue.toStringAsFixed(0)} units staged',
          forceDivider: false,
        ),
      ],
    );
  }
}

class _ListCardDoseStatus extends StatelessWidget {
  const _ListCardDoseStatus({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final med = concept.medication;
    final dose = concept.doseLog;
    final schedule = concept.schedule;
    final cs = Theme.of(context).colorScheme;
    return _ListBlock(
      title: 'Dose status',
      rows: [
        _ListRowSpec(
          leadingIcon: Icons.task_alt,
          leadingColor: cs.primary,
          title: _doseLogSummary(dose),
          subtitle: '${med.name} · ${_scheduleDoseLabel(schedule)}',
          trailingWidget: _PillChip(
            label: _doseActionLabel(dose?.action),
            tone: dose?.action == DoseAction.taken
                ? _PillChipTone.vibrant
                : _PillChipTone.soft,
          ),
          forceDivider: false,
        ),
      ],
    );
  }
}

class _ListCardQuickAction extends StatelessWidget {
  const _ListCardQuickAction({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final med = concept.medication;
    final dose = concept.doseLog;
    final cs = Theme.of(context).colorScheme;
    return _ListBlock(
      title: 'Quick actions',
      rows: [
        _ListRowSpec(
          leadingIcon: Icons.flash_on,
          leadingColor: cs.primary,
          title: 'Log ${med.name}',
          subtitle: _doseLogSummary(dose),
          trailingWidget: FilledButton.tonal(
            onPressed: () {},
            child: const Text('Log now'),
          ),
          forceDivider: false,
        ),
      ],
    );
  }
}

class _ListCardTemperature extends StatelessWidget {
  const _ListCardTemperature({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final med = concept.medication;
    final cs = Theme.of(context).colorScheme;
    final isColdChain = med.requiresRefrigeration;
    return _ListBlock(
      title: 'Storage',
      rows: [
        _ListRowSpec(
          leadingIcon: isColdChain ? Icons.ac_unit : Icons.wb_sunny_outlined,
          leadingColor: cs.primary,
          title: isColdChain ? 'Cold-chain' : 'Shelf stable',
          subtitle: isColdChain
              ? 'Hold 2-8°C · log fridge daily'
              : 'Store room temp · away from light',
          trailingLabel: isColdChain
              ? '2–8°C'
              : '${med.stockValue.toStringAsFixed(0)} on hand',
          forceDivider: false,
        ),
      ],
    );
  }
}

class _ListCardTimeline extends StatelessWidget {
  const _ListCardTimeline({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final schedule = concept.schedule;
    final steps = <Map<String, String>>[
      {
        'label': 'Prep',
        'detail': 'Ready ${_scheduleTimeLabel(context, schedule)}',
      },
      {'label': 'Dose', 'detail': _scheduleDoseLabel(schedule)},
      {'label': 'Review', 'detail': _doseLogSummary(concept.doseLog)},
    ];
    return _ListBlock(
      title: '${concept.medication.name} timeline',
      rows: [
        for (var i = 0; i < steps.length; i++)
          _ListRowSpec(
            leadingWidget: CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary.withValues(alpha: .1),
              child: Text(
                '${i + 1}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: steps[i]['label']!,
            subtitle: steps[i]['detail']!,
            forceDivider: i < steps.length - 1,
          ),
      ],
    );
  }
}

class _ListCardMinimalStats extends StatelessWidget {
  const _ListCardMinimalStats({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final med = concept.medication;
    final schedule = concept.schedule;
    final cs = Theme.of(context).colorScheme;
    return _ListBlock(
      title: '${med.name} snapshot',
      rows: [
        _ListRowSpec(
          leadingIcon: Icons.inventory_2_outlined,
          leadingColor: cs.primary,
          title: '${med.stockValue.toStringAsFixed(0)} stocked',
          subtitle: 'Baseline ${_strengthLabel(med)}',
        ),
        _ListRowSpec(
          leadingIcon: Icons.straighten,
          leadingColor: cs.tertiary,
          title: _scheduleDoseLabel(schedule),
          subtitle: 'Per administration',
        ),
        _ListRowSpec(
          leadingIcon: Icons.event_repeat,
          leadingColor: cs.secondary,
          title: _scheduleDaysLabel(schedule),
          subtitle: 'Cadence overview',
          forceDivider: false,
        ),
      ],
    );
  }
}

class _ListCardReorder extends StatelessWidget {
  const _ListCardReorder({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final med = concept.medication;
    final cs = Theme.of(context).colorScheme;
    final buffer = (med.initialStockValue ?? med.stockValue) * .3;
    final needsReorder = med.stockValue <= buffer;
    return _ListBlock(
      title: 'Supply watch',
      rows: [
        _ListRowSpec(
          leadingIcon: needsReorder
              ? Icons.warning_amber_rounded
              : Icons.inventory_2_outlined,
          leadingColor: needsReorder ? cs.error : cs.primary,
          title: needsReorder ? 'Reorder buffer' : 'Inventory buffer',
          subtitle:
              '${med.stockValue.toStringAsFixed(0)} on hand · baseline ${buffer.toStringAsFixed(0)}',
          trailingWidget: TextButton(
            onPressed: () {},
            child: const Text('Plan'),
          ),
        ),
        _ListRowSpec(
          leadingIcon: Icons.trending_down,
          leadingColor: cs.tertiary,
          title: needsReorder
              ? 'Need ${(buffer - med.stockValue).toStringAsFixed(0)} units'
              : 'Buffer surplus ${(med.stockValue - buffer).toStringAsFixed(0)}',
          subtitle: needsReorder
              ? 'Auto-alert once it drops under ${buffer.toStringAsFixed(0)}'
              : 'Alert threshold ${buffer.toStringAsFixed(0)} units',
          forceDivider: false,
        ),
      ],
    );
  }
}

class _ListCardNextDose extends StatelessWidget {
  const _ListCardNextDose({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final schedule = concept.schedule;
    final med = concept.medication;
    final cs = Theme.of(context).colorScheme;
    return _ListBlock(
      title: 'Next dose',
      rows: [
        _ListRowSpec(
          leadingIcon: Icons.alarm,
          leadingColor: cs.primary,
          title: _scheduleTimeLabel(context, schedule),
          subtitle: '${med.name} · ${_scheduleDoseLabel(schedule)}',
          trailingWidget: FilledButton(
            onPressed: () {},
            child: const Text('Prep'),
          ),
          forceDivider: false,
        ),
      ],
    );
  }
}

class _ListCardChecklist extends StatelessWidget {
  const _ListCardChecklist({required this.concept});

  final _ConceptContext concept;

  @override
  Widget build(BuildContext context) {
    final med = concept.medication;
    final cs = Theme.of(context).colorScheme;
    final baseline = (med.initialStockValue ?? med.stockValue) * .3;
    final buffer = baseline > 0 ? baseline : med.stockValue;
    return _ListBlock(
      title: '${med.name} checklist',
      rows: [
        _ListRowSpec(
          leadingWidget: Icon(Icons.radio_button_checked, color: cs.primary),
          title: 'Verify stock ≥ ${med.stockValue.toStringAsFixed(0)}',
          subtitle: 'Buffer ${buffer.toStringAsFixed(0)} baseline',
          emphasis: true,
        ),
        _ListRowSpec(
          leadingWidget: Icon(Icons.build_outlined, color: cs.primary),
          title: 'Prep ${_scheduleDoseLabel(concept.schedule)}',
          subtitle: 'Ready ${_scheduleTimeLabel(context, concept.schedule)}',
        ),
        _ListRowSpec(
          leadingWidget: Icon(Icons.fact_check_outlined, color: cs.primary),
          title: _doseLogSummary(concept.doseLog),
          subtitle: 'Capture vitals right after logging',
          forceDivider: false,
        ),
      ],
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.title, required this.rows, this.caption});

  final String title;
  final String? caption;
  final List<_ListRowSpec> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: .35);
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: .4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (caption != null)
              Text(
                caption!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: kFieldSpacing / 2),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor),
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _ListRow(
                  spec: rows[i],
                  showDivider: rows[i].forceDivider ?? i < rows.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListRowSpec {
  const _ListRowSpec({
    this.leadingIcon,
    this.leadingColor,
    this.leadingWidget,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.trailingWidget,
    this.footer,
    this.emphasis = false,
    this.forceDivider,
  });

  final IconData? leadingIcon;
  final Color? leadingColor;
  final Widget? leadingWidget;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final Widget? trailingWidget;
  final Widget? footer;
  final bool emphasis;
  final bool? forceDivider;
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.spec, required this.showDivider});

  final _ListRowSpec spec;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    Widget? leading;
    if (spec.leadingWidget != null) {
      leading = SizedBox(
        width: 36,
        height: 36,
        child: Center(child: spec.leadingWidget),
      );
    } else if (spec.leadingIcon != null) {
      final color = spec.leadingColor ?? cs.primary;
      leading = CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: .12),
        child: Icon(spec.leadingIcon, color: color, size: 18),
      );
    }

    final trailing =
        spec.trailingWidget ??
        (spec.trailingLabel != null
            ? Text(
                spec.trailingLabel!,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
            : null);

    final titleStyle = spec.emphasis
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kCardPadding,
            vertical: kFieldSpacing,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: kLabelFieldGap),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spec.title, style: titleStyle),
                    if (spec.subtitle != null)
                      Text(
                        spec.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    if (spec.footer != null) ...[
                      const SizedBox(height: kFieldSpacing / 2),
                      spec.footer!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: kLabelFieldGap),
                trailing,
              ],
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: .35),
          ),
      ],
    );
  }
}

class _MiniVerticalMeter extends StatelessWidget {
  const _MiniVerticalMeter({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 96,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(kBorderRadiusLarge),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: kAnimationSlow,
              height: 96 * value,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(kBorderRadiusLarge),
              ),
            ),
          ),
        ),
        const SizedBox(height: kFieldSpacing / 2),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.label, required this.tone});

  final String label;
  final _PillChipTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color background;
    Color foreground;
    switch (tone) {
      case _PillChipTone.vibrant:
        background = theme.colorScheme.primary.withValues(alpha: .12);
        foreground = theme.colorScheme.primary;
        break;
      case _PillChipTone.soft:
        background = theme.colorScheme.surfaceContainerHighest;
        foreground = theme.colorScheme.onSurfaceVariant;
        break;
      case _PillChipTone.neutral:
        background = theme.colorScheme.surfaceContainerHighest;
        foreground = theme.colorScheme.onSurface;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kFieldSpacing,
        vertical: kFieldSpacing / 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum _PillChipTone { vibrant, soft, neutral }

class _StockProgressBar extends StatelessWidget {
  const _StockProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: kAnimationSlow,
            builder: (context, progress, _) {
              return CustomPaint(
                painter: _ArcPainter(
                  progress: progress,
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: kFieldSpacing / 2),
        Text(
          '${(value * 100).round()}% stocked',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: .08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final constrained = progress.clamp(0.0, 1.0);
    final baseline = size.height * (1 - constrained);
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, baseline);

    const waveCount = 2;
    const amplitude = 8.0;
    for (double x = 0; x <= size.width; x += size.width / 24) {
      final sine = sin((x / size.width) * pi * waveCount);
      final y = baseline + sine * amplitude;
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: .35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePath = Path()..moveTo(0, baseline);
    for (double x = 0; x <= size.width; x += size.width / 24) {
      final sine = sin((x / size.width) * pi * waveCount);
      final y = baseline + sine * amplitude;
      strokePath.lineTo(x, y);
    }
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _NotebookLinesPainter extends CustomPainter {
  const _NotebookLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .2)
      ..strokeWidth = 1;
    for (double y = 32; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 6.0;
    final rect = Offset.zero & size;
    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(
        strokeWidth,
        strokeWidth,
        rect.width - strokeWidth * 2,
        rect.height - strokeWidth * 2,
      ),
      startAngle,
      2 * pi,
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        strokeWidth,
        strokeWidth,
        rect.width - strokeWidth * 2,
        rect.height - strokeWidth * 2,
      ),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _SegmentedRingPainter extends CustomPainter {
  const _SegmentedRingPainter({
    required this.progress,
    required this.baseColor,
    required this.primary,
    required this.warning,
  });

  final double progress;
  final Color baseColor;
  final Color primary;
  final Color warning;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final rect = Offset.zero & size;
    final startAngle = -pi / 2;

    final backgroundPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(
        strokeWidth,
        strokeWidth,
        rect.width - strokeWidth * 2,
        rect.height - strokeWidth * 2,
      ),
      startAngle,
      2 * pi,
      false,
      backgroundPaint,
    );

    final targetColor = progress < .25 ? warning : primary;

    final progressPaint = Paint()
      ..color = targetColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(
        strokeWidth,
        strokeWidth,
        rect.width - strokeWidth * 2,
        rect.height - strokeWidth * 2,
      ),
      startAngle,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.primary != primary ||
      oldDelegate.warning != warning;
}

String _strengthLabel(Medication med) {
  final value = med.strengthValue;
  final unit = med.strengthUnit;
  final isWhole = value.truncateToDouble() == value;
  final formattedValue = isWhole
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$formattedValue ${_unitLabel(unit)}';
}

String _formLabel(MedicationForm form) => form.name.replaceAll('_', ' ');

String _unitLabel(Unit unit) {
  switch (unit) {
    case Unit.mcg:
      return 'mcg';
    case Unit.mg:
      return 'mg';
    case Unit.g:
      return 'g';
    case Unit.units:
      return 'units';
    case Unit.mcgPerMl:
      return 'mcg/mL';
    case Unit.mgPerMl:
      return 'mg/mL';
    case Unit.gPerMl:
      return 'g/mL';
    case Unit.unitsPerMl:
      return 'units/mL';
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day/${date.year}';
}

String _scheduleTimeLabel(BuildContext context, Schedule? schedule) {
  if (schedule == null) return 'Draft';
  int minutes = schedule.minutesOfDay;
  final multi = schedule.timesOfDay;
  if (multi != null && multi.isNotEmpty) {
    minutes = multi.first;
  }
  final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  return time.format(context);
}

String _scheduleDoseLabel(Schedule? schedule) {
  if (schedule == null) return 'Dose TBD';
  final value = schedule.doseValue;
  final formatted = value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$formatted ${schedule.doseUnit}';
}

String _scheduleDaysLabel(Schedule? schedule) {
  if (schedule == null) return 'Any day';
  if (schedule.hasCycle && schedule.cycleEveryNDays != null) {
    return 'Every ${schedule.cycleEveryNDays} day(s)';
  }
  if (schedule.hasDaysOfMonth && schedule.daysOfMonth != null) {
    return schedule.daysOfMonth!
        .map((day) => day.toString().padLeft(2, '0'))
        .join(', ');
  }
  final days = schedule.daysOfWeek;
  if (days.isEmpty) return 'Any day';
  return days.map(_weekdayLabel).join(' · ');
}

String _doseLogSummary(DoseLog? doseLog) {
  if (doseLog == null) return 'No log yet';
  final action = _doseActionLabel(doseLog.action);
  final relative = _formatRelativeTime(doseLog.actionTime.toLocal());
  return '$action · $relative';
}

String _doseActionLabel(DoseAction? action) {
  switch (action) {
    case DoseAction.taken:
      return 'Taken';
    case DoseAction.skipped:
      return 'Skipped';
    case DoseAction.snoozed:
      return 'Snoozed';
    case null:
      return 'No action';
  }
}

String _formatRelativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  final isFuture = diff.isNegative;
  final minutes = diff.inMinutes.abs();
  if (minutes < 1) {
    return isFuture ? 'in <1m' : 'just now';
  }
  if (minutes < 60) {
    final text = '${minutes}m';
    return isFuture ? 'in $text' : '$text ago';
  }
  final hours = diff.inHours.abs();
  if (hours < 24) {
    final text = '${hours}h';
    return isFuture ? 'in $text' : '$text ago';
  }
  final days = diff.inDays.abs();
  final text = '${days}d';
  return isFuture ? 'in $text' : '$text ago';
}

String _weekdayLabel(int dayOfWeek) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  if (dayOfWeek < 1 || dayOfWeek > labels.length) {
    return 'Day $dayOfWeek';
  }
  return labels[dayOfWeek - 1];
}

List<_ConceptContext> _buildConceptContexts({
  required int count,
  required List<Medication> meds,
  required List<Schedule> schedules,
  required List<DoseLog> doses,
}) {
  final sortedMeds = List<Medication>.from(meds)
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final sortedSchedules = List<Schedule>.from(schedules)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final sortedDoses = List<DoseLog>.from(doses)
    ..sort((a, b) => b.actionTime.compareTo(a.actionTime));

  final contexts = <_ConceptContext>[];
  for (var i = 0; i < count; i++) {
    final medSource = sortedMeds.isNotEmpty ? sortedMeds : _sampleMedications;
    final med = medSource[i % medSource.length];
    final schedule = _findScheduleForMedication(med, sortedSchedules);
    final doseLog =
        _findDoseForSchedule(schedule, sortedDoses) ??
        _findDoseForMedication(med, sortedDoses);
    contexts.add(
      _ConceptContext(medication: med, schedule: schedule, doseLog: doseLog),
    );
  }
  return contexts;
}

Schedule? _findScheduleForMedication(Medication med, List<Schedule> schedules) {
  for (final schedule in schedules) {
    if (schedule.medicationId == med.id) {
      return schedule;
    }
  }
  for (final schedule in schedules) {
    if (schedule.medicationName == med.name) {
      return schedule;
    }
  }
  return schedules.isNotEmpty ? schedules.first : null;
}

DoseLog? _findDoseForSchedule(Schedule? schedule, List<DoseLog> doses) {
  if (schedule == null) return null;
  for (final log in doses) {
    if (log.scheduleId == schedule.id) {
      return log;
    }
  }
  return null;
}

DoseLog? _findDoseForMedication(Medication med, List<DoseLog> doses) {
  for (final log in doses) {
    if (log.medicationId == med.id) {
      return log;
    }
  }
  return doses.isNotEmpty ? doses.first : null;
}
