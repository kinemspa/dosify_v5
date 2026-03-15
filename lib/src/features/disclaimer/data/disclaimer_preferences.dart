// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'package:skedux/src/core/legal/disclaimer_settings.dart';

/// Persists and exposes the disclaimer acceptance state.
/// Used as a [GoRouter.refreshListenable] to gate first-run navigation.
class DisclaimerNotifier extends ChangeNotifier {
  bool _accepted = false;

  bool get isAccepted => _accepted;

  /// Load the persisted state from SharedPreferences.
  /// Must be called before the router is first evaluated.
  Future<void> load() async {
    _accepted = await DisclaimerSettings.isAccepted();
    notifyListeners();
  }

  /// Mark the disclaimer as accepted and persist the decision.
  Future<void> accept() async {
    await DisclaimerSettings.markAccepted();
    _accepted = true;
    notifyListeners();
  }

  /// Clear acceptance (used from Settings → Research Disclaimer).
  Future<void> reset() async {
    await DisclaimerSettings.reset();
    _accepted = false;
    notifyListeners();
  }
}
