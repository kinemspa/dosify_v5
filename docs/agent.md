# Agent Reference — Text Style Names and Sourcing

Policy
- No explicit font sizes in widgets. All text styles must source from ThemeData and shared UI constants.
- If sizes need to change (e.g., 12sp body, 11sp helper), update ThemeData (textTheme, InputDecorationTheme) or shared constants in ui_consts.dart, not individual widgets.
- Default to recommended actions without asking for confirmation. Implement the best-practice choice immediately; if the user dislikes it, they will request a change.

Canonical names to use when referring to text on the medication editors
- section.title
  - Source: Theme.of(context).textTheme.titleSmall (color/weight may be adjusted by theme)
- section.summary
  - Source: Theme.of(context).textTheme.bodySmall/bodyMedium via DefaultTextStyle (theme-driven)
- label.left
  - The left-column row label (e.g., "Name *", "Manufacturer")
  - Source: Theme.of(context).textTheme.bodyMedium
- input.text
  - Text entered into TextFormField controls
  - Source: Theme.of(context).textTheme.bodyMedium
- dropdown.text
  - Selected item and menu item text in DropdownButtonFormField
  - Source: Theme.of(context).textTheme.bodyMedium (selectedItemBuilder/menu items use the same style)
- hint.text
  - Placeholder/"eg." text shown inside inputs
  - Source: Theme.of(context).inputDecorationTheme.hintStyle (or theme.textTheme.bodySmall if not overridden)
- helper.text
  - Helper/instruction text rendered on its own row below fields
  - Source: Theme.of(context).textTheme.bodySmall and theme.colorScheme.onSurfaceVariant (muted)
- checkbox.label.muted
  - Right-hand labels in storage and low-stock rows (e.g., "Refrigerate", "Freeze", "Dark storage", "Enable alert when stock is low")
  - Source: kMutedLabelStyle(context) which derives from ThemeData (colorScheme.onSurfaceVariant)
- button.label.primary
  - The text inside primary FilledButton (Save/Update) and dialog buttons
  - Source: Theme.of(context).textTheme.labelLarge (Material defaults unless customized in theme)
- stepper.symbol
  - The text inside +/- stepper buttons
  - Source: Inherits from button defaults (Theme.of(context).textTheme.labelLarge) unless themed explicitly

Where these are set up in code
- Shared constants and helpers: lib/src/features/medications/presentation/ui_consts.dart
  - kFieldHeight, kBtnSize, kMutedLabelStyle(context)
- Input decorations: _dec/_decDrop helpers in each page, using ThemeData and InputDecorationTheme
- Field wrapper: lib/src/widgets/field36.dart ensures 36px control height uniformly

How to request changes
- "Make input text 12sp across editors" → Update ThemeData.textTheme.bodyMedium.fontSize.
- "Make hint text 12sp and helper 11sp" → Update ThemeData.inputDecorationTheme.hintStyle/helperStyle (and/or the shared _dec helpers) — avoid inline copyWith.
- "Mute the checkbox labels further" → Adjust kMutedLabelStyle(context) in ui_consts.dart to use a different onSurfaceVariant opacity.
- "Change section title weight/size" → Update ThemeData.textTheme.titleSmall.

Never do bottom pop-ups
- Do not use bottom sheets, bottom-page pop-ups, or similar modal surfaces that slide up from the bottom.
- If a summary or additional content is needed, prefer inline summaries within cards or dedicated pages.

Notes
- If a widget appears to override textStyle inline, refactor it to consume the theme or a shared constant.
- For exact pixel parity between pages, prefer shared helpers (Field36, _dec/_decDrop, _rowLabelField, _section) over per-page ad hoc styles.

Schedule editor policy (simplified)
- No scheduling modes or day-of-week chips. Scheduling is simplified to everyday with one or more times per day.
- Start and End dates are provided (End date supports "No end").
- Time and date buttons are primary FilledButtons (consistent width = kFieldHeight and 120px where applicable).
- Instructions are shown inline in the card (under General), mirroring Add Med style and using theme text styles.
- Validation and left-label Field36 rows match Add Med UX (red outline + under-label errors; gated when appropriate).

Medications list (Large view)
- No Refill button on cards.
- Large view uses a natural-height single-column list for readability and to avoid overflow/unused space on small screens.
