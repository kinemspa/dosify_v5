# Things To Fix

## Global
- Dark Theme 
	- The reconstitution calculator 
		- Can we change the background blue colour to something not blue? [COMPLETED]
	
- For All today Icons on cards, change to the Text "Today" [COMPLETED]
- Time Picker, make all text the grey font. unless selected.  [COMPLETED]

## Home Screen

==============

## Medication Screen

### Large Cards
- Non MDV Large cards, the Storage location text and remaining  text are NOT on the same row. [COMPLETED]

### Compact Cards

### List

==============

# Medication Details Screen
- Drag Icon is cropping over the boundary of the card. move it right a bit.  [COMPLETED]
- INstruct user that if trying to drag when other cards are not callapsed, that cards are not collapsed and all cards need to be callapsed. [COMPLETED]
- For MDV - The Dialog for refill and havign a seperate restock button for a the restock is very clunky. Can we have 2 selections within this dialog to change it? Maybe a page?  [COMPLETED]
	- You missed the point here. Its either Refill Active Vial Which means to add ot replace current active vial with aa new reconstituted vial. This can be pulled from the sealed vial stock or not. The you have a totall seperate action, for refilling the sealed vials stock. These most likely need to be seperate buttons or pages within the refill dialog. 
	- When reconsituting the active vial, we need to be able to also pull from the reconsitution calculator, use the same reconsitutiont as done previously, calculate a new reconstitution, retrieve a saved reconsitution, or reconsitution voluem is known and just enter the reconstitution. 
- Minimized Cards, make them all the same size as the Reconsitution card in height. [COMPLETED]
- Reconstitution Card:
	- Remove the dit button. [COMPLETED]
	- Can No longer edit the reconstitution. Need to be able to edit the reconstitution.  [COMPLETED]
	- Card within a card is not a good design concept. Make it one card. [COMPLETED]

### App Header
- On the Large Med Cards we have Storage Conditions Icons, Expiry, then storage locations. Then aligned right we have the stock. With MDV we have 2 lines for the active and sealed vials. I want this duplicated on the app header for where the storage and remaining stock informaiton is. [COMPLETED]

### Reports Card
- Scheduled Doses should be editable too.  [COMPLETED]
- Should be able to edit the dose time and date aswell.  [COMPLETED]
- Scheudled Dose Date Icon is not showing the date. [COMPLETED]
- Make edit icon smaller and lighter  [COMPLETED]
- AdHoc Dose:
	- Edit - Editing the dose needs to be the same dialog as taking a dose.  [COMPLETED]
- Scheduled Dose:
	- Scheduled Doses are disappearing when the schedule is disabled. Need to remain visible.  [COMPLETED]

### Schedule
- If the schedule is paused, disabled. It needs to show it everywhere. Including the dose cards, and the calendars. Probably need some sort of other colour representation.  [COMPLETED]
- Pause button. Its too big. Is it possiblke to have the Pause button enable a time frame, pause for ever, pause until etc etc..  [COMPLETED]
- Take Dose Card:
	- Dose Name is correct.
	- Underneath you have Dose amount and then the med type. No. Should have Med Name, Med strenght and Dose in all possibly metrics. Status, Date Icon, Time, And a big action button. Take, or edit depending on the action.
	- Take Dose Card: [COMPLETED]
		- Dose Name is correct. [COMPLETED]
		- Underneath you have Dose amount and then the med type. No. Should have Med Name, Med strenght and Dose in all possibly metrics. Status, Date Icon, Time, And a big action button. Take, or edit depending on the action. [COMPLETED]
- Make sure this entire card is a widget. As it will be expanded for the schedules, calendar and home screen.  [COMPLETED]


### Medication Details Card
- Sealed Vials heading should still be in primary colour. This was not completed.  [COMPLETED]
- Make Text field labels and text field values bottom aligned.  [COMPLETED]

==============
## Add Medication

- Wizard still doesnt have Next button instead of continue button at the bottom when filling in fields.  [COMPLETED]
- The above task is still not complete.  The continue button is supposed to be a next button to jump to the next field easily while the OSK is displaying. Must be for ALL wizards.  [COMPLETED]

### Choose Medicaiotn Type Screen

### Choose Injection Type Screen

### Add Medicaiton Tablet

### Add Medicaiton - Multi Dose Vial


==============
# Schedules List
- Large Cards:
	- Move Next Icon slightly Left.  [COMPLETED]
	- Underneath Dose Name - "Take "DOSE" of "MEdicineName" on "Schedule Type" at "Time of Day" (If more than 1 time set for the day) and "Time fo Day Dose 2" Repeat as needed.  [COMPLETED]
	- Place startdate and end date on same row.  [COMPLETED]
	- Change to Start Date: and End Date: [COMPLETED]
	- change today icon to today text [COMPLETED]
- Compact Card:
	- Add on same row ass Dose Name. "Take "DOSE" of "MEdicineName" on "Schedule Type" at "Time of Day" [COMPLETED]



==============
# Add Schedule
- Select a Dose input type or mode, Strenght, Volume or Units. Give a light summary.  [COMPLETED]
- Strength needs to be able to select the STrenght Unit. mcg, mg, g.  [COMPLETED]
- The incremental field and buttons are wrong. Use the same styling as the add med screen.  [COMPLETED]
- App Header dynaimc summary needs to contain the active medicine remaining.  [COMPLETED]
- Step 1:
	- Tablets:
		- Above Dose Type, helper text for sleecting tablet or Strenght per tablet.  [COMPLETED]
		- Formula summary needs to be centreed in the field. Text is still too dark.  [COMPLETED]
		- Centre align the shortcut buttons.  [COMPLETED]
		- Incremental field and buttons are still incorrect. Look at the dialogs, ad med wizard. i am fucking pissed you do not use the ceentral design system.  [COMPLETED]
		- If I choose input strenght, I need to have the strength dropdown and incremental buttons. tablets  can have a strenght of mcg, mg, or g. Fucken use your brain. Error or warning text to display when out of bounds of the administration method units, so must be within 1/4, 1/2, 3/4, 1. 




- Step 2:
	- Dont put SO you dont get past doses. This entire app and its helper text. you are not speaking to me. You are speaking to users. 
	- Schedule Dates Styling of fields is incorrect. not use system design.  [COMPLETED]
	- Start:
			- Selected date calnedar button is causing an overflow.  [COMPLETED]
			- Once changed to selected ate, the drop down is becominga calendar button. Calendar button needs to appear below the dropdown, alos make it the same sizing as the system design, same size as the date button on the add med screens.  [COMPLETED]
	- End:
		- Same as above.  [COMPLETED]
	- Schedule Pattern:
		- Drop Down Menu has sharp corners.  [COMPLETED]
		- Days of the Week:
			- Day selection chips. Reduce the size of them. Center align them. Reduce padding make more compact.  [COMPLETED]
			- Dont use Grey backgrounds. Ever. Put this in your rules.  [COMPLETED]
			- Dont use black font. Rules.  [COMPLETED]
		- Days on / Days Off
			- Days on and Days off fields are on the same horizaontal row, causing a major overflow. Shoult be vertically stacked.  [COMPLETED]
		- Days of the Month
			- Make the grid more compact like the days of the week.  [COMPLETED]
			- Centre Align  [COMPLETED]
			- No Grey backgorund  [COMPLETED]
			- No black font.  [COMPLETED]
			- If day doesnt exist option should only appear when selecting 28-31.  [COMPLETED]
			- If day doesnt exist field styling is not system centralised. Font too large, too black.  [COMPLETED]
			- Days of the Month in the dropdown menu once selected is only showing "days of the". Month is cropped off.  [COMPLETED]
			- Helper text should state something like, select on which days of the month to for doses.  [COMPLETED]
			- How can we handle something like, First monday of every month, or first 2 mondays of every month? How do other task apps approach this?
- Step 3:
	- These cards need to have the same heading styling as all other large cards.  [COMPLETED]
	- Summary:
		- Dose needs to show the following:
			- Go and find out the correct terminology for dosing medications. What I care about is framing the correct terms for Say, if a dose is 1 tablet, the tablet is called what?, then we have the strenght of medicaiont in the tabletm what is that called? Same with a capsule, this is like the medicaiont carrier or form. Then if its a single dose vial, we would have the Dose in Volume, the Dose in Strenght, and the DOse in the delivery or admiinstration mechanism, which would be a syringe for this one. These values need to be displayed evetrywhere on the app where these things appear. As this app is to communicate very specifically the details here. If I am using a pre filled syringe, I want the Med Strenght, the Med Volume and the Amount of the measurement in teh administation tool/ method. So go find the correct terminology for this so we can write it in as a rule for you to adhere to across this app. [COMPLETED]
	- Settings:
		- The Active button switch, we dont use this switch type anywhere in teh app, why are you using it now? [COMPLETED]
	- What is cycle start date? We already set the schedule start date on step 2. 

- You have stated all the below items are completed. None of them are. Are we dealing with a different add schedule screen? Are there multiple? Is there a different one that is not in the route?
- Add Tablet:
	- Configure Dose:
		- the unit type to use should be a dropdown and incremental like the add med wizard objects.  [COMPLETED]
		- Why is your helper text so lamen? Enter how many you take? WTF is this?
		- centre the shortcut buttons. This is not completed. They are left alinged.
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
		- I have a MDV of BCP-157 which is 16mg at 5mL. I have toggled strenght, and incremented by 1, which puts a 1 there, which is 1mg, it then trhows an error of Dose Exceeds vial Sytrenght of 10mcg. [COMPLETED]
		- If using strenght, we need to be able to change the unit of strenght from mcg, mg and the value. [COMPLETED]
		- Changing to volume, I incremented in 1 to . Whcih trhows an error. I suppose this is correct, but I dont know what I am incremewnting in. There is no mL display. [COMPLETED]
		- Changing to Units, I then increment and 2 syring graphics display. [COMPLETED]
	- Syringe Graphic should always be showing. [COMPLETED]
	- The Calculations are all incorrect. There is a bottom summary card, its displaying 1mg, 0,69ml, 69units, while the summary up in the appnbheader is shwoing Dose: 0mg, 0.69 mL, 69 units. [COMPLETED]
	- Dynamic summary needs to show mg to 3 decimal places or mcgs. Or both. [COMPLETED]
	- Syring graphic , the black circle indicator has some other numbers displaying in white, they maybe above hte syringe graphic indicators? [COMPLETED]
	- Cannot proceed from Step 1. Continue button remains greyed out no matter what settings are entered. [COMPLETED]
	- Incrementing units should be whole number, and lock in to whole numbers. Dont increment 31.6 to 32.6, incrment to next whole number. 
	- Remove 10mL syringe. 
	- Dose Calculations are incorrect. Check the Calculations in the engine. I have currently a 16mg vial with 5mL in it. I select 1mL syringe, and enter 1mg. It states its 50 units. It should be 31.3 Units. Also 0.5mL should not equal 1mg. 
	- Why does MDV have 2 summary boxes?


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
- Need to consider the objects that sit in the app header. I need them not to be just text objects. I want some flavour. [COMPLETED]
- DOse Calendar - Needs to use the same Dose calendar widget as the medicaiotn details screen. . [COMPLETED]
- Move DOse Calnedar to top card. [COMPLETED]
- Schedule Details needs to have edit options like medication details. [COMPLETED]
- SO we should have Schedule Status of , Active, Paused, Disabled, Completed. [COMPLETED]
	- Active is of course active
	- Paused, the ability to pause a schdule until a set date. 
	- Disabled. Paused indefinately. 
	- Completed, end of scheudle cycle has passed. 
- App Header:
	- Add the Date Icon for the next dose in the app header. [COMPLETED]
	- Add chips for the frequency type. [COMPLETED]
	- Include Pause button. [COMPLETED]
		Pause Button: Has an indefinate and an Pause end date option. Helper text explains the 2 options and how the schedule will behave. 

## Schedule Details Card
- Frequency is the incorrect term. Needs the Schedule type. Which is Daily, X days, Days of the week, Cycle. The it can display,  [COMPLETED]

	



==============
# Calendar

- Replace the enire calendar with the Schedule widget we created in the medicaiont details screen. Or rebuild a new one that is only for this screen. Whatever you think is the corretc move. 
- When the widget displays on the calendar screen, it behaves in the following manner. 
- Defaults to displaying Full month view.
- Calendar displays at the top
- Today, Selected Day is init. 
- Dose Cards (Universally Widget) display underneath the calendar. 
- Stacked vertical. 
- Can change to week view
- Can change to day view
- Info module from curr screen that displays at the top to be included. Has left and right buttons, current day, today shortcut, view mode display. 
- Day view:
	- Dont allow slecting doses direct from calendar. Hour has to be selected, whcih then displays all the doses below which are then selected. 



==============
# Dose Cards
- Too High. 
- Has time and an action to take at time. Dont need both. 
- Needs a date icon, will display today
- Dose instructions:
	- Take X X at X. 
- The take button. I am conflicted here. I want the shortcut buttons of take, snooze, skip. But also want the dialog to pop where notes can be added and the status can be changed. 



==============
# Take/edit Dose Dialog
- Take Dose:
	- Remove divivder from the top under the firts helper text. 
	- Why is tyhere grey chips????????????
	- Status Chips, need to be centred. Colour coordinate them. 
	- Dose card status symbol not displaying, needs to show and change as status is updated. 
	- If a MDV, Single Dose Vial or Pre Filled syringe, we need to be showing the syringe graphic. It is paramounbt. Plus the 2 or 3 values of the dose. 
	- Helper text: Change status if you need to correct this dose? WTF is this lamen crap. be instructional. 
	- Cards wwithin cards, I stated to make this screen look like the other dialog pop screens, the cards within this make it not look like that at all.
	 
- Edit Historical Dose:
	- Take dose screen to be styled into the same as the ad hoc dialog.  [COMPLETED]

- Ad-Hoc Dose
	- MDV Slider for Units is not allowing saving the state. [COMPLETED]
	- MDV Units, remove trailing 0. Increment in whole numbers. [COMPLETED]
	- MDV Slider, should be able to click on spot on the slider to jump slider. [COMPLETED]
==============
# Reconstitution  Calculator


## Add Med Wizard - Recon Calc

## Stand Alone - Recon Calc
- This is a stand alone version of the recon calculator used in the Add Med MDV wizard. I want it to be exactly the same as that one in an operations perspective. The only difference is that you will have the ability to enter a manual medicaiont name and medicaiont strenght. [COMPLETED]
- The standalone one will allow for the saving of reconstitution calculations. Which can be opened up and viewe and editied, and or sourced in the add med wizard. [COMPLETED]
- This should be the one accessible from the hamburger menu. [COMPLETED]
- The Reconstitution Calculator that is selectable from the Main Menu, is supposed to show the dsame recon calculator as in the Add MEd Screen MDV. 
- This one has a couple of differecnes because it is a standalone one. 
- Has the option to add a med name in it. 
- Requires a med strength.
- Allows for saving of reconstitotions. 
- You had supposedly done all of the above, but its not what is accessible or routable from the main menu. 

==============
# Analytics
- This will have the same widgets as the medicaiont details screen but it will allow for viewing data from all meds and schedules. It will also allow for exporting of data. 


==============
# Inventory
- A new screen that provides a high level of all stock. 





================================
# Notifications
- Seems to be a lot of notifications loading on startup. Is this goign to be a performance hit or an issue? [COMPLETED]








