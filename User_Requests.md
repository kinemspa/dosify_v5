# Things To Fix

## Global
- Medicaiont stock under 25% is showing as purple.  I want orange.  [COMPLETED]


## Home Screen


==============

## Medication Screen
- Medicaiont stock under 25% is showing as purple.  I want orange.  [COMPLETED]
- Expiry needs to change colour to indicate percentage of 25% orange, 10%-0% red.  [COMPLETED]
- Stock Level needs to change colour to indicate percentage of 25% orange, 10%-0% red. [COMPLETED]
- Search, clear results is not needed as it automatically clears it already. [COMPLETED]
- I stated remove the Clear search text in the window on a search. The search field is already blanked out on a search that results in nothing.  [COMPLETED]

### Large Cards


### Compact Cards

### List

==============

## Medication Details Screen
### Reports Card
- History: cane paginate it? is that advisable?
    - How do other task apps display task history, is there a way to it vial a calendr view aswell? or not advisable?
    - Can we expad an entry with all its details when selected?
- What other graphs can we add?
	- Doses taken vs missed (stacked bar per day/week)
	- Time-of-day consistency (histogram of taken times)
	- Streaks / consistency score (sparkline)
	- Action breakdown (taken / skipped / snoozed)
	- Dose amount trend (actual dose over time)
	- Inventory events timeline (refill/restock/vial opened markers)

### Medication Details Card
- Can you not bring in a little flare and style to all the different text elements?
- Remove the card border. [COMPLETED]
- Edit Dialogs are all shwoing black font. 
- Sealed Vials Card needs a little helper text on sealed vials. Used for reconstitution. 

==============
## Add Medication

### Choose Medicaiotn Type Screen
- Can we restyle this to suit the remaining app style.  [COMPLETED]
- Dont like the gradient for the Choose card at the top. 

### Choose Injection Type Screen
- Can we restyle this to suit the remaining app style.  [COMPLETED]
- Dont like the gradient for the Select card at the top.

### Add Medicaiton Tablet
- Is Ibuprofen allowed to be used as an example? Is there a legal issues here. 

### Add Medicaiton - Multi Dose Vial


==============
# Schedules List
- Cards Need to be restyled exactly like the medication screen ones. Large, Compact and list. [COMPLETED]
- This doesnt need to have the actual time and dose details. Its the saved object of a schedule of doses. Provide the best informaiotn you can for being concise and explicit. [COMPLETED]
- Cards Large and Compact - Put a nice big Date cirecly on the right which shows the next dose date and time in little underneath. 

==============
# Add Schedule
- What happens on this screen if there are 20, 30, 100 medicatinos. How will this display? [COMPLETED]
- Once the med is selected, we need to restyle all of this. It looks disgusting. Look at the edit dialgos on the medicaiont details screens that are used to edit an existing medication.  [COMPLETED]
- Needs helper text to instruct the user what to do, what the options do.  [COMPLETED]
- Remove trailing 0s.  [COMPLETED]
- Dynamic summary, Example = Dose: 1 tablets x 50.0mg = 50.mg total. This needs to be more consise. Also when its s singular remove the plural s.  [COMPLETED]
- Dynamic Summary, needs to show each metric, Dose: 1 tablet, 20mg, or dose: 0.01mgs, 0.03 mL, 14Units.
- If a tbalet is selected, incrementing the strenght optino should only increment in units of the med unit that are avaiable as a calculaiton to the unit x strenght per unit. SO if 1 tablet = 10mg. 1st increment will be 2.5mg = 1/4 tablet, 5mg = 1/2 tablet and so forth. Same for all med types. Capsules are whole numbers only, same with single dose vials and pre filled syringes.  [COMPLETED]
- MDV, this will need the syringe graphic and slider functionality that exists in the Reconstitution calculator. AT the end of the day its how many units in a syringe, which is calculated on the vial concetnraiton that was reconsituted.  [COMPLETED]
- Slider graphic is showing a 5mL or 10 ml syring. Should be able to change the syringe type. Also the bottom text is cropped by the dynamic card vaules below. 
- MDV should also default to the reconstituted value. As this is what the recon value was originally set to.  [COMPLETED]

- Name of Schedule needs to be extremely brief. The dynamic initial of it needs to be for example "1 Tablet - Daily - 9am"  [COMPLETED]
- Name of Schedule to be Just "1 Tablet" - Dont need the auto generate check box. It should auto generate the name and then the user can rename it if they want. We dont need the time, frequency or med name as this will be showing and referenced from other places. It becomes redundant. 

==============
# Calendar

- Style this to look similar to the calendar widget that exists in the medication details screen. 
- Bottom of calendar is cropped byt the doses area. 
- FAB Button, It has text for the instruction, piut this on all the FABS. 






