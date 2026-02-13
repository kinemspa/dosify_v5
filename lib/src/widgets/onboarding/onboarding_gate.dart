// Flutter imports:
import 'dart:async';
import 'dart:math' as math;

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
  State<_OnboardingCoachOverlay> createState() => _OnboardingCoachOverlayState();
}

class _OnboardingCoachOverlayState extends State<_OnboardingCoachOverlay> {
  int _stepIndex = 0;

  final List<_CoachStep> _steps = const [
    _CoachStep(
      title: 'Home screen',
      message:
          'This is your dashboard with an overall view of medications, schedules, and due doses.',
      targetAlignment: Alignment(0, -0.70),
      bubbleAlignment: Alignment(0, -0.25),
    ),
    _CoachStep(
      title: 'Medications',
      message:
          'Add medications here and track stock, expiry, and core medication details.',
      targetAlignment: Alignment(-0.25, 0.92),
      bubbleAlignment: Alignment(0, 0.48),
    ),
    _CoachStep(
      title: 'Schedules',
      message:
          'Create dose schedules here. You receive notifications from these schedules.',
      targetAlignment: Alignment(0.25, 0.92),
      bubbleAlignment: Alignment(0, 0.48),
    ),
    _CoachStep(
      title: 'Schedule links',
      message:
          'Each schedule is attached to a medication, and doses are attached to a schedule.',
      targetAlignment: Alignment(0.25, 0.92),
      bubbleAlignment: Alignment(0, 0.48),
    ),
    _CoachStep(
      title: 'Medication details',
      message:
          'Medication details include an ad hoc dose action for doses taken outside a schedule.',
      targetAlignment: Alignment(-0.25, 0.92),
      bubbleAlignment: Alignment(0, 0.48),
    ),
    _CoachStep(
      title: 'Reconstitution calculator',
      message:
          'Quickly calculate and save reconstitutions for later use when adding medications.',
      targetAlignment: Alignment(-0.25, 0.92),
      bubbleAlignment: Alignment(0, 0.48),
    ),
    _CoachStep(
      title: 'Multi-dose vial support',
      message:
          'Multi-dose vials include a built-in reconstitution calculator in their add/edit flow.',
      targetAlignment: Alignment(-0.25, 0.92),
      bubbleAlignment: Alignment(0, 0.48),
    ),
    _CoachStep(
      title: 'Analytics',
      message: 'Get reports and trend insights across your dose activity and history.',
      targetAlignment: Alignment(0.68, -0.82),
      bubbleAlignment: Alignment(0, -0.30),
    ),
    _CoachStep(
      title: 'Inventory',
      message:
          'See a quick overview of what remains in stock and what has been used over time.',
      targetAlignment: Alignment(0.68, -0.82),
      bubbleAlignment: Alignment(0, -0.30),
    ),
  ];

  bool get _isLastStep => _stepIndex == _steps.length - 1;

  Future<void> _goNext() async {
    if (_isLastStep) {
      await widget.onFinish();
      return;
    }

    if (!mounted) return;
    setState(() => _stepIndex += 1);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.black.withValues(alpha: 0.50),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CoachConnectorPainter(
                    bubbleAlignment: step.bubbleAlignment,
                    targetAlignment: step.targetAlignment,
                    color: cs.primary,
                  ),
                ),
                Align(
                  alignment: step.targetAlignment,
                  child: Container(
                    width: kOnboardingCoachTargetSize,
                    height: kOnboardingCoachTargetSize,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: kOpacityMedium),
                      borderRadius: BorderRadius.circular(kBorderRadiusFull),
                      border: Border.all(
                        color: cs.onPrimary,
                        width: kBorderWidthMedium,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: step.bubbleAlignment,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
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
                      padding: kOnboardingCoachBubblePadding,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: sectionTitleStyle(
                              context,
                            )?.copyWith(color: cs.onPrimary),
                          ),
                          const SizedBox(height: kSpacingXS),
                          Text(
                            step.message,
                            style: helperTextStyle(
                              context,
                              color: cs.onPrimary,
                            ),
                          ),
                          const SizedBox(height: kSpacingS),
                          Row(
                            children: [
                              Text(
                                '${_stepIndex + 1}/${_steps.length}',
                                style: smallHelperTextStyle(
                                  context,
                                  color: cs.onPrimary,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: widget.onFinish,
                                style: TextButton.styleFrom(
                                  foregroundColor: cs.onPrimary,
                                ),
                                child: const Text('Skip'),
                              ),
                              const SizedBox(width: kSpacingXS),
                              FilledButton(
                                onPressed: _goNext,
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.onPrimary,
                                  foregroundColor: cs.primary,
                                ),
                                child: Text(_isLastStep ? 'Done' : 'Next'),
                              ),
                            ],
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
    required this.targetAlignment,
    required this.bubbleAlignment,
  });

  final String title;
  final String message;
  final Alignment targetAlignment;
  final Alignment bubbleAlignment;
}

class _CoachConnectorPainter extends CustomPainter {
  _CoachConnectorPainter({
    required this.bubbleAlignment,
    required this.targetAlignment,
    required this.color,
  });

  final Alignment bubbleAlignment;
  final Alignment targetAlignment;
  final Color color;

  Offset _alignmentToOffset(Size size, Alignment alignment) {
    return Offset(
      (alignment.x + 1) * 0.5 * size.width,
      (alignment.y + 1) * 0.5 * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bubbleCenter = _alignmentToOffset(size, bubbleAlignment);
    final targetCenter = _alignmentToOffset(size, targetAlignment);

    final direction = targetCenter - bubbleCenter;
    final magnitude = math.max(direction.distance, 1.0).toDouble();
    final unit = direction / magnitude;

    final start = bubbleCenter + (unit * 34);
    final end = targetCenter - (unit * 28);

    final linePaint = Paint()
      ..color = color.withValues(alpha: kOpacityHigh)
      ..strokeWidth = kBorderWidthMedium
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, linePaint);
  }

  @override
  bool shouldRepaint(covariant _CoachConnectorPainter oldDelegate) {
    return oldDelegate.bubbleAlignment != bubbleAlignment ||
        oldDelegate.targetAlignment != targetAlignment ||
        oldDelegate.color != color;
  }
}
