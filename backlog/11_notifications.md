# Notifications

## Requests
- [x] Can we put in some test notificaiont in the settings screen that I can pop to see the different type of notifcations and how they look?

### Take Dose Reminder

- [x] Take DOse Reminder should be similar to the take dose card. 
- [x] Need to cater for multiple doses at once. Can we collectively group them?
- [x] Give me an explanation on how the notifcaiotn can work. I would like it to pop and then be expandable into the takedose widget. Is this possible without opening the app?


### Expiry Reminder

- 

### Low Stock Reminder

- [x] Provide the Refill or Restock buttons. 

### Notification Management

- [x] Seems to be a lot of notifications loading on startup. Is this goign to be a performance hit or an issue?

## Notes
- A notification can’t expand into a full Flutter widget UI without launching the app. We can show actions (e.g., Take/Snooze/Skip) and deep-link into the Take Dose dialog inside the app.
    - [x] Ok lets implement that. 
