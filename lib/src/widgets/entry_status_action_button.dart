import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/widgets/entry_status_badge.dart';
import 'package:dosifi_v5/src/widgets/entry_status_ui.dart';

class EntryStatusActionButton extends StatelessWidget {
  const EntryStatusActionButton({
    required this.currentStatus,
    required this.onSelect,
    required this.isActive,
    required this.compact,
    super.key,
  });

  final EntryStatus currentStatus;
  final ValueChanged<EntryStatus> onSelect;
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final disabled = !isActive;

    return PopupMenuButton<EntryStatus>(
      tooltip: 'Change status',
      onSelected: onSelect,
      itemBuilder: (context) => [
        _buildItem(context, EntryStatus.logged, enabled: !disabled),
        _buildItem(context, EntryStatus.snoozed, enabled: !disabled),
        _buildItem(context, EntryStatus.skipped, enabled: !disabled),
      ],
      child: EntryCardStatusChip(
        status: currentStatus,
        disabled: disabled,
        compact: compact,
      ),
    );
  }

  PopupMenuItem<EntryStatus> _buildItem(
    BuildContext context,
    EntryStatus status, {
    required bool enabled,
  }) {
    final visual = entryStatusVisual(context, status, disabled: !enabled);
    final label = entryStatusLabel(status, disabled: !enabled);

    return PopupMenuItem<EntryStatus>(
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
