import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum NextDoseBadgeLabelStyle {
  standard,
  tall,
}

class NextDoseDateBadge extends StatelessWidget {
  const NextDoseDateBadge({
    required this.nextDose,
    required this.isActive,
    required this.dense,
    this.showNextLabel = false,
    this.showTodayIcon = true,
    this.nextLabelStyle = NextDoseBadgeLabelStyle.standard,
    super.key,
  });

  final DateTime? nextDose;
  final bool isActive;
  final bool dense;
  final bool showNextLabel;
  final bool showTodayIcon;
  final NextDoseBadgeLabelStyle nextLabelStyle;

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

    final shouldShowNext = showNextLabel && isEnabled;

    final isToday = hasNext && _isSameDay(nextDose!, DateTime.now());

    final dayText = hasNext ? DateFormat('d').format(nextDose!) : '—';
    final monthText = isToday
        ? ''
        : (hasNext ? DateFormat('MMM').format(nextDose!).toUpperCase() : '');
    final timeText = hasNext
        ? TimeOfDay.fromDateTime(nextDose!).format(context)
        : 'No upcoming';

    final circleCore = Container(
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
            if (isToday && showTodayIcon)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Today',
                  style: TextStyle(
                    fontSize: dense ? kFontSizeXXSmall : kFontSizeXSmall,
                    fontWeight: kFontWeightExtraBold,
                    height: 1,
                    color: primaryTextColor,
                  ),
                ),
              )
            else
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
                  fontSize: dense
                      ? kFontSizeXSmall
                      : kNextDoseDateCircleMonthFontSize,
                  fontWeight: kFontWeightSemiBold,
                  height: 1,
                  color: primaryTextColor.withValues(alpha: kOpacityMediumHigh),
                ),
              ),
          ],
        ),
      ),
    );

    final nextLabelPadding = nextLabelStyle == NextDoseBadgeLabelStyle.tall
        ? const EdgeInsets.symmetric(
            horizontal: kSpacingXS,
            vertical: kSpacingXXS,
          )
        : const EdgeInsets.symmetric(
            horizontal: kSpacingXS,
            vertical: 0,
          );

    final nextLabelRadius = nextLabelStyle == NextDoseBadgeLabelStyle.tall
        ? kBorderRadiusChipTight
        : kBorderRadiusChip;

    final circle = shouldShowNext
        ? Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              circleCore,
              Positioned(
                top: -kSpacingXS,
                child: Transform.translate(
                  offset: const Offset(-kSpacingS, kSpacingXS),
                  child: Container(
                    padding: nextLabelPadding,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: kOpacityEmphasis),
                      borderRadius: BorderRadius.circular(nextLabelRadius),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontSize: kFontSizeXXSmall,
                        fontWeight: kFontWeightExtraBold,
                        height: 1,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : circleCore;

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
          )?.copyWith(fontSize: kFontSizeXSmall),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
