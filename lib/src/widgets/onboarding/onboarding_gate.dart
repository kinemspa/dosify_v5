import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/ui/onboarding_settings.dart';

// ── Per-screen tip definitions ───────────────────────────────────────────────

const _tips = <String, _CoachStep>{
  // Note: '/' tip intentionally omitted — the disclaimer gate serves as the
  // first-launch welcome screen. Showing a second tip immediately after would
  // create a double-onboarding experience.
  '/medications': _CoachStep(
    title: 'Medications',
    message:
        'Add medications here and track stock, expiry, and core details. '
        'Tap any medication to view its full detail page.',
    targetAlignment: Alignment(-0.6, 0.92),
  ),
  '/medications/:id': _CoachStep(
    title: 'Medication detail',
    message:
        'This page shows full medication details and lets you quickly log '
        'activity outside a scheduled time.',
    targetAlignment: Alignment(0.0, -0.5),
  ),
  '/medications/reconstitution': _CoachStep(
    title: 'Reconstitution calculator',
    message:
        'Record and save vial reconstitution entries here for reference. '
        'Always verify values with your clinician.',
    targetAlignment: Alignment(0.0, -0.5),
  ),
  '/schedules': _CoachStep(
    title: 'Schedules',
    message:
        'Create schedules here. You receive a notification when each '
        'scheduled time arrives.',
    targetAlignment: Alignment(0.0, 0.85),
  ),
  '/schedules/detail/:id': _CoachStep(
    title: 'Schedule detail',
    message:
        'View timing, next entry, and pause controls for this schedule. '
        'Use the top-right button to pause or resume.',
    targetAlignment: Alignment(0.6, -0.82),
  ),
  '/calendar': _CoachStep(
    title: 'Calendar',
    message:
        'See all scheduled entries across any day, week, or month. '
        'Tap a entry card to log or review it.',
    targetAlignment: Alignment(0.0, 0.85),
  ),
  '/analytics': _CoachStep(
    title: 'Analytics',
    message:
        'Get trend insights and reports across your activity and history.',
    targetAlignment: Alignment(0.0, -0.5),
  ),
  '/inventory': _CoachStep(
    title: 'Inventory',
    message:
        'See a quick overview of what remains in stock and what has been '
        'used over time.',
    targetAlignment: Alignment(0.0, -0.5),
  ),
  '/settings': _CoachStep(
    title: 'Settings',
    message:
        'Customise your nav bar, notifications, and app preferences. '
        'You can replay these tips at any time from here.',
    targetAlignment: Alignment(0.0, -0.5),
  ),
};

// ── Gate widget ──────────────────────────────────────────────────────────────

/// Wraps shell content and shows a contextual one-time tip bubble the first
/// time the user naturally navigates to each screen.
///
/// Lives inside [ShellScaffold] so it never fires on the disclaimer or legal
/// pages (which are outside the shell route).
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({required this.child, super.key});

  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _tipVisible = false;
  String? _activeRouteId;
  String? _lastCheckedPath;

  @override
  void initState() {
    super.initState();
    OnboardingSettings.replaySignal.addListener(_handleReplay);
  }

  @override
  void dispose() {
    OnboardingSettings.replaySignal.removeListener(_handleReplay);
    super.dispose();
  }

  void _handleReplay() {
    setState(() {
      _tipVisible = false;
      _activeRouteId = null;
      _lastCheckedPath = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_checkRoute());
    });
  }

  /// Normalise dynamic path segments so e.g. `/medications/abc123` becomes
  /// `/medications/:id` for tip lookup.
  String _normalise(String path) {
    if (path.startsWith('/medications/') &&
        !path.startsWith('/medications/add') &&
        !path.startsWith('/medications/edit') &&
        !path.startsWith('/medications/reconstitution') &&
        !path.startsWith('/medications/select')) {
      return '/medications/:id';
    }
    if (path.startsWith('/schedules/detail/')) return '/schedules/detail/:id';
    return path;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = GoRouterState.of(context).uri.path;
    if (path != _lastCheckedPath) {
      // Route changed — hide current tip and check the new route.
      if (_tipVisible) setState(() => _tipVisible = false);
      unawaited(_checkRoute());
    }
  }

  Future<void> _checkRoute() async {
    if (!mounted) return;
    final path = GoRouterState.of(context).uri.path;
    _lastCheckedPath = path;
    final routeId = _normalise(path);
    if (!_tips.containsKey(routeId)) return;
    final seen = await OnboardingSettings.isScreenSeen(routeId);
    // Guard: route may have changed while we awaited prefs.
    if (!mounted || _lastCheckedPath != path) return;
    if (!seen) {
      setState(() {
        _activeRouteId = routeId;
        _tipVisible = true;
      });
    }
  }

  Future<void> _dismiss() async {
    final id = _activeRouteId;
    if (id != null) await OnboardingSettings.markScreenSeen(id);
    if (!mounted) return;
    setState(() => _tipVisible = false);
  }

  Future<void> _skipAll() async {
    await OnboardingSettings.markAllSeen();
    if (!mounted) return;
    setState(() => _tipVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_tipVisible || _activeRouteId == null) return widget.child;
    final step = _tips[_activeRouteId!];
    if (step == null) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        _CoachBubble(
          step: step,
          onDismiss: _dismiss,
          onSkip: _skipAll,
        ),
      ],
    );
  }
}

// ── Bubble widget ─────────────────────────────────────────────────────────────

/// A non-blocking floating bubble — only the bubble area intercepts touches.
class _CoachBubble extends StatelessWidget {
  const _CoachBubble({
    required this.step,
    required this.onDismiss,
    required this.onSkip,
  });

  final _CoachStep step;
  final VoidCallback onDismiss;
  final VoidCallback onSkip;

  Alignment _bubbleAlignmentFor(Alignment target) {
    final isLowerHalf = target.y > 0.1;
    final bubbleY = isLowerHalf ? 0.35 : -0.35;
    final bubbleX = target.x.clamp(-0.55, 0.55);
    return Alignment(bubbleX, bubbleY);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coachFg = kOnboardingCoachForegroundColor;
    final bubbleAlignment = _bubbleAlignmentFor(step.targetAlignment);
    final bubbleIsBelowTarget = bubbleAlignment.y > step.targetAlignment.y;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetDeltaX = step.targetAlignment.x - bubbleAlignment.x;
          final pointerAlignmentX = (targetDeltaX *
                  (constraints.maxWidth / kOnboardingCoachBubbleMaxWidth))
              .clamp(
                -kOnboardingCoachPointerClamp,
                kOnboardingCoachPointerClamp,
              );

          return Align(
            alignment: bubbleAlignment,
            child: Container(
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
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                    child: Container(
                      width: double.infinity,
                      padding: kOnboardingCoachBubblePadding,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius:
                            BorderRadius.circular(kBorderRadiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: sectionTitleStyle(context)?.copyWith(
                                  color: coachFg,
                                ) ??
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: onSkip,
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      coachFg.withValues(alpha: 0.7),
                                  textStyle: const TextStyle(
                                    fontSize: kOnboardingCoachMetaFontSize,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: kSpacingS,
                                    vertical: kSpacingXXS,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Skip all'),
                              ),
                              const SizedBox(width: kSpacingXS),
                              FilledButton(
                                onPressed: onDismiss,
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
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        ],
                      ),
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
          );
        },
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _CoachStep {
  const _CoachStep({
    required this.title,
    required this.message,
    required this.targetAlignment,
  });

  final String title;
  final String message;
  final Alignment targetAlignment;
}

// ── Pointer painter ───────────────────────────────────────────────────────────

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
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CoachBubblePointerPainter old) =>
      old.color != color || old.pointUp != pointUp;
}
