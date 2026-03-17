# Skedux Free-First Launch Plan

Date: 2026-03-17

## Recommendation

Launch Skedux first as a free app with the existing 3-medication limit.

Do not enable paid Pro purchases until:

1. merchant and address setup are finished
2. business structure decisions are settled
3. legal/privacy pages are public
4. you have real user signal that the app is worth monetizing

This is the lower-risk way to validate demand without rushing into Google payments, insurance decisions, or public merchant identity exposure.

## What Is Already Solid In The App

Current app behavior already supports a free-first launch well:

1. the free-tier medication limit is enforced centrally
2. the limit is currently set to 3 medications
3. the app already distinguishes free vs Pro entitlement state
4. ads remain aligned with the free tier

Relevant files:

1. [lib/src/core/monetization/entitlement_service.dart](lib/src/core/monetization/entitlement_service.dart)
2. [lib/src/features/medications/data/medication_repository.dart](lib/src/features/medications/data/medication_repository.dart)

## Free-First Launch Adjustment

To support a proper free-first launch, the app should not actively drive users into a purchase flow that is not ready.

This repo now includes a monetization switch for that purpose:

1. [lib/src/core/monetization/monetization_config.dart](lib/src/core/monetization/monetization_config.dart)

Default behavior:

1. Pro purchases are disabled by default
2. the app behaves as a free-first build unless explicitly enabled with a build define later

## Build Flag For Later

When you are ready to enable Pro purchases in a future build, build with:

`--dart-define=SKEDUX_ENABLE_PRO_PURCHASES=true`

Until then, the app should launch in free-first mode by default.

## Free-First Launch Checklist

Before publishing the free version, complete these:

1. Confirm the 3-medication limit is enforced in release builds.
2. Confirm the app does not present a broken or unavailable purchase path.
3. Publish a public Privacy Policy page.
4. Publish a public Terms or legal page.
5. Publish a public support contact path.
6. Check store listing language so it does not promise paid Pro today if Pro is not available yet.
7. Make sure reminder and disclaimer messaging is consistent with the app’s research/reference positioning.
8. Validate the release build on a real Android device.
9. Confirm onboarding is understandable for first-time users.
10. Confirm the 3-med limit feels like a clear free tier, not like the app is broken.

## Product Positioning Guidance

The free-first launch should be framed like this:

1. Skedux is available now as a focused free app.
2. The free version supports up to 3 medications.
3. More advanced monetization or Pro expansion can come later if reception is strong.

Do not overemphasize the future paid tier in the store listing if users cannot buy it yet.

## In-App Messaging Guidance

For a free-first launch, the current product promise should feel complete even without Pro.

Good positioning:

1. clear free-tier limit
2. clear explanation of what the app already does well
3. no dead-end purchase or broken checkout path

## Store Listing Recommendation

Because this is a free-first launch, use store copy that sells the core utility of the app, not the upgrade path.

### Title Option

`Skedux: Med Tracker & Schedule`

### Short Description Option

`Track medication schedules, reminders, logs, inventory, and vial references.`

### Free-First Full Description Draft

`Skedux helps you track medication schedules, reminders, logs, inventory, and vial or reconstitution-related reference details in one place.`

`Create medication records, build schedules, log taken or skipped entries, and stay organized with practical daily tracking.`

`Skedux supports multiple dosage forms, including tablets, capsules, pre-filled syringes, single-entry vials, and multi-entry vials.`

`You can also track inventory, low-stock status, expiry details, and storage notes, while keeping a structured history of your entries.`

`For vial-based workflows, Skedux includes reconstitution-related reference tools and dedicated vial tracking to keep records organized.`

`Free version includes support for up to 3 medications.`

`Important: Skedux is a research reference and tracking tool only. It does not provide medical advice, diagnosis, treatment, clinical decision support, or emergency care. Notification behavior can vary by device and operating system settings.`

### Screenshot Caption Set

1. `Track Up To 3 Medications Free`
2. `Build Flexible Medication Schedules`
3. `Log Entries Clearly Every Day`
4. `Track Inventory, Stock, and Expiry`
5. `Manage Vials and Reconstitution References`
6. `Stay Organized With Daily Dose Views`

## What To Learn From The Free Launch

Use the free launch to learn:

1. do people install it?
2. do people keep using it?
3. do users hit the 3-med limit?
4. do users request Pro or more capacity?
5. do users trust the app and understand the positioning?

## Decision Gate For Turning On Pro Later

Consider enabling Pro only if these start to become true:

1. the app gets consistent installs and retention
2. users naturally hit the 3-med limit
3. the support burden is manageable
4. you are comfortable with merchant/address setup
5. business/tax/insurance steps are in place

## Final Recommendation

Releasing Skedux free-first with the 3-med limit is a wise way to gauge reception.

Treat the first release as a market validation release, not a revenue release.