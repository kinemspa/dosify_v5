import 'package:flutter/material.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/widgets/unified_status_badge.dart';

class EntryActionLegendRow extends StatelessWidget {
  const EntryActionLegendRow({
    super.key,
    this.actions = const [
      EntryAction.logged,
      EntryAction.skipped,
      EntryAction.snoozed,
    ],
    this.includeInventory = false,
    this.showHelp = false,
  });

  final List<EntryAction> actions;
  final bool includeInventory;
  final bool showHelp;

  String _label(EntryAction action) {
    return switch (action) {
      EntryAction.logged => 'Logged',
      EntryAction.skipped => 'Skipped',
      EntryAction.snoozed => 'Snoozed',
    };
  }

  void _showLegendHelp(BuildContext context) {
    final inventoryLine = includeInventory
        ? '\n\nInventory: stock changes (adds, adjustments, ad-hoc entry stock changes).'
        : '';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Legend', style: dialogTitleTextStyle(context)),
          content: Text(
            'These badges show what each activity item represents:\n\n'
            'Taken: entry recorded as taken.\n'
            'Skipped: entry recorded as skipped.\n'
            'Snoozed: entry postponed.'
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
            final spec = entryActionVisualSpec(context, action);
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
