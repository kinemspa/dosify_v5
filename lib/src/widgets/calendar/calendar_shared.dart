import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';

String formatCalendarHour(int hour) {
  if (hour == 0) return '12 AM';
  if (hour < 12) return '$hour AM';
  if (hour == 12) return '12 PM';
  return '${hour - 12} PM';
}

class CalendarHourLabel extends StatelessWidget {
  const CalendarHourLabel({
    required this.hour,
    this.width,
    this.padding = kCalendarStageHourLabelPadding,
    this.textAlign = TextAlign.left,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    super.key,
  });

  final int hour;
  final double? width;
  final EdgeInsets padding;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      formatCalendarHour(hour),
      textAlign: textAlign,
      style: calendarStageHourLabelTextStyle(context),
      maxLines: maxLines,
      overflow: overflow,
    );

    final padded = Padding(padding: padding, child: label);
    if (width == null) return padded;

    return SizedBox(width: width, child: padded);
  }
}

class CalendarNoDosesState extends StatelessWidget {
  const CalendarNoDosesState({
    this.date,
    this.showDate = false,
    this.showIcon = true,
    this.compact = false,
    this.message = 'No doses scheduled',
    super.key,
  });

  final DateTime? date;
  final bool showDate;
  final bool showIcon;
  final bool compact;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.event_available,
              size: kCalendarEmptyStateIconSize,
              color: cs.primary.withValues(alpha: kOpacityVeryLow),
            ),
            const SizedBox(height: kSectionSpacing),
          ],
          Text(
            message,
            style: compact
                ? helperTextStyle(
                    context,
                    color: cs.onSurface.withValues(alpha: kOpacityLow),
                  )
                : cardTitleStyle(context),
            textAlign: TextAlign.center,
          ),
          if (showDate && date != null) ...[
            const SizedBox(height: kCardInnerSpacing),
            Text(
              MaterialLocalizations.of(context).formatFullDate(date!),
              style: helperTextStyle(
                context,
                color: cs.onSurface.withValues(alpha: kOpacityLow),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
