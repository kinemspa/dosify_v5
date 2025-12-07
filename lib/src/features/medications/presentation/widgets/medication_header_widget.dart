import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/medication_stock_service.dart';
import 'package:dosifi_v5/src/features/medications/presentation/controllers/medication_detail_controller.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MedicationHeaderWidget extends ConsumerWidget {
  const MedicationHeaderWidget({
    required this.medication,
    required this.onRefill,
    super.key,
  });

  final Medication medication;
  final VoidCallback onRefill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    // Use current date for calculations
    final now = DateTime.now();

    // Watch the controller state to get calculated values
    final state = ref.watch(medicationDetailControllerProvider(medication.id));
    
    // Calculate Stock
    final stockRatio = MedicationStockService.calculateStockRatio(medication);

    // Get Days Remaining from State
    final double? daysRemaining = state?.daysRemaining;
    final DateTime? stockoutDate = state?.stockoutDate;
    
    // Adherence Data (stubbed for now or real if available)
    final adherenceData = [1.0, 1.0, 0.5, 1.0, 0.0, 1.0, 1.0]; // Example

    final strengthPerLabel = 'Strength per ${_unitLabel(medication.strengthUnit)}';
    
    // Storage Label: Use actual location data
    final storageLabel = (medication.storageLocation?.isNotEmpty ?? false)
        ? medication.storageLocation
        : (medication.activeVialStorageLocation?.isNotEmpty ?? false)
            ? medication.activeVialStorageLocation
            : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Space for the animated Name
              const SizedBox(height: 52),

              // Description & Notes
              if (medication.description != null &&
                  medication.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    medication.description!,
                    style: TextStyle(
                      color: onPrimary.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              if (medication.notes != null && medication.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    medication.notes!,
                    style: TextStyle(
                      color: onPrimary.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                      fontSize: 9,
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
              const SizedBox(height: 4),

              // Storage
              if (storageLabel != null && storageLabel.isNotEmpty) ...[
                _HeaderInfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Storage',
                  value: storageLabel,
                  textColor: onPrimary,
                  trailingIcons: [
                    if (medication.activeVialRequiresFreezer || medication.requiresFreezer)
                      Icons.severe_cold,
                    if (medication.requiresRefrigeration || medication.activeVialRequiresRefrigeration)
                      Icons.ac_unit,
                    if (medication.activeVialLightSensitive || medication.lightSensitive)
                      Icons.dark_mode_outlined,
                  ],
                ),
                const SizedBox(height: 4),
              ],

              const Spacer(),
              // Adherence Graph
              _AdherenceGraph(data: adherenceData, color: onPrimary),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // StockInfoCard 40% Width
        Expanded(
          flex: 4,
          child: _StockInfoCard(
            medication: medication,
            theme: theme,
            onPrimary: onPrimary,
            stockRatio: stockRatio,
            daysRemaining: daysRemaining,
            stockoutDate: stockoutDate,
            onRefill: onRefill,
          ),
        ),
      ],
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

  String _formLabel(MedicationForm form) => switch (form) {
        MedicationForm.tablet => 'Tablet',
        MedicationForm.capsule => 'Capsule',
        MedicationForm.prefilledSyringe => 'Syringe',
        MedicationForm.singleDoseVial => 'Vial',
        MedicationForm.multiDoseVial => 'Vial',
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
  final List<IconData>? trailingIcons;

  const _HeaderInfoTile({
    required this.label,
    required this.value,
    this.icon,
    this.textColor,
    this.trailingIcons,
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
            if (trailingIcons != null)
              for (final icon in trailingIcons!) ...[
                const SizedBox(width: 5),
                Icon(icon, color: color.withValues(alpha: 0.95), size: 15),
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

  @override
  Widget build(BuildContext context) {
    final pct = stockRatio.clamp(0.0, 1.0);

    // Correct logic for MDVs based on existing properties
    final isMdv = medication.form == MedicationForm.multiDoseVial;
    final hasBackup = isMdv && medication.stockUnit == StockUnit.multiDoseVials;

    double backupPct = 0.0;
    if (hasBackup) {
      final baseline = medication.lowStockVialsThresholdCount != null &&
              medication.lowStockVialsThresholdCount! > 0
          ? medication.lowStockVialsThresholdCount!.toDouble()
          : medication.stockValue;

      // Ensure we don't divide by zero
      if (baseline > 0) {
        backupPct = (medication.stockValue / baseline).clamp(0.0, 1.0);
      }
    }

    final primaryLabel = '${(pct * 100).round()}%';

    // User requested White Donut with Thick Line (Large Card Style)
    // Large Card uses defaults: isOutline=false (Thick), showGlow=true
    // We adjust for the header background (onPrimary for color, no glow for clean look on solid)
    final gaugeColor = onPrimary;

    // Calculate initial helper value
    final initial = isMdv && medication.containerVolumeMl != null
        ? medication.containerVolumeMl!
        : (medication.initialStockValue ?? medication.stockValue);

    final unit = _stockUnitLabel(medication.stockUnit);
    final helperLabel = isMdv ? 'Active Vial' : 'Remaining';

    String? extraStockLabel;

    // Calculate backup vials count if possible
    if (isMdv &&
        medication.containerVolumeMl != null &&
        medication.containerVolumeMl! > 0) {
      if (medication.activeVialVolume != null &&
          medication.stockValue > medication.activeVialVolume!) {
        final backupVol = medication.stockValue - medication.activeVialVolume!;
        final count = (backupVol / medication.containerVolumeMl!).floor();
        if (count > 0) {
          extraStockLabel = '+ $count backup ${count == 1 ? 'vial' : 'vials'}';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
          // Stock Count (Align Right)
          Align(
            alignment: Alignment.centerRight,
            child: RichText(
              textAlign: TextAlign.end,
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
                      color: onPrimary,
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
          ),
          const SizedBox(height: 2),
          Text(
            helperLabel,
            style: TextStyle(
              color: onPrimary.withValues(alpha: 0.75),
              fontSize: 10,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.end,
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
              textAlign: TextAlign.end,
            ),
          ],

          // Stock Forecast Text (Right Aligned RichText) - RESTORED
          if (daysRemaining != null && stockoutDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    textAlign: TextAlign.end,
                    text: TextSpan(
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.8),
                        fontSize: 10,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Projected to run out on '),
                        TextSpan(
                          text: DateFormat.yMMMd().format(stockoutDate!),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.end,
                    text: TextSpan(
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.8),
                        fontSize: 10,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '${daysRemaining!.ceil()} days left',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Expiry Text - RESTORED
          if (medication.expiry != null) ...[
             // If we didn't show the daysRemaining block, add some spacing
             if (daysRemaining == null) const SizedBox(height: 12),
             Padding(
               padding: const EdgeInsets.only(top: 2),
               child: RichText(
                 textAlign: TextAlign.end,
                 text: TextSpan(
                   style: TextStyle(
                    color: onPrimary.withValues(alpha: 0.65),
                    fontSize: 10,
                  ),
                  children: [
                    const TextSpan(text: 'Expires '),
                     TextSpan(
                      text: DateFormat.yMMMd().format(medication.expiry!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                 ),
               ),
             ),
          ],

          const SizedBox(height: 16),

          // Refill Button - Less Rounded, Subtle Outlined
          Align(
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: onPrimary.withValues(alpha: 0.5), width: 1),
              ),
              child: InkWell(
                onTap: onRefill,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
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

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
