import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:flutter/material.dart';

class MedicationSealedVialsEditorCard extends StatelessWidget {
  const MedicationSealedVialsEditorCard({
    super.key,
    required this.sealedVialsCountLabel,
    required this.batchNumberValue,
    required this.expiryValue,
    required this.locationValue,
    required this.onEditBatchNumber,
    required this.onEditExpiry,
    required this.onEditLocation,
    required this.conditionsRow,
    this.batchNumberIsPlaceholder = false,
    this.expiryIsPlaceholder = false,
    this.locationIsPlaceholder = false,
    this.expiryIsWarning = false,
  });

  final String sealedVialsCountLabel;

  final String batchNumberValue;
  final bool batchNumberIsPlaceholder;
  final VoidCallback onEditBatchNumber;

  final String expiryValue;
  final bool expiryIsPlaceholder;
  final bool expiryIsWarning;
  final VoidCallback onEditExpiry;

  final String locationValue;
  final bool locationIsPlaceholder;
  final VoidCallback onEditLocation;

  final Widget conditionsRow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SectionFormCard(
      title: 'Sealed Vials',
      neutral: true,
      trailing: Text(
        sealedVialsCountLabel,
        style: bodyTextStyle(context)?.copyWith(fontWeight: kFontWeightBold),
      ),
      children: [
        Text('Used for reconstitution.', style: helperTextStyle(context)),
        const SizedBox(height: kSpacingS),
        _DetailTile(
          label: 'Batch #',
          value: batchNumberValue,
          isPlaceholder: batchNumberIsPlaceholder,
          onTap: onEditBatchNumber,
        ),
        _DetailTile(
          label: 'Expiry',
          value: expiryValue,
          isPlaceholder: expiryIsPlaceholder,
          isWarning: expiryIsWarning,
          onTap: onEditExpiry,
        ),
        _DetailTile(
          label: 'Location',
          value: locationValue,
          isPlaceholder: locationIsPlaceholder,
          onTap: onEditLocation,
        ),
        Divider(
          height: kBorderWidthThin,
          indent: kSpacingL,
          endIndent: kSpacingL,
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
        conditionsRow,
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.isPlaceholder = false,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isPlaceholder;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final labelStyle = smallHelperTextStyle(
      context,
      color: colorScheme.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh),
    )?.copyWith(fontWeight: kFontWeightSemiBold);

    final valueBaseStyle = bodyTextStyle(context)?.copyWith(
      fontWeight: kFontWeightNormal,
      color: colorScheme.onSurface.withValues(alpha: kOpacityMediumHigh),
    );

    final placeholderStyle = mutedTextStyle(
      context,
    )?.copyWith(fontStyle: FontStyle.italic);

    final warningStyle = valueBaseStyle?.copyWith(color: colorScheme.secondary);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingL,
          vertical: kSpacingS,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: kMedicationDetailInlineLabelWidth,
              child: Text(
                label,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: isWarning
                    ? warningStyle
                    : isPlaceholder
                    ? placeholderStyle
                    : valueBaseStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: kIconSizeSmall,
              color: colorScheme.onSurfaceVariant.withValues(
                alpha: kOpacityLow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
