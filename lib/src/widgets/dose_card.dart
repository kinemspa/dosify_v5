// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/ui/dose_card_layout_settings.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_status_badge.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';

class DoseCard extends StatelessWidget {
  const DoseCard({
    required this.dose,
    required this.medicationName,
    required this.strengthOrConcentrationLabel,
    required this.doseMetrics,
    required this.onTap,
    this.isActive = true,
    this.compact = false,
    this.doseNumber,
    this.medicationFormIcon,
    this.statusOverride,
    this.titleTrailing,
    this.leadingFooter,
    this.showActions = true,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.onQuickAction,
    this.detailLines,
    this.footer,
    super.key,
  });

  final CalculatedDose dose;
  final String medicationName;
  final String strengthOrConcentrationLabel;
  final String doseMetrics;
  final VoidCallback onTap;
  final bool isActive;
  final bool compact;
  final int? doseNumber;
  final IconData? medicationFormIcon;
  final DoseStatus? statusOverride;
  final Widget? titleTrailing;
  final Widget? leadingFooter;
  final bool showActions;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final ValueChanged<DoseStatus>? onQuickAction;
  final List<Widget>? detailLines;
  final Widget? footer;

  double get _radius => compact ? kBorderRadiusSmall : kBorderRadiusMedium;

  ({
    Color statusColor,
    bool disabled,
    DoseStatus effectiveStatus,
    TextStyle? primaryStyle,
    TextStyle? secondaryStyle,
    List<Widget> detailWidgets,
    bool hasFooter,
    bool hasDetails,
  }) _computed(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveStatus = statusOverride ?? dose.status;
    final disabled = !isActive;
    final visual = doseStatusVisual(context, effectiveStatus, disabled: disabled);
    final statusColor = visual.color;

    final primaryStyle =
        doseCardPrimaryTitleTextStyle(context, color: statusColor);
    final secondaryStyle = doseCardSecondaryTitleTextStyle(
      context,
      color: isActive
          ? cs.onSurface.withValues(alpha: kOpacityMediumHigh)
          : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
    );

    final normalizedDetails = (detailLines ?? const <Widget>[])
        .where((w) => w is! SizedBox)
        .toList();

    return (
      statusColor: statusColor,
      disabled: disabled,
      effectiveStatus: effectiveStatus,
      primaryStyle: primaryStyle,
      secondaryStyle: secondaryStyle,
      detailWidgets: normalizedDetails,
      hasFooter: footer != null,
      hasDetails: normalizedDetails.isNotEmpty,
    );
  }

  Widget _chip(
    BuildContext context, {
    required DoseStatus status,
    required bool disabled,
  }) =>
      DoseCardStatusChip(status: status, disabled: disabled, compact: compact);

  Widget _shell({
    required BuildContext context,
    required BoxDecoration decoration,
    required Widget child,
  }) {
    return Container(
      decoration: decoration,
      child: Material(
        color: kColorTransparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: child,
        ),
      ),
    );
  }

  // ---- Layout A: icon-row --------------------------------------------------
  // 40x40 rounded-square avatar (status colour tint + med/clock icon) left.
  // Med name bold, schedule.dose, then time muted below in centre column.
  // Status chip anchored to the right.

  Widget _buildPillLayout(BuildContext context) {
    final c = _computed(context);
    final padding = doseCardContentPadding(compact: compact);
    final avatarSize = compact ? 36.0 : 40.0;
    final localTime = dose.scheduledTime.toLocal();
    final timeStr = DateTimeFormatter.formatTime(context, localTime);
    final iconColor =
        isActive ? c.statusColor : c.statusColor.withValues(alpha: kOpacityMediumLow);

    final timeStyle = doseCardTimeTextStyle(
      context,
      color: iconColor,
    );

    return _shell(
      context: context,
      decoration: buildDoseCardDecoration(context: context, borderRadius: _radius),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: kOpacityMinimal + 0.04),
                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    medicationFormIcon ?? Icons.alarm_rounded,
                    size: compact ? kIconSizeMedium : kIconSizeLarge,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: kSpacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              medicationName,
                              style: c.primaryStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (titleTrailing != null) ...[
                            const SizedBox(width: kSpacingXS),
                            titleTrailing!,
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        doseMetrics.isNotEmpty
                            ? '${dose.scheduleName}  \u00b7  $doseMetrics'
                            : dose.scheduleName,
                        style: c.secondaryStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(timeStr, style: timeStyle),
                      if (leadingFooter != null) ...[
                        const SizedBox(height: kSpacingXS),
                        leadingFooter!,
                      ],
                      if (c.hasDetails) ...[
                        const SizedBox(height: kSpacingXXS),
                        ...c.detailWidgets,
                      ],
                    ],
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(width: kSpacingS),
                  _chip(context, status: c.effectiveStatus, disabled: c.disabled),
                ],
              ],
            ),
            if (c.hasFooter) ...[const SizedBox(height: kSpacingS), footer!],
          ],
        ),
      ),
    );
  }

  // ---- Layout B: header-band -----------------------------------------------
  // Full-width status-tinted title band: med name + chip inside.
  // Clean body below: clock icon + time + schedule.dose detail.

  Widget _buildAccentLayout(BuildContext context) {
    final c = _computed(context);
    final cs = Theme.of(context).colorScheme;
    final hPad = compact ? kSpacingM.toDouble() : kSpacingL.toDouble();
    final localTime = dose.scheduledTime.toLocal();
    final timeStr = DateTimeFormatter.formatTime(context, localTime);
    final outlineColor =
        cs.outlineVariant.withValues(alpha: kStandardCardBorderOpacity);
    final bandColor = c.statusColor.withValues(alpha: isActive ? 0.13 : 0.07);
    final cardColor =
        buildStandardCardDecoration(context: context, useGradient: false).color;
    final timeColor = c.statusColor
        .withValues(alpha: isActive ? kOpacityMediumHigh : kOpacityMediumLow);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: outlineColor),
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: kDoseCardShadowOpacity),
              blurRadius: kDoseCardShadowBlurRadius,
              offset: kDoseCardShadowOffset,
            ),
          ],
        ),
        child: Material(
          color: kColorTransparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header band
                Container(
                  color: bandColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: compact ? 7.0 : 9.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                medicationName,
                                style: c.primaryStyle?.copyWith(
                                  color: c.statusColor.withValues(
                                    alpha: isActive ? 1.0 : kOpacityMediumHigh,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (titleTrailing != null) ...[
                              const SizedBox(width: kSpacingXS),
                              titleTrailing!,
                            ],
                          ],
                        ),
                      ),
                      if (showActions) ...[
                        const SizedBox(width: kSpacingS),
                        _chip(context,
                            status: c.effectiveStatus, disabled: c.disabled),
                      ],
                    ],
                  ),
                ),
                // Body row
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: compact ? 7.0 : 10.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: kIconSizeSmall, color: timeColor),
                      const SizedBox(width: 5),
                      Text(
                        timeStr,
                        style: doseCardTimeTextStyle(context, color: timeColor),
                      ),
                      const SizedBox(width: kSpacingM),
                      Expanded(
                        child: Text(
                          doseMetrics.isNotEmpty
                              ? '${dose.scheduleName}  \u00b7  $doseMetrics'
                              : dose.scheduleName,
                          style: c.secondaryStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (leadingFooter != null || c.hasDetails || c.hasFooter)
                  Padding(
                    padding: EdgeInsets.only(
                      left: hPad,
                      right: hPad,
                      bottom: compact ? 7.0 : 10.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leadingFooter != null) leadingFooter!,
                        if (c.hasDetails) ...[
                          const SizedBox(height: kSpacingXXS),
                          ...c.detailWidgets,
                        ],
                        if (c.hasFooter) ...[
                          const SizedBox(height: kSpacingS),
                          footer!,
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Layout C: sidebar-time ----------------------------------------------
  // Time stacked in a narrow status-tinted left column (HH:MM / AM|PM).
  // Thin vertical divider. Med name + schedule.dose + chip to the right.

  Widget _buildMinimalLayout(BuildContext context) {
    final c = _computed(context);
    final cs = Theme.of(context).colorScheme;
    final vPad = compact ? kSpacingS.toDouble() : kSpacingM.toDouble();
    final localTime = dose.scheduledTime.toLocal();
    final timeColor =
        isActive ? c.statusColor : c.statusColor.withValues(alpha: kOpacityMediumLow);
    final outlineColor =
        cs.outlineVariant.withValues(alpha: kStandardCardBorderOpacity);
    final cardColor =
        buildStandardCardDecoration(context: context, useGradient: false).color;

    // Split "8:00 AM" into "8:00" + "AM"
    final fullTime = DateTimeFormatter.formatTime(context, localTime);
    final spaceIdx = fullTime.lastIndexOf(' ');
    final timePart =
        spaceIdx > 0 ? fullTime.substring(0, spaceIdx) : fullTime;
    final amPmPart =
        spaceIdx > 0 ? fullTime.substring(spaceIdx + 1) : '';

    final timeMainStyle = TextStyle(
      fontSize: compact ? 13.0 : 14.0,
      fontWeight: kFontWeightBold,
      color: timeColor,
      height: 1.15,
      letterSpacing: -0.3,
    );
    final timeSubStyle = TextStyle(
      fontSize: 9.0,
      fontWeight: kFontWeightSemiBold,
      color: timeColor.withValues(alpha: 0.75),
      height: 1.2,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: outlineColor),
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: kDoseCardShadowOpacity),
              blurRadius: kDoseCardShadowBlurRadius,
              offset: kDoseCardShadowOffset,
            ),
          ],
        ),
        child: Material(
          color: kColorTransparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Time sidebar
                  Container(
                    width: compact ? 48.0 : 54.0,
                    color: timeColor.withValues(alpha: 0.09),
                    padding: EdgeInsets.symmetric(vertical: vPad),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(timePart,
                            style: timeMainStyle,
                            textAlign: TextAlign.center),
                        if (amPmPart.isNotEmpty)
                          Text(amPmPart,
                              style: timeSubStyle,
                              textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                      width: 1,
                      color: timeColor.withValues(alpha: 0.20)),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact
                            ? kSpacingM.toDouble()
                            : kSpacingL.toDouble(),
                        vertical: vPad,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        medicationName,
                                        style: c.primaryStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (titleTrailing != null) ...[
                                      const SizedBox(width: kSpacingXS),
                                      titleTrailing!,
                                    ],
                                  ],
                                ),
                              ),
                              if (showActions) ...[
                                const SizedBox(width: kSpacingS),
                                _chip(context,
                                    status: c.effectiveStatus,
                                    disabled: c.disabled),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doseMetrics.isNotEmpty
                                ? '${dose.scheduleName}  \u00b7  $doseMetrics'
                                : dose.scheduleName,
                            style: c.secondaryStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (leadingFooter != null) ...[
                            const SizedBox(height: kSpacingXS),
                            leadingFooter!,
                          ],
                          if (c.hasDetails) ...[
                            const SizedBox(height: kSpacingXXS),
                            ...c.detailWidgets,
                          ],
                          if (c.hasFooter) ...[
                            const SizedBox(height: kSpacingS),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DoseCardLayoutConfig>(
      valueListenable: DoseCardLayoutSettings.value,
      builder: (context, config, _) => switch (config.layout) {
        DoseCardLayout.pill => _buildPillLayout(context),
        DoseCardLayout.accent => _buildAccentLayout(context),
        DoseCardLayout.minimal => _buildMinimalLayout(context),
      },
    );
  }
}
