// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/monetization/billing_service.dart';
import 'package:skedux/src/core/monetization/entitlement_service.dart';
import 'package:skedux/src/core/monetization/monetization_metrics_service.dart';
import 'package:skedux/src/widgets/app_header.dart';
import 'package:skedux/src/widgets/app_snackbar.dart';

class PurchasesPage extends ConsumerWidget {
  const PurchasesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final entitlement = ref.watch(entitlementServiceProvider);
    final billing = ref.watch(billingServiceProvider);

    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Purchases & Pro',
        forceBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(kSpacingM),
        children: [
          // ── Pro status banner ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: kSpacingL),
            padding: const EdgeInsets.all(kSpacingL),
            decoration: BoxDecoration(
              color: entitlement.isPro
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(kBorderRadiusLarge),
              border: Border.all(
                color: entitlement.isPro
                    ? cs.primary.withValues(alpha: 0.4)
                    : cs.outline.withValues(alpha: 0.3),
                width: kBorderWidthThin,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  entitlement.isPro
                      ? Icons.workspace_premium
                      : Icons.workspace_premium_outlined,
                  size: kIconSizeLarge,
                  color: entitlement.isPro ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: kSpacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entitlement.isPro ? 'Pro — Unlocked' : 'Free Tier',
                        style: cardTitleStyle(context)?.copyWith(
                          fontWeight: kFontWeightBold,
                          color: entitlement.isPro ? cs.primary : null,
                        ),
                      ),
                      const SizedBox(height: kSpacingXXS),
                      Text(
                        entitlement.isPro
                            ? 'Unlimited medications and no ads'
                            : billing.product != null
                            ? 'Up to $kFreeTierMedicationLimit medications + ads\nPro upgrade: ${billing.product!.price}'
                            : 'Up to $kFreeTierMedicationLimit medications + ads',
                        style: helperTextStyle(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Upgrade options (only if not Pro) ────────────────────────────
          if (!entitlement.isPro) ...[
            Text(
              'Upgrade',
              style: cardTitleStyle(context)
                  ?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
            ),
            const SizedBox(height: kSpacingS),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Pro benefits'),
              subtitle: const Text('Unlimited medications + no ads'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await MonetizationMetricsService.trackPaywallShown();
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Go Pro'),
                      content: Text(
                        'Unlock unlimited medications and remove ads. '
                        'Purchases are linked to your Google Play account and '
                        'can be restored on reinstall or new device.',
                        style: bodyTextStyle(dialogContext),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Not now'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            final started = await ref
                                .read(billingServiceProvider.notifier)
                                .buyProLifetime();
                            if (!context.mounted || !started) return;
                            showAppSnackBar(
                              context,
                              'Purchase flow started. Complete checkout in Google Play.',
                            );
                          },
                          child: const Text('Buy Pro'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Buy Pro (lifetime)'),
              subtitle: Text(
                billing.product?.price ?? 'Loading product…',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: billing.isLoading
                  ? null
                  : () async {
                      final started = await ref
                          .read(billingServiceProvider.notifier)
                          .buyProLifetime();
                      if (!context.mounted || !started) return;
                      showAppSnackBar(
                        context,
                        'Purchase flow started. Complete checkout in Google Play.',
                      );
                    },
            ),
            const SizedBox(height: kSpacingL),
          ],

          // ── Purchase management ──────────────────────────────────────────
          Text(
            'Manage',
            style: cardTitleStyle(
              context,
            )?.copyWith(fontWeight: kFontWeightBold, color: cs.primary),
          ),
          const SizedBox(height: kSpacingS),
          ListTile(
            leading: const Icon(Icons.restore_rounded),
            title: const Text('Restore purchases'),
            subtitle: const Text('Refresh Pro entitlement on this device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await ref
                  .read(billingServiceProvider.notifier)
                  .restorePurchases();
              await ref.read(entitlementServiceProvider.notifier).restore();
              if (!context.mounted) return;
              final isProNow = ref.read(entitlementServiceProvider).isPro;
              showAppSnackBar(
                context,
                isProNow
                    ? 'Pro entitlement restored'
                    : 'No Pro entitlement found for this device/account',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Manage purchases'),
            subtitle: const Text('Open Google Play purchases/subscriptions'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              await ref
                  .read(billingServiceProvider.notifier)
                  .openManagePurchases();
            },
          ),

          if (billing.lastError != null &&
              billing.lastError!.trim().isNotEmpty) ...[
            const SizedBox(height: kSpacingS),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
              child: Text(
                billing.lastError!,
                style: helperTextStyle(context, color: cs.error),
              ),
            ),
          ],

          const SizedBox(height: kSpacingL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
            child: Text(
              'Pro unlock is tied to your Google Play account. Use "Restore purchases" after reinstalling or switching devices.',
              style: helperTextStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
