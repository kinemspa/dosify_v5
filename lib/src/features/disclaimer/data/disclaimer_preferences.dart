// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

const _kDisclaimerKey = 'disclaimer.accepted_v1';

/// Persists and exposes the disclaimer acceptance state.
/// Used as a [GoRouter.refreshListenable] to gate first-run navigation.
class DisclaimerNotifier extends ChangeNotifier {
  bool _accepted = false;

  bool get isAccepted => _accepted;

  /// Load the persisted state from SharedPreferences.
  /// Must be called before the router is first evaluated.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accepted = prefs.getBool(_kDisclaimerKey) ?? false;
    notifyListeners();
  }

  /// Mark the disclaimer as accepted and persist the decision.
  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDisclaimerKey, true);
    _accepted = true;
    notifyListeners();
  }

  /// Clear acceptance (used from Settings → Research Disclaimer).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDisclaimerKey);
    _accepted = false;
    notifyListeners();
  }
}
