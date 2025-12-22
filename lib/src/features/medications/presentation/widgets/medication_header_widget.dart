// ignore_for_file: unused_element, unused_local_variable

import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/services/medication_stock_service.dart';
import 'package:dosifi_v5/src/features/medications/presentation/controllers/medication_detail_controller.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class MedicationHeaderWidget extends ConsumerWidget {
  const MedicationHeaderWidget({
    required this.medication,
    required this.onRefill,
    this.onAdHocDose,
    this.hasSchedules = false,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    super.key,
  });

  final Medication medication;
  final VoidCallback onRefill;
  final VoidCallback? onAdHocDose;
  final bool hasSchedules;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    final headerActionButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: onPrimary,
      textStyle: buttonTextStyle(context),
      side: BorderSide(
        color: onPrimary.withValues(alpha: kOpacityMediumLow),
        width: kBorderWidthThin,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      padding: kButtonContentPadding,
      minimumSize: const Size(0, kStandardButtonHeight),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    // Watch the controller state to get calculated values
    final state = ref.watch(medicationDetailControllerProvider(medication.id));

    // Calculate Stock
    final stockRatio = MedicationStockService.calculateStockRatio(medication);

    // Get Days Remaining from State
    final double? daysRemaining = state?.daysRemaining;
    final DateTime? stockoutDate = state?.stockoutDate;

    final strengthPerLabel = 'Strength per ${_formLabel(medication.form)}';

    // Storage Label: Use actual location data
    final storageLabel = (medication.storageLocation?.isNotEmpty ?? false)
        ? medication.storageLocation
        : (medication.activeVialStorageLocation?.isNotEmpty ?? false)
        ? medication.activeVialStorageLocation
        : null;

    final effectiveRowCrossAxisAlignment =
        crossAxisAlignment == CrossAxisAlignment.stretch
        ? CrossAxisAlignment.start
        : crossAxisAlignment;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: effectiveRowCrossAxisAlignment,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Space for the animated Name + form chip (rendered above in the SliverAppBar)
                  const SizedBox(height: 68),

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
                    valueSize: 11,
                  ),
                  const SizedBox(height: kSpacingS),

                  // Storage
                  if (storageLabel != null && storageLabel.isNotEmpty) ...[
                    _HeaderInfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Storage Location',
                      value: storageLabel,
                      textColor: onPrimary,
                      valueSize: 11,
                      trailingIcons: [
                        if (medication.activeVialRequiresFreezer ||
                            medication.requiresFreezer)
                          Icons.severe_cold,
                        if (medication.requiresRefrigeration ||
                            medication.activeVialRequiresRefrigeration)
                          Icons.ac_unit,
                        if (medication.activeVialLightSensitive ||
                            medication.lightSensitive)
                          Icons.dark_mode_outlined,
                      ],
                    ),
                  ],

                  // Adherence graph moved to MedicationReportsWidget
                ],
              ),
            ),
            const SizedBox(width: 12),
            // StockInfoCard 40% Width
            Expanded(
              flex: 4,
              child: _StockInfoCard(
                medication: medication,
                onPrimary: onPrimary,
                stockRatio: stockRatio,
                daysRemaining: daysRemaining,
                stockoutDate: stockoutDate,
              ),
            ),
          ],
        ),
        SizedBox(
          height: kStandardButtonHeight,
          child: Row(
            children: [
              // Slot 1 (reserved)
              const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: kButtonSpacing),
              // Slot 2 (reserved)
              const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: kButtonSpacing),
              // Slot 3 (Dose)
              Expanded(
                child: onAdHocDose == null
                    ? const SizedBox.shrink()
                    : OutlinedButton.icon(
                        onPressed: onAdHocDose,
                        style: headerActionButtonStyle,
                        icon: Icon(
                          Icons.medication_rounded,
                          size: kIconSizeSmall,
                          color: onPrimary,
                        ),
                        label: const Text('Log dose'),
                      ),
              ),
              const SizedBox(width: kButtonSpacing),
              // Slot 4 (Refill)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRefill,
                  style: headerActionButtonStyle,
                  icon: Icon(Icons.add, size: kIconSizeSmall, color: onPrimary),
                  label: const Text('Refill'),
                ),
              ),
            ],
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

  /// Calculate real adherence data for last 7 days from DoseLog
  /// Returns list of 7 values (0.0 to 1.0) representing adherence per day
  /// -1.0 means no doses scheduled that day
  List<double> _calculateAdherenceData(String medicationId) {
    final now = DateTime.now();
    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final scheduleBox = Hive.box<Schedule>('schedules');

    // Get schedules for this medication
    final schedules = scheduleBox.values
        .where((s) => s.medicationId == medicationId && s.active)
        .toList();

    if (schedules.isEmpty) {
      return List.filled(7, -1.0); // No schedules = no data
    }

    final adherenceData = <double>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));

      // Count expected doses for this day
      int expectedDoses = 0;
      int takenDoses = 0;

      for (final schedule in schedules) {
        // Check if schedule is active on this day
        if (!schedule.daysOfWeek.contains(day.weekday)) continue;

        // Count times per day - use timesOfDay if available, otherwise 1
        final int timesPerDay = schedule.timesOfDay?.length ?? 1;
        expectedDoses += timesPerDay;
      }

      // Count taken doses from logs for this medication and day
      final dayLogs = doseLogBox.values.where(
        (log) =>
            log.medicationId == medicationId &&
            log.scheduledTime.isAfter(
              day.subtract(const Duration(seconds: 1)),
            ) &&
            log.scheduledTime.isBefore(dayEnd),
      );

      takenDoses = dayLogs
          .where((log) => log.action == DoseAction.taken)
          .length;

      if (expectedDoses == 0) {
        adherenceData.add(-1.0); // No doses scheduled
      } else {
        adherenceData.add((takenDoses / expectedDoses).clamp(0.0, 1.0));
      }
    }

    return adherenceData;
  }
}

class _HeaderInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? textColor;
  final List<IconData>? trailingIcons;
  final double? valueSize;

  const _HeaderInfoTile({
    required this.label,
    required this.value,
    this.icon,
    this.textColor,
    this.trailingIcons,
    this.valueSize,
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
        const SizedBox(height: kSpacingXS / 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: valueSize ?? 13,
                  letterSpacing: 0.1,
                  height: 1.1,
                ),
              ),
            ),
            if (trailingIcons != null)
              for (final icon in trailingIcons!) ...[
                const SizedBox(width: kSpacingXS),
                Icon(icon, color: color.withValues(alpha: 0.95), size: 15),
              ],
          ],
        ),
      ],
    );
  }
}

class _AdherenceGraph extends StatelessWidget {
  const _AdherenceGraph({required this.data, required this.color});

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
            final dayName = [
              'M',
              'T',
              'W',
              'T',
              'F',
              'S',
              'S',
            ][day.weekday - 1];
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

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final spacing = width / (data.length - 1);

    // Draw background grid
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
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
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.05)],
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
    required this.onPrimary,
    required this.stockRatio,
    required this.daysRemaining,
    required this.stockoutDate,
  });

  final Medication medication;
  final Color onPrimary;
  final double stockRatio;
  final double? daysRemaining;
  final DateTime? stockoutDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = stockRatio.clamp(0.0, 1.0);

    // Use centralized helper for consistent stock calculations
    final stockInfo = MedicationDisplayHelpers.calculateStock(medication);
    final isMdv = stockInfo.isMdv;
    final hasBackup = isMdv && medication.stockUnit == StockUnit.multiDoseVials;

    // Active Vial % (outer ring) and Sealed Vials % (inner ring)
    final activeVialPct = stockInfo.percentage / 100.0; // Convert 0-100 to 0-1
    final sealedVialsPct =
        stockInfo.backupPercentage / 100.0; // Convert 0-100 to 0-1

    // For MDV, show active vial %; for others, show overall stock %
    final primaryLabel = isMdv
        ? '${stockInfo.percentage.round()}%'
        : '${(pct * 100).round()}%';

    final labelPct = (isMdv ? stockInfo.percentage : (pct * 100)).clamp(
      0.0,
      100.0,
    );
    final Color gaugeLabelColor;
    if (labelPct <= 0) {
      gaugeLabelColor = statusColorOnPrimary(context, cs.error);
    } else if (labelPct < 20) {
      gaugeLabelColor = statusColorOnPrimary(context, cs.tertiary);
    } else {
      gaugeLabelColor = onPrimary;
    }

    // User requested White Donut with Thick Line (Large Card Style)
    // Large Card uses defaults: isOutline=false (Thick), showGlow=true
    // We adjust for the header background (onPrimary for color, no glow for clean look on solid)
    final gaugeColor = onPrimary;

    // Calculate initial helper value
    final initial = isMdv && medication.containerVolumeMl != null
        ? medication.containerVolumeMl!
        : (medication.initialStockValue ?? medication.stockValue);

    // For MDV, show mL for active vial volume; for others, show the stock unit
    final unit =
        (isMdv &&
            medication.containerVolumeMl != null &&
            medication.containerVolumeMl! > 0)
        ? 'mL'
        : _stockUnitLabel(medication.stockUnit);
    final helperLabel = isMdv ? '' : 'Remaining';

    String? extraStockLabel;

    // For MDV, show sealed vials count as separate line
    if (isMdv) {
      final sealedCount = medication.stockValue.floor();
      extraStockLabel =
          '$sealedCount sealed ${sealedCount == 1 ? 'vial' : 'vials'}';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min, // Only take space needed
        children: [
          // Stock Gauge (Right aligned)
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 80, // Reduced from 90
              width: 80, // Reduced from 90
              // Single ring for all: MDV shows Active Vial %, others show overall stock %
              // Using white (onPrimary) color for arc, thicker stroke
              child: StockDonutGauge(
                percentage: isMdv ? activeVialPct * 100 : pct * 100,
                primaryLabel: primaryLabel,
                color: onPrimary, // White arc
                backgroundColor: onPrimary.withValues(alpha: 0.15),
                textColor: gaugeLabelColor,
                showGlow: false,
                isOutline: false,
                strokeWidth: 10, // Slightly thicker stroke
              ),
            ),
          ),
          const SizedBox(height: 4), // Reduced from 6
          // Stock Count (Align Right)
          Align(
            alignment: Alignment.centerRight,
            child: RichText(
              textAlign: TextAlign.end,
              text: TextSpan(
                style: TextStyle(color: onPrimary, fontSize: 10),
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
                      color: gaugeLabelColor,
                    ),
                  ),
                  const TextSpan(text: ' / '),
                  TextSpan(
                    text: _formatNumber(initial),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $unit'),
                  if (isMdv)
                    TextSpan(
                      text: ' remaining in active vial',
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.75),
                        letterSpacing: 0.2,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isMdv) ...[
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
          ],
          if (extraStockLabel != null) ...[
            const SizedBox(height: 2),
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

          // Expiry Text (condensed)
          if (medication.expiry != null) ...[
            const SizedBox(height: 4),
            Text(
              'Exp ${DateFormat.MMMd().format(medication.expiry!)}',
              style: TextStyle(
                color: onPrimary.withValues(alpha: 0.65),
                fontSize: 9,
              ),
              textAlign: TextAlign.end,
            ),
          ],
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
