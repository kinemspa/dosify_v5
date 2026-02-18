import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String _kDebugBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

class AdService {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  static String bannerAdUnitId() {
    if (kDebugMode) return _kDebugBannerAdUnitId;
    return const String.fromEnvironment(
      'DOSIFI_BANNER_AD_UNIT_ID',
      defaultValue: _kDebugBannerAdUnitId,
    );
  }
}
