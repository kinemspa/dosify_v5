# Warp Project Rules and Workflows — Dosifi v5

This file defines the project’s standing rules, common workflows, and quick links so this Flutter app behaves like a “proper Warp project.”

Project: Dosifi v5 (Flutter)
Platform: Android (Windows + PowerShell)
Primary colors: #09A8BD → #18537D gradient; Secondary: #EC873F

Standing rules
- Always commit to the local git
- ALways update the technical documentation
- Never use interactive or fullscreen terminal commands in automation
- For git commands that might page, prefer no-pager
- Never print secrets; use environment variables when needed
- Do not edit source code via shell; use structured diffs for code changes

Key docs
- Product design: docs/product-design.md
- Technical overview: docs/technical.md

Environment and paths
- OS: Windows; Shell: PowerShell (pwsh)
- Project root: .
- Android packageId: com.dosifi.app
- Android namespace: com.dosifi.dosifi_v5
- Useful paths: lib/, android/, docs/

Day-to-day workflows
- Build (clean + deps + codegen + analyze)
  - flutter clean
  - flutter pub get
  - flutter packages pub run build_runner build --delete-conflicting-outputs
  - flutter analyze
- Run (debug)
  - flutter run
- Run (release)
  - flutter run --release
- Regenerate Hive / Freezed adapters
  - flutter clean
  - flutter packages pub run build_runner build --delete-conflicting-outputs
  - flutter analyze
- Format and quick health checks
  - dart format .
  - flutter analyze

UI work focus (current)
- Add Medication — Tablet pages:
  - lib/src/features/medications/presentation/add_edit_tablet_page.dart
  - lib/src/features/medications/presentation/add_edit_tablet_hybrid_page.dart
  - lib/src/features/medications/presentation/add_edit_tablet_details_style_page.dart
- Align with docs/product-design.md: summary card, section order (General, Strength, Inventory, Storage), consistent form styling (FormFieldStyler, StrengthInput), live summary updates.

Git conventions
- Commit early and often, grouping related changes
- Use conventional message types where possible: chore, feat, fix, docs, refactor, style
- Prefer small, reviewable diffs; run flutter analyze before committing

Notes
- If analyzer warnings are noisy, address structure/style first (e.g., package: imports, file newlines) before deep refactors.
- If a refactor causes cascading errors, reduce a widget subtree to a minimal Scaffold + Card and then reintroduce elements incrementally.
