// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/medication_stock_service.dart';
import 'package:dosifi_v5/src/features/supplies/data/supply_repository.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final medsBox = Hive.box<Medication>('medications');
    final suppliesBox = Hive.box<Supply>(SupplyRepository.suppliesBoxName);
    final movementsBox = Hive.box<StockMovement>(
      SupplyRepository.movementsBoxName,
    );

    return Scaffold(
      appBar: const GradientAppBar(title: 'Inventory', forceBackButton: true),
      body: ValueListenableBuilder<Box<Medication>>(
        valueListenable: medsBox.listenable(),
        builder: (context, meds, _) {
          return ValueListenableBuilder<Box<Supply>>(
            valueListenable: suppliesBox.listenable(),
            builder: (context, supplies, __) {
              return ValueListenableBuilder<Box<StockMovement>>(
                valueListenable: movementsBox.listenable(),
                builder: (context, ___, ____) {
                  final medItems = meds.values.toList(growable: false);
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
                  final soon = DateTime.now().add(const Duration(days: 30));
                  final supplyExpiringSoon = supplyItems
                      .where(
                        (s) => s.expiry != null && s.expiry!.isBefore(soon),
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
                            'View medication stock levels and details.',
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
      ),
    );
  }
}
