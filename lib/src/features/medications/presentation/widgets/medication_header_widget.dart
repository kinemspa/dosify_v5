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
                        backgroundColor: onPrimary.withValues(alpha: 0.05),
                        textColor: onPrimary,
                        showGlow: false,
                        isOutline: false,
                      )
                    : StockDonutGauge(
                        percentage: pct,
                        primaryLabel: primaryLabel,
                        color: gaugeColor,
                        backgroundColor: onPrimary.withValues(alpha: 0.05),
                        textColor: onPrimary,
                        showGlow: false,
                        isOutline: false,
                      ),
              ),
              const SizedBox(height: 6),
              RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  style: TextStyle(
                    color: onPrimary,
                    fontSize: 10,
                  ),
                  children: [
                    TextSpan(
                      text: _formatNumber(
                        (isMdv &&
                                medication.containerVolumeMl != null &&
                                medication.containerVolumeMl! > 0)
                            ? (medication.activeVialVolume ??
                                medication.containerVolumeMl!)
                            : medication.stockValue,
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
              const SizedBox(height: 2),
              Text(
                helperLabel,
                style: TextStyle(
                  color: onPrimary.withValues(alpha: 0.75),
                  fontSize: 10,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.right,
              ),
              if (extraStockLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  extraStockLabel,
                  style: TextStyle(
                    color: onPrimary.withValues(alpha: 0.95),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
              const SizedBox(height: 8),

              // Stock Forecast
              if (daysRemaining != null && stockoutDate != null)
                _StockForecastCard(
                  color: onPrimary,
                  medication: medication,
                  daysRemaining: daysRemaining!,
                  stockoutDate: stockoutDate!,
                ),

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
                    onTap: onRefill,
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
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
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

class _StockForecastCard extends StatelessWidget {
  const _StockForecastCard({
    required this.color,
    required this.medication,
    required this.daysRemaining,
    required this.stockoutDate,
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
}
