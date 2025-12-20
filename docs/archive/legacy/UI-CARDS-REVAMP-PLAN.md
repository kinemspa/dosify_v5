# UI Cards Revamp Plan & MDV Logic Fix

## 1. Executive Summary
This plan outlines the standardization of UI cards (Large, Compact, List) for Medications and Schedules, ensuring a consistent "Concept 9" (Glass Halo) aesthetic for compact views and maximizing utility for each view type. It also addresses the critical logic error in Multi-Dose Vial (MDV) tracking by prioritizing active vial volume.

## 2. Multi-Dose Vial (MDV) Logic Fix
**Problem:** Currently, `stockValue` for MDVs is ambiguous, often tracking sealed vials while the active vial volume is secondary or conflated.
**Solution:** Explicitly separate "Active Vial" (Open) and "Backup Stock" (Sealed).

### Data Model Updates (`Medication`)
- **New Field:** `activeVialVolume` (double?) - Tracks the remaining liquid in the currently open vial (mL).
- **Existing Field Usage:**
  - `stockValue`: Tracks the count of **sealed/backup vials**.
  - `containerVolumeMl`: The total capacity of one vial (constant).
  - `lowStockVialsThresholdCount`: Threshold for `stockValue`.
  - `activeVialLowStockMl`: Threshold for `activeVialVolume`.

### Consumption Logic
1. **Dose Taken:** Decrement `activeVialVolume`.
2. **Vial Depleted:** If `activeVialVolume` <= 0:
   - User prompted to open new vial.
   - Action: Decrement `stockValue` (Backup Count) by 1.
   - Action: Reset `activeVialVolume` to `containerVolumeMl`.

## 3. Card Strategy

### A. Medication Cards

| View Type | Purpose | Content | Visuals |
| :--- | :--- | :--- | :--- |
| **Large** | Full Detail & Management | Name, Manufacturer, Strength, Form, Storage, Expiry, **Dual Stock** (MDV) or Single Stock. | **DualStockDonutGauge** (MDV) or **StockDonutGauge**. Large typography. |
| **Compact** | Overview & Status | Name, Strength, Stock Summary. | **GlassCardSurface**. **MiniStockGauge** (Halo). |
| **List** | Search & Sort | Name, Strength, Simple Stock Text (e.g., "12/30"). | Minimal height. No graphs. |

**Compact Card Design (Concept 9):**
- **Background:** `GlassCardSurface` (Gradient + Halo Shadow).
- **Layout:** Row.
  - **Left:** Info (Name, Strength).
  - **Right:** **MiniStockGauge** (32x32 donut).
- **MDV Specifics:** Mini gauge shows *Active Vial* %. Text shows "X mL".

### B. Schedule Cards

| View Type | Purpose | Content | Visuals |
| :--- | :--- | :--- | :--- |
| **Large** | Full Detail & Action | Time, Frequency, Med Name, Dose, Next/Last Dose. | "Take" Button. Progress/Status indicators. |
| **Compact** | Daily Overview | Time, Med Name, Dose. | **GlassCardSurface**. Status Icon/Color (Pending/Taken). |
| **List** | Quick Scan | Time, Med Name. | Minimal. |

**Compact Card Design (Concept 9):**
- **Background:** `GlassCardSurface`.
- **Layout:** Row.
  - **Left:** Time (Big), Frequency (Small).
  - **Middle:** Med Name, Dose.
  - **Right:** Status Icon (or "Take" button if space permits).

## 4. Implementation Steps
1. **Model Update:** Add `activeVialVolume` to `Medication` and regenerate Hive adapters.
2. **Logic Update:** Refactor `_applyStockDecrement` to handle the new MDV flow.
3. **Widget Creation:** Create `MiniStockGauge` (scaled-down donut).
4. **UI Refactor:**
   - Update `MedicationListPage` to use new Compact Card with Mini Gauge.
   - Update `SchedulesPage` to use new Compact Card layout.
   - Ensure `LargeCard` correctly uses `DualStockDonutGauge` for MDV.

## 5. Styling Rules
- **Strict Adherence:** All spacing, colors, and typography must come from `design_system.dart`.
- **No Inline Styles:** Use `GlassCardSurface` for the container.
