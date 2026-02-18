import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kEntitlementIsProPrefsKey = 'entitlement_is_pro';
const int kFreeTierMedicationLimit = 3;

class EntitlementState {
  const EntitlementState({required this.isPro, this.isLoaded = false});

  final bool isPro;
  final bool isLoaded;

  bool get shouldShowAds => !isPro;

  bool canAddMedication(int currentMedicationCount) {
    return isPro || currentMedicationCount < kFreeTierMedicationLimit;
  }

  EntitlementState copyWith({bool? isPro, bool? isLoaded}) {
    return EntitlementState(
      isPro: isPro ?? this.isPro,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class EntitlementService extends StateNotifier<EntitlementState> {
  EntitlementService() : super(const EntitlementState(isPro: false));

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool(kEntitlementIsProPrefsKey) ?? false;
    state = state.copyWith(isPro: isPro, isLoaded: true);
  }

  Future<void> setPro(bool isPro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kEntitlementIsProPrefsKey, isPro);
    state = state.copyWith(isPro: isPro, isLoaded: true);
  }

  Future<void> clearLocalEntitlement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kEntitlementIsProPrefsKey);
    state = state.copyWith(isPro: false, isLoaded: true);
  }
}

final entitlementServiceProvider =
    StateNotifierProvider<EntitlementService, EntitlementState>((ref) {
      final service = EntitlementService();
      service.restore();
      return service;
    });
