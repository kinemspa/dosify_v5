/// Canonical disclaimer strings for Skedux.
///
/// All disclaimer text lives here as a single source of truth so that the
/// marketing docs, in-app dialogs, settings page, and Store listings all
/// reference the same wording.
///
/// Variants:
///   [full]             – Website / Terms / In-App Legal (long form)
///   [onboarding]       – In-App first-launch dialog / onboarding screen
///   [onboardingHighlights] – Short, scannable first-run safety summary
///   [reviewHighlights] – Short summary for the read-only disclaimer view
///   [ageAcknowledgement] – Age/consent confirmation shown in-app
///   [footer]           – Ultra-short footer line used beneath calculated results
///   [emergency]        – Emergency banner copy
///   [reconstitution]   – Reconstitution-calculator-specific warning
///   [playStoreListing] – Google Play listing short disclaimer (2 sentences)
class DisclaimerStrings {
  DisclaimerStrings._();

  static const String onboardingHeading = 'Important Research Disclaimer';
  static const String onboardingSubheading =
      'Read this before using Skedux for the first time.';
  static const String reviewHeading = 'Research Disclaimer';
  static const String reviewSubheading =
      'Full disclaimer, privacy details, and legal terms for Skedux.';

  // ─── Full / Legal ────────────────────────────────────────────────────────

  static const String full = '''
Skedux is a research reference, organization, and tracking tool. It is not a medical device and does not provide medical advice, diagnosis, treatment, clinical decision support, or recommendations/decisions about the treatment of any disease, condition, ailment, or defect.

Skedux is not a doctor, pharmacist, nurse, or healthcare provider.

Skedux does not offer health recommendations, treatment plans, or clinical guidance.

Skedux is a research reference and tracking tool for medication metrics and records (for example: schedules, entries, entry logs, inventory, and vial/reconstitution tracking). It is intended for informational, research, and tracking purposes and does not provide clinical guidance, therapeutic recommendations, or endorsement of any substance.

You should always follow instructions from your licensed healthcare professional and the official medication labeling. Do not start, stop, or change any medicine, entry, concentration, schedule, titration, or injection/reconstitution process based solely on information displayed in this app.

Skedux reminders and notifications may be affected by device settings, battery optimization, operating system restrictions, network conditions, time zone changes, and manufacturer-specific behavior. Reminder delivery is not guaranteed. You are responsible for maintaining a backup reminder method for critical entries.

Any calculations, including reconstitution, concentration, and vial-related calculations, are simple mathematical conversions provided for organizational convenience only and must be independently verified by a qualified healthcare professional before use. Skedux does not interpret or analyze medical data.

If you think you may be having a medical emergency, call your local emergency number immediately. Do not rely on this app for emergency care.

You are solely responsible for reviewing all entered data for accuracy, including medication name, strength/concentration, units, schedule times, and inventory details.

To the maximum extent permitted by applicable law, Skedux and its developers disclaim liability for any loss, injury, claim, or damages arising from use of, inability to use, or reliance on the app.''';

  // ─── In-App Onboarding Dialog ────────────────────────────────────────────

  static const String onboarding =
      'Skedux is a research reference and tracking tool for medication records, '
      'schedules, inventory, and reconstitution-related values. It is not medical '
      'advice, diagnosis, treatment, or clinical decision support.\n\n'
      'Before acting on anything shown in the app, independently verify all '
      'medication names, units, concentrations, schedules, reminders, and '
      'reconstitution values with a qualified healthcare professional and the '
      'official medication labeling.';

  static const List<String> onboardingHighlights = <String>[
    'Skedux is a reference and tracking tool only, not a medical device or healthcare provider.',
    'Verify all calculations, entries, concentrations, and schedules before use.',
    'Critical reminders are your responsibility. Keep a backup reminder method.',
  ];

  static const List<String> reviewHighlights = <String>[
    'No medical advice, diagnosis, treatment, or clinical decision support.',
    'Notification delivery is not guaranteed on every device or operating system.',
    'You are responsible for reviewing all entered data for accuracy before use.',
  ];

  static const String ageRequirement =
      'You must be 18 years of age or older to use Skedux.';

  static const String ageAcknowledgement =
      'By continuing, you confirm that you are 18 years of age or older and '
      'that you understand and accept these limitations.';

  static const String privacyPolicy = '''
Skedux stores the medication records, schedules, inventory details, and other data you enter locally on your device inside an encrypted database. Skedux does not operate its own cloud sync or application server for your primary records.

Skedux also stores certain local app settings and local event counters on your device, such as reminder preferences, disclaimer acceptance state, and in-app monetization event counts used by the app itself.

Skedux may integrate with Google Play billing, Google AdMob, and optional Google Drive backup features. If you use those features, Google or other platform providers may process account, purchase, device, advertising, identifier, sign-in, or backup metadata in accordance with their own terms and privacy policies.

Advertising may be served by Google AdMob. Skedux does not operate its own separate cloud analytics service for primary medication records, but third-party platform and advertising services may collect their own usage or device data when their SDKs or services are used.

If you enable optional Google Drive backup, backup files are uploaded to Skedux app storage in your Google Drive account. Current portable backups are intended to survive reinstall and compatible-device restore, so they should be treated as copies of your data stored under your Google account until you delete them. If you choose password-protected backup, the backup payload is encrypted before export or upload.

If you buy or restore Pro, entitlement and purchase state are tied to your Google Play account and may remain subject to Google Play billing records even if you clear local app data.

Removing Skedux from your device or using local erase-data controls removes local app data on that device, but does not automatically delete Google Drive backups or Google Play billing records held by Google.''';

  static const String termsOfUse = '''
By using Skedux, you agree to use it only as a research, organizational, and tracking tool and not as a substitute for professional medical judgment, diagnosis, treatment, or emergency care.

You are responsible for all information entered into the app, for independently verifying calculations and schedules, and for maintaining any backup reminder methods needed for critical use cases.

Skedux is provided on an as-is and as-available basis to the maximum extent permitted by applicable law. Features may change, be limited, or be removed without notice.

Purchases, restores, subscriptions, billing issues, and refunds handled through Google Play are also subject to Google Play terms, billing policies, and account requirements.

You may stop using Skedux at any time. If you choose to stop using it, you are responsible for removing any local exports or cloud backup copies you previously created.''';

  static const String termsChanges =
      'We may update these terms, privacy details, and disclaimer text from time '
      'to time. When the disclaimer changes materially, Skedux requires a new '
      'in-app acknowledgement before continued use.';

  // ─── Ultra-Short Footer ───────────────────────────────────────────────────

  static const String footer =
      'For research and tracking reference only - not medical advice or disease treatment decisions. '
      'Verify all values with a qualified professional.';

  // ─── Emergency Banner ─────────────────────────────────────────────────────

  static const String emergency =
      'Medical emergency? Call local emergency services immediately. '
      'Do not rely on this app for urgent care.';

  // ─── Reconstitution-Specific Warning ─────────────────────────────────────

  static const String reconstitution =
      'Reconstitution values are simple mathematical conversions for reference-only '
      'and must be independently verified by a qualified healthcare professional before '
      'administration. Skedux does not provide therapeutic decisions or endorse '
      'unapproved substances.';

  // ─── Google Play Listing (Short) ─────────────────────────────────────────

  static const String playStoreListing =
      'Skedux is a research reference and tracking tool and does not provide medical advice, '
      'diagnosis, treatment, or decisions about any disease/condition. Always follow '
      'guidance from licensed healthcare professionals. Notification delivery may vary '
      'by device/OS settings and is not guaranteed.\n\n'
      'Skedux is not a doctor and does not provide health recommendations. It is a '
      'research reference and tracking tool for medication metrics and records.';
}
