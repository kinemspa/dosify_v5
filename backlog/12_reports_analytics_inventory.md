# Reports (Analytics, Inventory, Export)

## Analytics

### Requests
- [x] This will have the same widgets as the medicaiont details screen but it will allow for viewing data from all meds and schedules. It will also allow for exporting of data.

## Inventory
- [x] Need a full inventory table. 

### Requests
- [x] A new screen that provides a high level of all stock.


## Recommendations
- [x] Start with read-only aggregated widgets reused from Medication Details, then add Export (CSV) as v1.
- [x] Inventory overview: show per-med stock gauges + “days remaining” summaries with consistent cards.

- [x] Extract CSV generation out of `AnalyticsPage` into a reusable export service and add unit tests for CSV escaping + stable ordering.
- [x] Add a shared “time range” selector that controls the analytics widgets and export output (and can be reused by report cards).
- [x] Decide and document export semantics: include both `scheduledTimeUtc` and `actionTimeUtc` consistently; define inclusive/exclusive range rules.
- [x] Make Inventory meds-first by default: hide the Supplies summary unless supplies exist (since supplies are not in use yet).
- [x] Avoid reading supplies Hive boxes in Inventory unless the Supplies section is enabled (prevents future crashes if supplies initialization changes).
