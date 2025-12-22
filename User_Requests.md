# Things To Fix

## Global



## Home Screen


==============

## Medication Screen
- Search - Needs to prioritise Medname first, then Manufacturer, then description. [COMPLETED]
- Seacrh results font is too dark.  [COMPLETED]
- All cards/lists have different text colours for the Med Name. Make the med name primary colour for all. [COMPLETED]

### Large Cards
- Large Cards are a bit too spacious, how can we compact them a bit.  [COMPLETED]
- Large Cards MDV we can change the x/x reserve vials, change it to x sealed vials.  [COMPLETED]
- Expiry needs to change colour to indicate. [COMPLETED]
- The donut graph and the text underneath needs to be right aligned. [COMPLETED]

### Compact Cards
- Need to be restyled to be more in line with the app style [COMPLETED]

### List
- Make the list items less tall [COMPLETED]

==============

## Medication Details Screen
- The text under the DOnut graph, it needs some better alignment and styling. It looks not great. [COMPLETED]
- When medicaiton is at 0% the percentage number nees to be red, same with the remaining value. make an orange for 20%. [COMPLETED]
- Move the dose and refill buttons to the right side of app header. 

### Reports Card
- We need to have a more compact wat to display the history. [COMPLETED]
- What other graphs can we add?
	- Doses taken vs missed (stacked bar per day/week)
	- Time-of-day consistency (histogram of taken times)
	- Streaks / consistency score (sparkline)
	- Action breakdown (taken / skipped / snoozed)
	- Dose amount trend (actual dose over time)
	- Inventory events timeline (refill/restock/vial opened markers)

### Medication Details Card
- Restyle the entire card. Make it look nice. The dialog cards on this screen are something to go by. 
- Font is black. [COMPLETED]
- MDV Backup Stock - We need to unify the terminology across the app for this. We had reserve vials, sealed vials backup stock. Pick the best terminology for this and stikc with it. [COMPLETED]
- MDV Backup Stock - restock button is way too big. [COMPLETED]

==============
## Add Medication

### Choose Medicaiotn Type Screen
- Can we restyle this to suit the remaining app style. 

### Choose Injection Type Screen
- Can we restyle this to suit the remaining app style. 

### Add Medicaiton Tablet
- Is Ibuprofen allowed to be used as an example? Is there a legal issues here. 
- Default Expires date for all Meds should be 90 days, not 364. 

### Add Medicaiton - Multi Dose Vial
- Step 4, Sealed VIals, when landing on this screen, the Track Invnetory Check box shows ched for a split second then it vanishes. 


==============
# Schedules List
- Cards Need to be restyled exactly like the medication screen ones. Large, Compact and list. 
- This doesnt need to have the actual time and dose details. Its the saved object of a schedule of doses. Provide the best informaiotn you can for being concise and explicit. 


==============
# Add Schedule
- Select Medication screen, Use the list view to display the meds. 
- What happens on this screen if there are 20, 30, 100 medicatinos. How will this display?
- Once the med is selected, we need to restyle all of this. It looks disgusting. Look at the edit dialgos on the medicaiont details screens that are used to edit an existing medication. 
- Needs helper text to instruct the user what to do, what the options do. 
- Remove trailing 0s. 
- Dynamic summary, Example = Dose: 1 tablets x 50.0mg = 50.mg total. This needs to be more consise. Also when its s singular remove the plural s. 
- If a tbalet is selected, incrementing the strenght optino should only increment in units of the med unit that are avaiable as a calculaiton to the unit x strenght per unit. SO if 1 tablet = 10mg. 1st increment will be 2.5mg = 1/4 tablet, 5mg = 1/2 tablet and so forth. Same for all med types. Capsules are whole numbers only, same with single dose vials and pre filled syringes. 
- MDV, this will need the syringe graphic and slider functionality that exists in the Reconstitution calculator. AT the end of the day its how many units in a syringe, which is calculated on the vial concetnraiton that was reconsituted. 
- MDV should also default to the reconstituted value. As this is what the recon value was originally set to. 

- Time selector has violet colour in the AM and PM Selector. 
- Name of Schedule needs to be extremely brief. The dynamic initial of it needs to be for example "1 Tablet - Daily - 9am" 

==============
# Calendar

- Style this to look similar to the calendar widget that exists in the medication details screen. 
- Bottom of calendar is cropped byt the doses area. 
- FAB Button, It has text for the instruction, piut this on all the FABS. 






