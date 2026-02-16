import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/status_pill.dart';
import 'package:flutter/material.dart';

class MedicationDetailHeaderIdentity extends StatelessWidget {
  const MedicationDetailHeaderIdentity({
    super.key,
    required this.name,
    required this.formLabel,
    required this.headerForeground,
    required this.onPrimary,
    required this.t,
    required this.onTapName,
    this.manufacturer,
    this.onTapManufacturer,
  });

  final String name;
  final String formLabel;
  final String? manufacturer;
  final Color headerForeground;
  final Color onPrimary;
  final double t;
  final VoidCallback onTapName;
  final VoidCallback? onTapManufacturer;

  @override
  Widget build(BuildContext context) {
    final cleanManufacturer = manufacturer?.trim();

    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTapName,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: medicationDetailHeaderNameTextStyle(
                    context,
                    color: headerForeground,
                    t: t,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (t < 0.8) ...[
                  const SizedBox(height: kSpacingXS),
                  StatusPill(label: formLabel, color: onPrimary, dense: true),
                ],
              ],
            ),
          ),
          if (cleanManufacturer != null &&
              cleanManufacturer.isNotEmpty &&
              t < 0.5)
            GestureDetector(
              onTap: onTapManufacturer,
              child: Opacity(
                opacity: (1.0 - t * 2.0).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: kMedicationDetailHeaderManufacturerTopPadding,
                  ),
                  child: Text(
                    cleanManufacturer,
                    style:
                        microHelperTextStyle(
                          context,
                          color: onPrimary.withValues(alpha: 0.7),
                        )?.copyWith(
                          fontWeight: kFontWeightNormal,
                          letterSpacing: 0.2,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
