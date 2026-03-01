import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

/// A read-only syringe gauge displaying current fill level for MDV doses.
///
/// Extracted from [DoseActionSheet._buildMdvGaugeInCard] to keep the
/// coordinator thin.
class DoseSyringeGauge extends StatelessWidget {
  const DoseSyringeGauge({
    required this.syringeType,
    required this.fillUnits,
    super.key,
  });

  final SyringeType syringeType;
  final double fillUnits;

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
          interactive: false,
          showValueLabel: false,
        ),
        const SizedBox(height: kSpacingXS),
        Text('$unitsLabel units on $syringeLabel syringe', style: captionStyle),
      ],
    );
  }
}
