# Internal Testing Build 0.1.0+5

Date: 2026-03-15

## Android metadata

- Application ID: `com.skedux.app`
- Version name: `0.1.0`
- Version code: `5`
- Target artifact for Google Play internal testing: Android App Bundle (`.aab`)

## Built artifacts

- Bundle: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

## Versioned copies

- `build/release-artifacts/0.1.0+5/skedux-v0.1.0+5-release.aab`
- `build/release-artifacts/0.1.0+5/skedux-v0.1.0+5-release.apk`
- `build/release-artifacts/0.1.0+5/SHA256SUMS.txt`

## Artifact sizes

- `app-release.aab`: 53.29 MB
- `app-release.apk`: 68.81 MB

## SHA-256

- `skedux-v0.1.0+5-release.aab`: `08900cde03c2e6ebe7e3848dcdd17c185605c971e2f309812abc4a1c65a17674`
- `skedux-v0.1.0+5-release.apk`: `f13b45cb48455934552fe54240b349c9fd89da6b53a8064cae2a447b1e433f43`

## Fastest Play Console path

1. Open Google Play Console.
2. Select the `com.skedux.app` app.
3. Open `Testing` -> `Internal testing`.
4. Create a release or edit the existing draft.
5. Upload `build/release-artifacts/0.1.0+5/skedux-v0.1.0+5-release.aab`.
6. Add release notes if needed.
7. Review rollout warnings, save, then roll out to internal testing.
8. Confirm the uploaded release shows version name `0.1.0` and version code `5`.

## Notes

- Use the `.aab` for Play Console. The `.apk` is only for direct install testing.
- The files under `build/` are generated artifacts and are not intended as source-controlled release assets.