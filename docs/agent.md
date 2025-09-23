# Agent Reference — Text Style Names and Sourcing

Policy
- No explicit font sizes in widgets. All text styles must source from ThemeData and shared UI constants.
- If sizes need to change (e.g., 12sp body, 11sp helper), update ThemeData (textTheme, InputDecorationTheme) or shared constants in ui_consts.dart, not individual widgets.

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

Notes
- If a widget appears to override textStyle inline, refactor it to consume the theme or a shared constant.
- For exact pixel parity between pages, prefer shared helpers (Field36, _dec/_decDrop, _rowLabelField, _section) over per-page ad hoc styles.
