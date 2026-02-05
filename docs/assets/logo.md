# Logo Assets

Primary source asset:
- `assets/logo/logo_001_primary.png`

## Placement checklist

- Launcher icon (adaptive + legacy) in `android/app/src/main/res/mipmap-*`
- Splash (if/when enabled)
- In-app header (optional: small mark in the top bar)
- Settings/About page
- Notifications (large icon where supported)

## Notes

- Ensure Android density variants and adaptive icon layers are generated from the same source.
- Prefer using `kPrimaryLogoAssetPath` for in-app image usage to avoid hardcoding paths.
