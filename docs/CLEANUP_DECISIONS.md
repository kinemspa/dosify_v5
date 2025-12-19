# Cleanup Decisions (Repo Hygiene)

This document explains what can be deleted/moved safely vs what is required for building/running the app.

## Repo root map (what each thing is)

- `lib/`: App source code (required)
- `assets/`: App assets (required)
- `android/`: Android host project (required)
- `test/`: Dart/Flutter tests (recommended)
- `pubspec.yaml`, `pubspec.lock`: Dependencies (required)
- `.metadata`: Flutter tool metadata (required)
- `.gitignore`: Ignore rules (required)
- `analysis_options.yaml`: Analyzer + lint rules (required)
- `devtools_options.yaml`: DevTools config (optional, keep)
- `import_sorter.yaml`: Import sorter config (optional, keep)
- `docs/`: Canonical documentation (recommended)
- `scripts/`, `tool/`: Dev scripts/tooling (keep if used)
- `AGENTS.md`: Agent/workflow rules for this repo (keep)
- `FutterTestMcp/`, `mcp_flutter/`: Submodules (external repos; not required to build the main app)
- `.gitmodules`: Submodule mapping (required if submodules are present)

## Required for the Flutter app

Keep these (they are part of the build/runtime or developer workflow):
- `lib/`, `assets/`, `android/`, `test/`, `pubspec.yaml`, `pubspec.lock`
- `.metadata` (Flutter tool metadata)
- `analysis_options.yaml`, `devtools_options.yaml`, `import_sorter.yaml`
- `docs/` (canonical docs)

## Submodules / external tooling

These are git submodules (gitlinks), not normal folders:
- `mcp_flutter/` (external repo)
- `FutterTestMcp/` (external repo)

This repo now includes a `.gitmodules` file so submodule commands work.

Note: `analysis_options.yaml` excludes these submodule folders so `flutter analyze` only checks the main app package.

## Deleted (not needed)

These were tracked outputs / scratch files and should not live in git:
- `analysis_output.txt` (analyzer output snapshot)
- `test_output.txt` (test output snapshot)
- `temp_*.txt`, `temp_original.dart` (scratch/debug artifacts)

If you need analyzer/test output again, regenerate locally (`flutter analyze`, `flutter test`) instead of committing the outputs.

## Moved into docs/

These were tracked progress notes that cluttered the repo root but are still useful as history:
- Moved to `docs/archive/`:
  - `CONSISTENCY_FIXES_COMPLETE.md`
  - `DOSE_RECORDING_ENHANCEMENTS.md`
  - `MEDICATION_PAGES_AUDIT.md`
  - `STOCK_CALCULATION_FIX.md`
  - `WARP.md`
  - `WEEK_3_MDV_INTEGRATION_COMPLETE.md`, `WEEK_3_MDV_UI_FLOW.md`
  - `WEEK_4_INTERACTIVE_SYRINGE_COMPLETE.md`
  - `WEEK_5_RECONSTITUTION_INTEGRATION_COMPLETE.md`
  - `DESIGN_SYSTEM_MIGRATION_PROGRESS.md` (renamed from a root-level duplicate filename)

Screenshots were moved out of the repo root:
- `screenshot.png`, `screenshot2.png` -> `docs/assets/`

## Recommended local-only cleanup (not committed)

Safe to delete locally because they are generated and already ignored by `.gitignore`:
- `build/`, `.dart_tool/`
- IDE files like `*.iml`, `.idea/`
- `flutter_*.png`
