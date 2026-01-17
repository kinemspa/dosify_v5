// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

/// Centralized reconstitution summary card widget
/// Used in both medication detail page and MDV wizard
/// Displays reconstitution information in a consistent dark gradient style
class ReconstitutionSummaryCard extends StatelessWidget {
  const ReconstitutionSummaryCard({
    required this.strengthValue,
    required this.strengthUnit,
    required this.medicationName,
    super.key,
    this.containerVolumeMl,
    this.perMlValue,
    this.volumePerDose,
    this.reconFluidName,
    this.syringeSizeMl,
    this.compact = false,
    this.showCardSurface = true,
  });

  final double strengthValue;
  final String strengthUnit;
  final String medicationName;
  final double? containerVolumeMl;
  final double? perMlValue;
  final double? volumePerDose;
  final String? reconFluidName;
  final double? syringeSizeMl;
  final bool compact;
  final bool showCardSurface;

  String _formatNoTrailing(double value) {
    final str = value.toStringAsFixed(2);
    if (str.endsWith('.00')) return value.toInt().toString();
    if (str.endsWith('0')) return str.substring(0, str.length - 1);
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final baseForeground = showCardSurface
      ? reconForegroundColor(context)
      : cs.onSurface;

    // The recon opacities assume white text on a dark background.
    // When rendering on normal surfaces, cap darkness per design system.
    final baseTextAlpha = showCardSurface ? kReconTextHighOpacity : kOpacityFull;

    final baseTextColor = baseForeground.withValues(alpha: baseTextAlpha);
    final baseStyle = reconSummaryBaseTextStyle(context, color: baseTextColor);

    final strengthStyle = reconSummaryEmphasisTextStyle(
      context,
      color: cs.primary,
      fontSize: compact
          ? kReconSummaryStrengthValueFontSizeCompact
          : kReconSummaryStrengthValueFontSize,
      fontWeight: kFontWeightExtraBold,
    );
    final ofStyle = reconSummaryEmphasisTextStyle(
      context,
      color: baseTextColor,
      fontSize: compact ? kReconSummaryOfFontSizeCompact : kReconSummaryOfFontSize,
      fontWeight: kFontWeightNormal,
    );
    final medicationNameStyle = reconSummaryEmphasisTextStyle(
      context,
      color: cs.primary,
      fontSize: compact ? kReconSummaryNameFontSizeCompact : kReconSummaryNameFontSize,
      fontWeight: kFontWeightBold,
    );
    final metaStyle = reconSummaryEmphasisTextStyle(
      context,
      color: baseTextColor,
      fontSize:
          compact ? kReconSummaryMetaFontSizeCompact : kReconSummaryMetaFontSize,
      fontWeight: kFontWeightMedium,
    );
    final metaPrimaryStyle = reconSummaryEmphasisTextStyle(
      context,
      color: cs.primary,
      fontSize:
          compact ? kReconSummaryMetaFontSizeCompact : kReconSummaryMetaFontSize,
      fontWeight: kFontWeightSemiBold,
    );
    final totalVolumeStyle = reconSummaryEmphasisTextStyle(
      context,
      color: cs.primary,
      fontSize: compact
          ? kReconSummaryTotalVolumeFontSizeCompact
          : kReconSummaryTotalVolumeFontSize,
      fontWeight: kFontWeightExtraBold,
    );
    final valueStyle = reconSummaryEmphasisTextStyle(
      context,
      color: cs.primary,
      fontSize: compact ? kReconSummaryValueFontSizeCompact : kReconSummaryValueFontSize,
      fontWeight: kFontWeightBold,
    );

    return Container(
      padding: showCardSurface
          ? (compact
              ? const EdgeInsets.symmetric(
                  horizontal: kSpacingM,
                  vertical: kSpacingS,
                )
              : kReconSummaryPadding)
          : EdgeInsets.zero,
      decoration: showCardSurface
          ? BoxDecoration(
              color: reconBackgroundDarkColor(context),
              borderRadius: BorderRadius.circular(kReconSummaryBorderRadius),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: kReconSummaryBorderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Removed "Multi-Dose Vial: Reconstitution" header per user request
          // Centered content
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Science icon
              if (!compact) ...[
                Icon(
                  Icons.science_outlined,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
              ],
              // New format: "Reconstituted X of MedName with ReconVolume of ReconFluidName"
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: baseStyle,
                  children: [
                    const TextSpan(text: 'Reconstituted '),
                    TextSpan(
                      text: '${_formatNoTrailing(strengthValue)} $strengthUnit',
                      style: strengthStyle,
                    ),
                    TextSpan(
                      text: ' of ',
                      style: ofStyle,
                    ),
                    TextSpan(
                      text: medicationName,
                      style: medicationNameStyle,
                    ),
                    if (reconFluidName != null &&
                        reconFluidName!.isNotEmpty &&
                        containerVolumeMl != null) ...[
                      TextSpan(
                        text: '\nwith ',
                        style: metaStyle,
                      ),
                      TextSpan(
                        text: '${_formatNoTrailing(containerVolumeMl!)} mL',
                        style: metaPrimaryStyle,
                      ),
                      TextSpan(
                        text: ' of $reconFluidName',
                        style: metaStyle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (containerVolumeMl != null && containerVolumeMl! > 0) ...[
            SizedBox(height: compact ? 4 : 6),
            // Divider line
            Container(
              height: kReconDividerHeight,
              margin: EdgeInsets.symmetric(
                vertical: compact ? 8 : kReconDividerVerticalMargin,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.surface.withValues(alpha: kOpacityTransparent),
                    theme.colorScheme.primary.withValues(
                      alpha: kReconDividerOpacity,
                    ),
                    cs.surface.withValues(alpha: kOpacityTransparent),
                  ],
                  stops: kReconDividerStops,
                ),
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            // Total volume line
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: baseStyle,
                children: [
                  const TextSpan(text: 'Total Volume  '),
                  TextSpan(
                    text: '${_formatNoTrailing(containerVolumeMl!)} mL',
                    style: totalVolumeStyle,
                  ),
                ],
              ),
            ),
          ],
          if (perMlValue != null && perMlValue! > 0) ...[
            SizedBox(height: compact ? 8 : 14),
            // Concentration line
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: baseStyle,
                children: [
                  const TextSpan(text: 'Concentration  '),
                  TextSpan(
                    text:
                        '${_formatNoTrailing(perMlValue!)} ${strengthUnit.replaceAll('/mL', '')}/mL',
                    style: valueStyle,
                  ),
                ],
              ),
            ),
          ],
          if (volumePerDose != null && volumePerDose! > 0) ...[
            SizedBox(height: compact ? 8 : 14),
            // Volume per dose line
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: baseStyle,
                children: [
                  const TextSpan(text: 'Volume per Dose  '),
                  TextSpan(
                    text: '${_formatNoTrailing(volumePerDose!)} mL',
                    style: valueStyle,
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
            // Syringe size text
            if (syringeSizeMl != null)
              Text(
                '${_formatNoTrailing(syringeSizeMl!)} mL (${(syringeSizeMl! * 100).round()} U) Syringe',
                textAlign: TextAlign.center,
                style: reconSummaryEmphasisTextStyle(
                  context,
                  color: baseTextColor,
                  fontSize: kReconSummarySyringeLineFontSize,
                  fontWeight: kFontWeightMedium,
                ),
              ),
            const SizedBox(height: 6),
            // Syringe gauge showing target dose
            WhiteSyringeGauge(
              totalUnits: (syringeSizeMl ?? 3.0) * 100,
              fillUnits: volumePerDose! * 100,
              showValueLabel: true,
            ),
            const SizedBox(height: 8), // Extra padding to prevent cropping
          ],
        ],
      ),
    );
  }
}
