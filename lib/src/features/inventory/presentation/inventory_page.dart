// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/medication_stock_service.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/supplies/data/supply_repository.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final medsBox = Hive.box<Medication>('medications');
    final schedulesBox = Hive.box<Schedule>('schedules');
    final suppliesBox = Hive.box<Supply>(SupplyRepository.suppliesBoxName);
    final movementsBox = Hive.box<StockMovement>(
      SupplyRepository.movementsBoxName,
    );

    return Scaffold(
      appBar: const GradientAppBar(title: 'Inventory', forceBackButton: true),
      body: ValueListenableBuilder<Box<Medication>>(
        valueListenable: medsBox.listenable(),
        builder: (context, meds, _) {
          return ValueListenableBuilder<Box<Schedule>>(
            valueListenable: schedulesBox.listenable(),
            builder: (context, schedules, __) {
              return ValueListenableBuilder<Box<Supply>>(
                valueListenable: suppliesBox.listenable(),
                builder: (context, supplies, ___) {
                  return ValueListenableBuilder<Box<StockMovement>>(
                    valueListenable: movementsBox.listenable(),
                    builder: (context, ____, _____) {
                      final medItems = meds.values.toList(growable: false)
                        ..sort((a, b) => a.name
                            .toLowerCase()
                            .compareTo(b.name.toLowerCase()));
                      final scheduleItems = schedules.values.toList(
                        growable: false,
                      );
                      final supplyRepo = SupplyRepository();
                      final supplyItems = supplyRepo.allSupplies();

                      final medLow = medItems
                          .where(MedicationStockService.isLowStock)
                          .length;
                      final medOut = medItems
                          .where((m) => m.stockValue <= 0)
                          .length;

                      final supplyLow = supplyItems
                          .where(supplyRepo.isLowStock)
                          .length;
                      final soon =
                          DateTime.now().add(const Duration(days: 30));
                      final supplyExpiringSoon = supplyItems
                          .where(
                            (s) =>
                                s.expiry != null && s.expiry!.isBefore(soon),
                          )
                          .length;

                      return ListView(
                        padding: const EdgeInsets.all(kSpacingL),
                        children: [
                          SectionFormCard(
                            title: 'Medications',
                            neutral: true,
                            children: [
                              buildDetailInfoRow(
                                context,
                                label: 'Total',
                                value: medItems.length.toString(),
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Low stock',
                                value: medLow.toString(),
                                warning: medLow > 0,
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Out of stock',
                                value: medOut.toString(),
                                warning: medOut > 0,
                              ),
                              buildHelperText(
                                context,
                                'Overview of medication stock and projected days remaining based on linked schedules.',
                              ),
                              const SizedBox(height: kSpacingS),
                              if (medItems.isEmpty)
                                Text(
                                  'No medications',
                                  style: mutedTextStyle(context),
                                )
                              else
                                Column(
                                  children: [
                                    for (int i = 0; i < medItems.length; i++)
                                      ...[
                                        _MedicationInventoryRow(
                                          medication: medItems[i],
                                          schedules: scheduleItems,
                                        ),
                                        if (i != medItems.length - 1)
                                          Divider(
                                            height: kSpacingS,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant
                                                .withValues(
                                                  alpha: kOpacityVeryLow,
                                                ),
                                          ),
                                      ],
                                  ],
                                ),
                              const SizedBox(height: kSpacingS),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  onPressed: () => context.go('/medications'),
                                  child: const Text('View Medications'),
                                ),
                              ),
                            ],
                          ),
                          sectionSpacing,
                          SectionFormCard(
                            title: 'Supplies',
                            neutral: true,
                            children: [
                              buildDetailInfoRow(
                                context,
                                label: 'Total',
                                value: supplyItems.length.toString(),
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Low stock',
                                value: supplyLow.toString(),
                                warning: supplyLow > 0,
                              ),
                              buildDetailInfoRow(
                                context,
                                label: 'Expiring soon',
                                value: supplyExpiringSoon.toString(),
                                warning: supplyExpiringSoon > 0,
                              ),
                              buildHelperText(
                                context,
                                'View supply stock movements and expiry tracking.',
                              ),
                              const SizedBox(height: kSpacingS),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  onPressed: () => context.go('/supplies'),
                                  child: const Text('View Supplies'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MedicationInventoryRow extends StatelessWidget {
  const _MedicationInventoryRow({
    required this.medication,
    required this.schedules,
  });

  final Medication medication;
  final List<Schedule> schedules;

  List<Schedule> _linkedSchedules() {
    return schedules
        .where(
          (s) =>
              (s.medicationId != null && s.medicationId == medication.id) ||
              (s.medicationId == null && s.medicationName == medication.name),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = MedicationStockService.calculateStockRatio(medication);
    final percentage = (ratio * 100).clamp(0.0, 100.0);

    final stockInfo = MedicationDisplayHelpers.calculateStock(medication);
    final linked = _linkedSchedules();
    final daysRemaining = MedicationStockService.calculateDaysRemaining(
      medication,
      linked,
    );

    final daysLabel = daysRemaining == null
        ? '—'
        : daysRemaining.isNaN
            ? '—'
            : daysRemaining.isInfinite
                ? '—'
                : daysRemaining < 1
                    ? '<1 day'
                    : '${daysRemaining.floor()} days';

    final daysWarning = daysRemaining != null && daysRemaining <= 7;
    final daysColor = daysWarning
        ? cs.error
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: MiniStockGauge(
              percentage: percentage,
              color: cs.primary,
              size: 44,
            ),
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: cardTitleStyle(context)?.copyWith(
                    fontWeight: kFontWeightSemiBold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: kSpacingXS),
                Text(
                  stockInfo.label,
                  style: helperTextStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: kSpacingS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Days left',
                style: hintLabelTextStyle(context, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: kSpacingXS),
              Text(
                daysLabel,
                style: helperTextStyle(context, color: daysColor)?.copyWith(
                  fontWeight: kFontWeightSemiBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
