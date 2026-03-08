// Reconstitution section extracted from medication_detail_page.dart (#166).
import 'package:flutter/material.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:skedux/src/features/medications/domain/enums.dart';
import 'package:skedux/src/features/medications/domain/medication.dart';
import 'package:skedux/src/features/schedules/domain/entry_calculator.dart';
import 'package:skedux/src/widgets/glass_card_surface.dart';
import 'package:skedux/src/widgets/reconstitution_summary_card.dart';

// ---------------------------------------------------------------------------
// Private helper functions
// ---------------------------------------------------------------------------

double? _inferEntryAmountFromSavedRecon(Medication med) {
  final perMl = med.perMlValue;
  final entryVolumeMl = med.volumePerEntry;
  if (perMl == null || entryVolumeMl == null) return null;
  if (perMl <= 0 || entryVolumeMl <= 0) return null;
  return perMl * entryVolumeMl;
}

String _unitLabel(Unit unit) => switch (unit) {
      Unit.mcg => 'mcg',
      Unit.mg => 'mg',
      Unit.g => 'g',
      Unit.units => 'units',
      Unit.mcgPerMl => 'mcg/mL',
      Unit.mgPerMl => 'mg/mL',
      Unit.gPerMl => 'g/mL',
      Unit.unitsPerMl => 'units/mL',
    };

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Reconstitution card with expand/collapse, shown on the medication detail page.
///
/// [isExpanded] and [onExpandedChanged] are owned by the parent so the parent
/// can coordinate the reorder-handle gutter logic across all cards.
/// [onEdit] is called when the user taps anywhere on the card to open the
/// reconstitution calculator.
class MedicationReconstitutionSection extends StatelessWidget {
  const MedicationReconstitutionSection({
    super.key,
    required this.med,
    required this.isExpanded,
    required this.onExpandedChanged,
    required this.onEdit,
  });

  final Medication med;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (med.form != MedicationForm.multiDoseVial ||
        med.strengthValue <= 0 ||
        (med.containerVolumeMl == null && med.perMlValue == null)) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    final savedRecon =
        SavedReconstitutionRepository().ownedForMedication(med.id);
    final actualEntryStrengthValue =
        (savedRecon?.calculatedEntry != null && savedRecon!.calculatedEntry! > 0)
            ? savedRecon.calculatedEntry
            : _inferEntryAmountFromSavedRecon(med);
    final actualEntryStrengthUnit =
        savedRecon?.entryUnit?.trim().isNotEmpty == true
            ? savedRecon!.entryUnit!.trim()
            : _unitLabel(med.strengthUnit);
    final syringeSizeMl =
        (savedRecon != null && savedRecon.syringeSizeMl > 0)
            ? savedRecon.syringeSizeMl
            : 3.0;
    final diluentName = savedRecon?.diluentName ?? med.diluentName;
    final volumePerEntry = med.volumePerEntry ??
        (savedRecon != null && savedRecon.calculatedUnits > 0
            ? savedRecon.calculatedUnits / SyringeType.ml_1_0.unitsPerMl
            : null);

    return GlassCardSurface(
      useGradient: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onEdit,
            child: Padding(
              padding: kDetailCardCollapsedHeaderPadding,
              child: Row(
                children: [
                  if (!isExpanded)
                    const SizedBox(
                      width: kDetailCardReorderHandleGutterWidth,
                    ),
                  Icon(
                    Icons.science_outlined,
                    size: kIconSizeMedium,
                    color: cs.primary,
                  ),
                  const SizedBox(width: kSpacingS),
                  Text(
                    'Reconstitution',
                    style: cardTitleStyle(context)?.copyWith(color: cs.primary),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: ConstrainedBox(
                      constraints: kTightIconButtonConstraints,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onExpandedChanged(!isExpanded),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: kIconSizeLarge,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                kCardPadding,
                0,
                kCardPadding,
                kCardPadding,
              ),
              child: InkWell(
                onTap: onEdit,
                child: ReconstitutionSummaryCard(
                  strengthValue: med.strengthValue,
                  strengthUnit: _unitLabel(med.strengthUnit),
                  medicationName: med.name,
                  containerVolumeMl: med.containerVolumeMl,
                  perMlValue: med.perMlValue,
                  volumePerEntry: volumePerEntry,
                  entryStrengthValue: actualEntryStrengthValue,
                  entryStrengthUnit: actualEntryStrengthUnit,
                  reconFluidName: diluentName ?? 'Bacteriostatic Water',
                  syringeSizeMl: syringeSizeMl,
                  compact: true,
                  showCardSurface: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
