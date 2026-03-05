import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/medications/presentation/medication_providers.dart';

/// Displays a prominent call-to-action when the user has no medications yet.
///
/// Returns [SizedBox.shrink] once at least one medication exists.
/// Place this near the top of any page that is meaningless without medication
/// data (Home, Schedules, Calendar, Analytics, Inventory).
class NoMedicationsBanner extends ConsumerWidget {
  const NoMedicationsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(medicationsListProvider);
    if (meds.isNotEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingM,
        vertical: kSpacingL,
      ),
      child: Card(
        elevation: 0,
        color: cs.primaryContainer.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadiusLarge),
          side: BorderSide(
            color: cs.primary.withValues(alpha: 0.30),
            width: kBorderWidthThin,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(kSpacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medication_outlined,
                size: kEmptyStateIconSize,
                color: cs.primary,
              ),
              const SizedBox(height: kSpacingM),
              Text(
                'Add your first medication',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: kSpacingXS),
              Text(
                'Skedux tracks schedules, entries, and inventory per medication. '
                'Add one to get started.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: kSpacingL),
              FilledButton.icon(
                onPressed: () => context.go('/medications'),
                icon: const Icon(Icons.add),
                label: const Text('Add Medication'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
