// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/disclaimer/data/disclaimer_preferences.dart';

/// Full-screen disclaimer gate shown on first launch.
///
/// When [readOnly] is `false` (default) the user must tap "Acknowledge"
/// to unlock the app. When `true` (revisited from Settings) a "Close"
/// button is shown instead.
class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({
    super.key,
    this.readOnly = false,
    required this.notifier,
    this.onAcknowledged,
    this.onClose,
    this.onNavigateToLegal,
  });

  final bool readOnly;
  final DisclaimerNotifier notifier;
  final VoidCallback? onAcknowledged;
  final VoidCallback? onClose;
  final VoidCallback? onNavigateToLegal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: kSpacingXXL,
            vertical: kSpacingXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: kSpacingXXL),

              // ── Logo ──────────────────────────────────────────────────
              Image.asset(
                kPrimaryLogoAssetPath,
                width: 120,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: kSpacingXXL),

              // ── Heading ───────────────────────────────────────────────
              Text(
                'Research & Reference Tool',
                textAlign: TextAlign.center,
                style: sectionTitleStyle(context)?.copyWith(
                  fontSize: kFontSizeXLarge,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: kSpacingXL),

              // ── Disclaimer body ───────────────────────────────────────
              _DisclaimerBody(context: context),

              const SizedBox(height: kSpacingXXL),

              // ── Legal links ───────────────────────────────────────────
              if (onNavigateToLegal != null) ...[
                Text.rich(
                  TextSpan(
                    text: 'By continuing you agree to the\u00a0',
                    style: helperTextStyle(context),
                    children: [
                      TextSpan(
                        text: 'Privacy Policy',
                        style: helperTextStyle(context)?.copyWith(
                          color: teal,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = onNavigateToLegal,
                      ),
                      TextSpan(text: '\u00a0and\u00a0'),
                      TextSpan(
                        text: 'Terms of Use',
                        style: helperTextStyle(context)?.copyWith(
                          color: teal,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = onNavigateToLegal,
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kSpacingL),
              ],

              // ── Primary action ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: readOnly
                    ? OutlinedButton(
                        onPressed: onClose,
                        child: const Text('Close'),
                      )
                    : FilledButton(
                        onPressed: () async {
                          await notifier.accept();
                          onAcknowledged?.call();
                        },
                        child: const Text('Acknowledge'),
                      ),
              ),

              const SizedBox(height: kSpacingL),
            ],
          ),
        ),
      ),
    );
  }
}

/// Disclaimer text body — shared between first-run and read-only modes.
class _DisclaimerBody extends StatelessWidget {
  const _DisclaimerBody({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext outerContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Paragraph(
          'Dosifi is designed for research and informational purposes only. '
          'It does not constitute medical advice, diagnosis, or treatment.',
        ),
        const SizedBox(height: kSpacingL),
        _Paragraph(
          'Dosifi is not a medical device and has not been evaluated or '
          'approved by the TGA, FDA, or any other regulatory authority '
          'as a clinical decision-support tool.',
        ),
        const SizedBox(height: kSpacingL),
        _Paragraph(
          'All calculations, logs, and references produced by this application '
          'are for personal tracking and reference only. They must be verified '
          'by a qualified healthcare professional before being acted upon.',
        ),
        const SizedBox(height: kSpacingL),
        _Paragraph(
          'By tapping \u201cAcknowledge\u201d you confirm that you are '
          '18 years of age or older and that you understand and accept '
          'these terms.',
        ),
      ],
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: bodyTextStyle(context),
      textAlign: TextAlign.left,
    );
  }
}
