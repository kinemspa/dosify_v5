# Global

## Requests

- [x] Dose Cards need some sort of background colour. slight difference to backkground. maybe shadow. Also needs to help differentiate from each dose
- [x] Status Icons. Need to Globally Uniformed across the entire app. From Schedule cards, Dose Cards, Take Dose Dialogs, Historical Dose. Needs review. 
- [ ] Make all Text fields that take text to set the keyboard to Capital for the first letter. 

- Text sizes:
	- [x] Agent, please put in this file here in this file all the text sizes in use. I feel there is no uniformity of all text sizes across the app.
		- Design system font sizes (lib/src/core/design_system.dart)
			- kFontSizeXXSmall = 6
			- kFontSizeXSmall = 9
			- kFontSizeSmall = 11
			- kFontSizeMedium = 13
			- kFontSizeLarge = 15
			- kFontSizeXLarge = 17
			- kFontSizeHint = 10.5 (from kHintFontSize)
			- Next-dose date badge: 15 (compact), 18 (large)
		- Hardcoded fontSize values found in lib/ (occurrence counts)
			- 0 (5)
			- 8 (1)
			- 9 (7)
			- 10 (24)
			- 11 (17)
			- 12 (19)
			- 13 (3)
			- 14 (5)
			- 15 (3)
			- 16 (4)
			- 17 (1)
			- 18 (9)
			- 20 (4)
			- 22 (1)
			- 24 (2)
			- 32 (3)
		- [x] Can we put in a plan to replace all the hardcoded fonts with system design fonts.
		- [ ] Proceed with all the below. 
			- Plan (incremental, safe)
				1) Baseline scan: keep a running list of all `TextStyle(fontSize: ...)`/`fontSize:` occurrences in `lib/` and categorize by UI surface (Home, Medications, Schedules, Dialogs, Charts).
				2) Fill gaps in `lib/src/core/design_system.dart`: if a repeated typographic need exists (e.g., tiny badge text, dense table text), add a named helper there (e.g., `badgeTextStyle`, `denseLabelStyle`) instead of re-adding `fontSize` in feature code.
				3) Replace in priority order (highest visibility first): dose card + take dose dialog → headers/toolbars → list tiles/cards → settings/debug screens → charts/edge cases last.
				4) Enforce the rule: no new `fontSize:` in feature widgets. Any new typography must go through design-system helpers.
				5) Verification loop per batch: `flutter analyze` clean, then quick visual pass on the touched screens.
				6) Final cleanup: re-run the scan and confirm remaining `fontSize:` usages are either eliminated or explicitly justified (e.g., 3rd-party widgets/charts that require it).


## Recommendations
- [ ] Split the typography migration into per-screen sub-checklists (so progress can be tracked incrementally).
- [ ] Add a simple guard (CI/script) to prevent new `fontSize:` usage in `lib/src/`.
- [ ] Centralize text-field keyboard settings in shared field widgets (e.g., capitalization defaults).


