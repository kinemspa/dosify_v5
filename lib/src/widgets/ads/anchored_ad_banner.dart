import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/monetization/ad_service.dart';
import 'package:dosifi_v5/src/core/monetization/entitlement_service.dart';

class AnchoredAdBanner extends ConsumerStatefulWidget {
  const AnchoredAdBanner({super.key});

  @override
  ConsumerState<AnchoredAdBanner> createState() => _AnchoredAdBannerState();
}

class _AnchoredAdBannerState extends ConsumerState<AnchoredAdBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    await AdService.ensureInitialized();
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: AdService.bannerAdUnitId(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _loaded = false;
            _banner = null;
          });
        },
      ),
      request: const AdRequest(),
    );

    setState(() => _banner = banner);
    await banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(entitlementServiceProvider);
    if (!entitlement.shouldShowAds) {
      return const SizedBox.shrink();
    }

    if (!_loaded || _banner == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: kAnchoredAdBannerPadding,
        child: SizedBox(
          height: kAnchoredAdBannerHeight,
          child: Center(
            child: SizedBox(
              width: _banner!.size.width.toDouble(),
              height: _banner!.size.height.toDouble(),
              child: AdWidget(ad: _banner!),
            ),
          ),
        ),
      ),
    );
  }
}
