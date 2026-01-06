# Things To Fix

## Global
- Dark Theme 
	- The reconstitution calculator [COMPLETED]
	
- Time Picker, the AM / PM text Grey when not selected. White when selected.  Same with the clock numbers. [COMPLETED]

## Home Screen

- Home - Upcoming Widget (DoseCard) [COMPLETED]
- Home - Schedule Card (DoseCard) [COMPLETED]
- Home - Calendar Widget (mini calendar) [COMPLETED]

==============

## Medication Screen

### Large Cards

### Compact Cards

### List

==============

# Medication Details Screen
- Minimized Cards, make them taller. [COMPLETED]
- MDV: 
	- Can we change the refill dialog. " Open New VIal" this is not the correct terminology for medicine.  [COMPLETED]
	- When reconsituting the active vial, we need to be able to also pull from the reconsitution calculator, use the same reconsitutiont as done previously, calculate a new reconstitution, retrieve a saved reconsitution, or reconsitution voluem is known and just enter the reconstitution.  [COMPLETED]
- Reconstitution Card:
	- Why is the text so dark? [COMPLETED]

### App Header
- On the Large Med Cards we have Storage Conditions Icons, Expiry, then storage locations. Then aligned right we have the stock. With MDV we have 2 lines for the active and sealed vials. I want this duplicated on the app header for where the storage and remaining stock informaiton is. [COMPLETED]
- Expiry date text is unreadable, What colour is it? [COMPLETED]
- Expiry date, can we put the letters Exp in front of the date. [COMPLETED]
- MDV:
	- Where is the storage details for the sealed vials [COMPLETED]


### Reports Card
- Should be able to edit the dose time and date aswell.  This is not completed. need to add the date and time into the dose editor. [COMPLETED]
- AdHoc Dose:
- Scheduled Dose:

### Schedule
- Grey Buttonas again. Do not use grey buttons or chips. put this in your rules. [COMPLETED]


### Medication Details Card

==============
## Add Medication

- Wizard still doesnt have Next button instead of continue button at the bottom when filling in fields.  [COMPLETED]
- The above task is still not complete.  The continue button is supposed to be a next button to jump to the next field easily while the OSK is displaying. Must be for ALL wizards.  [COMPLETED]
- Above Task is still not complete. You changed the continue button to be Next. Great.But it still jumps to the next step. It needs to jump through the fields on the current step. Once at the last field, it then changes to continue. This is so users can fill all the fields on the screen without havign to minimize the OSK to click on the next field to fill out.  [COMPLETED]

### Choose Medicaiotn Type Screen

### Choose Injection Type Screen

### Add Medicaiton Tablet

### Add Medicaiton - Multi Dose Vial


==============
# Schedules List
- Large Cards:
	- Make Next background chip a slight biut taller. Less rounded borders. [COMPLETED]
	- Remove the duplicate days and dose times which are underneath the worded insruction. [COMPLETED]
	- Needs Schedule status or chip somewhere. Active, Paused, Disabled, Expired. 
- Compact Card:
	- Add on same row ass Dose Name. "Take "DOSE" of "MEdicineName" on "Schedule Type" at "Time of Day" [COMPLETED]
	- Place above text directly under the Dose Name and make the font smaller. 
	- Needs Schedule status or chip somewhere. Active, Paused, Disabled, Expired.
- List:
	- Needs Schedule status or chip somewhere. Active, Paused, Disabled, Expired.



==============
# Add Schedule
- When changing to strenght, can we not abruptly nudge the entire screen. Can there be an easier way to ease the new menu item in? [COMPLETED]
- Step 1:
	- Text "Set Per DOse amount. You can fine tune it later if needed." WHat is this text I never asked for this. There is no fine tuning later section. [COMPLETED]
	- Tablets:
		- The forumal summary field below only appears once entering data. Why? EveryDose type should have an init amount relative to the medicine. Make sure the forumal display field is there always. Popping things in and out is visually jarring. It also moves the screen around. [COMPLETED]
		- Shortuct buttons have the wrong border colour. Make it the same as everything else. [COMPLETED]
		- Incremental field Centre align it in the card. [COMPLETED]




- Step 2:
- Schedule Dates card and Patter card are touching. Also headings need to be primary colour. [COMPLETED]
	- Start:
	- End:
	- Schedule Pattern:
		- Days of the Week:
			- Day selection chips. Inactive Chips are too active looking. maybe reduce the border. [COMPLETED]
		- Days on / Days Off
		- Days of the Month
			- How can we handle something like, First monday of every month, or first 2 mondays of every month? How do other task apps approach this?
- Step 3:
	- These cards need to have the same heading styling as all other large cards.  [COMPLETED]
	- Summary:
		- Dose needs to show the following:
			- Go and find out the correct terminology for dosing medications. What I care about is framing the correct terms for Say, if a dose is 1 tablet, the tablet is called what?, then we have the strenght of medicaiont in the tabletm what is that called? Same with a capsule, this is like the medicaiont carrier or form. Then if its a single dose vial, we would have the Dose in Volume, the Dose in Strenght, and the DOse in the delivery or admiinstration mechanism, which would be a syringe for this one. These values need to be displayed evetrywhere on the app where these things appear. As this app is to communicate very specifically the details here. If I am using a pre filled syringe, I want the Med Strenght, the Med Volume and the Amount of the measurement in teh administation tool/ method. So go find the correct terminology for this so we can write it in as a rule for you to adhere to across this app. [COMPLETED]
	- Settings:

- You have stated all the below items are completed. None of them are. Are we dealing with a different add schedule screen? Are there multiple? Is there a different one that is not in the route?




==============
# Schedule Details Screen

## Schedule Details Card

	



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
- Too High. [COMPLETED]
- Has time and an action to take at time. Dont need both. 
- Needs a date icon, will display today
- Dose instructions:
	- Take X X at X. 
- The take button. I am conflicted here. I want the shortcut buttons of take, snooze, skip. But also want the dialog to pop where notes can be added and the status can be changed. 



==============
# Take/edit Dose Dialog Widget
##### Is Requiring a FULL OVVERHAUL to manage all the options and all the palces where it can be used.
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








