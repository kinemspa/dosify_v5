import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NextDoseDateBadge extends StatelessWidget {
  const NextDoseDateBadge({
    required this.nextDose,
    required this.isActive,
    required this.dense,
    super.key,
  });

  final DateTime? nextDose;
  final bool isActive;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hasNext = nextDose != null;
    final isEnabled = isActive && hasNext;

    final size = dense
        ? kNextDoseDateCircleSizeCompact
        : kNextDoseDateCircleSizeLarge;

    final circleBg = isEnabled
        ? cs.primary.withValues(alpha: kOpacitySubtle)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityFaint);

    final circleBorder = isEnabled
        ? cs.primary.withValues(alpha: kOpacityMediumLow)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityVeryLow);

    final primaryTextColor = isEnabled
        ? cs.primary.withValues(alpha: kOpacityFull)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMedium);

    final dayText = hasNext ? DateFormat('d').format(nextDose!) : '—';
    final monthText = hasNext
        ? DateFormat('MMM').format(nextDose!).toUpperCase()
        : '';
    final timeText = hasNext
        ? TimeOfDay.fromDateTime(nextDose!).format(context)
        : 'No upcoming';

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleBg,
        border: Border.all(width: kBorderWidthThin, color: circleBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayText,
              style: TextStyle(
                fontSize: dense
                    ? kNextDoseDateCircleDayFontSizeCompact
                    : kNextDoseDateCircleDayFontSizeLarge,
                fontWeight: kFontWeightExtraBold,
                height: 1,
                color: primaryTextColor,
              ),
            ),
            if (monthText.isNotEmpty)
              Text(
                monthText,
                style: TextStyle(
                  fontSize: kNextDoseDateCircleMonthFontSize,
                  fontWeight: kFontWeightSemiBold,
                  height: 1,
                  color: primaryTextColor.withValues(alpha: kOpacityMediumHigh),
                ),
              ),
          ],
        ),
      ),
    );

    if (dense) return circle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        const SizedBox(height: kSpacingXS),
        Text(
          timeText,
          style: helperTextStyle(
            context,
            color: isEnabled
                ? cs.primary.withValues(alpha: kOpacityFull)
                : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
