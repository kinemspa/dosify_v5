# Things To Fix

## Global
- Create a setting in the settings screen to inject some test data. 1 of each type of med and different schedules. Allow for adding it , init it, and remove it.  [COMPLETED]

## Home Screen


==============

## Medication Screen

### Large Cards


### Compact Cards

### List

==============

## Medication Details Screen
### Reports Card
- History: 
	- Paginate it [COMPLETED]
	- Allow for expansion of historical dose entry, allows edit. Maybe it pops the bottom page. [COMPLETED]
- Add reports
	- Doses taken vs missed (stacked bar per day/week) [COMPLETED]
	- Time-of-day consistency (histogram of taken times)
	- Streaks / consistency score (sparkline)
	- Action breakdown (taken / skipped / snoozed)
	- Dose amount trend (actual dose over time)
	- Inventory events timeline (refill/restock/vial opened markers)

### Medication Details Card
- Can you not bring in a little flare and style to all the different text elements?  Still boring. [COMPLETED]
- Remove the card border. This is still there. [COMPLETED]
- Active vial needs helper text, thetracked medication. [COMPLETED]
- Description text in thius part needs to wrap and display all. not elipses. [COMPLETED]

==============
## Add Medication

### Choose Medicaiotn Type Screen

### Choose Injection Type Screen

### Add Medicaiton Tablet
- Is Ibuprofen allowed to be used as an example? Is there a legal issues here. 

### Add Medicaiton - Multi Dose Vial


==============
# Schedules List
- Cards Need to be restyled exactly like the medication screen ones. Large, Compact and list. [COMPLETED]
- This doesnt need to have the actual time and dose details. Its the saved object of a schedule of doses. Provide the best informaiotn you can for being concise and explicit. [COMPLETED]
- Cards Large and Compact - Put a nice big Date cirecly on the right which shows the next dose date and time in little underneath.  [COMPLETED]
- COmpact Cards date circle has made the compact card just as big as the large card. Need to fix this. The Large card purpose is to show mroe infoarmation. COmpact shows less. list shows the least.  [COMPLETED]

==============
# Add Schedule
- Adding a schedule seems to be adding events in the past. SHould not do this. Maybe have a start from setting, Now, or selected date.  [COMPLETED]
- Needs an end date picker too.  [COMPLETED]
- Alot of black text on this screen. [COMPLETED]
- Add Tablet:
	- Configure Dose:
		- the unit type to use should be a dropdown and incremental like the add med wizard objects.  [COMPLETED]
		- needs helper text to instruct user to seletc  dose via tablets ot med strenght and it will be calculated to show how much is being taken [COMPLETED]
		- centre the shortcut buttons. [COMPLETED]
		- Incrementaning via med strenght is only incrementing in full tablet calculations, it needs to go in 1/4 tablet calculations. [COMPLETED]
		- Dosing times should be on the next page along with the schedule type selection. [COMPLETED]
	- Schedule Type:
		- Change name to type [COMPLETED]
		- Days of the month:
			- If I select the 31st day, how does this translate for 30 day or less months? [COMPLETED]
			-  I dont like the answer to the above item, if a user wants a monthly, they need to dose every month, if the 31st doesnt occur then the user will miss a month. what is the options here, what do other task schedulers do?  [COMPLETED]
			- compact the grid, its too spacious. [COMPLETED]
- Add MDV:
	- Dose needs to only show 2 decimals.  [COMPLETED]


- Once the med is selected, we need to restyle all of this. It looks disgusting. Look at the edit dialgos on the medicaiont details screens that are used to edit an existing medication.  [COMPLETED]
- Needs helper text to instruct the user what to do, what the options do.  [COMPLETED]
- Remove trailing 0s.  [COMPLETED]
- Dynamic summary, Example = Dose: 1 tablets x 50.0mg = 50.mg total. This needs to be more consise. Also when its s singular remove the plural s.  [COMPLETED]
- Dynamic Summary, needs to show each metric, Dose: 1 tablet, 20mg, or dose: 0.01mgs, 0.03 mL, 14Units.  [COMPLETED]
- If a tbalet is selected, incrementing the strenght optino should only increment in units of the med unit that are avaiable as a calculaiton to the unit x strenght per unit. SO if 1 tablet = 10mg. 1st increment will be 2.5mg = 1/4 tablet, 5mg = 1/2 tablet and so forth. Same for all med types. Capsules are whole numbers only, same with single dose vials and pre filled syringes.  [COMPLETED]
- MDV, this will need the syringe graphic and slider functionality that exists in the Reconstitution calculator. AT the end of the day its how many units in a syringe, which is calculated on the vial concetnraiton that was reconsituted.  [COMPLETED]
- Slider graphic is showing a 5mL or 10 ml syring. Should be able to change the syringe type. Also the bottom text is cropped by the dynamic card vaules below.  [COMPLETED]
- MDV should also default to the reconstituted value. As this is what the recon value was originally set to.  [COMPLETED]

- Name of Schedule to be Just "1 Tablet" - Dont need the auto generate check box. It should auto generate the name and then the user can rename it if they want. We dont need the time, frequency or med name as this will be showing and referenced from other places. It becomes redundant.  [COMPLETED]

==============
# Schedule Details Screen
- Needs a full rework to align with the med details screen. [COMPLETED]


==============
# Calendar

- Style this to look similar to the calendar widget that exists in the medication details screen.  [COMPLETED]
- Bottom of calendar is cropped byt the doses area.  [COMPLETED]
- FAB Button, It has text for the instruction, piut this on all the FABS.  [COMPLETED]






