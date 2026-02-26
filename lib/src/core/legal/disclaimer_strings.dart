/// Canonical disclaimer strings for Dosifi.
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
Dosifi is a medication organization and tracking tool. It is not a medical device and does not provide medical advice, diagnosis, treatment, clinical decision support, or recommendations/decisions about the treatment of any disease, condition, ailment, or defect.

Dosifi is not a doctor, pharmacist, nurse, or healthcare provider.

Dosifi does not offer health recommendations, treatment plans, or clinical guidance.

Dosifi is purely a tracking app with medication metrics and records (for example: schedules, doses, dose logs, inventory, and vial/reconstitution tracking). It is intended for tracking approved medications only and does not endorse or facilitate use of unapproved substances.

You should always follow instructions from your licensed healthcare professional and the official medication labeling. Do not start, stop, or change any medicine, dose, concentration, schedule, titration, or injection/reconstitution process based solely on information displayed in this app.

Dosifi reminders and notifications may be affected by device settings, battery optimization, operating system restrictions, network conditions, time zone changes, and manufacturer-specific behavior. Reminder delivery is not guaranteed. You are responsible for maintaining a backup reminder method for critical doses.

Any calculations, including reconstitution, concentration, and vial-related calculations, are simple mathematical conversions provided for organizational convenience only and must be independently verified by a qualified healthcare professional before use. Dosifi does not interpret or analyze medical data.

If you think you may be having a medical emergency, call your local emergency number immediately. Do not rely on this app for emergency care.

You are solely responsible for reviewing all entered data for accuracy, including medication name, strength/concentration, units, schedule times, and inventory details.

To the maximum extent permitted by applicable law, Dosifi and its developers disclaim liability for any loss, injury, claim, or damages arising from use of, inability to use, or reliance on the app.''';

  // ─── In-App Onboarding Dialog ────────────────────────────────────────────

  static const String onboarding =
      'Dosifi helps you organize medicines and schedules, but it is not medical advice, '
      'diagnosis, or treatment. Verify all dose and reconstitution details with your '
      'healthcare professional. Keep a backup reminder method for important doses.\n\n'
      'Dosifi is not a doctor and does not offer health recommendations or decisions about '
      'diseases/conditions. It is a tracking app for medication metrics only, intended '
      'for approved medications.';

  // ─── Ultra-Short Footer ───────────────────────────────────────────────────

  static const String footer =
      'For organization only — not medical advice or disease treatment decisions. '
      'For approved meds; verify all dosing with your clinician.';

  // ─── Emergency Banner ─────────────────────────────────────────────────────

  static const String emergency =
      'Medical emergency? Call local emergency services immediately. '
      'Do not rely on this app for urgent care.';

  // ─── Reconstitution-Specific Warning ─────────────────────────────────────

  static const String reconstitution =
      'Reconstitution values are simple mathematical conversions for reference-only '
      'and must be independently verified by a qualified healthcare professional before '
      'administration. Dosifi does not provide therapeutic decisions or endorse '
      'unapproved substances.';

  // ─── Google Play Listing (Short) ─────────────────────────────────────────

  static const String playStoreListing =
      'Dosifi is an organizational tool only and does not provide medical advice, '
      'diagnosis, treatment, or decisions about any disease/condition. Always follow '
      'guidance from licensed healthcare professionals. Notification delivery may vary '
      'by device/OS settings and is not guaranteed.\n\n'
      'Dosifi is not a doctor and does not provide health recommendations. It is '
      'purely a tracking app with medication metrics, intended for approved medications only.';
}
