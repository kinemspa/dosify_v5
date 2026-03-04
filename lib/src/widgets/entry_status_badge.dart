import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/widgets/entry_status_ui.dart';
import 'package:dosifi_v5/src/widgets/unified_status_badge.dart';

class EntryStatusBadge extends StatelessWidget {
  const EntryStatusBadge({
    super.key,
    required this.status,
    required this.disabled,
    this.dense = true,
    this.showPending = false,
  });

  final EntryStatus status;
  final bool disabled;
  final bool dense;
  final bool showPending;

  @override
  Widget build(BuildContext context) {
    if (!disabled && status == EntryStatus.pending && !showPending) {
      return const SizedBox.shrink();
    }

    final visual = entryStatusVisual(context, status, disabled: disabled);
    final label = entryStatusLabel(status, disabled: disabled);

    return UnifiedStatusBadge(
      label: label,
      icon: visual.icon,
      color: visual.color,
      dense: dense,
    );
  }
}

/// Fixed-size status chip used by [EntryCard] when quick-actions are disabled.
///
/// This keeps all states visually consistent (same width/height/padding) and
/// prevents off-center rendering when labels differ.
class EntryCardStatusChip extends StatelessWidget {
  const EntryCardStatusChip({
    super.key,
    required this.status,
    required this.disabled,
    required this.compact,
  });

  final EntryStatus status;
  final bool disabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visual = entryStatusVisual(context, status, disabled: disabled);
    final label = entryStatusLabel(status, disabled: disabled);

    final width = compact
        ? kEntryCardStatusChipWidthCompact
        : kEntryCardStatusChipWidth;
    final height = compact
        ? kEntryCardStatusChipHeightCompact
        : kEntryCardStatusChipHeight;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: visual.color,
          borderRadius: BorderRadius.circular(kBorderRadiusChip),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? kSpacingXS : kSpacingS,
            ),
            child: UnifiedStatusBadge(
              label: label,
              icon: visual.icon,
              color: kColorOnFilledStatus,
              dense: true,
              decorate: false,
              textStyle: (context, color) =>
                  entryCardStatusChipLabelTextStyle(context, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
