# Global

## Requests


## Recommendations

- [ ] Introduce an injectable “clock/now” helper for time-sensitive logic (scheduling, reports ranges, expiry) to improve testability and reduce DST bugs.
- [x] Introduce an injectable “clock/now” helper for time-sensitive logic (scheduling, reports ranges, expiry) to improve testability and reduce DST bugs.
- [ ] Standardize ID generation (single helper for logs/models) to avoid collisions and simplify dedupe.
- [ ] Reduce direct Hive access in UI: define a consistent repository/provider pattern and stop nesting multiple `ValueListenableBuilder`s.
- [ ] Remove Hive reads from `go_router` route builders (pass IDs/params; resolve data inside pages via repository/provider).



