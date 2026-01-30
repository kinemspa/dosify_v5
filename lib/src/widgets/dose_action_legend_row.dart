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
  });

  final List<DoseAction> actions;
  final bool includeInventory;

  String _label(DoseAction action) {
    return switch (action) {
      DoseAction.taken => 'Taken',
      DoseAction.skipped => 'Skipped',
      DoseAction.snoozed => 'Snoozed',
    };
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

    return Wrap(
      spacing: kSpacingS,
      runSpacing: kSpacingS,
      children: badges,
    );
  }
}
