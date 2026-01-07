# Take Dose
- [ ] This will be a working document for the Take Dose dialog widget.

## Status (Implemented)
- [x] Heading + helper text
- [x] Dose section shows a DoseCard when details available (fallback summary otherwise)
- [x] Status selection chips + Save & Close flow
- [x] Notes field
- [x] Date & Time editing (for historical doses / existing logs)
- [x] Ad-hoc amount editing (stepper)

## Status (Pending)
- [x] Remove divider under helper text
- [ ] MDV/syringe visual graphic + multi-value dose presentation rules
- [ ] Snooze-until picker + prevent snoozing past next dose
- [ ] Center status chips + finalize per-status color behavior (taken/snoozed/skipped)

- [ ] We need to come up with a naming concept for this dialog. Will it be the DOse Status Editor Dialog widget? Dose Taker? Dose Instructions WIdget?

- [ ] Begin with same style as the Medication Details Screen - Edit Strenght DIalog. This Background colour, Font styling and everything is to be the system design for ALL DIALOGS. 

- [ ] The Features required for this Dialog are:
    - [ ] Even though we are trakcing doses, we are not forcing the user into any specific dose regimen. Even though we state here is the dose, time and date, the user can edit it all at the time of taking the dose if they like. the main purposes is to track the dose accurately. SO if they want to increase the dose and set it back 4 hours they can. 
    - [ ] Heading with helper text
    - [ ] Dose Instructions
        - [ ] The Medicine Name
        - [ ] The Dose
            - [ ] In all available values formulated.
                - [ ] Tablet - Strenght in mcg, mg, or g, Tablets
                - [ ] Capsule - Strenght mcg, mg, or g, Capsules
                - [ ] Pre-Filled-Syringe - Strenght in mcg, mg, or g, Volume in mL, IU medicine Internaitonal Units, and Syringe volume in Units
                - [ ] Single Use Vials - Strenght in mcg, mg, or g, Volume in mL, IU medicine Internaitonal Units, and Syringe volume in Units
                - [ ] Multi Dose Vials - Strenght in mcg, mg, or g, Volume in mL, IU medicine Internaitonal Units, and Syringe volume in Units
            - [ ] MDV:
                - [ ] The syringe graphic to inform the user how much visually 
    - [ ] The Schedule name
    - [ ] The Schduled Date and Time
    - [ ] The Dose Status
    - [ ] Dose status buttons
    - [ ] Date Change
    - [ ] Time Change
    - [ ] Notes
    - [ ] Dose change

 - [ ] Status Changes
    - [ ] Take
        - [ ] Take Dose button Marks Dose as taken. 
        - [ ] Take Dose button Becomes Green. 
        - [ ] Status Icon is Taken. 
        - [ ] Date Icon turns green colour. 
        - [ ] Deducts Dose from active medication stock
    - [ ] Snooze
        - [ ] Snooze Button changes colour to an Orange. 
        - [ ] Marks Dose as Snoozed. 
        - [ ] Status Icon is Snoozed. 
        - [ ] Date Icon changes to Orange
        - [ ] Snooze Time Picker appears for time until. 
        - [ ] Cannot Snooze past the next scheduled dose, will throw an alert. 
    - [ ] Skip
        - [ ] Skip button becomes Red
        - [ ] Marks Dose as Skipped. 
        - [ ] Status Icon is Skipped. 
        - [ ] Date Icon changes to Red
    

     - [ ] Missed and disabled are not statuses to set from teh take Dose Widget. But, if a historical Dose is marked Untaken, it will be marked as Missed.    
        - [ ] Missed
            - [ ] Marks Dose as Missed. 
            - [ ] Status Icon is Missed. 
            - [ ] Date Icon changes to Dark Red
        - [ ] Disabled
            - [ ] Marks Dose as Disabled
            - [ ] Status Icon is Disabled
            - [ ] Date Icon changes to grey. 

