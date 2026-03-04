// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
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

  // ---- Layout C: sidebar-time ----------------------------------------------
  // Time stacked in a narrow status-tinted left column (HH:MM / AM|PM).
  // Thin vertical divider. Med name + schedule.dose + chip to the right.

  Widget _buildMinimalLayout(BuildContext context) {
    final c = _computed(context);
    final cs = Theme.of(context).colorScheme;
    final vPad = compact ? kSpacingXS.toDouble() : kSpacingS.toDouble();
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
      fontSize: compact ? 10.0 : 11.0,
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
                    width: compact ? 52.0 : 58.0,
                    color: timeColor.withValues(alpha: 0.09),
                    padding: EdgeInsets.symmetric(vertical: vPad),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Time + AM/PM on same row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(timePart, style: timeMainStyle),
                            if (amPmPart.isNotEmpty) ...[const SizedBox(width: 2),
                              Text(amPmPart, style: timeSubStyle),
                            ],
                          ],
                        ),
                        // Dose: value + unit (short form)
                        Builder(builder: (_) {
                          final shortDose =
                              '${DoseValueFormatter.format(dose.doseValue, dose.doseUnit)} ${dose.doseUnit}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              shortDose,
                              style: TextStyle(
                                fontSize: 8.0,
                                fontWeight: kFontWeightSemiBold,
                                color: timeColor.withValues(alpha: 0.70),
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        if (doseNumber != null) ...[const SizedBox(height: 1),
                          Text(
                            '#$doseNumber',
                            style: TextStyle(
                              fontSize: 8.0,
                              fontWeight: kFontWeightSemiBold,
                              color: timeColor.withValues(alpha: 0.45),
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                      child: Center(
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
                            if (doseMetrics.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                doseMetrics,
                                style: c.secondaryStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
  Widget build(BuildContext context) => _buildMinimalLayout(context);
}
