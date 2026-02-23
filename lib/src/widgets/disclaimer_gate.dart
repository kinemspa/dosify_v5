import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/legal/disclaimer_settings.dart';
import 'package:dosifi_v5/src/core/legal/disclaimer_strings.dart';

/// Shows a mandatory disclaimer acceptance dialog on first launch.
///
/// The child is rendered behind the dialog so that routing is fully
/// initialized before the gate is dismissed. The user must tap
/// "I Understand & Accept" to proceed — there is no dismiss or cancel action.
///
/// Acceptance is persisted via [DisclaimerSettings] so the dialog is shown
/// only once per install.
class DisclaimerGate extends StatefulWidget {
  const DisclaimerGate({required this.child, super.key});

  final Widget child;

  @override
  State<DisclaimerGate> createState() => _DisclaimerGateState();
}

class _DisclaimerGateState extends State<DisclaimerGate> {
  /// null = still loading, true = accepted, false = needs acceptance.
  bool? _accepted;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final accepted = await DisclaimerSettings.isAccepted();
    if (!mounted) return;
    setState(() => _accepted = accepted);
  }

  Future<void> _accept() async {
    await DisclaimerSettings.markAccepted();
    if (!mounted) return;
    setState(() => _accepted = true);
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _accepted;

    // While loading, show the child immediately (avoids a flash of blank screen).
    if (accepted == null || accepted) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        _DisclaimerDialog(onAccept: _accept),
      ],
    );
  }
}

/// Full-screen disclaimer overlay with scrollable content and a single
/// accept action.  Uses [WillPopScope] to prevent back-button dismissal.
class _DisclaimerDialog extends StatefulWidget {
  const _DisclaimerDialog({required this.onAccept});

  final Future<void> Function() onAccept;

  @override
  State<_DisclaimerDialog> createState() => _DisclaimerDialogState();
}

class _DisclaimerDialogState extends State<_DisclaimerDialog> {
  bool _accepting = false;

  Future<void> _handleAccept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    await widget.onAccept();
    // No need to reset — parent will rebuild child without this overlay.
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      // Prevent back-button dismissal — user must explicitly accept.
      canPop: false,
      child: Material(
        // Semi-transparent scrim over the app behind the gate.
        color: cs.scrim.withValues(alpha: 0.72),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpacingM,
                  vertical: kSpacingL,
                ),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(kSpacingL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──────────────────────────────────────
                        Row(
                          children: [
                            Icon(
                              Icons.health_and_safety_outlined,
                              color: cs.primary,
                              size: kIconSizeLarge,
                            ),
                            const SizedBox(width: kSpacingS),
                            Expanded(
                              child: Text(
                                'Important Notice',
                                style: sectionTitleStyle(context)?.copyWith(
                                  color: cs.primary,
                                  fontWeight: kFontWeightBold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: kSpacingM),

                        // ── Scrollable disclaimer body ───────────────────
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.45,
                          ),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Text(
                                DisclaimerStrings.onboarding,
                                style: bodyTextStyle(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: kSpacingM),

                        // ── Emergency note ───────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(kSpacingS),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius:
                                BorderRadius.circular(kBorderRadiusSmall),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: cs.onErrorContainer,
                                size: kIconSizeSmall,
                              ),
                              const SizedBox(width: kSpacingXS),
                              Expanded(
                                child: Text(
                                  DisclaimerStrings.emergency,
                                  style: helperTextStyle(context)?.copyWith(
                                    color: cs.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: kSpacingM),

                        // ── Accept button ────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _accepting ? null : _handleAccept,
                            child: _accepting
                                ? const SizedBox(
                                    height: kIconSizeSmall,
                                    width: kIconSizeSmall,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('I Understand & Accept'),
                          ),
                        ),
                        const SizedBox(height: kSpacingXS),

                        // ── Footer line ──────────────────────────────────
                        Center(
                          child: Text(
                            DisclaimerStrings.footer,
                            textAlign: TextAlign.center,
                            style: smallHelperTextStyle(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
