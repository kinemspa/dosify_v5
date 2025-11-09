// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/calendar/dose_calendar_widget.dart';
import 'package:dosifi_v5/src/widgets/calendar/calendar_header.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';
import 'package:dosifi_v5/src/widgets/reconstitution_summary_card.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// Modern, revolutionized medication detail screen with:
/// - Hero header with gradient and key stats
/// - Interactive quick action cards
/// - Visual stock progress indicators
/// - Clean sectioned information display
/// - Responsive layout for all screen sizes
class MedicationDetailPage extends StatelessWidget {
  const MedicationDetailPage({super.key, this.medicationId, this.initial});
  final String? medicationId;
  final Medication? initial;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');
    final med =
        initial ?? (medicationId != null ? box.get(medicationId) : null);

    if (med == null) {
      return Scaffold(
        appBar: const GradientAppBar(
          title: 'Medication',
          forceBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Medication not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Medication> box, _) {
          final updatedMed = box.get(med.id) ?? med;
          return CustomScrollView(
            slivers: [
              // Combined AppBar and Stats Banner in one SliverAppBar
              SliverAppBar(
                toolbarHeight: 48,
                expandedHeight: 280, // Increased to prevent overflow
                collapsedHeight: 48,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate scroll progress (0 = expanded, 1 = collapsed)
                    final scrollProgress =
                        ((280 - constraints.maxHeight) / (280 - 48)).clamp(
                          0.0,
                          1.0,
                        );

                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF09A8BD), Color(0xFF18537D)],
                        ),
                      ),
                      child: FlexibleSpaceBar(
                        titlePadding: EdgeInsets.only(
                          left: scrollProgress > 0.5 ? 0 : 56,
                          bottom: 16,
                        ),
                        centerTitle: scrollProgress > 0.5,
                        title: Opacity(
                          opacity: scrollProgress,
                          child: Text(
                            updatedMed.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        background: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              kPageHorizontalPadding,
                              56, // Below toolbar
                              kPageHorizontalPadding,
                              8, // Reduced bottom padding to prevent overflow
                            ),
                            child: _buildStatsBannerContent(
                              context,
                              updatedMed,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    // Access parent SliverAppBar constraints to calculate scroll
                    final appBarHeight = constraints.maxHeight;
                    final scrollProgress = ((280 - appBarHeight) / (280 - 48))
                        .clamp(0.0, 1.0);

                    return Opacity(
                      opacity: 1.0 - scrollProgress, // Fade out as scrolling
                      child: const Text(
                        'Medication Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                centerTitle: true,
                actions: [
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    tooltip: 'Edit Medication',
                    onPressed: () {
                      // Navigate to appropriate edit wizard based on medication form
                      switch (updatedMed.form) {
                        case MedicationForm.tablet:
                          context.push(
                            '/medications/edit/tablet/${updatedMed.id}',
                          );
                        case MedicationForm.capsule:
                          context.push(
                            '/medications/edit/capsule/${updatedMed.id}',
                          );
                        case MedicationForm.prefilledSyringe:
                          context.push(
                            '/medications/edit/injection/pfs/${updatedMed.id}',
                          );
                        case MedicationForm.singleDoseVial:
                          context.push(
                            '/medications/edit/injection/single/${updatedMed.id}',
                          );
                        case MedicationForm.multiDoseVial:
                          context.push(
                            '/medications/edit/injection/multi/${updatedMed.id}',
                          );
                      }
                    },
                  ),
                  // Menu button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onSelected: (value) {
                      switch (value) {
                        case 'home':
                          context.go('/');
                        case 'medications':
                          context.go('/medications');
                        case 'supplies':
                          context.go('/supplies');
                        case 'schedules':
                          context.go('/schedules');
                        case 'calendar':
                          context.go('/calendar');
                        case 'reconstitution':
                          context.push('/medications/reconstitution');
                        case 'analytics':
                          context.go('/analytics');
                        case 'settings':
                          context.go('/settings');
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'home', child: Text('Home')),
                      PopupMenuItem(
                        value: 'medications',
                        child: Text('Medications'),
                      ),
                      PopupMenuItem(value: 'supplies', child: Text('Supplies')),
                      PopupMenuItem(
                        value: 'schedules',
                        child: Text('Schedules'),
                      ),
                      PopupMenuItem(value: 'calendar', child: Text('Calendar')),
                      PopupMenuItem(
                        value: 'reconstitution',
                        child: Text('Reconstitution Calculator'),
                      ),
                      PopupMenuItem(
                        value: 'analytics',
                        child: Text('Analytics'),
                      ),
                      PopupMenuItem(value: 'settings', child: Text('Settings')),
                    ],
                  ),
                ],
              ),
              // Schedule calendar
              SliverToBoxAdapter(
                child: _buildScheduleCalendar(context, updatedMed),
              ),
              // Active Vial Card (for MDV only) - moved higher
              if (updatedMed.form == MedicationForm.multiDoseVial)
                SliverToBoxAdapter(
                  child: _buildActiveVialCard(context, updatedMed),
                ),
              // Main content sections
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildModernSections(context, updatedMed),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Compact stats banner (no SliverAppBar, just a Container)
  /// Stats banner content (without outer container/gradient, used inside FlexibleSpace)
  Widget _buildStatsBannerContent(BuildContext context, Medication med) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication name - centered
            Center(
              child: Text(
                med.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: kFontWeightBold,
                  fontSize: 24,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: kCardInnerSpacing),

            // Row 1: Manufacturer and Type badge
            Row(
              children: [
                if (med.manufacturer != null && med.manufacturer!.isNotEmpty)
                  Expanded(
                    child: Text(
                      med.manufacturer!,
                      style: helperTextStyle(context)?.copyWith(
                        color: Colors.white.withValues(
                          alpha: kOpacityMediumHigh,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kCardInnerSpacing,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: kBorderWidthThin,
                    ),
                  ),
                  child: Text(
                    _formLabel(med.form),
                    style: helperTextStyle(context)?.copyWith(
                      color: Colors.white,
                      fontWeight: kFontWeightSemiBold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kCardInnerSpacing),

            // Row 2: Strength and Stock (2-column grid)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: kIconSizeSmall,
                            color: Colors.white.withValues(
                              alpha: kOpacityMedium,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Strength',
                            style: helperTextStyle(context)?.copyWith(
                              color: Colors.white.withValues(
                                alpha: kOpacityMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatNumber(med.strengthValue)} ${_unitLabel(med.strengthUnit)}',
                        style: bodyTextStyle(context)?.copyWith(
                          color: Colors.white,
                          fontWeight: kFontWeightSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: kPageHorizontalPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: kIconSizeSmall,
                            color: Colors.white.withValues(
                              alpha: kOpacityMedium,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _stockRemainingLabel(med.stockUnit),
                            style: helperTextStyle(context)?.copyWith(
                              color: Colors.white.withValues(
                                alpha: kOpacityMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatNumber(med.stockValue)}',
                        style: bodyTextStyle(context)?.copyWith(
                          color: Colors.white,
                          fontWeight: kFontWeightSemiBold,
                        ),
                      ),
                      if (med.lowStockEnabled &&
                          med.lowStockThreshold != null &&
                          med.stockValue <= med.lowStockThreshold!)
                        Text(
                          'Alert at ${_formatNumber(med.lowStockThreshold!)}',
                          style: helperTextStyle(context)?.copyWith(
                            color: Colors.orange.shade300,
                            fontWeight: kFontWeightSemiBold,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: kCardInnerSpacing),

            // Row 3: Expiry and Storage (2-column grid)
            Row(
              children: [
                Expanded(
                  child: med.expiry != null
                      ? Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: kIconSizeSmall,
                              color: Colors.white.withValues(
                                alpha: kOpacityMedium,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                DateFormat('MMM d, y').format(med.expiry!),
                                style: helperTextStyle(context)?.copyWith(
                                  color: Colors.white.withValues(
                                    alpha: kOpacityHigh,
                                  ),
                                  fontWeight: kFontWeightMedium,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: kPageHorizontalPadding),
                Expanded(
                  child:
                      (med.storageLocation != null &&
                          med.storageLocation!.isNotEmpty)
                      ? Row(
                          children: [
                            if (med.requiresRefrigeration)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.ac_unit,
                                  size: kIconSizeSmall,
                                  color: Colors.blue.shade200,
                                ),
                              ),
                            Icon(
                              Icons.location_on,
                              size: kIconSizeSmall,
                              color: Colors.white.withValues(
                                alpha: kOpacityMedium,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                med.storageLocation!,
                                style: helperTextStyle(context)?.copyWith(
                                  color: Colors.white.withValues(
                                    alpha: kOpacityHigh,
                                  ),
                                  fontWeight: kFontWeightMedium,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: kSectionSpacing),

            // Row 4: Dose tracking metrics container
            Container(
              padding: const EdgeInsets.all(kCardInnerSpacing),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: kStandardBorderRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: kIconSizeSmall,
                        color: Colors.white.withValues(alpha: kOpacityHigh),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Next dose in 4h 23m',
                        style: helperTextStyle(context)?.copyWith(
                          color: Colors.white.withValues(alpha: kOpacityHigh),
                          fontWeight: kFontWeightSemiBold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kCardInnerSpacing,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(
                            kBorderRadiusMedium,
                          ),
                          border: Border.all(
                            color: Colors.green.shade300,
                            width: kBorderWidthThin,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: kIconSizeSmall,
                              color: Colors.green.shade200,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '92% adherence',
                              style: helperTextStyle(context)?.copyWith(
                                color: Colors.white,
                                fontWeight: kFontWeightSemiBold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kCardInnerSpacing),
                  Row(
                    children: [
                      Text(
                        'Recent:',
                        style: helperTextStyle(context)?.copyWith(
                          color: Colors.white.withValues(alpha: kOpacityMedium),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ..._buildDoseTimeline(),
                      const Spacer(),
                      Text(
                        '~14 days left',
                        style: helperTextStyle(context)?.copyWith(
                          color: Colors.orange.shade200,
                          fontWeight: kFontWeightSemiBold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        // Tiny refill button bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: FilledButton.tonalIcon(
            onPressed: () => _showRefillDialog(context, med),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 14),
            label: Text(
              'Refill',
              style: helperTextStyle(
                context,
              )?.copyWith(fontWeight: kFontWeightSemiBold),
            ),
          ),
        ),
      ],
    );
  }

  /// Schedule calendar row showing active schedules
  Widget _buildScheduleCalendar(BuildContext context, Medication med) {
    final schedulesBox = Hive.box<Schedule>('schedules');
    final relatedSchedules = schedulesBox.values
        .where((s) => s.medicationId == med.id)
        .toList();

    if (relatedSchedules.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    // Build a set of days that have schedules
    final Set<int> activeDays = {};
    final Map<int, int> earliestMinutePerDay = {};

    for (final schedule in relatedSchedules) {
      activeDays.addAll(schedule.daysOfWeek);

      // Find earliest time for each day
      final minutesToCheck = schedule.hasMultipleTimes
          ? schedule.timesOfDay!
          : [schedule.minutesOfDay];

      final earliestMinute = minutesToCheck.reduce((a, b) => a < b ? a : b);

      for (final dayNum in schedule.daysOfWeek) {
        final currentEarliest = earliestMinutePerDay[dayNum];
        if (currentEarliest == null || earliestMinute < currentEarliest) {
          earliestMinutePerDay[dayNum] = earliestMinute;
        }
      }
    }

    // Day labels: Sun(7), Mon(1), Tue(2), Wed(3), Thu(4), Fri(5), Sat(6)
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final dayNums = [7, 1, 2, 3, 4, 5, 6];
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${relatedSchedules.length} Active Schedule${relatedSchedules.length == 1 ? '' : 's'}',
                    style: bodyTextStyle(
                      context,
                    )?.copyWith(fontWeight: kFontWeightSemiBold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Horizontal day boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final dayLabel = dayLabels[index];
                  final dayNum = dayNums[index];
                  final hasSchedule = activeDays.contains(dayNum);
                  final isToday = dayNum == today;
                  final earliestMinute = earliestMinutePerDay[dayNum];

                  // Format time compactly (e.g., "9a" or "12p")
                  String? timeText;
                  if (earliestMinute != null) {
                    final hour = earliestMinute ~/ 60;
                    final isPm = hour >= 12;
                    final displayHour = hour == 0
                        ? 12
                        : (hour > 12 ? hour - 12 : hour);
                    timeText = '$displayHour${isPm ? 'pm' : 'am'}';
                  }

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 48,
                      decoration: BoxDecoration(
                        color: hasSchedule
                            ? theme.colorScheme.primary.withOpacity(0.15)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isToday
                              ? theme.colorScheme.primary
                              : (hasSchedule
                                    ? theme.colorScheme.primary.withOpacity(0.3)
                                    : theme.colorScheme.outlineVariant),
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: bodyTextStyle(context)?.copyWith(
                              color: hasSchedule
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isToday
                                  ? kFontWeightBold
                                  : (hasSchedule
                                        ? kFontWeightSemiBold
                                        : kFontWeightMedium),
                              fontSize: 14,
                            ),
                          ),
                          if (timeText != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              timeText,
                              style: helperTextStyle(context)?.copyWith(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.7,
                                ),
                                fontSize: 10,
                                fontWeight: kFontWeightMedium,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Active Vial Card for Multi-Dose Vials
  Widget _buildActiveVialCard(BuildContext context, Medication med) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SectionFormCard(
        neutral: true,
        title: 'Active Vial (Current Dose Tracking)',
        children: [
          // Info banner explaining active vial
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Medicine being drawn from for each injection',
                    style: helperTextStyle(context),
                  ),
                ),
              ],
            ),
          ),
          // Show current volume remaining in active vial
          if (med.containerVolumeMl != null && med.containerVolumeMl! > 0)
            buildDetailInfoRow(
              context,
              label: 'Volume Remaining',
              value:
                  '${_formatNumber(med.stockValue)} / ${_formatNumber(med.containerVolumeMl!)} mL',
              highlighted: true,
              onTap: null,
            ),
          if (med.activeVialBatchNumber != null &&
              med.activeVialBatchNumber!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Batch Number',
              value: med.activeVialBatchNumber!,
              onTap: null,
            ),
          if (med.activeVialStorageLocation != null &&
              med.activeVialStorageLocation!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Storage Location',
              value: med.activeVialStorageLocation!,
              onTap: null,
            ),
          if (med.activeVialRequiresRefrigeration)
            buildDetailInfoRow(
              context,
              label: 'Storage Condition',
              value: 'Refrigerated (2-8°C)',
              onTap: null,
            ),
          if (med.activeVialRequiresFreezer)
            buildDetailInfoRow(
              context,
              label: 'Storage Condition',
              value: 'Frozen',
              onTap: null,
            ),
          if (med.activeVialLightSensitive)
            buildDetailInfoRow(
              context,
              label: 'Light Protection',
              value: 'Protect from light',
              onTap: null,
            ),
          if (med.activeVialLowStockMl != null && med.activeVialLowStockMl! > 0)
            buildDetailInfoRow(
              context,
              label: 'Low Stock Threshold',
              value: '${_formatNumber(med.activeVialLowStockMl!)} mL',
              onTap: null,
            ),
        ],
      ),
    );
  }

  /// Quick action cards for common tasks
  /// Modern information sections
  List<Widget> _buildModernSections(BuildContext context, Medication med) {
    return [
      // Medication Information
      SectionFormCard(
        neutral: true,
        title: 'Medication Information',
        children: [
          buildDetailInfoRow(
            context,
            label: 'Name',
            value: med.name,
            onTap: () => _editName(context, med),
          ),
          if (med.manufacturer != null && med.manufacturer!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Manufacturer',
              value: med.manufacturer!,
              onTap: () => _editManufacturer(context, med),
            ),
          if (med.batchNumber != null && med.batchNumber!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Batch Number',
              value: med.batchNumber!,
              onTap: () => _editBatchNumber(context, med),
            ),
          if (med.description != null && med.description!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Description',
              value: med.description!,
              maxLines: 3,
              onTap: () => _editDescription(context, med),
            ),
        ],
      ),
      const SizedBox(height: 16),

      // Storage & Handling
      SectionFormCard(
        neutral: true,
        title: 'Storage & Handling',
        children: [
          if (med.expiry != null)
            buildDetailInfoRow(
              context,
              label: 'Expiry Date',
              value: DateFormat('MMMM d, y').format(med.expiry!),
              warning: _isExpiringSoon(med.expiry!),
              onTap: () => _editExpiry(context, med),
            ),
          if (med.storageLocation != null && med.storageLocation!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Location',
              value: med.storageLocation!,
              onTap: () => _editStorageLocation(context, med),
            ),
          if (med.requiresRefrigeration)
            buildDetailInfoRow(
              context,
              label: 'Temperature',
              value: 'Refrigerated (2-8°C)',
              onTap: null,
            ),
          // MDV-specific storage conditions for active vial
          if (med.form == MedicationForm.multiDoseVial ||
              med.form == MedicationForm.singleDoseVial) ...[
            if (med.activeVialRequiresFreezer)
              buildDetailInfoRow(
                context,
                label: 'Active Vial',
                value: 'Frozen (Active Vial)',
                onTap: null,
              ),
            if (med.activeVialLightSensitive)
              buildDetailInfoRow(
                context,
                label: 'Light (Active)',
                value: 'Protect from light',
                onTap: null,
              ),
          ],
          if (med.storageInstructions != null &&
              med.storageInstructions!.isNotEmpty)
            buildDetailInfoRow(
              context,
              label: 'Special Instructions',
              value: med.storageInstructions!,
              maxLines: 3,
              onTap: () => _editStorageInstructions(context, med),
            ),
        ],
      ),

      // Multi-Dose Vial: Reconstitution Information (Wizard-style summary)
      if (med.form == MedicationForm.multiDoseVial &&
          med.strengthValue > 0 &&
          (med.containerVolumeMl != null || med.perMlValue != null)) ...[
        const SizedBox(height: 16),
        Center(
          child: Stack(
            children: [
              ReconstitutionSummaryCard(
                strengthValue: med.strengthValue,
                strengthUnit: _unitLabel(med.strengthUnit),
                medicationName: med.name,
                containerVolumeMl: med.containerVolumeMl,
                perMlValue: med.perMlValue,
                volumePerDose: med.volumePerDose,
                reconFluidName:
                    'Bacteriostatic Water', // TODO: Add to medication model
                syringeSizeMl: 3.0, // TODO: Add to medication model
              ),
              // Edit button positioned at top-right
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    // Open reconstitution calculator dialog
                    final result =
                        await showModalBottomSheet<ReconstitutionResult>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ReconstitutionCalculatorDialog(
                            initialStrengthValue: med.strengthValue,
                            unitLabel: _unitLabel(med.strengthUnit),
                            initialDoseValue: med.volumePerDose,
                            initialVialSize: med.containerVolumeMl,
                          ),
                        );

                    if (result != null && context.mounted) {
                      // Update medication with new reconstitution values
                      final updatedMed = med.copyWith(
                        containerVolumeMl: result.solventVolumeMl,
                        perMlValue: result.perMlConcentration,
                        volumePerDose:
                            result.recommendedUnits /
                            100, // Convert units back to mL
                      );

                      // Save directly to Hive
                      final box = await Hive.openBox<Medication>('medications');
                      await box.put(updatedMed.id, updatedMed);
                    }
                  },
                  tooltip: 'Edit Reconstitution',
                ),
              ),
            ],
          ),
        ),
      ],

      // Multi-Dose Vial: Backup Vials (Sealed Stock - can be reconstituted)
      if (med.form == MedicationForm.multiDoseVial) ...[
        const SizedBox(height: 16),
        SectionFormCard(
          neutral: true,
          title: 'Sealed Vials in Stock',
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Backup stock that can be reconstituted to become active vial',
                      style: helperTextStyle(context),
                    ),
                  ),
                ],
              ),
            ),
            // Show count of sealed vials
            buildDetailInfoRow(
              context,
              label: 'Vials in Stock',
              value: '${_formatNumber(med.stockValue)} vials',
              highlighted: true,
              onTap: null,
            ),
            if (med.backupVialsExpiry != null)
              buildDetailInfoRow(
                context,
                label: 'Expiry Date',
                value: DateFormat('MMMM d, y').format(med.backupVialsExpiry!),
                warning: _isExpiringSoon(med.backupVialsExpiry!),
                onTap: null,
              ),
            if (med.backupVialsBatchNumber != null &&
                med.backupVialsBatchNumber!.isNotEmpty)
              buildDetailInfoRow(
                context,
                label: 'Batch Number',
                value: med.backupVialsBatchNumber!,
                onTap: null,
              ),
            if (med.backupVialsStorageLocation != null &&
                med.backupVialsStorageLocation!.isNotEmpty)
              buildDetailInfoRow(
                context,
                label: 'Storage Location',
                value: med.backupVialsStorageLocation!,
                onTap: null,
              ),
            if (med.backupVialsRequiresRefrigeration)
              buildDetailInfoRow(
                context,
                label: 'Storage Condition',
                value: 'Refrigerated (2-8°C)',
                onTap: null,
              ),
            if (med.backupVialsRequiresFreezer)
              buildDetailInfoRow(
                context,
                label: 'Storage Condition',
                value: 'Frozen',
                onTap: null,
              ),
            if (med.backupVialsLightSensitive)
              buildDetailInfoRow(
                context,
                label: 'Light Protection',
                value: 'Protect from light',
                onTap: null,
              ),
          ],
        ),
      ],

      // Dose Calendar Section
      const SizedBox(height: 16),
      SectionFormCard(
        neutral: true,
        title: 'Dose Calendar',
        children: [
          SizedBox(
            height: 400,
            child: DoseCalendarWidget(
              variant: CalendarVariant.compact,
              defaultView: CalendarView.week,
              medicationId: med.id,
            ),
          ),
        ],
      ),

      if (med.notes != null && med.notes!.isNotEmpty) ...[
        const SizedBox(height: 16),
        SectionFormCard(
          neutral: true,
          title: 'Notes',
          children: [
            buildDetailInfoRow(
              context,
              label: '',
              value: med.notes!,
              maxLines: 10,
              onTap: null,
            ),
          ],
        ),
      ],
    ];
  }

  bool _isExpiringSoon(DateTime expiry) {
    final now = DateTime.now();
    final daysUntilExpiry = expiry.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  /// Build mini dose timeline (last 5 doses)
  List<Widget> _buildDoseTimeline() {
    // TODO: Replace with real dose data from schedule history
    // This is placeholder data showing last 5 doses
    final doses = [
      {'taken': true, 'time': '2h ago'},
      {'taken': true, 'time': '8h ago'},
      {'taken': true, 'time': '14h ago'},
      {'taken': false, 'time': '20h ago'}, // Missed dose
      {'taken': true, 'time': '1d ago'},
    ];

    return doses.map((dose) {
      final taken = dose['taken'] as bool;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Tooltip(
          message: dose['time'] as String,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: taken
                  ? Colors.green.shade300
                  : Colors.red.shade300.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Show refill dialog with toggle for refill mode
  Future<void> _showRefillDialog(BuildContext context, Medication med) async {
    bool refillToInitial = true; // true = refill to initial, false = add on top
    double? refillAmount;
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Refill Medication'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock: ${_formatNumber(med.stockValue)} ${_stockUnitLabel(med.stockUnit)}',
                      style: bodyTextStyle(context),
                    ),
                    if (med.initialStockValue != null)
                      Text(
                        'Initial Amount: ${_formatNumber(med.initialStockValue!)} ${_stockUnitLabel(med.stockUnit)}',
                        style: helperTextStyle(context),
                      ),
                    const SizedBox(height: 16),

                    // Refill mode explanation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Refill Mode',
                                style: bodyTextStyle(
                                  context,
                                )?.copyWith(fontWeight: kFontWeightSemiBold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Toggle ON: Reset stock to initial amount\n• Toggle OFF: Add amount to current stock',
                            style: helperTextStyle(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Refill to Initial Amount'),
                      value: refillToInitial,
                      onChanged: (bool value) {
                        setState(() {
                          refillToInitial = value;
                          controller.clear();
                        });
                      },
                    ),

                    // Amount input (always shown, but disabled when refilling to initial)
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      enabled: !refillToInitial,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: refillToInitial
                            ? 'Amount (Auto-calculated)'
                            : 'Amount to Add',
                        hintText: refillToInitial
                            ? (med.initialStockValue != null
                                  ? _formatNumber(med.initialStockValue!)
                                  : 'N/A')
                            : 'Enter amount',
                        suffixText: _stockUnitLabel(med.stockUnit),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        refillAmount = double.tryParse(value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirm Refill'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && context.mounted) {
      final box = Hive.box<Medication>('medications');
      double newStockValue;

      if (refillToInitial) {
        // Refill to initial amount
        newStockValue = med.initialStockValue ?? med.stockValue;
      } else {
        // Add to current stock
        if (refillAmount == null || refillAmount! <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid amount')),
          );
          return;
        }
        newStockValue = med.stockValue + refillAmount!;
      }

      await box.put(med.id, med.copyWith(stockValue: newStockValue));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              refillToInitial
                  ? 'Stock refilled to ${_formatNumber(newStockValue)} ${_stockUnitLabel(med.stockUnit)}'
                  : 'Added ${_formatNumber(refillAmount!)} ${_stockUnitLabel(med.stockUnit)} (Total: ${_formatNumber(newStockValue)})',
            ),
          ),
        );
      }
    }
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

  /// Edit name dialog
  Future<void> _editName(BuildContext context, Medication med) async {
    final controller = TextEditingController(text: med.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medication Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: buildFieldDecoration(
                context,
                hint: 'Medication name',
              ),
              onSubmitted: (_) => Navigator.of(context).pop(controller.text),
            ),
            const SizedBox(height: 8),
            buildHelperText(
              context,
              'Enter the medication name',
              fullWidth: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && result != med.name) {
      final box = Hive.box<Medication>('medications');
      await box.put(med.id, med.copyWith(name: result.trim()));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Name updated')));
      }
    }
  }

  /// Edit manufacturer dialog
  Future<void> _editManufacturer(BuildContext context, Medication med) async {
    final controller = TextEditingController(text: med.manufacturer ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Manufacturer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: buildFieldDecoration(context, hint: 'e.g., GSK'),
              onSubmitted: (_) => Navigator.of(context).pop(controller.text),
            ),
            const SizedBox(height: 8),
            buildHelperText(
              context,
              'Brand or company name (optional)',
              fullWidth: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final box = Hive.box<Medication>('medications');
      await box.put(
        med.id,
        med.copyWith(
          manufacturer: result.trim().isEmpty ? null : result.trim(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Manufacturer updated')));
      }
    }
  }

  /// Edit strength dialog
  /// Edit description dialog
  Future<void> _editDescription(BuildContext context, Medication med) async {
    final controller = TextEditingController(text: med.description ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: buildFieldDecoration(
                context,
                hint: 'Notes or description',
              ),
            ),
            const SizedBox(height: 8),
            buildHelperText(
              context,
              'Optional notes about this medication',
              fullWidth: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final box = Hive.box<Medication>('medications');
      await box.put(
        med.id,
        med.copyWith(description: result.trim().isEmpty ? null : result.trim()),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Description updated')));
      }
    }
  }

  /// Edit storage location dialog
  Future<void> _editStorageLocation(
    BuildContext context,
    Medication med,
  ) async {
    final controller = TextEditingController(text: med.storageLocation ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Storage Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: buildFieldDecoration(
                context,
                hint: 'e.g., Medicine cabinet',
              ),
              onSubmitted: (_) => Navigator.of(context).pop(controller.text),
            ),
            const SizedBox(height: 8),
            buildHelperText(
              context,
              'Where you keep the medication',
              fullWidth: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final box = Hive.box<Medication>('medications');
      await box.put(
        med.id,
        med.copyWith(
          storageLocation: result.trim().isEmpty ? null : result.trim(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage location updated')),
        );
      }
    }
  }

  /// Edit expiry date dialog
  Future<void> _editExpiry(BuildContext context, Medication med) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      initialDate: med.expiry ?? now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      final box = Hive.box<Medication>('medications');
      await box.put(med.id, med.copyWith(expiry: picked));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Expiry date updated')));
      }
    }
  }

  /// Edit batch number dialog
  Future<void> _editBatchNumber(BuildContext context, Medication med) async {
    final controller = TextEditingController(text: med.batchNumber ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Batch Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: buildFieldDecoration(context, hint: 'Optional'),
              onSubmitted: (_) => Navigator.of(context).pop(controller.text),
            ),
            const SizedBox(height: 8),
            buildHelperText(
              context,
              'Batch number from the packaging',
              fullWidth: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final box = Hive.box<Medication>('medications');
      await box.put(
        med.id,
        med.copyWith(batchNumber: result.trim().isEmpty ? null : result.trim()),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Batch number updated')));
      }
    }
  }

  /// Edit storage instructions dialog
  Future<void> _editStorageInstructions(
    BuildContext context,
    Medication med,
  ) async {
    final controller = TextEditingController(
      text: med.storageInstructions ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Storage Instructions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: buildFieldDecoration(
                context,
                hint: 'e.g., Keep upright, protect from light',
              ),
              onSubmitted: (_) => Navigator.of(context).pop(controller.text),
            ),
            const SizedBox(height: 8),
            buildHelperText(
              context,
              'Special handling or storage requirements',
              fullWidth: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final box = Hive.box<Medication>('medications');
      await box.put(
        med.id,
        med.copyWith(
          storageInstructions: result.trim().isEmpty ? null : result.trim(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage instructions updated')),
        );
      }
    }
  }

  /// Delete medication with cascade delete of linked schedules
}

// Helper functions
String _formLabel(MedicationForm form) => switch (form) {
  MedicationForm.tablet => 'Tablet',
  MedicationForm.capsule => 'Capsule',
  MedicationForm.prefilledSyringe => 'Pre-Filled Syringe',
  MedicationForm.singleDoseVial => 'Single Dose Vial',
  MedicationForm.multiDoseVial => 'Multi Dose Vial',
};

String _unitLabel(Unit u) => switch (u) {
  Unit.mcg => 'mcg',
  Unit.mg => 'mg',
  Unit.g => 'g',
  Unit.units => 'units',
  Unit.mcgPerMl => 'mcg/mL',
  Unit.mgPerMl => 'mg/mL',
  Unit.gPerMl => 'g/mL',
  Unit.unitsPerMl => 'units/mL',
};

String _stockRemainingLabel(StockUnit unit) => switch (unit) {
  StockUnit.tablets => 'Tablets Remaining',
  StockUnit.capsules => 'Capsules Remaining',
  StockUnit.preFilledSyringes => 'Syringes Remaining',
  StockUnit.singleDoseVials => 'Vials Remaining',
  StockUnit.multiDoseVials => 'Vials Remaining',
  StockUnit.mcg => 'mcg Remaining',
  StockUnit.mg => 'mg Remaining',
  StockUnit.g => 'g Remaining',
};

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}
