/// Canonical disclaimer strings for Skedux.
///
/// All disclaimer text lives here as a single source of truth so that the
/// marketing docs, in-app dialogs, settings page, and Store listings all
/// reference the same wording.
///
/// Variants:
///   [full]             – Website / Terms / In-App Legal (long form)
///   [onboarding]       – In-App first-launch dialog / onboarding screen
///   [footer]           – Ultra-short footer line used beneath calculated results
///   [emergency]        – Emergency banner copy
///   [reconstitution]   – Reconstitution-calculator-specific warning
///   [playStoreListing] – Google Play listing short disclaimer (2 sentences)
class DisclaimerStrings {
  DisclaimerStrings._();

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
      'Skedux helps you organize and track medication metrics and schedules for '
      'informational and research purposes. It is not medical advice, diagnosis, or '
      'treatment. Verify all entry and reconstitution details with a qualified '
      'professional. Keep a backup reminder method for important entries.\n\n'
      'Skedux is not a doctor and does not offer health recommendations or decisions '
      'about diseases/conditions. It is a research reference and tracking tool for '
      'medication metrics.';

  // ─── Ultra-Short Footer ───────────────────────────────────────────────────

  static const String footer =
      'For research and tracking reference only — not medical advice or disease treatment decisions. '
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
