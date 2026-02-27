import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

enum NextDoseBadgeLabelStyle { standard, tall }

enum NextDoseBadgeDenseContent { date, time }

class NextDoseDateBadge extends StatelessWidget {
  const NextDoseDateBadge({
    required this.nextDose,
    required this.isActive,
    required this.dense,
    this.activeColor,
    this.denseContent = NextDoseBadgeDenseContent.date,
    this.showNextLabel = false,
    this.showTodayIcon = true,
    this.nextLabelStyle = NextDoseBadgeLabelStyle.standard,
    this.doseMetrics,
    super.key,
  });

  final DateTime? nextDose;
  final bool isActive;
  final bool dense;
  final Color? activeColor;
  final NextDoseBadgeDenseContent denseContent;
  final bool showNextLabel;
  final bool showTodayIcon;
  final NextDoseBadgeLabelStyle nextLabelStyle;

  /// Optional dose amount + units (e.g. "50 mg") shown inside the pill badge
  /// when [dense] is true and [denseContent] is [NextDoseBadgeDenseContent.time].
  final String? doseMetrics;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hasNext = nextDose != null;
    final isEnabled = isActive && hasNext;

    final accentColor = activeColor ?? cs.primary;

    final circleBg = isEnabled
        ? accentColor.withValues(alpha: kOpacitySubtle)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityFaint);

    final circleBorder = isEnabled
        ? accentColor.withValues(alpha: kOpacityMediumLow)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityVeryLow);

    final primaryTextColor = isEnabled
        ? accentColor.withValues(alpha: kOpacityFull)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMedium);

    final shouldShowNext = showNextLabel && isEnabled;

    final DateTime? nextLocal = nextDose?.toLocal();
    final isToday = nextLocal != null && _isSameDay(nextLocal, DateTime.now());

    final dayText = nextLocal != null
        ? DateTimeFormatter.formatDay(nextLocal)
        : '—';
    final monthText = isToday
        ? ''
        : (nextLocal != null
              ? DateTimeFormatter.formatMonthAbbr(nextLocal)
              : '');
    final timeText = nextLocal != null
        ? DateTimeFormatter.formatTimeCompact(context, nextLocal)
        : 'No upcoming';

    final todayDateText = isToday
        ? () {
            final localeTag = Localizations.localeOf(context).toLanguageTag();
            final weekday = intl.DateFormat.E(localeTag).format(nextLocal);
            final shortDate = MaterialLocalizations.of(
              context,
            ).formatCompactDate(nextLocal);
            return '$weekday $shortDate';
          }()
        : null;

    final timeTextParts = timeText.split(' ');
    final timeMain = timeTextParts.isNotEmpty ? timeTextParts.first : timeText;
    final timeSuffix = timeTextParts.length > 1
        ? timeTextParts.sublist(1).join(' ')
        : null;

    final Widget circleContent;
    if (dense && denseContent == NextDoseBadgeDenseContent.time) {
      circleContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hasNext ? timeMain : '—',
                style: nextDoseBadgeDayTextStyle(
                  context,
                  dense: true,
                  color: primaryTextColor,
                ),
              ),
            ),
            if (timeSuffix != null && timeSuffix.trim().isNotEmpty)
              Text(
                timeSuffix.toUpperCase(),
                style: nextDoseBadgeMonthTextStyle(
                  context,
                  dense: true,
                  color: primaryTextColor.withValues(alpha: kOpacityMediumHigh),
                ),
              ),
          ],
        ),
      );
    } else {
      circleContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToday && showTodayIcon)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Today',
                  style: nextDoseBadgeTodayTextStyle(
                    context,
                    dense: dense,
                    color: primaryTextColor,
                  ),
                ),
              )
            else
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  dayText,
                  style: nextDoseBadgeDayTextStyle(
                    context,
                    dense: dense,
                    color: primaryTextColor,
                  ),
                ),
              ),

            if (isToday && showTodayIcon && todayDateText != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  todayDateText,
                  style: nextDoseBadgeMonthTextStyle(
                    context,
                    dense: dense,
                    color: primaryTextColor.withValues(
                      alpha: kOpacityMediumHigh,
                    ),
                  ),
                ),
              )
            else if (monthText.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  monthText,
                  style: nextDoseBadgeMonthTextStyle(
                    context,
                    dense: dense,
                    color: primaryTextColor.withValues(
                      alpha: kOpacityMediumHigh,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // In dense + time mode, use a pill/chip shape instead of a circle so the
    // time text sits comfortably. The circle is kept for the date variant.
    final bool usePill =
        dense && denseContent == NextDoseBadgeDenseContent.time;

    final Widget circleCore;
    if (usePill) {
      // Build the pill: time text (bold) + AM/PM suffix only.
      circleCore = Container(
        constraints: const BoxConstraints(minWidth: kDoseTimePillMinWidth),
        padding: kDoseTimePillPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDoseTimePillBorderRadius),
          color: circleBg,
          border: Border.all(width: kBorderWidthThin, color: circleBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hasNext ? timeMain : '—',
                style: nextDoseBadgeDayTextStyle(
                  context,
                  dense: true,
                  color: primaryTextColor,
                ),
              ),
            ),
            if (timeSuffix != null && timeSuffix.trim().isNotEmpty)
              Text(
                timeSuffix.toUpperCase(),
                style: nextDoseBadgeMonthTextStyle(
                  context,
                  dense: true,
                  color: primaryTextColor.withValues(alpha: kOpacityMediumHigh),
                ),
              ),
          ],
        ),
      );
    } else {
      final circleSize = dense
          ? kNextDoseDateCircleSizeCompact
          : kNextDoseDateCircleSizeLarge;
      final circleContentPadding = dense
          ? kNextDoseDateCircleContentPaddingCompact
          : kNextDoseDateCircleContentPaddingLarge;
      circleCore = Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: circleBg,
          border: Border.all(width: kBorderWidthThin, color: circleBorder),
        ),
        child: Padding(padding: circleContentPadding, child: circleContent),
      );
    }

    final nextLabelPadding = nextLabelStyle == NextDoseBadgeLabelStyle.tall
        ? kNextDoseBadgeNextLabelPaddingTall
        : kNextDoseBadgeNextLabelPaddingStandard;

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
                      color: accentColor.withValues(alpha: kOpacityEmphasis),
                      borderRadius: BorderRadius.circular(nextLabelRadius),
                    ),
                    child: Text(
                      'Next',
                      style: nextDoseBadgeNextTagTextStyle(
                        context,
                        color: statusColorOnPrimary(context, accentColor),
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
          style: nextDoseBadgeTimeTextStyle(
            context,
            color: isEnabled
                ? accentColor.withValues(alpha: kOpacityFull)
                : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
          ),
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
