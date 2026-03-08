import 'package:flutter/material.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/schedules/domain/entry_calculator.dart';
import 'package:skedux/src/widgets/white_syringe_gauge.dart';

/// A syringe gauge displaying current fill level for MDV entries.
///
/// When [onChanged] is provided the gauge becomes interactive (draggable).
///
/// Extracted from [EntryActionSheet._buildMdvGaugeInCard] to keep the
/// coordinator thin.
class EntrySyringeGauge extends StatelessWidget {
  const EntrySyringeGauge({
    required this.syringeType,
    required this.fillUnits,
    this.onChanged,
    super.key,
  });

  final SyringeType syringeType;
  final double fillUnits;

  /// When non-null, the gauge is rendered as interactive and calls [onChanged]
  /// with the new syringe-units value on each drag update.
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final captionStyle = microHelperTextStyle(context)?.copyWith(
      color: cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
    );
    final clampedFill = fillUnits.clamp(0.0, syringeType.maxUnits.toDouble());
    final syringeLabel = syringeType.name.replaceAll('ml', 'mL');
    final unitsLabel = clampedFill.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WhiteSyringeGauge(
          totalUnits: syringeType.maxUnits.toDouble(),
          fillUnits: clampedFill,
          interactive: onChanged != null,
          onChanged: onChanged,
          showValueLabel: onChanged != null,
        ),
        const SizedBox(height: kSpacingXS),
        Text('$unitsLabel units on $syringeLabel syringe', style: captionStyle),
        if (onChanged != null) ...[
          const SizedBox(height: 2),
          Text(
            'Drag to adjust',
            style: captionStyle?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
