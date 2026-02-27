// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:dosifi_v5/src/app/app_navigator.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/ui/onboarding_settings.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

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

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        _OnboardingCoachOverlay(onFinish: _finish),
      ],
    );
  }
}

class _OnboardingCoachOverlay extends StatefulWidget {
  const _OnboardingCoachOverlay({required this.onFinish});

  final Future<void> Function() onFinish;

  @override
  State<_OnboardingCoachOverlay> createState() =>
      _OnboardingCoachOverlayState();
}

class _OnboardingCoachOverlayState extends State<_OnboardingCoachOverlay> {
  int _stepIndex = 0;
  bool _queuedRouteSync = false;

  final List<_CoachStep> _steps = const [
    _CoachStep(
      title: 'Home screen',
      message:
          'This is your dashboard with an overall view of medications, schedules, and due doses.',
      routePath: '/',
      targetAlignment: Alignment(0, -0.70),
    ),
    _CoachStep(
      title: 'Medications',
      message:
          'Add medications here and track stock, expiry, and core medication details.',
      routePath: '/medications',
      targetAlignment: Alignment(-0.25, 0.92),
    ),
    _CoachStep(
      title: 'Schedules',
      message:
          'Create dose schedules here. You receive notifications from these schedules.',
      routePath: '/schedules',
      targetAlignment: Alignment(0.25, 0.92),
    ),
    _CoachStep(
      title: 'Schedule links',
      message:
          'Each schedule is attached to a medication, and doses are attached to a schedule.',
      routePath: '/schedules',
      targetAlignment: Alignment(0.25, 0.92),
    ),
    _CoachStep(
      title: 'Medication details',
      message:
          'Open any medication details page. It has an ad hoc dose action for doses taken outside a schedule.',
      routePath: '/medications/',
      usesPrefixMatch: true,
      waitForUserNavigation: true,
      openMedicationDetailIfAvailable: true,
      targetAlignment: Alignment(0, -0.18),
    ),
    _CoachStep(
      title: 'Reconstitution calculator',
      message:
          'Quickly calculate and save reconstitutions for later use when adding medications.',
      routePath: '/medications/reconstitution',
      targetAlignment: Alignment(-0.25, 0.92),
    ),
    _CoachStep(
      title: 'Multi-dose vial support',
      message:
          'Multi-dose vials include a built-in reconstitution calculator in their add/edit flow.',
      routePath: '/medications/add/injection/multi',
      targetAlignment: Alignment(-0.25, 0.92),
    ),
    _CoachStep(
      title: 'Analytics',
      message:
          'Get reports and trend insights across your dose activity and history.',
      routePath: '/analytics',
      targetAlignment: Alignment(0.68, -0.82),
    ),
    _CoachStep(
      title: 'Inventory',
      message:
          'See a quick overview of what remains in stock and what has been used over time.',
      routePath: '/inventory',
      targetAlignment: Alignment(0.68, -0.82),
    ),
  ];

  bool get _isLastStep => _stepIndex == _steps.length - 1;

  /// Returns true when the immediately next step targets the same route path,
  /// so a "Next" button is shown instead of "Got it".
  bool _hasNextStepOnSameRoute() {
    if (_isLastStep) return false;
    final current = _steps[_stepIndex];
    final next = _steps[_stepIndex + 1];
    return next.routePath == current.routePath;
  }

  String _currentPath(BuildContext context) {
    final rootContext = rootNavigatorKey.currentContext;
    if (rootContext != null) {
      return GoRouter.of(rootContext).routeInformationProvider.value.uri.path;
    }

    try {
      return GoRouter.of(context).routeInformationProvider.value.uri.path;
    } catch (_) {
      return '/';
    }
  }

  void _goToPath(String path) {
    final rootContext = rootNavigatorKey.currentContext;
    if (rootContext != null) {
      GoRouter.of(rootContext).go(path);
      return;
    }

    if (!mounted) return;
    try {
      GoRouter.of(context).go(path);
    } catch (_) {
      // No-op when router context is not available yet.
    }
  }

  bool _isOnStepRoute(_CoachStep step, String currentPath) {
    if (step.openMedicationDetailIfAvailable &&
        !_hasAnyMedications() &&
        currentPath == '/medications') {
      return true;
    }

    if (step.usesPrefixMatch) {
      return currentPath.startsWith(step.routePath);
    }
    return currentPath == step.routePath;
  }

  bool _hasAnyMedications() {
    final box = Hive.box<Medication>('medications');
    return box.isNotEmpty;
  }

  void _openMedicationDetailIfAvailable() {
    final box = Hive.box<Medication>('medications');
    if (box.isEmpty) {
      _goToPath('/medications');
      return;
    }

    final meds = box.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final firstMedicationId = meds.first.id;
    _goToPath('/medications/$firstMedicationId');
  }

  void _syncRouteForStep(_CoachStep step, String currentPath) {
    if (step.waitForUserNavigation || _isOnStepRoute(step, currentPath)) {
      return;
    }
    if (_queuedRouteSync) return;

    _queuedRouteSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queuedRouteSync = false;
      if (!mounted) return;
      _goToPath(step.routePath);
    });
  }

  Alignment _bubbleAlignmentForTarget(Alignment target) {
    final isLowerHalf = target.y > 0.25;
    final bubbleY = isLowerHalf ? 0.40 : -0.40;
    final bubbleX = target.x.clamp(-0.55, 0.55);
    return Alignment(bubbleX, bubbleY);
  }

  Future<void> _goNext() async {
    final step = _steps[_stepIndex];
    final currentPath = _currentPath(context);
    final onExpectedRoute = _isOnStepRoute(step, currentPath);

    if (step.waitForUserNavigation && !onExpectedRoute) {
      if (step.openMedicationDetailIfAvailable) {
        _openMedicationDetailIfAvailable();
      }
      return;
    }

    if (_isLastStep) {
      await widget.onFinish();
      return;
    }

    if (!mounted) return;
    setState(() => _stepIndex += 1);

    final next = _steps[_stepIndex];
    if (!next.waitForUserNavigation) {
      _goToPath(next.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final currentPath = _currentPath(context);
    _syncRouteForStep(step, currentPath);
    final onExpectedRoute = _isOnStepRoute(step, currentPath);
    final cs = Theme.of(context).colorScheme;
    final bubbleAlignment = _bubbleAlignmentForTarget(step.targetAlignment);
    final coachFg = kOnboardingCoachForegroundColor;
    final bubbleIsBelowTarget = bubbleAlignment.y > step.targetAlignment.y;

    return Material(
      color: Colors.black.withValues(alpha: 0.50),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final targetDeltaX = step.targetAlignment.x - bubbleAlignment.x;
            final pointerAlignmentX = (targetDeltaX *
                    (constraints.maxWidth / kOnboardingCoachBubbleMaxWidth))
                .clamp(
                  -kOnboardingCoachPointerClamp,
                  kOnboardingCoachPointerClamp,
                );

            return Stack(
              children: [
                Align(
                  alignment: bubbleAlignment,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<int>(_stepIndex),
                      constraints: const BoxConstraints(
                        maxWidth: kOnboardingCoachBubbleMaxWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (bubbleIsBelowTarget)
                            Align(
                              alignment: Alignment(pointerAlignmentX, 0),
                              child: Transform.translate(
                                offset: const Offset(
                                  0,
                                  kOnboardingCoachPointerOverlap,
                                ),
                                child: CustomPaint(
                                  size: const Size(
                                    kOnboardingCoachPointerSize * 2,
                                    kOnboardingCoachPointerSize,
                                  ),
                                  painter: _CoachBubblePointerPainter(
                                    color: cs.primary,
                                    pointUp: true,
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            width: double.infinity,
                            padding: kOnboardingCoachBubblePadding,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(
                                kBorderRadiusMedium,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style:
                                      sectionTitleStyle(
                                        context,
                                      )?.copyWith(color: coachFg) ??
                                      TextStyle(
                                        color: coachFg,
                                        fontSize: kOnboardingCoachTitleFontSize,
                                        fontWeight: kFontWeightBold,
                                      ),
                                ),
                                const SizedBox(height: kSpacingXS),
                                Text(
                                  step.message,
                                  style: helperTextStyle(
                                    context,
                                    color: coachFg,
                                  )?.copyWith(
                                    fontSize: kOnboardingCoachMessageFontSize,
                                  ),
                                ),
                                const SizedBox(height: kSpacingS),
                                Row(
                                  children: [
                                    Text(
                                      '${_stepIndex + 1}/${_steps.length}',
                                      style: smallHelperTextStyle(
                                        context,
                                        color: coachFg,
                                      )?.copyWith(
                                        fontSize: kOnboardingCoachMetaFontSize,
                                      ),
                                    ),
                                    const Spacer(),
                                    FilledButton(
                                      onPressed: _goNext,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: cs.primary.withValues(
                                          alpha: kOpacityMedium,
                                        ),
                                        foregroundColor: coachFg,
                                        side: BorderSide(
                                          color: coachFg,
                                          width: kBorderWidthThin,
                                        ),
                                        textStyle: TextStyle(
                                          color: coachFg,
                                          fontWeight: kFontWeightSemiBold,
                                        ),
                                      ),
                                      child: Text(
                                        step.waitForUserNavigation &&
                                                !onExpectedRoute
                                            ? 'Open page'
                                            : _hasNextStepOnSameRoute()
                                            ? 'Next'
                                            : (_isLastStep
                                                ? 'Close'
                                                : 'Got it'),
                                      ),
                                    ),
                                  ],
                                ),
                                if (step.waitForUserNavigation &&
                                    !onExpectedRoute)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: kSpacingXS,
                                    ),
                                    child: Text(
                                      'Navigate to the target page, then continue.',
                                      style: smallHelperTextStyle(
                                        context,
                                        color: coachFg,
                                      )?.copyWith(
                                        fontSize: kOnboardingCoachMetaFontSize,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!bubbleIsBelowTarget)
                            Align(
                              alignment: Alignment(pointerAlignmentX, 0),
                              child: Transform.translate(
                                offset: const Offset(
                                  0,
                                  -kOnboardingCoachPointerOverlap,
                                ),
                                child: CustomPaint(
                                  size: const Size(
                                    kOnboardingCoachPointerSize * 2,
                                    kOnboardingCoachPointerSize,
                                  ),
                                  painter: _CoachBubblePointerPainter(
                                    color: cs.primary,
                                    pointUp: false,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CoachStep {
  const _CoachStep({
    required this.title,
    required this.message,
    required this.routePath,
    required this.targetAlignment,
    this.usesPrefixMatch = false,
    this.waitForUserNavigation = false,
    this.openMedicationDetailIfAvailable = false,
  });

  final String title;
  final String message;
  final String routePath;
  final Alignment targetAlignment;
  final bool usesPrefixMatch;
  final bool waitForUserNavigation;
  final bool openMedicationDetailIfAvailable;
}

class _CoachBubblePointerPainter extends CustomPainter {
  _CoachBubblePointerPainter({required this.color, required this.pointUp});

  final Color color;
  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointUp) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CoachBubblePointerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointUp != pointUp;
  }
}
