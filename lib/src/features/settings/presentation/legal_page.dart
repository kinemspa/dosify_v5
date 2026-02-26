// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Privacy Policy ─────────────────────────────────────────────
        _SectionHeading('Privacy Policy'),
        const SizedBox(height: kSpacingM),
        _Para(
          'Dosifi stores all data you enter — including compound names, '
          'reconstitution calculations, schedules, and dose logs — locally '
          'on your device inside an encrypted Hive database. No data is '
          'transmitted to any Dosifi server.',
        ),
        const SizedBox(height: kSpacingM),
        _Para(
          'Google Drive Backup (optional): If you enable Google Drive backup '
          'via the Settings screen, Dosifi requests read/write access to a '
          'dedicated app folder in your Google Drive. This data is governed '
          'by Google\u2019s Privacy Policy (policies.google.com/privacy). '
          'You may revoke access at any time from your Google Account settings.',
        ),
        const SizedBox(height: kSpacingM),
        _Para(
          'Google Sign-In: Used solely to authenticate the Google Drive '
          'backup feature. We do not store your Google credentials.',
        ),
        const SizedBox(height: kSpacingM),
        _Para(
          'Advertising: Dosifi may display ads served by Google AdMob. '
          'AdMob may use device identifiers in accordance with '
          'Google\u2019s advertising policies. You can reset your '
          'advertising ID or opt out of personalised ads in your device '
          '\u2019s Privacy settings.',
        ),
        const SizedBox(height: kSpacingM),
        _Para(
          'Analytics: Dosifi does not collect personally identifiable '
          'analytics. Aggregate, non-identifiable usage signals may be '
          'collected by Google Play Services.',
        ),
        const SizedBox(height: kSpacingM),
        _Para(
          'Right to deletion: Because all primary data is stored locally, '
          'you can delete all your data at any time by uninstalling the app '
          'or using the \u201cErase all data\u201d option in Settings. '
          'If you enabled Google Drive backup, delete the app folder '
          'from your Google Drive directly.',
        ),
        const SizedBox(height: kSpacingXXL),

        // ── Terms of Use ───────────────────────────────────────────────
        _SectionHeading('Terms of Use'),
        const SizedBox(height: kSpacingM),
        _SubHeading('Research & Informational Purposes Only'),
        const SizedBox(height: kSpacingS),
        _Para(
          'Dosifi is a research reference and personal tracking application. '
          'It is not a medical device and does not provide medical advice, '
          'diagnosis, or treatment of any kind.',
        ),
        const SizedBox(height: kSpacingM),
        _SubHeading('No Regulatory Approval'),
        const SizedBox(height: kSpacingS),
        _Para(
          'Dosifi has not been assessed, registered, or approved by the '
          'Therapeutic Goods Administration (TGA, Australia), the Food and '
          'Drug Administration (FDA, USA), the European Medicines Agency '
          '(EMA), or any other health authority as a clinical or '
          'diagnostic tool.',
        ),
        const SizedBox(height: kSpacingM),
        _SubHeading('Reconstitution Reference Calculator'),
        const SizedBox(height: kSpacingS),
        _Para(
          'The reconstitution calculator produces reference values based '
          'on the inputs you provide. Calculated volumes are mathematical '
          'outputs only. They may contain errors. All calculated values '
          'must be independently verified by a qualified healthcare '
          'professional before use.',
        ),
        const SizedBox(height: kSpacingM),
        _SubHeading('Limitation of Liability'),
        const SizedBox(height: kSpacingS),
        _Para(
          'To the fullest extent permitted by applicable law, the developers '
          'of Dosifi disclaim all liability for any loss, injury, or damage '
          'arising from reliance on information or calculations produced by '
          'this application. The app is provided \u201cas is\u201d without '
          'any warranty of accuracy, fitness for purpose, or '
          'non-infringement.',
        ),
        const SizedBox(height: kSpacingM),
        _SubHeading('Age Requirement'),
        const SizedBox(height: kSpacingS),
        _Para(
          'By using Dosifi you confirm that you are 18 years of age or older.',
        ),
        const SizedBox(height: kSpacingM),
        _SubHeading('Changes to These Terms'),
        const SizedBox(height: kSpacingS),
        _Para(
          'We may update these terms from time to time. Continued use of '
          'the app after changes are posted constitutes acceptance of the '
          'revised terms. The in-app disclaimer acknowledgement will be '
          'reset when material changes are made.',
        ),
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
