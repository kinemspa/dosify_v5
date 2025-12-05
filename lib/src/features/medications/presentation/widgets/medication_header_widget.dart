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
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.65),
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.1,
                  height: 1.1,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 5),
              Icon(trailingIcon, color: color.withValues(alpha: 0.95), size: 15),
            ],
          ],
        ),
      ],
    );
  }
}

class _AdherenceGraph extends StatelessWidget {
  const _AdherenceGraph({
    required this.data,
    required this.color,
  });

  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.show_chart,
              size: 12,
              color: color.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 4),
            Text(
              '7 DAY ADHERENCE',
              style: TextStyle(
                color: color.withValues(alpha: 0.65),
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: CustomPaint(
            painter: _AdherenceLinePainter(data: data, color: color),
            child: Container(),
          ),
        ),
        const SizedBox(height: 6),
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = DateTime.now().subtract(Duration(days: 6 - i));
            final dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
            return Text(
              dayName,
              style: TextStyle(
                color: color.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AdherenceLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _AdherenceLinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final spacing = width / (data.length - 1);

    // Draw background grid
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        gridPaint,
      );
    }

    // Build path for line and area
    final linePath = Path();
    final areaPath = Path();
    bool hasStarted = false;

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      if (value < 0) continue; // Skip no-data points

      final x = i * spacing;
      final y = height - (value * height * 0.8) - (height * 0.1);

      if (!hasStarted) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, height);
        areaPath.lineTo(x, y);
        hasStarted = true;
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    if (hasStarted) {
      // Close area path
      areaPath.lineTo((data.length - 1) * spacing, height);
      areaPath.close();

      // Draw gradient fill
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.05),
        ],
      );

      fillPaint.shader = gradient.createShader(
        Rect.fromLTWH(0, 0, width, height),
      );

      canvas.drawPath(areaPath, fillPaint);

      // Draw line
      paint.color = color.withValues(alpha: 0.9);
      canvas.drawPath(linePath, paint);

      // Draw points
      for (int i = 0; i < data.length; i++) {
        final value = data[i];
        if (value < 0) continue;

        final x = i * spacing;
        final y = height - (value * height * 0.8) - (height * 0.1);

        // Outer circle
        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()
            ..color = color.withValues(alpha: 0.9)
            ..style = PaintingStyle.fill,
        );

        // Inner circle
        canvas.drawCircle(
          Offset(x, y),
          2,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AdherenceLinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

class _StockInfoCard extends StatelessWidget {
  const _StockInfoCard({
    required this.medication,
    required this.theme,
    required this.onPrimary,
    required this.stockRatio,
    required this.daysRemaining,
    required this.stockoutDate,
    required this.onRefill,
  });

  final Medication medication;
  final ThemeData theme;
  final Color onPrimary;
  final double stockRatio;
  final double? daysRemaining;
  final DateTime? stockoutDate;
  final VoidCallback onRefill;

  });

  final Color color;
  final Medication medication;
  final double daysRemaining;
  final DateTime stockoutDate;

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
