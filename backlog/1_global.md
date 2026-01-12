# Global

## Requests

- [x] Timepicker, The editing field such as hour has a light blue colour with white font. The white font is not readable, should be dark like the other fonts on the screen. 
- [x] Deleting a Medication.
	- Warngin Dialog needs to state. Deleting a medication will delete all associated schedules. But will maintain and historical data. 
	- Deleting Medication must delete schedules, all futere schduled doses and associated notifications. Currently Is not doing this. 

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
		- [ ] Can we put in a plan to replace all the hardcoded fonts with system design fonts. 


