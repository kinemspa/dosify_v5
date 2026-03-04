import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/utils/datetime_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

enum NextEntryBadgeLabelStyle { standard, tall }

enum NextEntryBadgeDenseContent { date, time }

class NextEntryDateBadge extends StatelessWidget {
  const NextEntryDateBadge({
    required this.nextEntry,
    required this.isActive,
    required this.dense,
    this.activeColor,
    this.denseContent = NextEntryBadgeDenseContent.date,
    this.showNextLabel = false,
    this.showTodayIcon = true,
    this.nextLabelStyle = NextEntryBadgeLabelStyle.standard,
    this.entryMetrics,
    this.medicationName,
    super.key,
  });

  final DateTime? nextEntry;
  final bool isActive;
  final bool dense;
  final Color? activeColor;
  final NextEntryBadgeDenseContent denseContent;
  final bool showNextLabel;
  final bool showTodayIcon;
  final NextEntryBadgeLabelStyle nextLabelStyle;

  /// Optional entry amount + units (e.g. "50 mg") shown inside the pill badge
  /// when [dense] is true and [denseContent] is [NextEntryBadgeDenseContent.time].
  final String? entryMetrics;

  /// Optional medication name shown inside the pill badge below the time.
  final String? medicationName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hasNext = nextEntry != null;
    final isEnabled = isActive && hasNext;

    final accentColor = activeColor ?? cs.primary;

    final circleBg = isEnabled
        ? cs.surface
        : cs.onSurfaceVariant.withValues(alpha: kOpacityFaint);

    final circleBorder = isEnabled
        ? accentColor.withValues(alpha: kOpacityMediumLow)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityVeryLow);

    final primaryTextColor = isEnabled
        ? accentColor.withValues(alpha: kOpacityFull)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMedium);

    final shouldShowNext = showNextLabel && isEnabled;

    final DateTime? nextLocal = nextEntry?.toLocal();
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
    if (dense && denseContent == NextEntryBadgeDenseContent.time) {
      circleContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hasNext ? timeMain : '—',
                style: nextEntryBadgeDayTextStyle(
                  context,
                  dense: true,
                  color: primaryTextColor,
                ),
              ),
            ),
            if (timeSuffix != null && timeSuffix.trim().isNotEmpty)
              Text(
                timeSuffix.toUpperCase(),
                style: nextEntryBadgeMonthTextStyle(
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
                  style: nextEntryBadgeTodayTextStyle(
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
                  style: nextEntryBadgeDayTextStyle(
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
                  style: nextEntryBadgeMonthTextStyle(
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
                  style: nextEntryBadgeMonthTextStyle(
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
        dense && denseContent == NextEntryBadgeDenseContent.time;

    final Widget circleCore;
    if (usePill) {
      // Build the pill: time (bold) → AM/PM → med name → entry metrics.
      final dimColor = primaryTextColor.withValues(alpha: kOpacityMediumHigh);
      final metaColor = primaryTextColor.withValues(alpha: kOpacityMedium);
      circleCore = Container(
        constraints: const BoxConstraints(
          minWidth: kEntryTimePillMinWidth,
          maxWidth: kEntryTimePillMaxWidth,
        ),
        padding: kEntryTimePillPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kEntryTimePillBorderRadius),
          color: circleBg,
          border: Border.all(width: kBorderWidthThin, color: circleBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hasNext
                    ? (timeSuffix != null && timeSuffix.trim().isNotEmpty
                        ? '$timeMain ${timeSuffix.toUpperCase()}'
                        : timeMain)
                    : '—',
                style: nextEntryBadgeDayTextStyle(
                  context,
                  dense: true,
                  color: primaryTextColor,
                )?.copyWith(fontSize: kFontSizeMedium),
              ),
            ),
            if (medicationName != null || entryMetrics != null) ...([
              const SizedBox(height: 2),
              Divider(height: 1, thickness: 0.5, color: circleBorder),
              const SizedBox(height: 2),
              if (medicationName != null)
                Text(
                  medicationName!,
                  style: nextEntryBadgeMonthTextStyle(
                    context,
                    dense: true,
                    color: dimColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              if (entryMetrics != null)
                Text(
                  entryMetrics!,
                  style: nextEntryBadgeNextTagTextStyle(
                    context,
                    color: metaColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
            ]),
          ],
        ),
      );
    } else {
      final circleSize = dense
          ? kNextEntryDateCircleSizeCompact
          : kNextEntryDateCircleSizeLarge;
      final circleContentPadding = dense
          ? kNextEntryDateCircleContentPaddingCompact
          : kNextEntryDateCircleContentPaddingLarge;
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

    final nextLabelPadding = nextLabelStyle == NextEntryBadgeLabelStyle.tall
        ? kNextEntryBadgeNextLabelPaddingTall
        : kNextEntryBadgeNextLabelPaddingStandard;

    final nextLabelRadius = nextLabelStyle == NextEntryBadgeLabelStyle.tall
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
                      style: nextEntryBadgeNextTagTextStyle(
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
          style: nextEntryBadgeTimeTextStyle(
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
