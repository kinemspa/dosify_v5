// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/core/legal/disclaimer_strings.dart';

/// Static Legal page containing Privacy Policy and Terms of Use.
///
/// Route: `/legal`
class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: kSpacingXXL,
          vertical: kSpacingXL,
        ),
        child: _LegalContent(),
      ),
    );
  }
}

class _LegalContent extends StatelessWidget {
  const _LegalContent();

  List<String> _paragraphs(String value) {
    return value
        .split('\n\n')
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final privacyParagraphs = _paragraphs(DisclaimerStrings.privacyPolicy);
    final termsParagraphs = _paragraphs(DisclaimerStrings.termsOfUse);
    final disclaimerParagraphs = _paragraphs(DisclaimerStrings.full);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Privacy Policy ─────────────────────────────────────────────
        _SectionHeading('Privacy Policy'),
        for (final entry in privacyParagraphs.asMap().entries) ...[
          const SizedBox(height: kSpacingM),
          _Para(entry.value),
        ],
        const SizedBox(height: kSpacingXXL),

        // ── Terms of Use ───────────────────────────────────────────────
        _SectionHeading('Terms of Use'),
        for (final entry in termsParagraphs.asMap().entries) ...[
          const SizedBox(height: kSpacingM),
          _Para(entry.value),
        ],
        const SizedBox(height: kSpacingM),
        _SubHeading('Age Requirement'),
        const SizedBox(height: kSpacingS),
        _Para(DisclaimerStrings.ageRequirement),
        const SizedBox(height: kSpacingM),
        _SubHeading('Changes to These Terms'),
        const SizedBox(height: kSpacingS),
        _Para(DisclaimerStrings.termsChanges),
        const SizedBox(height: kSpacingXXL),

        // ── Research Disclaimer ────────────────────────────────────────
        _SectionHeading('Research Disclaimer'),
        for (final entry in disclaimerParagraphs.asMap().entries) ...[
          const SizedBox(height: kSpacingM),
          _Para(entry.value),
        ],
        const SizedBox(height: kSpacingXXL),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: sectionTitleStyle(context)?.copyWith(
        fontSize: kFontSizeLarge,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  const _SubHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: bodyTextStyle(context)?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Para extends StatelessWidget {
  const _Para(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: bodyTextStyle(context));
  }
}
