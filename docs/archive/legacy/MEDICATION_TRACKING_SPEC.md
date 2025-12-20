# Medication Tracking Architecture & Data Specification

## 1. Core Concept
To ensure accurate inventory management, we distinguish between **Count-Based** medications (pills, patches) and **Volume-Based** medications (liquids, vials), with specific handling for **Multi-Dose Vials (MDV)** which have a two-stage lifecycle (Sealed -> Open).

## 2. Data Fields Reference (`Medication` Class)

| Field | Type | Description | Usage by Form |
| :--- | :--- | :--- | :--- |
| `stockValue` | `double` | The primary inventory quantity. | **Tablets/Capsules:** Total pill count.<br>**Syringes:** Total syringe count.<br>**MDV:** Count of **SEALED** vials (Backup). |
| `activeVialVolume` | `double?` | The remaining liquid in the **OPEN** vial. | **MDV Only:** Tracks mL remaining in the current vial. |
| `containerVolumeMl` | `double?` | The capacity of a single vial. | **MDV Only:** Used to reset `activeVialVolume` when a new vial is opened. |
| `strengthValue` | `double` | Amount of active ingredient. | Used for dose calculations (e.g., 10 mg). |
| `strengthUnit` | `Unit` | Unit of active ingredient. | e.g., `mg`, `mcg`, `mg/mL`. |

---

## 3. Tracking Logic by Form

### A. Tablets, Capsules, Patches (Simple Count)
*   **Tracked Item:** Individual Units.
*   **Data Mapping:**
    *   `stockValue`: Total units available.
    *   `activeVialVolume`: *Ignored*.
*   **Deduction Logic:**
    *   `stockValue = stockValue - doseAmount`

### B. Pre-Filled Syringes, Single-Dose Vials (Simple Count)
*   **Tracked Item:** Whole Units.
*   **Data Mapping:**
    *   `stockValue`: Total units available.
    *   `activeVialVolume`: *Ignored*.
*   **Deduction Logic:**
    *   `stockValue = stockValue - doseCount`

### C. Multi-Dose Vials (MDV) (Complex)
*   **Tracked Items:**
    1.  **Active Vial:** The open vial currently being drawn from.
    2.  **Reserve Stock:** Sealed vials on the shelf.
*   **Data Mapping:**
    *   `activeVialVolume`: **Primary Tracking Target**. mL remaining in open vial.
    *   `stockValue`: **Secondary Tracking Target**. Count of full, sealed vials.
    *   `containerVolumeMl`: Constant size of one vial.
*   **Legacy Data Handling (Migration):**
    *   *Issue:* Older app versions stored the active mL in `stockValue` and had no `activeVialVolume`.
    *   *Resolution:* If `form == MDV` AND `activeVialVolume == null`:
        *   Treat `stockValue` as the **Active Vial Volume**.
        *   Treat **Reserve Stock** as 0.
*   **Deduction Logic:**
    1.  Calculate `doseMl`.
    2.  `activeVialVolume = activeVialVolume - doseMl`.
    3.  **Auto-Switch:** If `activeVialVolume <= 0`:
        *   `stockValue = stockValue - 1` (Remove 1 sealed vial).
        *   `activeVialVolume = activeVialVolume + containerVolumeMl` (Add full volume of new vial).
        *   *Alert:* Notify user "New vial opened".

---

## 4. Display Logic (Cards)

### Compact Card
*   **MDV:** Show `activeVialVolume` / `containerVolumeMl` (The immediate status).
*   **Others:** Show `stockValue` / `initialStockValue`.

### Large Card
*   **MDV:**
    *   **Outer Ring:** `activeVialVolume` % (Current Vial).
    *   **Inner Ring:** `stockValue` % (Reserve Stock).
*   **Others:**
    *   **Single Ring:** `stockValue` %.

---

## 5. Critical Rules for Developers
1.  **NEVER** decrement `stockValue` for MDVs directly unless opening a new vial.
2.  **ALWAYS** check `activeVialVolume` first for MDVs.
3.  **ALWAYS** handle the `null` case for `activeVialVolume` by falling back to `stockValue` (Legacy Mode) to prevent "0 mL" errors.
