# UI Cards: Large Height and Inventory Fraction

Status: Active

- Large cards for Medications and Schedules now use a fixed height for consistent visual rhythm across the list. Current standard height: 140 px.
- Medication inventory fraction now shows Remaining / Originally Entered (e.g., 18/30 tablets), instead of Remaining / Low Stock Threshold.
- The original amount is stored as initialStockValue on Medication and is initialized to the first observed stock value (and updated when stock increases, treated as a restock).

Implementation Notes
- Medications: List large view wraps each card in a SizedBox(height: 140).
- Schedules: List large view wraps each card in a SizedBox(height: 140).
- Supplies: Large view remains a responsive grid; cells already have consistent heights via aspect ratio.
- initialStockValue is optional for backward compatibility; it is set lazily the first time we render the list (or when stock increases beyond the stored initial).

QA Checklist
- Large cards are equal height within Medications and Schedules lists.
- Medication stock line displays X/Y with Y = original amount (or falls back to X if unknown).
- No overflow or clipped content within the fixed card height on common devices.

Change History
- 2025-09-26: Standardized Large card heights; corrected inventory fraction semantics; added docs.
