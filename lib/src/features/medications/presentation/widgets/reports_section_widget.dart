// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';

/// Reports section widget showing adherence graphs and history
class ReportsSectionWidget extends StatelessWidget {
  const ReportsSectionWidget({
    required this.medicationId,
    super.key,
  });

  final String medicationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate adherence data
    final adherenceData = _calculateAdherenceData(medicationId);
    
    // Don't show if no schedules
    if (adherenceData.every((v) => v < 0)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kPageHorizontalPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Adherence',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '7 Days',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Adherence Graph
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _AdherenceLinePainter(
                data: adherenceData, 
                color: colorScheme.primary,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = DateTime.now().subtract(Duration(days: 6 - i));
              final dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
              return Text(
                dayName,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          
          // Summary stats
          _buildSummaryStats(context, adherenceData),
        ],
      ),
    );
  }
  
  Widget _buildSummaryStats(BuildContext context, List<double> data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate average (excluding no-data days)
    final validDays = data.where((v) => v >= 0).toList();
    final average = validDays.isEmpty 
        ? 0.0 
        : validDays.reduce((a, b) => a + b) / validDays.length;
    
    // Count perfect days
    final perfectDays = data.where((v) => v >= 1.0).length;
    
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Avg',
            value: '${(average * 100).toInt()}%',
            color: average >= 0.8 ? Colors.green : (average >= 0.5 ? Colors.amber : Colors.red),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'Perfect',
            value: '$perfectDays days',
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
  
  /// Calculate real adherence data for last 7 days from DoseLog
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
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      
      // Count expected doses for this day
      int expectedDoses = 0;
      int takenDoses = 0;
      
      for (final schedule in schedules) {
        // Check if schedule is active on this day
        if (!schedule.daysOfWeek.contains(day.weekday)) continue;
        
        // Count times per day
        final timesPerDay = schedule.timesOfDay?.length ?? 1;
        expectedDoses += timesPerDay;
      }
      
      // Count taken doses from logs for this medication and day
      final dayLogs = doseLogBox.values.where((log) =>
          log.medicationId == medicationId &&
          log.scheduledTime.isAfter(day.subtract(const Duration(seconds: 1))) &&
          log.scheduledTime.isBefore(dayEnd));
      
      takenDoses = dayLogs.where((log) => log.action == DoseAction.taken).length;
      
      if (expectedDoses == 0) {
        adherenceData.add(-1.0); // No doses scheduled
      } else {
        adherenceData.add((takenDoses / expectedDoses).clamp(0.0, 1.0));
      }
    }
    
    return adherenceData;
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  
  final String label;
  final String value;
  final Color color;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
