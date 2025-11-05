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
  });

  final double strengthValue;
  final String strengthUnit;
  final String medicationName;
  final double? containerVolumeMl;
  final double? perMlValue;
  final double? volumePerDose;
  final String? reconFluidName;
  final double? syringeSizeMl;

  String _formatNoTrailing(double value) {
    final str = value.toStringAsFixed(2);
    if (str.endsWith('.00')) return value.toInt().toString();
    if (str.endsWith('0')) return str.substring(0, str.length - 1);
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: kReconSummaryPadding,
      decoration: BoxDecoration(
        color: kReconBackgroundActive,
        borderRadius: BorderRadius.circular(kReconSummaryBorderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: kReconSummaryBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: "Multi-Dose Vial: Reconstitution" aligned left
          Text(
            'Multi-Dose Vial: Reconstitution',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // Center the rest of the content
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Science icon
              Icon(
                Icons.science_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              // Medication strength and name with "Reconstituted" prefix and fluid
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(kReconTextHighOpacity),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Reconstituted '),
                    TextSpan(
                      text: '${_formatNoTrailing(strengthValue)} $strengthUnit',
                      style: TextStyle(
                        fontSize: 20,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: '  of  ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(kReconTextHighOpacity),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: medicationName,
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (reconFluidName != null && reconFluidName!.isNotEmpty)
                      TextSpan(
                        text: '\nwith $reconFluidName',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(
                            kReconTextHighOpacity,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (containerVolumeMl != null && containerVolumeMl! > 0) ...[
            const SizedBox(height: 6),
            // Divider line
            Container(
              height: kReconDividerHeight,
              margin: EdgeInsets.symmetric(
                vertical: kReconDividerVerticalMargin,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.primary.withOpacity(kReconDividerOpacity),
                    Colors.transparent,
                  ],
                  stops: kReconDividerStops,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Total volume line
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(kReconTextHighOpacity),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Total Volume  '),
                  TextSpan(
                    text: '${_formatNoTrailing(containerVolumeMl!)} mL',
                    style: TextStyle(
                      fontSize: 22,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (perMlValue != null && perMlValue! > 0) ...[
            const SizedBox(height: 14),
            // Concentration line
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(kReconTextHighOpacity),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Concentration  '),
                  TextSpan(
                    text:
                        '${_formatNoTrailing(perMlValue!)} ${strengthUnit.replaceAll('/mL', '')}/mL',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (volumePerDose != null && volumePerDose! > 0) ...[
            const SizedBox(height: 14),
            // Volume per dose line
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(kReconTextHighOpacity),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Volume per Dose  '),
                  TextSpan(
                    text: '${_formatNoTrailing(volumePerDose!)} mL',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Syringe size text
            if (syringeSizeMl != null)
              Text(
                '${_formatNoTrailing(syringeSizeMl!)} mL Syringe',
                textAlign: TextAlign.center,
                style: helperTextStyle(context)?.copyWith(
                  color: Colors.white.withOpacity(kReconTextHighOpacity),
                  fontSize: 11,
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
