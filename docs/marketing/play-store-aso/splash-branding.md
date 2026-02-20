# Splash Branding Spec (Primary)

## Primary Splash Copy
- Tagline: **Track Smarter Every Day**

## Primary Splash Layout Requirement
- The primary splash screen must include the **Dosifi logo**.
- Recommended lockup:
  1. Logo (primary visual)
  2. App name: Dosifi
  3. Tagline: Track Smarter Every Day

## Store Consistency
Use the same tagline in app-store assets for consistency:
- App Store / Play Store marketing tagline: **Track Smarter Every Day**
- Suggested support line: Track smarter every day with clear medication schedules and dose logs.

## Compliance / Safety Note
Splash or listing copy must not imply diagnosis, treatment, or medical advice. Keep positioning as organization and tracking.

## Implementation Note (Current Project)
The project already has splash logo asset configuration in `pubspec.yaml` under `flutter_native_splash`:
- `image: assets/logo/logo_001_white_splash.png`

If you want tagline text rendered directly on splash, that usually requires baking text into the splash image asset or implementing a brief branded in-app launch screen after native splash.
