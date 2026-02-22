import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

/// Branded launch gate that shows a primary-colour splash with logo and
/// animated tagline.  Displayed once per cold-start, then fades away.
class BrandedLaunchGate extends StatefulWidget {
  const BrandedLaunchGate({required this.child, super.key});

  final Widget child;

  @override
  State<BrandedLaunchGate> createState() => _BrandedLaunchGateState();
}

class _BrandedLaunchGateState extends State<BrandedLaunchGate>
    with TickerProviderStateMixin {
  bool _showBranding = true;
  Timer? _timer;

  // Tagline: fade + gentle upward slide
  late final AnimationController _taglineController;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;

  // Dismiss: fade the whole overlay out
  late final AnimationController _dismissController;
  late final Animation<double> _dismissOpacity;

  @override
  void initState() {
    super.initState();

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _taglineController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _taglineOffset = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _taglineController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Dismiss animation (fade to transparent)
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _dismissOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeIn),
    );

    // Start tagline animation immediately
    _taglineController.forward();

    // Hold for the configured duration, then fade out
    _timer = Timer(kBrandedLaunchHoldDuration, () {
      if (!mounted) return;
      _dismissController.forward().orCancel.then((_) {
        if (mounted) setState(() => _showBranding = false);
      }, onError: (_) {
        // Animation cancelled (widget disposed) — safe to ignore.
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
                            // Logo — static, never moves
                            Image.asset(
                              kSplashLogoAssetPath,
                              width: logoWidth,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: kSpacingM),
                            // Tagline animates in below logo
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
