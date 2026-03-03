import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

/// Branded launch gate that shows a primary-colour splash with logo and
/// animated tagline.  Displayed once per cold-start, then fades away.
///
/// Flow:
///   1. Overlay appears immediately (logo visible, tagline hidden).
///   2. After [kBrandedLaunchTaglineDelay] the tagline fades+slides in
///      over [kBrandedLaunchTaglineDuration].
///   3. Once the tagline animation completes, hold for
///      [kBrandedLaunchHoldAfterVisible] so the user can comfortably read.
///   4. Dismiss fade ([kBrandedLaunchDismissDuration]) then the overlay
///      is removed from the tree.
class BrandedLaunchGate extends StatefulWidget {
  const BrandedLaunchGate({required this.child, super.key});

  final Widget child;

  @override
  State<BrandedLaunchGate> createState() => _BrandedLaunchGateState();
}

class _BrandedLaunchGateState extends State<BrandedLaunchGate>
    with TickerProviderStateMixin {
  bool _showBranding = true;
  Timer? _holdTimer;
  Timer? _delayTimer;

  // Tagline: fade + gentle upward slide
  late final AnimationController _taglineController;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;

  // Logo: subtle scale-up entrance
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  // Dismiss: fade the whole overlay out
  late final AnimationController _dismissController;
  late final Animation<double> _dismissOpacity;

  @override
  void initState() {
    super.initState();

    // Logo scale animation (immediate, 400 ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: kBrandedLaunchTaglineDuration,
    );
    _taglineOpacity = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOut,
    );
    _taglineOffset = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOutCubic),
    );

    // Dismiss animation
    _dismissController = AnimationController(
      vsync: this,
      duration: kBrandedLaunchDismissDuration,
    );
    _dismissOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeIn),
    );

    // Start logo animation immediately
    _logoController.forward();

    // After logo settles, animate tagline in
    _delayTimer = Timer(kBrandedLaunchTaglineDelay, () {
      if (!mounted) return;
      _taglineController.forward().whenComplete(() {
        // Tagline fully visible — start hold timer
        if (!mounted) return;
        _holdTimer = Timer(kBrandedLaunchHoldAfterVisible, () {
          if (!mounted) return;
          _dismissController.forward().orCancel.then((_) {
            if (mounted) setState(() => _showBranding = false);
          }, onError: (_) {
            // Animation cancelled (widget disposed) — safe to ignore.
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _holdTimer?.cancel();
    _logoController.dispose();
    _taglineController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBranding) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Render the real child so it can load in the background
        widget.child,

        // Branding overlay — fades out on dismiss
        AnimatedBuilder(
          animation: _dismissOpacity,
          builder: (context, _) {
            return Opacity(
              opacity: _dismissOpacity.value,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.primary,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final logoWidth =
                        (constraints.maxWidth * kBrandedLaunchLogoWidthFactor)
                            .clamp(
                              kBrandedLaunchLogoMinWidth,
                              kBrandedLaunchLogoMaxWidth,
                            );

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpacingL,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo — scale-up entrance
                            ScaleTransition(
                              scale: _logoScale,
                              child: Image.asset(
                                kSplashLogoAssetPath,
                                width: logoWidth,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: kSpacingM),
                            // Tagline animates in below logo
                            // (invisible until kBrandedLaunchTaglineDelay fires)
                            FadeTransition(
                              opacity: _taglineOpacity,
                              child: SlideTransition(
                                position: _taglineOffset,
                                child: Text(
                                  kPrimaryBrandTagline,
                                  textAlign: TextAlign.center,
                                  style: splashTaglineTextStyle(context)
                                          ?.copyWith(color: Colors.white) ??
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: kFontSizeLarge,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

