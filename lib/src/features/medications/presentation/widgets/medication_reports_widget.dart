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
  const MedicationReportsWidget({required this.medication, super.key});

  final Medication medication;

  @override
  State<MedicationReportsWidget> createState() =>
      _MedicationReportsWidgetState();
}

class _MedicationReportsWidgetState extends State<MedicationReportsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = true; // Collapsible state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // History + Adherence
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingL,
                vertical: kSpacingM,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: kIconSizeMedium,
                    color: cs.primary,
                  ),
                  const SizedBox(width: kSpacingS),
                  Text(
                    'Reports',
                    style: cardTitleStyle(
                      context,
                    )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0 : -0.25,
                    duration: kAnimationNormal,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: kIconSizeLarge,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          AnimatedCrossFade(
            duration: kAnimationNormal,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
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
                  dividerColor: cs.surface.withValues(
                    alpha: kOpacityTransparent,
                  ),
                  labelStyle: helperTextStyle(context)?.copyWith(
                    fontSize: kFontSizeMedium,
                    fontWeight: kFontWeightSemiBold,
                  ),
                  tabs: const [
                    Tab(
                      text: 'History',
                      icon: Icon(Icons.history, size: kIconSizeMedium),
                    ),
                    Tab(
                      text: 'Adherence',
                      icon: Icon(
                        Icons.analytics_outlined,
                        size: kIconSizeMedium,
                      ),
                    ),
                  ],
                ),
                // Tab content
                SizedBox(
                  height: kMedicationReportsTabHeight,
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
    final logs =
        doseLogBox.values
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
              size: kEmptyStateIconSize,
              color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
            ),
            const SizedBox(height: kSpacingM),
            Text('No dose history', style: helperTextStyle(context)),
            const SizedBox(height: kSpacingXS),
            Text(
              'Recorded doses will appear here',
              style: helperTextStyle(
                context,
              )?.copyWith(fontSize: kFontSizeSmall),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(kSpacingS),
      itemCount: displayLogs.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: kOpacityVeryLow),
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
        iconColor = cs.tertiary;
        break;
      case DoseAction.snoozed:
        icon = Icons.snooze;
        iconColor = cs.secondary;
        break;
    }

    final displayValue = log.actualDoseValue ?? log.doseValue;
    final displayUnit = log.actualDoseUnit ?? log.doseUnit;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
      child: Row(
        children: [
          Container(
            width: kStepperButtonSize,
            height: kStepperButtonSize,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: kOpacitySubtle),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: kIconSizeSmall, color: iconColor),
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatAmount(displayValue),
                      style: bodyTextStyle(
                        context,
                      )?.copyWith(fontWeight: kFontWeightBold),
                    ),
                    const SizedBox(width: kSpacingXS),
                    Text(displayUnit, style: helperTextStyle(context)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpacingXS,
                        vertical: kSpacingXS / 2,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: kOpacitySubtle),
                        borderRadius: BorderRadius.circular(kBorderRadiusChip),
                      ),
                      child: Text(
                        log.action.name,
                        style: helperTextStyle(context, color: iconColor)
                            ?.copyWith(
                              fontSize: kFontSizeHint,
                              fontWeight: kFontWeightBold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSpacingXS),
                Row(
                  children: [
                    Text(
                      dateFormat.format(log.actionTime),
                      style: helperTextStyle(
                        context,
                      )?.copyWith(fontSize: kFontSizeSmall),
                    ),
                    const SizedBox(width: kSpacingS),
                    Text(
                      timeFormat.format(log.actionTime),
                      style: helperTextStyle(
                        context,
                      )?.copyWith(fontSize: kFontSizeSmall),
                    ),
                  ],
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: kSpacingXS),
                  Text(
                    log.notes!,
                    style: helperTextStyle(context)?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: kFontSizeSmall,
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
    final cs = Theme.of(context).colorScheme;
    final adherenceData = _calculateAdherenceData();
    final avgPct = _getAveragePercentage(adherenceData);

    // No schedules = show message
    if (adherenceData.every((v) => v < 0)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: kEmptyStateIconSize,
              color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
            ),
            const SizedBox(height: kSpacingM),
            Text('No schedule data', style: helperTextStyle(context)),
            const SizedBox(height: kSpacingXS),
            Text(
              'Create a schedule to track adherence',
              style: helperTextStyle(
                context,
              )?.copyWith(fontSize: kFontSizeSmall),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(kSpacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period label
          Row(
            children: [
              Text('Last 7 Days', style: helperTextStyle(context)),
              const Spacer(),
              Text(
                '${avgPct}% avg',
                style: bodyTextStyle(context)?.copyWith(
                  color: _getAdherenceColor(cs, avgPct),
                  fontWeight: kFontWeightSemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingL),

          // Adherence graph
          Expanded(
            child: CustomPaint(
              painter: _AdherenceLinePainter(
                data: adherenceData,
                color: cs.primary,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: kSpacingS),

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
                style: helperTextStyle(context, color: cs.onSurfaceVariant)
                    ?.copyWith(
                      fontSize: kFontSizeHint,
                      fontWeight: kFontWeightMedium,
                    ),
              );
            }),
          ),
          const SizedBox(height: kSpacingM),

          // Summary stats row
          _buildSummaryStats(context, adherenceData),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, List<double> data) {
    final cs = Theme.of(context).colorScheme;

    final validDays = data.where((v) => v >= 0).toList();
    final average = validDays.isEmpty
        ? 0.0
        : validDays.reduce((a, b) => a + b) / validDays.length;
    final perfectDays = data.where((v) => v >= 1.0).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            context,
            label: 'Average',
            value: '${(average * 100).toInt()}%',
            color: _getAdherenceColor(cs, (average * 100).toInt()),
          ),
        ),
        const SizedBox(width: kSpacingS),
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
    return Container(
      padding: kFieldContentPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: kOpacitySubtleLow),
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: helperTextStyle(context, color: color)),
          const SizedBox(width: kFieldSpacing),
          Text(
            value,
            style: bodyTextStyle(
              context,
            )?.copyWith(color: color, fontWeight: kFontWeightSemiBold),
          ),
        ],
      ),
    );
  }

  int _getAveragePercentage(List<double> data) {
    final validDays = data.where((v) => v >= 0).toList();
    if (validDays.isEmpty) return 0;
    return ((validDays.reduce((a, b) => a + b) / validDays.length) * 100)
        .toInt();
  }

  Color _getAdherenceColor(ColorScheme cs, int percentage) {
    if (percentage >= 80) return cs.primary;
    if (percentage >= 50) return cs.tertiary;
    return cs.error;
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
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));

      int expectedDoses = 0;
      int takenDoses = 0;

      for (final schedule in schedules) {
        if (!schedule.daysOfWeek.contains(day.weekday)) continue;
        final timesPerDay = schedule.timesOfDay?.length ?? 1;
        expectedDoses += timesPerDay;
      }

      final dayLogs = doseLogBox.values.where(
        (log) =>
            log.medicationId == widget.medication.id &&
            log.scheduledTime.isAfter(
              day.subtract(const Duration(seconds: 1)),
            ) &&
            log.scheduledTime.isBefore(dayEnd),
      );

      takenDoses = dayLogs
          .where((log) => log.action == DoseAction.taken)
          .length;

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
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
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
      ..strokeWidth = kAdherenceChartLineStrokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final spacing = width / (data.length - 1);

    // Draw background grid
    final gridPaint = Paint()
      ..color = color.withValues(alpha: kOpacitySubtleLow)
      ..strokeWidth = kAdherenceChartGridStrokeWidth;

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
      final y =
          height -
          (value * height * kAdherenceChartValueScale) -
          (height * kAdherenceChartVerticalPaddingFraction);

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
        colors: [
          color.withValues(alpha: kOpacityVeryLow),
          color.withValues(alpha: kOpacityFaint),
        ],
      );

      fillPaint.shader = gradient.createShader(
        Rect.fromLTWH(0, 0, width, height),
      );
      canvas.drawPath(areaPath, fillPaint);

      paint.color = color.withValues(alpha: kOpacityEmphasis);
      canvas.drawPath(linePath, paint);

      // Draw points
      for (int i = 0; i < data.length; i++) {
        final value = data[i];
        if (value < 0) continue;

        final x = i * spacing;
        final y =
            height -
            (value * height * kAdherenceChartValueScale) -
            (height * kAdherenceChartVerticalPaddingFraction);

        canvas.drawCircle(
          Offset(x, y),
          kAdherenceChartPointOuterRadius,
          Paint()
            ..color = color.withValues(alpha: kOpacityEmphasis)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(x, y),
          kAdherenceChartPointInnerRadius,
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
