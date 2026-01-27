
# Settings

## Scope
- Settings screen and sub-pages.

## Requests
- [x] Add a Notifications section for grace period and overdue reminders.
- [x] Add an “Experimental” group for UI toggles before they’re finalized.
- [ ] Ability to backup data to google drive or someother method
- [ ] Ability to import a backup
- [ ] Ability to set Time and Date formats which override OS
- [x] Ability to setup notificaiton Snooze settings, a percentage of time before the next scheduled dose. Percentage slider, defaults at 65%. Shouldnt be able to snbooze into the next schduled dose. 
- [ ] Ability to set amount of time before expiry date notification
- [ ] Ability to set up folluw up reminders. Off, once, twice....

## Notes
- 


## Recommendations

- [ ] Define a backup/export format (which Hive boxes, schema/version marker, validation rules) before implementing Google Drive.
- [ ] Define import behavior for partial/invalid backups (fail-fast vs best-effort) and how to handle schema migrations.
- [ ] Add tests for time/date formatting overrides so UI remains consistent across locales and DST.

- [ ] Keep Settings + sub-pages as “reference implementations” for design-system usage: remove any literal styling and rely on shared widgets/tokens.
- [ ] Ensure any sample/demo pages (e.g., wide card samples) only demonstrate centralized tokens/widgets and never introduce new ad-hoc decoration.


