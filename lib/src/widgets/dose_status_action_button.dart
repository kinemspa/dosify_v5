import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_status_badge.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';

class DoseStatusActionButton extends StatelessWidget {
  const DoseStatusActionButton({
    required this.currentStatus,
    required this.onSelect,
    required this.isActive,
    required this.compact,
    super.key,
  });

  final DoseStatus currentStatus;
  final ValueChanged<DoseStatus> onSelect;
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final disabled = !isActive;

    return PopupMenuButton<DoseStatus>(
      tooltip: 'Change status',
      onSelected: onSelect,
      itemBuilder: (context) => [
        _buildItem(context, DoseStatus.logged, enabled: !disabled),
        _buildItem(context, DoseStatus.snoozed, enabled: !disabled),
        _buildItem(context, DoseStatus.skipped, enabled: !disabled),
      ],
      child: DoseCardStatusChip(
        status: currentStatus,
        disabled: disabled,
        compact: compact,
      ),
    );
  }

  PopupMenuItem<DoseStatus> _buildItem(
    BuildContext context,
    DoseStatus status, {
    required bool enabled,
  }) {
    final visual = doseStatusVisual(context, status, disabled: !enabled);
    final label = doseStatusLabel(status, disabled: !enabled);

    return PopupMenuItem<DoseStatus>(
      value: status,
      enabled: enabled,
      child: Row(
        children: [
          Icon(visual.icon, size: kIconSizeMedium, color: visual.color),
          const SizedBox(width: kSpacingS),
          Text(label, style: bodyTextStyle(context)),
        ],
      ),
    );
  }
}
