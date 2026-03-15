// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/legal/disclaimer_strings.dart';
import 'package:skedux/src/features/disclaimer/data/disclaimer_preferences.dart';

/// Full-screen disclaimer gate shown on first launch.
///
/// When [readOnly] is `false` the user must acknowledge the disclaimer to
/// continue. When `true`, the same screen acts as a read-only legal review
/// surface opened from Settings.
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
    final colorScheme = Theme.of(context).colorScheme;
    final disclaimerText = readOnly
        ? DisclaimerStrings.full
        : DisclaimerStrings.onboarding;
    final heading = readOnly
        ? DisclaimerStrings.reviewHeading
        : DisclaimerStrings.onboardingHeading;
    final subheading = readOnly
        ? DisclaimerStrings.reviewSubheading
        : DisclaimerStrings.onboardingSubheading;
    final highlights = readOnly
        ? DisclaimerStrings.reviewHighlights
        : DisclaimerStrings.onboardingHighlights;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingL,
            vertical: kSpacingL,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: kSpacingL),
                  Align(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpacingS,
                        vertical: kSpacingXXS,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          kBorderRadiusFull,
                        ),
                      ),
                      child: Text(
                        readOnly
                            ? 'Full disclaimer review'
                            : 'Required before use',
                        style: smallHelperTextStyle(context)?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: kFontWeightSemiBold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: kSpacingL),
                  Align(
                    child: Image.asset(
                      kPrimaryLogoAssetPath,
                      width: 112,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: kSpacingL),
                  Text(
                    heading,
                    textAlign: TextAlign.center,
                    style: sectionTitleStyle(context)?.copyWith(
                      fontSize: kFontSizeXLarge,
                      fontWeight: kFontWeightBold,
                    ),
                  ),
                  const SizedBox(height: kSpacingXS),
                  Text(
                    subheading,
                    textAlign: TextAlign.center,
                    style: helperTextStyle(context)?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: kSpacingL),
                  _DisclaimerHighlightsCard(items: highlights),
                  const SizedBox(height: kSpacingM),
                  const _EmergencyNoticeCard(),
                  const SizedBox(height: kSpacingM),
                  _DisclaimerBodyCard(
                    disclaimerText: disclaimerText,
                    includeAgeAcknowledgement: !readOnly,
                  ),
                  const SizedBox(height: kSpacingL),
                  if (onNavigateToLegal != null) ...[
                    _LegalLinksText(
                      color: colorScheme.primary,
                      readOnly: readOnly,
                      onNavigateToLegal: onNavigateToLegal!,
                    ),
                    const SizedBox(height: kSpacingL),
                  ],
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
                            child: const Text('Acknowledge & Continue'),
                          ),
                  ),
                  const SizedBox(height: kSpacingS),
                  Text(
                    DisclaimerStrings.footer,
                    textAlign: TextAlign.center,
                    style: smallHelperTextStyle(context)?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: kSpacingL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclaimerHighlightsCard extends StatelessWidget {
  const _DisclaimerHighlightsCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(kSpacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: kOpacitySubtle),
          width: kBorderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key points',
            style: bodyTextStyle(context)?.copyWith(
              fontWeight: kFontWeightBold,
            ),
          ),
          const SizedBox(height: kSpacingS),
          for (final entry in items.asMap().entries) ...[
            _BulletRow(text: entry.value),
            if (entry.key != items.length - 1)
              const SizedBox(height: kSpacingS),
          ],
        ],
      ),
    );
  }
}

class _EmergencyNoticeCard extends StatelessWidget {
  const _EmergencyNoticeCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(kSpacingM),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.onErrorContainer,
            size: kIconSizeMedium,
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            child: Text(
              DisclaimerStrings.emergency,
              style: bodyTextStyle(context)?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: kFontWeightSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBodyCard extends StatelessWidget {
  const _DisclaimerBodyCard({
    required this.disclaimerText,
    required this.includeAgeAcknowledgement,
  });

  final String disclaimerText;
  final bool includeAgeAcknowledgement;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paragraphs = disclaimerText
        .split('\n\n')
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(kSpacingL),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: kOpacitySubtle),
          width: kBorderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            includeAgeAcknowledgement ? 'Read and acknowledge' : 'Full text',
            style: bodyTextStyle(context)?.copyWith(
              fontWeight: kFontWeightBold,
            ),
          ),
          const SizedBox(height: kSpacingM),
          for (final entry in paragraphs.asMap().entries) ...[
            _Paragraph(entry.value),
            if (entry.key != paragraphs.length - 1)
              const SizedBox(height: kSpacingL),
          ],
          if (includeAgeAcknowledgement) ...[
            const SizedBox(height: kSpacingL),
            Container(
              padding: const EdgeInsets.all(kSpacingM),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(kBorderRadiusMedium),
              ),
              child: const _Paragraph(DisclaimerStrings.ageAcknowledgement),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegalLinksText extends StatelessWidget {
  const _LegalLinksText({
    required this.color,
    required this.readOnly,
    required this.onNavigateToLegal,
  });

  final Color color;
  final bool readOnly;
  final VoidCallback onNavigateToLegal;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: readOnly
            ? 'See the '
            : 'By continuing you acknowledge the research disclaimer and agree to the ',
        style: helperTextStyle(context),
        children: [
          TextSpan(
            text: 'Privacy Policy',
            style: helperTextStyle(context)?.copyWith(
              color: color,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onNavigateToLegal,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Terms of Use',
            style: helperTextStyle(context)?.copyWith(
              color: color,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onNavigateToLegal,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: kIconSizeSmall,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: kSpacingS),
        Expanded(child: _Paragraph(text)),
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
