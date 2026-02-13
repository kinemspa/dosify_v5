import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

class BrandedLaunchGate extends StatefulWidget {
  const BrandedLaunchGate({required this.child, super.key});

  final Widget child;

  @override
  State<BrandedLaunchGate> createState() => _BrandedLaunchGateState();
}

class _BrandedLaunchGateState extends State<BrandedLaunchGate> {
  bool _showBranding = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(kBrandedLaunchHoldDuration, () {
      if (!mounted) return;
      setState(() => _showBranding = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
                        Text(
                          kPrimaryBrandTagline,
                          textAlign: TextAlign.center,
                          style: splashTaglineTextStyle(context),
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
