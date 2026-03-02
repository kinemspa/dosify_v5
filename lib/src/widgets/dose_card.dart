// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/ui/dose_card_layout_settings.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/widgets/dose_status_badge.dart';
import 'package:dosifi_v5/src/widgets/dose_status_ui.dart';
import 'package:dosifi_v5/src/widgets/next_dose_date_badge.dart';

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

  // ── Layout A: pill ────────────────────────────────────────────────────────
  // Narrow time-only pill on the left, med name + schedule + dose in center,
  // status chip on right.

  Widget _buildPillLayout(BuildContext context) {
    final c = _computed(context);
    final padding = doseCardContentPadding(compact: compact);
    final gap = doseCardColumnGap(compact: compact);

    return _shell(
      context: context,
      decoration:
          buildDoseCardDecoration(context: context, borderRadius: _radius),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NextDoseDateBadge(
                      nextDose: dose.scheduledTime,
                      isActive: isActive,
                      dense: true,
                      activeColor: c.statusColor,
                      denseContent: NextDoseBadgeDenseContent.time,
                      showNextLabel: false,
                      showTodayIcon: true,
                      // Pill shows time only — no duplicated med/dose content.
                    ),
                    if (leadingFooter != null) ...[
                      const SizedBox(height: kSpacingXS),
                      leadingFooter!,
                    ],
                  ],
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(width: kSpacingS),
                            titleTrailing!,
                          ],
                        ],
                      ),
                      Text(
                        dose.scheduleName,
                        style: c.secondaryStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (doseMetrics.isNotEmpty)
                        Text(
                          doseMetrics,
                          style: c.secondaryStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (c.hasDetails) ...[
                        const SizedBox(height: kSpacingXXS),
                        ...c.detailWidgets,
                      ],
                    ],
                  ),
                ),
                if (showActions) ...[
                  SizedBox(width: gap),
                  _chip(context,
                      status: c.effectiveStatus, disabled: c.disabled),
                ],
              ],
            ),
            if (c.hasFooter) ...[
              const SizedBox(height: kSpacingS),
              footer!,
            ],
          ],
        ),
      ),
    );
  }

  // ── Layout B: accent ──────────────────────────────────────────────────────
  // Status-coloured 4dp left strip.  Time shown inline on the first text row.
  // Most information-dense while remaining visually clean.

  Widget _buildAccentLayout(BuildContext context) {
    final c = _computed(context);
    final cs = Theme.of(context).colorScheme;
    final vPad = compact ? kSpacingS.toDouble() : kSpacingM.toDouble();
    final hPad = compact ? kSpacingM.toDouble() : kSpacingL.toDouble();
    final localTime = dose.scheduledTime.toLocal();
    final timeStr = DateTimeFormatter.formatTime(context, localTime);
    final outlineColor =
        cs.outlineVariant.withValues(alpha: kStandardCardBorderOpacity);

    final cardColor =
        buildStandardCardDecoration(context: context, useGradient: false)
            .color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
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
                  // Accent strip.
                  Container(width: 4, color: c.statusColor),
                  // Content with subtle right/top/bottom borders.
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: outlineColor),
                          top: BorderSide(color: outlineColor),
                          bottom: BorderSide(color: outlineColor),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
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
                                      const SizedBox(width: kSpacingS),
                                      titleTrailing!,
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: kSpacingS),
                              Text(
                                timeStr,
                                style: c.secondaryStyle?.copyWith(
                                  color: c.statusColor.withValues(
                                    alpha: isActive
                                        ? kOpacityMediumHigh
                                        : kOpacityMediumLow,
                                  ),
                                  fontWeight: kFontWeightBold,
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
                                ? '${dose.scheduleName}  ·  $doseMetrics'
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

  // ── Layout C: minimal ─────────────────────────────────────────────────────
  // Tiny status dot + inline time.  Everything on two compact text rows.
  // No pill, no separate chip column — most height-efficient.

  Widget _buildMinimalLayout(BuildContext context) {
    final c = _computed(context);
    final padding = doseCardContentPadding(compact: compact);
    final localTime = dose.scheduledTime.toLocal();
    final timeStr = DateTimeFormatter.formatTime(context, localTime);
    final dotSize = compact ? 7.0 : 8.0;

    final timeStyle = doseCardTimeTextStyle(
      context,
      color: c.statusColor.withValues(
        alpha: isActive ? kOpacityMediumHigh : kOpacityMediumLow,
      ),
    );

    return _shell(
      context: context,
      decoration:
          buildDoseCardDecoration(context: context, borderRadius: _radius),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status dot.
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: c.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(timeStr, style: timeStyle),
                          const SizedBox(width: kSpacingXS),
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
                                  const SizedBox(width: kSpacingS),
                                  titleTrailing!,
                                ],
                              ],
                            ),
                          ),
                          if (showActions) ...[
                            const SizedBox(width: kSpacingXS),
                            _chip(context,
                                status: c.effectiveStatus,
                                disabled: c.disabled),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doseMetrics.isNotEmpty
                            ? '${dose.scheduleName}  ·  $doseMetrics'
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
                    ],
                  ),
                ),
              ],
            ),
            if (c.hasFooter) ...[const SizedBox(height: kSpacingS), footer!],
          ],
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

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
