# Things To Fix

## Global
- Dark Theme 
	- The reconstitution calculator 
		- Can we change the background blue colour to something not blue?
	


	




## Home Screen


==============

## Medication Screen

### Large Cards
- The Storage row and remaining row need to be the same row. Storage on the left side is 1 row below. Move it up. [COMPLETED] They are still not on the same rows. FIX IT.
	- Remove the text under the Donut Graph percentage. [COMPLETED]


### Compact Cards

### List

==============

# Medication Details Screen
- Can we have some help text somewhere to state minimize all the cards to arrange them? Maybe put the drag icon on minimized cards to inform user they are rearrangeable. 
- Re Arrange state is not saving on return to the screen. 
- For MDV - The Dialog for refill and havign a seperate restock button for a the restock is very clunky. Can we have 2 selections within this dialog to change it? Maybe a page?  [COMPLETED]
	- You missed the point here. Its either Refill Active Vial Which means to add ot replace current active vial with aa new reconstituted vial. This can be pulled from the sealed vial stock or not. The you have a totall seperate action, for refilling the sealed vials stock. These most likely need to be seperate buttons or pages within the refill dialog. 
	- When reconsituting the active vial, we need to be able to also pull from the reconsitution calculator, use the same reconsitutiont as done previously, calculate a new reconstitution, retrieve a saved reconsitution, or reconsitution voluem is known and just enter the reconstitution. 
- Minimized Cards, make them all the same size as the Reconsitution card in height. 
- Reconstitution Card:
	- Remove the dit button.
	- Card within a card is not a good design concept. Make it one card. 

### App Header
- Can we make the Storage details and expiry info the same as how we did it on the large cards? Place Active Vial Location, Storage Conditoins and Expiry in same row on left, and the remaining in the same row on the right. We did this on the Large Medicaiont Cards on Med list screen. Do the same with the Sealed Vials row too. Mirror the Large Med Cards on the Med List screen. [COMPLETED] No this is not done. The Sotrage Locaiton Text is above the value, the remaining text is on 2 lines. What do you not understand about make it the same as the Large Med Card?

### Reports Card
- History: 
	- Date Icon - make smaller. [COMPLETED]
	- AdHoc Doses should be editable. [COMPLETED]
		- Editing an ad hoc dose, needs to include the ability to select the dose unit type. Same as a dose. 
	- Indicate entries that are editable. [COMPLETED]
	- Edit icon should always be to the left of all icons. This is not the case. 
	- Adhoc doses are showing up as 2 entries. 
	- Add if Recositution of a vial. 
		- If a sealed vial was used or deducted
		- If a new calculation was made, existing, saved, or direct mL entry. 
	



### Schedule
- Can we include som sort of animation when the Schedule card has to expand to fit multiple doses for the day. its jarring how it just snaps. 
- Pausing the Schedule, removes the schedule from showing on the medicaiont screen. Need to still display disabled schedules. I paused the schedule now the schedule shows No shcedules. 
- Top Area of Schedule should expand or collapse schedule. Currenly it is editing scehdule. the only area to expand and collapse seems to be the little arrow. Make the enitre top orw where the arrow sits the expand and collaps.
- Set Paused button is not the right terminology.
- Take Dose Card:
	- Dose Name is correct.
	- Underneath you have Dose amount and then the med type. No. Should have Med Name, Med strenght and Dose in all possibly metrics. Status, Date Icon, Time, And a big action button. Take, or edit depending on the action.
- Make sure this entire card is a widget. As it will be expanded for the schedules, calendar and home screen. 


### Medication Details Card
- Sealed VIals heading should still be in primary colour. 
- Some text is out of horizontal alignment. For example Active VIal Location heading is higher up than the Value. 

==============
## Add Medication

- Wizard still doesnt have Next button instead of continue button at the bottom when filling in fields. 

### Choose Medicaiotn Type Screen

### Choose Injection Type Screen

### Add Medicaiton Tablet
- Is Ibuprofen allowed to be used as an example? Is there a legal issues here.  [COMPLETED]
- Go through the entire app and find any exmaple text or helper text that contyains any actual real life medicaiotn names or company names. These are legal issues.

### Add Medicaiton - Multi Dose Vial


==============
# Schedules List
- Large Cards:
	- Make Next icon and text smaller. [COMPLETED]
	- Make the Dose name in a bolder font [COMPLETED]
	- Add a started date
	- Add an End date or doesnt end.
	- Seperate Schedule Type and time of day. If multiple times of day they need to show. Reduce text size. 
	- If today, change date icon to today
- Compact Card:
	- Next Dose date Icon to inculde the Next icon. Smaller. 
	- If today, change date icon to today



==============
# Add Schedule
- Adding a schedule is still entriing historical entries that become skipped. Fix this.  [COMPLETED]
- Still Black text on a forumal box that appeare below the inputs on step 1.  [COMPLETED]
- Helper Text., We need hel text above the type input selection.  [COMPLETED]
	- Select a Dose input type or mode, Strenght, Volume or Units. Give a light summary.  [COMPLETED]
	- Strength needs to be able to select the STrenght Unit. mcg, mg, g.  [COMPLETED]
- The incremental field and buttons are wrong. Use the same styling as the add med screen.  [COMPLETED]
- Step 1:

- Step 2:
	- Schedule Dates Styling of fields is incorrect. not use system design. 
	- Start:
		- Change to Start Date
		- CHange Now to Today
		- Selected date calnedar button is causing an overflow. 
		- Once changed to selected ate, the drop down is becominga calendar button. Calendar button needs to appear below the dropdown, alos make it the same sizing as the system design, same size as the date button on the add med screens. 
	- End:
		- Same as above. 
	- Schedule Pattern:
		- Drop Down Menu has sharp corners. 
		- Days of the Week:
			- Day selection chips. Reduce the size of them. Center align them. Reduce padding make more compact. 
			- Dont use Grey backgrounds. Ever. Put this in your rules.
			- Dont use black font. Rules. 
		- Days on / Days Off
			- Days on and Days off fields are on the same horizaontal row, causing a major overflow. Shoult be vertically stacked. 
		- Days of the Month
			- Make the grid more compact like the days of the week.
			- Centre Align
			- No Grey backgorund
			- No black font.
			- If day doesnt exist option should only appear when selecting 28-31.  
			- If day doesnt exist field styling is not system centralised. Font too large, too black. 
- Step 3:
	- These cards need to have the same heading styling as all other large cards. 
	- Summary:
		- Dose needs to show the following:
			- Go and find out the correct terminology for dosing medications. What I care about is framing the correct terms for Say, if a dose is 1 tablet, the tablet is called what?, then we have the strenght of medicaiont in the tabletm what is that called? Same with a capsule, this is like the medicaiont carrier or form. Then if its a single dose vial, we would have the Dose in Volume, the Dose in Strenght, and the DOse in the delivery or admiinstration mechanism, which would be a syringe for this one. These values need to be displayed evetrywhere on the app where these things appear. As this app is to communicate very specifically the details here. If I am using a pre filled syringe, I want the Med Strenght, the Med Volume and the Amount of the measurement in teh administation tool/ method. So go find the correct terminology for this so we can write it in as a rule for you to adhere to across this app.
	- Settings:
		- The Active button switch, we dont use this switch type anywhere in teh app, why are you using it now?

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
# Take Dose Screen
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

==============
# Analytics
- This will have the same widgets as the medicaiont details screen but it will allow for viewing data from all meds and schedules. It will also allow for exporting of data. 


==============
# Inventory
- A new screen that provides a high level of all stock. 





================================
# Notifications
- Seems to be a lot of notifications loading on startup. Is this goign to be a performance hit or an issue? [COMPLETED]








