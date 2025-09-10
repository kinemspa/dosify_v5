# Calendar Module

This implements the Calendar screen per design with Month, Week, and Day views.

Month
- Month calendar grid with 7 columns (weekday letters displayed)
- Square blocks for each day
- Scheduled doses appear as dots within the day cell
- Selecting a day expands an accordion at the bottom with the day’s dose cards (tap again to collapse)
- View density uses simple dots in the grid and full cards in the accordion

Week
- Columns are days of the week (Mon–Sun)
- Rows represent a vertical list per day (simplified rendering of times). A full hour grid can be added later.
- Scheduled doses appear as compact cards in their day column, ordered by time

Day
- List of all doses for the selected day as cards

Event generation (UTC aware)
- Uses schedules’ UTC fields when available (minutesOfDayUtc, daysOfWeekUtc)
- For each date in the visible range, we compare the date’s UTC weekday to the schedule’s UTC weekday set; when matched we create a DateTime.utc(y,m,d,hUtc,mUtc) and convert to local for display
- If legacy local fields are present, we map them to UTC on the fly for correctness

Navigation
- New route: `/calendar`
- Bottom nav shows “Calendar” (Schedules remains available at `/schedules` and via the top-right action on Calendar)

Next steps
- Density modes (Large/Compact/List) in Month accordion and Week columns
- Visual color coding per medication and status (taken/missed/canceled)
- DoseLog integration to mark taken/skipped and overlay states on the calendar
- Drag/scroll enhancements and hour grid positioning for the Week view

References
- Product design: docs/product-design.md (Calendar section)
- Backlog: docs/backlog.md

