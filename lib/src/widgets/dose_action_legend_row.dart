import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/widgets/unified_status_badge.dart';

class DoseActionLegendRow extends StatelessWidget {
  const DoseActionLegendRow({
    super.key,
    this.actions = const [
      DoseAction.taken,
      DoseAction.skipped,
      DoseAction.snoozed,
    ],
    this.includeInventory = false,
    this.showHelp = false,
  });

  final List<DoseAction> actions;
  final bool includeInventory;
  final bool showHelp;

  String _label(DoseAction action) {
    return switch (action) {
      DoseAction.taken => 'Taken',
      DoseAction.skipped => 'Skipped',
      DoseAction.snoozed => 'Snoozed',
    };
  }

  void _showLegendHelp(BuildContext context) {
    final inventoryLine = includeInventory
        ? '\n\nInventory: stock changes (adds, adjustments, ad-hoc dose stock changes).'
        : '';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Legend', style: dialogTitleTextStyle(context)),
          content: Text(
            'These badges show what each activity item represents:\n\n'
            'Taken: dose recorded as taken.\n'
            'Skipped: dose recorded as skipped.\n'
            'Snoozed: dose postponed.'
            '$inventoryLine',
            style: dialogContentTextStyle(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final badges = <Widget>[
      for (final action in actions) ...[
        Builder(
          builder: (context) {
            final spec = doseActionVisualSpec(context, action);
            return UnifiedStatusBadge(
              label: _label(action),
              icon: spec.icon,
              color: spec.color,
              dense: true,
            );
          },
        ),
      ],
      if (includeInventory)
        UnifiedStatusBadge(
          label: 'Inventory',
          icon: Icons.inventory_2_rounded,
          color: cs.onSurfaceVariant,
          dense: true,
        ),
    ];

    final wrap = Wrap(
      spacing: kSpacingS,
      runSpacing: kSpacingS,
      children: badges,
    );

    if (!showHelp) return wrap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Legend',
              style: smallHelperTextStyle(
                context,
                color: cs.onSurfaceVariant.withValues(alpha: kOpacityMedium),
              ),
            ),
            const SizedBox(width: kSpacingXS),
            IconButton(
              tooltip: 'What do these mean?',
              constraints: kTightIconButtonConstraints,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () => _showLegendHelp(context),
              icon: Icon(
                Icons.info_outline_rounded,
                size: kIconSizeSmall,
                color:
                    cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
              ),
            ),
          ],
        ),
        const SizedBox(height: kSpacingS),
        wrap,
      ],
    );
  }
}
