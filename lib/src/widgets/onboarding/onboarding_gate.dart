// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/ui/onboarding_settings.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({required this.child, super.key});

  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _completed;

  @override
  void initState() {
    super.initState();
    OnboardingSettings.replaySignal.addListener(_handleReplaySignal);
    unawaited(_load());
  }

  void _handleReplaySignal() {
    unawaited(_load());
  }

  Future<void> _load() async {
    final completed = await OnboardingSettings.isCompleted();
    if (!mounted) return;
    setState(() => _completed = completed);
  }

  Future<void> _finish() async {
    await OnboardingSettings.markCompleted();
    if (!mounted) return;
    setState(() => _completed = true);
  }

  @override
  void dispose() {
    OnboardingSettings.replaySignal.removeListener(_handleReplaySignal);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completed;
    if (completed == null || completed) return widget.child;

    return _OnboardingFlow(onFinish: _finish);
  }
}

class _OnboardingFlow extends StatefulWidget {
  const _OnboardingFlow({required this.onFinish});

  final Future<void> Function() onFinish;

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  static const int _welcomeIndex = 0;

  final PageController _pageController = PageController();
  int _pageIndex = 0;

  final List<_OnboardingTip> _tips = const [
    _OnboardingTip(
      icon: Icons.today_rounded,
      title: 'Today card',
      body:
          'See what is due now, and quickly mark doses as taken, skipped, or snoozed.',
    ),
    _OnboardingTip(
      icon: Icons.medication_rounded,
      title: 'Medication tracking',
      body:
          'Track medicine details, strength, stock, expiry, and storage in one place.',
    ),
    _OnboardingTip(
      icon: Icons.schedule_rounded,
      title: 'Schedules',
      body:
          'Create flexible schedules with multiple times and keep your routine consistent.',
    ),
    _OnboardingTip(
      icon: Icons.science_rounded,
      title: 'Reconstitution calculator',
      body:
          'Use the calculator for vial workflows and keep dose metrics organized.',
    ),
  ];

  int get _lastTipPageIndex => _tips.length;

  bool get _isWelcomePage => _pageIndex == _welcomeIndex;

  bool get _isLastPage => _pageIndex == _lastTipPageIndex;

  Future<void> _goNext() async {
    if (_isLastPage) {
      await widget.onFinish();
      return;
    }

    final nextIndex = _pageIndex + 1;
    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goBack() async {
    if (_isWelcomePage) return;
    final previousIndex = _pageIndex - 1;
    await _pageController.animateToPage(
      previousIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: kPagePadding,
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _pageIndex = index);
                  },
                  children: [
                    _WelcomeSplashPage(onStart: _goNext),
                    for (final tip in _tips) _OnboardingTipPage(tip: tip),
                  ],
                ),
              ),
              const SizedBox(height: kSpacingM),
              Row(
                children: [
                  TextButton(
                    onPressed: widget.onFinish,
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  if (!_isWelcomePage)
                    OutlinedButton(
                      onPressed: _goBack,
                      child: const Text('Back'),
                    ),
                  if (!_isWelcomePage) const SizedBox(width: kSpacingS),
                  FilledButton(
                    onPressed: _goNext,
                    child: Text(_isLastPage ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
              const SizedBox(height: kSpacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i <= _lastTipPageIndex; i++)
                    Container(
                      width: kSpacingS,
                      height: kSpacingS,
                      margin: const EdgeInsets.symmetric(horizontal: kSpacingXXS),
                      decoration: BoxDecoration(
                        color: i == _pageIndex
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: kOpacityLow),
                        borderRadius: BorderRadius.circular(kBorderRadiusFull),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: kSpacingXS),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeSplashPage extends StatelessWidget {
  const _WelcomeSplashPage({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoWidth =
            (constraints.maxWidth * kOnboardingLogoWidthFactor).clamp(
              kOnboardingLogoMinWidth,
              kOnboardingLogoMaxWidth,
            );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kOnboardingContentMaxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(kBorderRadiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpacingL,
                  vertical: kSpacingXL,
                ),
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
                      'Welcome to Dosifi',
                      textAlign: TextAlign.center,
                      style: homeHeroTitleStyle(context)?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: kSpacingXS),
                    Text(
                      kPrimaryBrandTagline,
                      textAlign: TextAlign.center,
                      style: splashTaglineTextStyle(context),
                    ),
                    const SizedBox(height: kSpacingL),
                    FilledButton(
                      onPressed: onStart,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onPrimary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Start Quick Tips'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingTipPage extends StatelessWidget {
  const _OnboardingTipPage({required this.tip});

  final _OnboardingTip tip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kOnboardingContentMaxWidth),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(kSpacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tip.icon, size: kOnboardingTipIconSize, color: cs.primary),
                const SizedBox(height: kSpacingS),
                Text(
                  tip.title,
                  textAlign: TextAlign.center,
                  style: sectionTitleStyle(context),
                ),
                const SizedBox(height: kSpacingS),
                Text(
                  tip.body,
                  textAlign: TextAlign.center,
                  style: helperTextStyle(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingTip {
  const _OnboardingTip({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
