// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

/// Comprehensive reports widget with tabs for History, Adherence, and future analytics
/// Replaces DoseHistoryWidget with expanded functionality
class MedicationReportsWidget extends StatefulWidget {
  const MedicationReportsWidget({
    required this.medication,
    super.key,
  });

  final Medication medication;

  @override
  State<MedicationReportsWidget> createState() => _MedicationReportsWidgetState();
}

class _MedicationReportsWidgetState extends State<MedicationReportsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = true;  // Collapsible state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // History + Adherence
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      decoration: buildStandardCardDecoration(context: context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsible header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Reports', style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  )),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 24,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tab bar
                TabBar(
                  controller: _tabController,
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicatorColor: cs.primary,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'History', icon: Icon(Icons.history, size: 18)),
                    Tab(text: 'Adherence', icon: Icon(Icons.analytics_outlined, size: 18)),
                  ],
                ),
                // Tab content
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHistoryTab(context),
                      _buildAdherenceTab(context),
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

  Widget _buildHistoryTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doseLogBox = Hive.box<DoseLog>('dose_logs');

    // Get dose logs for this medication (limit to 50 for performance)
    final logs = doseLogBox.values
        .where((log) => log.medicationId == widget.medication.id)
        .toList()
      ..sort((a, b) => b.actionTime.compareTo(a.actionTime));
    
    final displayLogs = logs.take(50).toList();

    if (displayLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text('No dose history', style: helperTextStyle(context)),
            const SizedBox(height: 4),
            Text(
              'Recorded doses will appear here',
              style: helperTextStyle(context)?.copyWith(fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: displayLogs.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final log = displayLogs[index];
        return _buildDoseLogItem(context, log);
      },
    );
  }

  Widget _buildDoseLogItem(BuildContext context, DoseLog log) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final IconData icon;
    final Color iconColor;
    switch (log.action) {
      case DoseAction.taken:
        icon = Icons.check_circle_outline;
        iconColor = cs.primary;
        break;
      case DoseAction.skipped:
        icon = Icons.cancel_outlined;
        iconColor = Colors.orange;
        break;
      case DoseAction.snoozed:
        icon = Icons.snooze;
        iconColor = Colors.amber;
        break;
    }

    final displayValue = log.actualDoseValue ?? log.doseValue;
    final displayUnit = log.actualDoseUnit ?? log.doseUnit;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatAmount(displayValue),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(displayUnit, style: helperTextStyle(context)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.action.name,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateFormat.format(log.actionTime),
                      style: helperTextStyle(context)?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeFormat.format(log.actionTime),
                      style: helperTextStyle(context)?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.notes!,
                    style: helperTextStyle(context)?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceTab(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final adherenceData = _calculateAdherenceData();

    // No schedules = show message
    if (adherenceData.every((v) => v < 0)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text('No schedule data', style: helperTextStyle(context)),
            const SizedBox(height: 4),
            Text(
              'Create a schedule to track adherence',
              style: helperTextStyle(context)?.copyWith(fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period label
          Row(
            children: [
              Text('Last 7 Days', style: helperTextStyle(context)),
              const Spacer(),
              Text(
                '${_getAveragePercentage(adherenceData)}% avg',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getAdherenceColor(_getAveragePercentage(adherenceData)),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Adherence graph
          Expanded(
            child: CustomPaint(
              painter: _AdherenceLinePainter(data: adherenceData, color: cs.primary),
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
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Summary stats row
          _buildSummaryStats(context, adherenceData),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, List<double> data) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final validDays = data.where((v) => v >= 0).toList();
    final average = validDays.isEmpty ? 0.0 : validDays.reduce((a, b) => a + b) / validDays.length;
    final perfectDays = data.where((v) => v >= 1.0).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            context,
            label: 'Average',
            value: '${(average * 100).toInt()}%',
            color: _getAdherenceColor((average * 100).toInt()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            context,
            label: 'Perfect',
            value: '$perfectDays days',
            color: cs.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
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
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
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

  int _getAveragePercentage(List<double> data) {
    final validDays = data.where((v) => v >= 0).toList();
    if (validDays.isEmpty) return 0;
    return ((validDays.reduce((a, b) => a + b) / validDays.length) * 100).toInt();
  }

  Color _getAdherenceColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  List<double> _calculateAdherenceData() {
    final now = DateTime.now();
    final doseLogBox = Hive.box<DoseLog>('dose_logs');
    final scheduleBox = Hive.box<Schedule>('schedules');

    final schedules = scheduleBox.values
        .where((s) => s.medicationId == widget.medication.id && s.active)
        .toList();

    if (schedules.isEmpty) return List.filled(7, -1.0);

    final adherenceData = <double>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));

      int expectedDoses = 0;
      int takenDoses = 0;

      for (final schedule in schedules) {
        if (!schedule.daysOfWeek.contains(day.weekday)) continue;
        final timesPerDay = schedule.timesOfDay?.length ?? 1;
        expectedDoses += timesPerDay;
      }

      final dayLogs = doseLogBox.values.where((log) =>
          log.medicationId == widget.medication.id &&
          log.scheduledTime.isAfter(day.subtract(const Duration(seconds: 1))) &&
          log.scheduledTime.isBefore(dayEnd));

      takenDoses = dayLogs.where((log) => log.action == DoseAction.taken).length;

      if (expectedDoses == 0) {
        adherenceData.add(-1.0);
      } else {
        adherenceData.add((takenDoses / expectedDoses).clamp(0.0, 1.0));
      }
    }

    return adherenceData;
  }

  String _formatAmount(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
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

    // Build paths
    final linePath = Path();
    final areaPath = Path();
    bool hasStarted = false;

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      if (value < 0) continue;

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
      areaPath.lineTo((data.length - 1) * spacing, height);
      areaPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.05)],
      );

      fillPaint.shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height));
      canvas.drawPath(areaPath, fillPaint);

      paint.color = color.withValues(alpha: 0.9);
      canvas.drawPath(linePath, paint);

      // Draw points
      for (int i = 0; i < data.length; i++) {
        final value = data[i];
        if (value < 0) continue;

        final x = i * spacing;
        final y = height - (value * height * 0.8) - (height * 0.1);

        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()
            ..color = color.withValues(alpha: 0.9)
            ..style = PaintingStyle.fill,
        );
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
