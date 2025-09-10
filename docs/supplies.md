# Supplies Module

This document describes the Supplies feature in Dosifi v5 (initial implementation).

Overview
- Track consumables and fluids used in medication routines.
- Maintain stock via additive movements (purchases/additions) and subtractive movements (used).
- Provide low-stock indicators and quick adjustments.

Storage (Hive)
- Box: `supplies` (Supply)
- Box: `stock_movements` (StockMovement)
- Types and adapters
  - Supply (typeId 50)
  - StockMovement (typeId 51)
  - SupplyType (typeId 52) — item | fluid
  - SupplyUnit (typeId 53) — pcs | mL | L
  - MovementReason (typeId 54) — purchase | used | correction | other

Data model
- Supply
  - id: String (uuid)
  - name: String
  - type: SupplyType
  - category: String? (e.g., needles, swabs)
  - unit: SupplyUnit (pcs/mL/L)
  - reorderThreshold: double? (same unit as unit)
  - expiry: DateTime?
  - storageLocation: String?
  - notes: String?
  - createdAt, updatedAt
- StockMovement
  - id: String (uuid)
  - supplyId: String
  - delta: double (positive for purchase/add; negative for usage)
  - reason: MovementReason
  - note: String?
  - at: DateTime

Computed stock
- currentStock(supplyId) = sum(delta) for movements with matching supplyId.
- Low stock if currentStock ≤ reorderThreshold (when configured).

UI
- Route: `/supplies` — list of supplies with stock, threshold info, and low-stock badge.
- Route: `/supplies/add` — add supply (option to set initial quantity → creates a purchase movement).
- Route: `/supplies/edit/:id` — edit supply.
- StockAdjustSheet — quick +/− adjustment with reason and note.

Navigation
- Bottom navigation adds a “Supplies” tab.

Next steps
- Categories: filter/group by category; badges.
- Link to medications and reconstitution flows (select/add supplies from calculator dialog).
- Forecast depletion dates (requires DoseLog or consumption model integration).
- Export/Import supplies and movements with app data.
- Unit conversion helpers (e.g., L ↔ mL) — current UI assumes consistent unit entry.

References
- Product design: docs/product-design.md (Supplies section and calculator integration)
- Backlog: docs/backlog.md

