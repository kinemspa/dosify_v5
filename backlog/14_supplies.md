# Supplies

## Scope
- Supplies feature screens and inventory integration.

## Requests
- 

## Recommendations
- [ ] Migrate the Supplies screen to the centralized design system (remove `Colors.*`, raw padding/radii, and ad-hoc decorations).
- [ ] Replace Supplies page custom cards/containers with shared card primitives (standard + compact) from `lib/src/widgets/`.
- [ ] Replace Supplies “empty state” and list row styling with shared empty-state + row primitives to match the rest of the app.
- [ ] Decide whether Supplies is optional/feature-flagged; hide Supplies sections/CTAs unless the user has supplies (or explicitly enables it).
- [ ] Add unit tests for supply stock aggregation (movements ordering, negative deltas) and “low stock / expiring soon” thresholds.
