import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

class BrandedLaunchGate extends StatefulWidget {
  const BrandedLaunchGate({required this.child, super.key});

  final Widget child;

  @override
  State<BrandedLaunchGate> createState() => _BrandedLaunchGateState();
}

class _BrandedLaunchGateState extends State<BrandedLaunchGate>
    with SingleTickerProviderStateMixin {
  bool _showBranding = true;
  Timer? _timer;
  late final AnimationController _taglineController;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;

  @override
  void initState() {
    super.initState();
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _taglineController,
      curve: const Interval(0.25, 1, curve: Curves.easeOut),
    );
    _taglineOffset = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _taglineController,
        curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
      ),
    );

    _taglineController.forward();

    _timer = Timer(kBrandedLaunchHoldDuration, () {
      if (!mounted) return;
      setState(() => _showBranding = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.child;
    if (!_showBranding) return content;

    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: SafeArea(
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
                    padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          kSplashLogoAssetPath,
                          width: logoWidth,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: kSpacingM),
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: SlideTransition(
                            position: _taglineOffset,
                            child: Text(
                              kPrimaryBrandTagline,
                              textAlign: TextAlign.center,
                              style:
                                  splashTaglineTextStyle(context)?.copyWith(
                                    color: Colors.white,
                                  ) ??
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
        ),
      ],
    );
  }
}
