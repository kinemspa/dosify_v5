// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/data/saved_reconstitution_repository.dart';
import 'package:dosifi_v5/src/features/medications/domain/saved_reconstitution_calculation.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

class SavedReconstitutionSheet extends StatelessWidget {
  const SavedReconstitutionSheet({
    required this.repo,
    required this.onSelect,
    super.key,
    this.allowManage = false,
    this.onRename,
    this.onDelete,
  });

  final SavedReconstitutionRepository repo;
  final ValueChanged<SavedReconstitutionCalculation> onSelect;
  final bool allowManage;
  final Future<void> Function(SavedReconstitutionCalculation item)? onRename;
  final Future<void> Function(SavedReconstitutionCalculation item)? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(kSpacingL, kSpacingM, kSpacingL, 0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(kBorderRadiusXLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Saved Reconstitutions',
                    style: cardTitleStyle(context),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            buildSectionHelperText(
              context,
              'Tap one to load it into the calculator.',
            ),
            Flexible(
              child: ValueListenableBuilder<Box<SavedReconstitutionCalculation>>(
                valueListenable: repo.listenable(),
                builder: (context, box, _) {
                  final items = repo.allSorted();
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(kSpacingL),
                      child: Text(
                        'No saved reconstitutions yet.',
                        style: helperTextStyle(context),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: kSpacingL),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: kSpacingS),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final subtitleParts = <String>[];
                      if (item.medicationName != null &&
                          item.medicationName!.trim().isNotEmpty) {
                        subtitleParts.add(item.medicationName!.trim());
                      }
                      subtitleParts.add(
                        '${item.strengthValue.toStringAsFixed(2)} ${item.strengthUnit}',
                      );
                      subtitleParts.add(
                        '${item.solventVolumeMl.toStringAsFixed(2)} mL',
                      );
                      subtitleParts.add(
                        '${item.recommendedUnits.toStringAsFixed(0)} units',
                      );
                      subtitleParts.add(
                        '${item.syringeSizeMl.toStringAsFixed(1)} mL syringe',
                      );

                      return InkWell(
                        onTap: () => onSelect(item),
                        borderRadius: BorderRadius.circular(
                          kBorderRadiusMedium,
                        ),
                        child: Container(
                          decoration: softWhiteCardDecoration(context),
                          padding: const EdgeInsets.all(kSpacingM),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: bodyTextStyle(context),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitleParts.join(' • '),
                                      style: helperTextStyle(context),
                                    ),
                                  ],
                                ),
                              ),
                              if (allowManage) ...[
                                IconButton(
                                  tooltip: 'Rename',
                                  onPressed: onRename == null
                                      ? null
                                      : () => onRename!(item),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: onDelete == null
                                      ? null
                                      : () => onDelete!(item),
                                  icon: Icon(
                                    Icons.delete,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
