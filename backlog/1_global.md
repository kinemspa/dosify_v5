# Global

## Requests

- [x] Dose cards need more padding between border and inside objects
    - [x] A little more. Make them a little wider aswell. 
- [x] Next badge on Schedule cards is not ledgible. Make 1 pixel larger text or make font bold. Do not make this badge increase in size, the badge size is perfect, just the text is not readable. 



## Recommendations

- [ ] Add a short “Path Map” so backlog/docs refer to real feature folders (e.g., Analytics lives under `lib/src/features/analytics/`, and “Reports” widgets are in medications/widgets + shared widgets).
- [x] Remove `.bak` files from `lib/` (delete or move to docs) so they don’t ship and don’t confuse navigation.
- [ ] Enforce design-system compliance via an automated check for `Colors.*`, `EdgeInsets.*`, `BorderRadius.circular(...)` in `lib/src/features/**` (similar to the existing font-size checker).
- [ ] Introduce an injectable “clock/now” helper for time-sensitive logic (scheduling, reports ranges, expiry) to improve testability and reduce DST bugs.
- [ ] Standardize ID generation (single helper for logs/models) to avoid collisions and simplify dedupe.
- [ ] Reduce direct Hive access in UI: define a consistent repository/provider pattern and stop nesting multiple `ValueListenableBuilder`s.
- [ ] Remove Hive reads from `go_router` route builders (pass IDs/params; resolve data inside pages via repository/provider).

- [ ] Create a dedicated UI styling unification backlog item and track migration progress there (see `backlog/15_ui_styling_unification.md`).
- [ ] Add an automated “no literal styling” gate for `lib/src/features/**`: block `Colors.*`, `Color(0x...)`, `EdgeInsets.*`, `BorderRadius.circular(...)`, `TextStyle(...)` unless explicitly allowed.
- [ ] Standardize shared primitives (card surfaces, section headers, empty states, status chips/badges) in `lib/src/widgets/` so features don’t rebuild them.


