# Global

## Requests

- [x] Timepicker, The editing field such as hour has a light blue colour with white font. The white font is not readable, should be dark like the other fonts on the screen. 
- [x] Deleting a Medication.
	- Warngin Dialog needs to state. Deleting a medication will delete all associated schedules. But will maintain and historical data. 
	- Deleting Medication must delete schedules, all futere schduled doses and associated notifications. Currently Is not doing this. 
- [x] I want to number the doses. So Dose 1, 2 3 etc etc. Numbered according to the schedule. Each Schedule starts from 1. 
- [x] I want to include images for all medicaitons like the syringe. So for Tablets its a tablet image and the number of tablets, capsules the same, pre filled syringe is a syringe graphic, single dose vial can be an ampule or vial icon. 

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
			- Plan (incremental, safe)
				1) Baseline scan: keep a running list of all `TextStyle(fontSize: ...)`/`fontSize:` occurrences in `lib/` and categorize by UI surface (Home, Medications, Schedules, Dialogs, Charts).
				2) Fill gaps in `lib/src/core/design_system.dart`: if a repeated typographic need exists (e.g., tiny badge text, dense table text), add a named helper there (e.g., `badgeTextStyle`, `denseLabelStyle`) instead of re-adding `fontSize` in feature code.
				3) Replace in priority order (highest visibility first): dose card + take dose dialog → headers/toolbars → list tiles/cards → settings/debug screens → charts/edge cases last.
				4) Enforce the rule: no new `fontSize:` in feature widgets. Any new typography must go through design-system helpers.
				5) Verification loop per batch: `flutter analyze` clean, then quick visual pass on the touched screens.
				6) Final cleanup: re-run the scan and confirm remaining `fontSize:` usages are either eliminated or explicitly justified (e.g., 3rd-party widgets/charts that require it).


