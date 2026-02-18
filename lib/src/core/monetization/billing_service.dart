import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:dosifi_v5/src/core/monetization/entitlement_service.dart';
import 'package:dosifi_v5/src/core/monetization/monetization_metrics_service.dart';

const String kProLifetimeProductId = 'dosifi_pro_lifetime';

class BillingState {
  const BillingState({
    this.available = false,
    this.isLoading = false,
    this.product,
    this.lastError,
  });

  final bool available;
  final bool isLoading;
  final ProductDetails? product;
  final String? lastError;

  BillingState copyWith({
    bool? available,
    bool? isLoading,
    ProductDetails? product,
    String? lastError,
  }) {
    return BillingState(
      available: available ?? this.available,
      isLoading: isLoading ?? this.isLoading,
      product: product ?? this.product,
      lastError: lastError,
    );
  }
}

class BillingService extends StateNotifier<BillingState> {
  BillingService(this._ref)
    : _iap = InAppPurchase.instance,
      super(const BillingState()) {
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        state = state.copyWith(isLoading: false, lastError: error.toString());
      },
    );
    unawaited(initialize());
  }

  final Ref _ref;
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, lastError: null);
    final available = await _iap.isAvailable();
    if (!available) {
      state = state.copyWith(
        available: false,
        isLoading: false,
        lastError: null,
      );
      return;
    }

    final response = await _iap.queryProductDetails({kProLifetimeProductId});
    ProductDetails? product;
    if (response.productDetails.isNotEmpty) {
      product = response.productDetails.firstWhere(
        (p) => p.id == kProLifetimeProductId,
        orElse: () => response.productDetails.first,
      );
    }

    state = state.copyWith(
      available: true,
      isLoading: false,
      product: product,
      lastError: response.error?.message,
    );
  }

  Future<bool> buyProLifetime() async {
    final product = state.product;
    if (product == null || !state.available) {
      state = state.copyWith(lastError: 'Pro product is not available.');
      return false;
    }

    state = state.copyWith(isLoading: true, lastError: null);
    await MonetizationMetricsService.trackPurchaseStarted();
    final param = PurchaseParam(productDetails: product);
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      state = state.copyWith(
        isLoading: false,
        lastError: 'Purchase could not be started.',
      );
    }
    return started;
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, lastError: null);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      state = state.copyWith(isLoading: false, lastError: e.toString());
      rethrow;
    }
  }

  Future<void> openManagePurchases() async {
    if (!Platform.isAndroid) return;
    final packageInfo = await PackageInfo.fromPlatform();
    final intents = <AndroidIntent>[
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'https://play.google.com/store/account/subscriptions',
        flags: <int>[268435456],
      ),
      AndroidIntent(
        action: 'android.intent.action.VIEW',
        data:
            'https://play.google.com/store/apps/details?id=${packageInfo.packageName}',
        flags: const <int>[268435456],
      ),
    ];

    for (final intent in intents) {
      try {
        await intent.launch();
        return;
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    var granted = false;
    for (final purchase in purchases) {
      if (purchase.productID != kProLifetimeProductId) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.purchased:
          granted = true;
          await MonetizationMetricsService.trackPurchaseSuccess();
          await _ref.read(entitlementServiceProvider.notifier).setPro(true);
          break;
        case PurchaseStatus.restored:
          granted = true;
          await MonetizationMetricsService.trackRestoreSuccess();
          await _ref.read(entitlementServiceProvider.notifier).setPro(true);
          break;
        case PurchaseStatus.pending:
          state = state.copyWith(isLoading: true, lastError: null);
          break;
        case PurchaseStatus.error:
          state = state.copyWith(
            isLoading: false,
            lastError: purchase.error?.message ?? 'Purchase failed',
          );
          break;
        case PurchaseStatus.canceled:
          state = state.copyWith(isLoading: false, lastError: null);
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }

    if (granted) {
      state = state.copyWith(isLoading: false, lastError: null);
      return;
    }

    if (state.isLoading) {
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}

final billingServiceProvider =
    StateNotifierProvider<BillingService, BillingState>((ref) {
      return BillingService(ref);
    });
