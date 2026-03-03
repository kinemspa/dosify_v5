// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/ui/dose_card_layout_settings.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_value_formatter.dart';
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
  // 32px rounded-square icon avatar (status colour tint) left.
  // Med name bold + dose metrics muted below + time in status colour at bottom.
  // Status chip anchored to the right.

  Widget _buildPillLayout(BuildContext context) {
    final c = _computed(context);
    final padding = doseCardContentPadding(compact: compact);
    const avatarSize = 32.0;
    final localTime = dose.scheduledTime.toLocal();
    final timeStr = DateTimeFormatter.formatTime(context, localTime);
    final iconColor =
        isActive ? c.statusColor : c.statusColor.withValues(alpha: kOpacityMediumLow);

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
                // Avatar – medication form icon in a status-tinted square
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    medicationFormIcon ?? Icons.medication_rounded,
                    size: 16.0,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: kSpacingM),
                // Centre column: name / metrics / time
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
                      if (doseMetrics.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          doseMetrics,
                          style: c.secondaryStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: doseCardTimeTextStyle(context, color: iconColor),
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

  // ---- Layout B: accent-strip ----------------------------------------------
  // 4 px status-colour left strip. Time bold (status colour) anchored left in
  // a fixed 60 dp column so med names align across cards.
  // Med name + chip on the same row. Dose metrics on a compact second row.

  Widget _buildAccentLayout(BuildContext context) {
    final c = _computed(context);
    final cs = Theme.of(context).colorScheme;
    final hPad = compact ? kSpacingM.toDouble() : kSpacingL.toDouble();
    final vPad = compact ? 8.0 : 10.0;
    const timeColWidth = 60.0;
    final localTime = dose.scheduledTime.toLocal();
    final timeStr = DateTimeFormatter.formatTime(context, localTime);
    final outlineColor =
        cs.outlineVariant.withValues(alpha: kStandardCardBorderOpacity);
    final cardColor =
        buildStandardCardDecoration(context: context, useGradient: false).color;
    final timeColor = c.statusColor
        .withValues(alpha: isActive ? 1.0 : kOpacityMediumLow);

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
                  // 4 px accent strip
                  Container(width: 4, color: timeColor),
                  // Content area
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: vPad,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: time (fixed width) + name + chip
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: timeColWidth,
                                child: Text(
                                  timeStr,
                                  style: doseCardTimeTextStyle(
                                    context,
                                    color: timeColor,
                                  )?.copyWith(
                                    fontSize: compact ? 12.0 : 13.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
                                _chip(
                                  context,
                                  status: c.effectiveStatus,
                                  disabled: c.disabled,
                                ),
                              ],
                            ],
                          ),
                          // Row 2: metrics + dose number (indented under name)
                          if (doseMetrics.isNotEmpty || doseNumber != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const SizedBox(width: timeColWidth),
                                if (doseMetrics.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      doseMetrics,
                                      style: c.secondaryStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (doseNumber != null)
                                  Text(
                                    '#$doseNumber',
                                    style: c.secondaryStyle?.copyWith(
                                      color: cs.onSurface
                                          .withValues(alpha: 0.35),
                                      fontSize: compact ? 10.0 : 11.0,
                                    ),
                                  ),
                              ],
                            ),
                          ],
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

  // ---- Layout C: compact ---------------------------------------------------
  // No sidebar or strip. Status communicated via an 8 px dot indicator.
  // Row 1 : dot + med name (expanded, bold) + chip.
  // Row 2 : time (bold, status colour) · dose value+unit · #N (muted).
  // Maximum information density at minimum card height.

  Widget _buildMinimalLayout(BuildContext context) {
    final c = _computed(context);
    final cs = Theme.of(context).colorScheme;
    final hPad = compact ? kSpacingM.toDouble() : kSpacingL.toDouble();
    final vPad = compact ? 9.0 : 11.0;
    final localTime = dose.scheduledTime.toLocal();
    final timeStr = DateTimeFormatter.formatTime(context, localTime);
    final timeColor =
        isActive ? c.statusColor : c.statusColor.withValues(alpha: kOpacityMediumLow);
    final dotColor = timeColor;

    // Compact dose line: "12.5 mg"
    final shortDose =
        '${DoseValueFormatter.format(dose.doseValue, dose.doseUnit)} ${dose.doseUnit}';

    // Separator style
    final sepStyle = c.secondaryStyle?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.25),
    );

    return _shell(
      context: context,
      decoration: buildDoseCardDecoration(context: context, borderRadius: _radius),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: status dot + name + chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 8 px status dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
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
                  _chip(context, status: c.effectiveStatus, disabled: c.disabled),
                ],
              ],
            ),
            // Row 2: time · dose · #N (indented past the dot)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Row(
                children: [
                  Text(
                    timeStr,
                    style: doseCardTimeTextStyle(context, color: timeColor)
                        ?.copyWith(fontSize: compact ? 11.0 : 12.0),
                  ),
                  const SizedBox(width: kSpacingXS),
                  Text('·', style: sepStyle),
                  const SizedBox(width: kSpacingXS),
                  Expanded(
                    child: Text(
                      shortDose,
                      style: c.secondaryStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (doseNumber != null) ...[
                    const SizedBox(width: kSpacingXS),
                    Text(
                      '#$doseNumber',
                      style: c.secondaryStyle?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.35),
                        fontSize: compact ? 10.0 : 11.0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Optional extras
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
