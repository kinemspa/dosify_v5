// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class SelectMedicationForSchedulePage extends StatelessWidget {
  const SelectMedicationForSchedulePage({super.key});

  Color _stockColorFor(BuildContext context, Medication m) {
    final cs = Theme.of(context).colorScheme;
    if (m.stockValue <= 0) return cs.error;
    final low = m.lowStockThreshold?.toInt() ?? 5;
    if (m.lowStockEnabled && m.stockValue <= low) return cs.tertiary;
    return cs.onSurfaceVariant.withValues(alpha: kOpacityMedium);
  }

  Widget _buildMedicationRow(BuildContext context, Medication m) {
    final cs = Theme.of(context).colorScheme;
    final manufacturer = (m.manufacturer ?? '').trim();
    final strengthLabel =
        '${fmt2(m.strengthValue)} ${MedicationDisplayHelpers.unitLabel(m.strengthUnit)} '
        '${MedicationDisplayHelpers.formLabel(m.form, plural: true)}';
    final detailLabel = manufacturer.isEmpty
        ? strengthLabel
        : '$manufacturer | $strengthLabel';

    final stockInfo = MedicationDisplayHelpers.calculateStock(m);
    final stockColor = _stockColorFor(context, m);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(m),
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingS,
            vertical: kSpacingXS,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.name,
                      style: cardTitleStyle(context)?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingXS),
                    Text(
                      detailLabel,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stockInfo.label,
                    style: helperTextStyle(
                      context,
                      color: stockColor,
                    )?.copyWith(fontWeight: kFontWeightSemiBold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(width: kSpacingXS),
              Icon(
                Icons.chevron_right,
                size: kIconSizeMedium,
                color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');
    final meds = box.values.toList(growable: false);

    // Filter out medications with no stock
    final availableMeds = meds.where((m) => m.stockValue > 0).toList();

    return Scaffold(
      appBar: const GradientAppBar(title: 'Select Medication'),
      body: availableMeds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: kEmptyStateIconSize,
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: kOpacityMedium),
                  ),
                  const SizedBox(height: kSpacingM),
                  Text(
                    'No medications with stock',
                    style: mutedTextStyle(context),
                  ),
                  const SizedBox(height: kSpacingS),
                  Text(
                    'Add medications first to create schedules',
                    style: helperTextStyle(context),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: availableMeds.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = availableMeds[i];
                return _buildMedicationRow(context, m);
              },
            ),
    );
  }
}
