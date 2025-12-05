import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/medication_stock_service.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/expiry_tracking_service.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';

class MedicationHeaderWidget extends StatelessWidget {
  const MedicationHeaderWidget({
    super.key,
    required this.medication,
    required this.onRefill,
    this.daysRemaining,
    this.stockoutDate,
    this.adherenceData = const [],
  });

  final Medication medication;
  final VoidCallback onRefill;
  final double? daysRemaining;
  final DateTime? stockoutDate;
  final List<double> adherenceData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final stockRatio = MedicationStockService.calculateStockRatio(medication);
    final storageLabel = medication.storageLocation;

    // Gauge logic
    final isMdv = medication.form == MedicationForm.multiDoseVial;

    double pct = 0;
    String primaryLabel = '';
    String helperLabel = '';
    String? extraStockLabel;
    double initial = medication.initialStockValue ?? medication.stockValue;
    String unit = _stockUnitLabel(medication.stockUnit);

    if (isMdv) {
      if (medication.containerVolumeMl != null &&
          medication.containerVolumeMl! > 0) {
        final currentVol =
            medication.activeVialVolume ?? medication.containerVolumeMl!;
        pct = (currentVol / medication.containerVolumeMl!) * 100;
        primaryLabel = '${pct.round()}%';

        initial = medication.containerVolumeMl!;
        unit = 'mL';

        helperLabel = 'Remaining of Active Vial';
        extraStockLabel =
            '${_formatNumber(medication.stockValue)} sealed vials in stock';
      } else {
        pct = stockRatio * 100;
        primaryLabel = '${pct.round()}%';
        helperLabel = 'Remaining';
      }
    } else {
      pct = stockRatio * 100;
      primaryLabel = '${pct.round()}%';
      helperLabel = 'Remaining';
    }

    final hasBackup = isMdv &&
        medication.stockUnit == StockUnit.multiDoseVials &&
        medication.stockValue > 0;

    double backupPct = 0;
    if (hasBackup) {
      final baseline = medication.lowStockVialsThresholdCount != null &&
              medication.lowStockVialsThresholdCount! > 0
          ? medication.lowStockVialsThresholdCount!
          : medication.stockValue;
      backupPct =
          baseline > 0 ? (medication.stockValue / baseline) * 100.0 : 0.0;
    }

    // Strength per X label
    String strengthPerLabel = switch (medication.form) {
      MedicationForm.tablet => 'Strength per Tablet',
      MedicationForm.capsule => 'Strength per Capsule',
      MedicationForm.prefilledSyringe => 'Strength per Syringe',
      MedicationForm.singleDoseVial ||
      MedicationForm.multiDoseVial =>
        'Strength per Vial',
    };

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
                // Space for the animated Name (which is positioned absolutely in parent)
                const SizedBox(height: 52),

                // Description & Notes
                if (medication.description != null &&
                    medication.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      medication.description!,
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                if (medication.notes != null && medication.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      medication.notes!,
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.65),
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(height: 4),

                // Strength with Icon
                _HeaderInfoTile(
                  icon: Icons.medication_liquid,
                  label: strengthPerLabel,
                  value:
                      '${_formatNumber(medication.strengthValue)} ${_unitLabel(medication.strengthUnit)}',
                  textColor: onPrimary,
                ),
                const SizedBox(height: 8),

                // Storage
                if (storageLabel != null && storageLabel.isNotEmpty) ...[
                  _HeaderInfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Storage',
                    value: storageLabel,
                    textColor: onPrimary,
                    trailingIcon: medication.activeVialRequiresFreezer
                        ? Icons.severe_cold
                        : (medication.requiresRefrigeration
                            ? Icons.ac_unit
                            : (medication.activeVialLightSensitive
                                ? Icons.dark_mode_outlined
                                : null)),
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 16),
                // Adherence Graph
                _AdherenceGraph(data: adherenceData, color: onPrimary),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _StockInfoCard(
            medication: medication,
            theme: theme,
            onPrimary: onPrimary,
            stockRatio: stockRatio,
            daysRemaining: daysRemaining,
            stockoutDate: stockoutDate,
            onRefill: onRefill,
          ),
        ],
      ),
    );
  }

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

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
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
    final color = textColor ?? Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color.withValues(alpha: 0.65), size: 12),
              const SizedBox(width: 4),
            ],

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM y').format(stockoutDate);
    final expiry = medication.expiry;
    final expiresBeforeStockout = ExpiryTrackingService.willExpireBeforeStockout(
      expiry,
      stockoutDate,
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 11,
                color: color.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 4),
              Text(
                'STOCK FORECAST',
                style: TextStyle(
                  color: color.withValues(alpha: 0.65),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lasts until',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.6),
                      fontSize: 9,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${daysRemaining.floor()} days',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (expiry != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: expiresBeforeStockout
                    ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 11,
                    color: expiresBeforeStockout
                        ? Theme.of(context).colorScheme.error
                        : color.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires ${DateFormat('d MMM').format(expiry)}',
                    style: TextStyle(
                      color: expiresBeforeStockout
                          ? Theme.of(context).colorScheme.error
                          : color.withValues(alpha: 0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
