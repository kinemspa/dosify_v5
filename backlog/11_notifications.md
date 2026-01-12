# Notifications

## Requests
- [x] Can we put in some test notificaiont in the settings screen that I can pop to see the different type of notifcations and how they look?
- [x] There are cumulating notifications. So the Notificaiton from the previous days dose is appearing on the next days along with the next days. 
- [ ] We should put in a grace period for when a dose is marked missed. Maybe its a percentage towards the next dose. (Should be added to the settings as an option to tweak.)
- [ ] Need to make the notifications more like the dose cards
- [ ] How can we manage the Take, SNooze, Skip sections. Can we open up an advanced layout? 
- [ ] Take Dose needs more details. 
- [ ] Can the Notification show the syringe image?

### Take Dose Reminder

- [x] Take DOse Reminder should be similar to the take dose card. 
- [x] Need to cater for multiple doses at once. Can we collectively group them?
- [x] Give me an explanation on how the notifcaiotn can work. I would like it to pop and then be expandable into the takedose widget. Is this possible without opening the app?
- [ ] Need to provide an overdue reminder a percentage of the time before it is marked as missed. 

### Expiry Reminder

- 

### Low Stock Reminder

- [x] Provide the Refill or Restock buttons. 

### Notification Management

- [x] Seems to be a lot of notifications loading on startup. Is this goign to be a performance hit or an issue?

## Notes
- A notification can’t expand into a full Flutter widget UI without launching the app. We can show actions (e.g., Take/Snooze/Skip) and deep-link into the Take Dose dialog inside the app.
    - [x] Ok lets implement that. 
