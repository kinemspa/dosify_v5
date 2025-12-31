# Things To Fix

## Global
- How does changign the text size in the Android Phone settings impact the app layout and text styling? [COMPLETED] - How do I test this?

## Home Screen


==============

## Medication Screen

### Large Cards
- Need some space between the Storage info and the schedules row.  [COMPLETED]
- Can we place all the storage objects in their own little space? MDV Have Active and Sealed with Storage Conditionas and Storage Locations. 
- MDV has Expiry for Active and Sealed, Maybe the expiry needs to sit within the storage details. 

### Compact Cards

### List

==============

## Medication Details Screen
- I am conflicted on the Schedule Card. It looks redundant having Schedules then Doses and Schedules within this card with the same prominant heading.  Do we split them into seperate cards or try to organise it a different way?
- App header objects and text are cropping on a smaller Samsung S22+ screen. We need to make sure everything is responsive, I suppose we can do this pass later once the app is completed and check everything on all screen sizes. Adhoc and Refill button text needs to adapt the text size too.  [COMPLETED] - Not completed, there is issues with the fullly documented details nudging the refill and ad hoc down belowe the app header gradient bottom edge. The app header edge needs to adjust to fit all App header items. 
- Prbably need to restrict the Description to x number of characters on the app header so it doesnt blow the app header size out. 
- When Expanding or Minimizing the cards, the animation highlight is a full square so the corneers slightly flash on press outside of the cards roudner border radius.  [COMPLETED] This is not complete. There are light grey corners still  appearing on clicking. 
- Samsung S22+ and Pixel 5, there is an overflow on the bottom of app header, i think its the buttons are pushed out. the app header background gradient always should fit to the internal objects. 

### Reports Card

- The pages of all the rports looks shit and takes up too much real estate. Is there a more compact way to provide these pages? Maybe compact it all? [COMPLETED] Not good enough. This page menu display view is taking up way to much vertical real estate. I can post an image when you get to this one. 
- History: 
	- Remove the view change. 
	- Date Icon like on the Schedule cards. Make it really small. The date needs to be the most visible as its sorted by that. 
	- Missed Doses should be editable. 
	- The expansion of the hisotrical dose is awesome, but you have created some new bottom pop up page for changing it. Use the existing one that pops on taking doses. This is to be the universal dose widget for editing doses. [COMPLETED]
	- Need to include Refills in the history.  [COMPLETED]
	- Need to include all actions taken on doses. SKipped, missed. Status changed.  [COMPLETED]
- Add reports
	- Doses taken vs missed (stacked bar per day/week) [COMPLETED]
	- Time-of-day consistency (histogram of taken times) [COMPLETED]
	- Streaks / consistency score (sparkline) [COMPLETED]
	- Action breakdown (taken / skipped / snoozed) [COMPLETED]
	- Dose amount trend (actual dose over time) [COMPLETED]
	- Inventory events timeline (refill/restock/vial opened markers) [COMPLETED]
	- Dose Strenght History over time in a bar chart graph. [COMPLETED]

### Schedule
- Change Scheduled Doses heading to Doses [COMPLETED]

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
- On the cards, Schedule Name needs to Merge the Med Name into it. If the Schedule is named "1 Tablet" it should show "Panadol - 1 Tablet" [COMPLETED]
- For the date icon on the cards, can we put a little "Next" somewhere? Maybe overlap it over the icon or something. I will let you recommend what you think.  [COMPLETED]

==============
# Add Schedule
- Adding a schedule seems to be adding events in the past. SHould not do this. Maybe have a start from setting, Now, or selected date.  [COMPLETED]
- Needs an end date picker too.  [COMPLETED]
- Alot of black text on this screen. [COMPLETED]
- Increment field/buttons is not correct its not using the correct styling. [COMPLETED]
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
	- Default to 1mL syringe. Or to the saved reconstitution settings if exists. [COMPLETED]
	- Needs helper text, input strenght of dose, or select volume or Units of the syringe size. It will do all the calculaiotns for you based on input. [COMPLETED]
	- Formula is shwing incorrect.
		- I have a MDV of BCP-157 which is 16mg at 5mL. I have toggled strenght, and incremented by 1, which puts a 1 there, which is 1mg, it then trhows an error of Dose Exceeds vial Sytrenght of 10mcg. 
		- If using strenght, we need to be able to change the unit of strenght from mcg, mg and the value. 
		- Changing to volume, I incremented in 1 to . Whcih trhows an error. I suppose this is correct, but I dont know what I am incremewnting in. There is no mL display. 
		- Changing to Units, I then increment and 2 syring graphics display. 
	- Syringe Graphic should always be showing. 
	- The Calculations are all incorrect. There is a bottom summary card, its displaying 1mg, 0,69ml, 69units, while the summary up in the appnbheader is shwoing Dose: 0mg, 0.69 mL, 69 units. 
	- Dynamic summary needs to show mg to 3 decimal places or mcgs. Or both.  
	- Syring graphic , the black circle indicator has some other numbers displaying in white, they maybe above hte syringe graphic indicators? 
	- Cannot proceed from Step 1. Continue button remains greyed out no matter what settings are entered.



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
- Needs the Med Name at the top as part of the Shedule Name [COMPLETED]
- Dose needs to show all the calulations. The Unit amount, the strenght and the volume if a liquid. Remove all trailing 0s. Remove plurality on single.  [COMPLETED]
- Status needs to be a toggle button.  [COMPLETED]
- Next dose card needs to be the same as the scehdules widget used in the medication details screen. Dose timeline doesnt really make sense.  [COMPLETED]



==============
# Calendar

- Style this to look similar to the calendar widget that exists in the medication details screen.  [COMPLETED]
- Bottom of calendar is cropped byt the doses area.  [COMPLETED]
- FAB Button, It has text for the instruction, piut this on all the FABS.  [COMPLETED]
- The bottom part which shows all the doses, use the same widget as the Med details screen.  [COMPLETED]
- Make the calendar section a set size, so it fits the month view, week view and day view.  [COMPLETED]
- The Days on the calnedar are no longer showing if they have a scheduled dose. Can we implement a tiny little number? We had some colour codeing for all the dose status, coming, skipped, missed and snoozed.  [COMPLETED]
- Style the month view a little nicer, its actually looking really good.  [COMPLETED]
- It might be good to have a little up next display up the top for the next dose. (These kinds of widgets will be used on the home page aswell.)  [COMPLETED]


==============
# Take Dose Screen
- Take Dose:
	- Take dose screen to be styled into the same as the ad hoc dialog. Ad hoc dialog is very nice and stylish. I want all Take doses to look like this and display like that.  [COMPLETED]

- Edit Historical Dose:
	- Take dose screen to be styled into the same as the ad hoc dialog.  [COMPLETED]

- Ad-Hoc Dose
	- MDV Slider for Units is not allowing saving the state. 
	- MDV Units, remove trailing 0. Increment in whole numbers. 
	- MDV Slider, should be able to click on spot on the slider to jump slider.
==============
# Reconstitution  Calculator

## Add Med Wizard - Recon Calc

## Stand Alone - Recon Calc
- This is a stand alone version of the recon calculator used in the Add Med MDV wizard. I want it to be exactly the same as that one in an operations perspective. The only difference is that you will have the ability to enter a manual medicaiont name and medicaiont strenght. [COMPLETED]
- The standalone one will allow for the saving of reconstitution calculations. Which can be opened up and viewe and editied, and or sourced in the add med wizard. [COMPLETED]
- This should be the one accessible from the hamburger menu. [COMPLETED]

==============
# Analytics
- This will have the same widgets as the medicaiont details screen but it will allow for viewing data from all meds and schedules. It will also allow for exporting of data. 


==============
# Inventory
- A new screen that provides a high level of all stock. 





================================
# Notifications
- Seems to be a lot of notifications loading on startup. Is this goign to be a performance hit or an issue?








