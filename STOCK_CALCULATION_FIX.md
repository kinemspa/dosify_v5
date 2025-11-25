# Stock Calculation Fix - MDV Critical Bug

## Issue Identified

The stock deduction calculation for Multi-Dose Vials (MDV) had a **critical bug** that incorrectly calculated stock depletion.

### Bug Details

**INCORRECT CODE** (Before Fix):
```dart
case StockUnit.multiDoseVials:
  final containerMl = med.containerVolumeMl ?? 0;
  var usedMl = 0.0;
  // ... calculate usedMl from dose ...
  if (containerMl > 0 && usedMl > 0) {
    delta = usedMl / containerMl;  // ❌ WRONG! Calculates vial fraction
  }
```

**Example of the Bug:**
- Vial has 10mL total volume (`containerVolumeMl = 10`)
- Dose uses 0.25mL (`usedMl = 0.25`)
- **Bug calculation**: `delta = 0.25 / 10 = 0.025`
- **Result**: Stock goes from `10.0` → `9.975` mL (only deducted 0.025 mL!)
- **Expected**: Stock should go from `10.0` → `9.75` mL (deduct full 0.25 mL)

### Root Cause

The code incorrectly treated MDV stock as "vial count" instead of "active vial mL remaining". It calculated a fractional vial deduction rather than directly deducting the mL volume used.

## Correct Stock Management Logic

### Stock Unit Definitions

| Medication Type | Stock Unit | Stock Value Represents | Deduction Logic |
|----------------|-----------|----------------------|-----------------|
| **Tablets** | `tablets` | Count of tablets | `doseTabletQuarters / 4.0` (quarters → tablets) |
| **Capsules** | `capsules` | Count of capsules | `doseCapsules` (whole numbers) |
| **Pre-Filled Syringes** | `preFilledSyringes` | Count of syringes | `doseSyringes` (whole numbers) |
| **Single Dose Vials** | `singleDoseVials` | Count of vials | `doseVials` (whole numbers) |
| **Multi-Dose Vials** | `multiDoseVials` | **Active vial mL remaining** | `usedMl` (raw mL volume) |
| **Mass Units** | `mcg`, `mg`, `g` | Total mass | `doseMassMcg` converted to unit |

### MDV Stock Architecture

Multi-Dose Vials have **TWO separate stock tracking systems**:

1. **Active Vial** (`Medication.stockValue` with `stockUnit = multiDoseVials`):
   - Represents **mL remaining** in the currently reconstituted/opened vial
   - Decremented in **mL** each time a dose is taken
   - Tracked separately with `activeVialLowStockMl` threshold

2. **Backup Vials** (separate fields):
   - `Medication.backupVialsStock`: Count of unopened/unsealed vials
   - Decremented by **1 whole vial** when reconstituting a new vial
   - Tracked with `backupVialsLowStockThreshold`

## Fix Implementation

### CORRECT CODE (After Fix):

```dart
case StockUnit.multiDoseVials:
  // For MDV: stockValue = active vial mL remaining
  // Deduct the raw mL volume used, NOT a vial fraction
  var usedMl = 0.0;
  if (schedule.doseVolumeMicroliter != null) {
    usedMl = schedule.doseVolumeMicroliter! / 1000.0;
  } else if (schedule.doseMassMcg != null) {
    // Calculate volume from mass using concentration (mg/mL or mcg/mL)
    double? mgPerMl;
    switch (med.strengthUnit) {
      case Unit.mgPerMl:
        mgPerMl = med.perMlValue ?? med.strengthValue;
      case Unit.mcgPerMl:
        mgPerMl = (med.perMlValue ?? med.strengthValue) / 1000.0;
      case Unit.gPerMl:
        mgPerMl = (med.perMlValue ?? med.strengthValue) * 1000.0;
      default:
        mgPerMl = null;
    }
    if (mgPerMl != null)
      usedMl = (schedule.doseMassMcg! / 1000.0) / mgPerMl;
  } else if (schedule.doseIU != null) {
    // Calculate volume from units using concentration (units/mL)
    double? iuPerMl;
    if (med.strengthUnit == Unit.unitsPerMl) {
      iuPerMl = med.perMlValue ?? med.strengthValue;
    }
    if (iuPerMl != null) usedMl = schedule.doseIU! / iuPerMl;
  }
  // ✅ CORRECT: Deduct mL directly from active vial stock
  if (usedMl > 0) {
    delta = usedMl;
  }
```

### Example (Corrected):
- Vial has 10mL active volume (`stockValue = 10.0`)
- Dose uses 0.25mL
- **Correct calculation**: `delta = 0.25`
- **Result**: Stock goes from `10.0` → `9.75` mL ✅

## Dose Action Stock Rules

| Action | Stock Deduction | Notification Canceled |
|--------|----------------|---------------------|
| **Take Dose** | ✅ YES - Deducts stock | ✅ YES |
| **Skip Dose** | ❌ NO - No stock change | ✅ YES |
| **Snooze Dose** | ❌ NO - No stock change | ❌ NO (rescheduled) |
| **Missed Dose** | ❌ NO - No stock change | N/A (already past) |
| **Cancel/Delete Taken Dose** | ✅ YES - **Restores** stock | ✅ YES |

### Stock Restoration Logic

When a user cancels a dose that was previously marked as "taken":

```dart
Future<void> _deleteDoseLog(CalculatedDose dose) async {
  if (dose.existingLog == null) return;

  try {
    final repo = DoseLogRepository(Hive.box<DoseLog>('dose_logs'));
    await repo.delete(dose.existingLog!.id);

    // ✅ Restore stock ONLY if the dose was previously taken
    if (dose.existingLog!.action == DoseAction.taken) {
      await _restoreStock(dose);
    }

    await _cancelNotificationForDose(dose);
    await _loadDoses();
    // ...
  }
}
```

## Files Fixed

### 1. Calendar Widget
**File**: `lib/src/widgets/calendar/dose_calendar_widget.dart`
**Method**: `_calculateStockDelta()` (line ~520)
**Change**: MDV case changed from `delta = usedMl / containerMl` → `delta = usedMl`

### 2. Schedules Page
**File**: `lib/src/features/schedules/presentation/schedules_page.dart`
**Method**: `_applyStockDecrement()` (line ~862)
**Change**: Same MDV fix applied to maintain consistency

## Tablet Stock Calculation (Verified Correct)

The tablet calculation was **already correct**:

```dart
case StockUnit.tablets:
  if (schedule.doseTabletQuarters != null) {
    delta = schedule.doseTabletQuarters! / 4.0;  // ✅ CORRECT
  }
```

**Why this is correct:**
- `doseTabletQuarters` stores dose in quarters (1 tablet = 4 quarters)
- Example: 2 tablets = 8 quarters
- Calculation: `8 / 4.0 = 2.0` tablets deducted ✅
- Example: 1/2 tablet = 2 quarters
- Calculation: `2 / 4.0 = 0.5` tablets deducted ✅
- Example: 1/4 tablet = 1 quarter
- Calculation: `1 / 4.0 = 0.25` tablets deducted ✅

## Testing Recommendations

### Manual Test Cases

**Test 1: MDV Dose Deduction**
1. Create MDV medication with 10mL active vial (`stockValue = 10.0`)
2. Create schedule with 0.25mL dose
3. Mark dose as taken from calendar
4. **Expected**: `stockValue` changes from `10.0` → `9.75`
5. Cancel the taken dose
6. **Expected**: `stockValue` restored to `10.0`

**Test 2: Tablet Quarter Deduction**
1. Create tablet medication with 100 tablets stock
2. Create schedule with 1/2 tablet dose (2 quarters)
3. Mark dose as taken
4. **Expected**: `stockValue` changes from `100.0` → `99.5`
5. Mark another dose (1/4 tablet = 1 quarter)
6. **Expected**: `stockValue` changes from `99.5` → `99.25`

**Test 3: Skip/Snooze No Deduction**
1. Any medication type
2. Skip a dose
3. **Expected**: `stockValue` unchanged
4. Snooze a dose
5. **Expected**: `stockValue` unchanged

## Impact Assessment

### Critical Impact
- **Severity**: HIGH - MDV stock was incorrectly calculated by 1/100th the expected amount
- **User Impact**: MDV users would see negligible stock depletion (e.g., 0.025 mL instead of 0.25 mL)
- **Data Integrity**: Existing MDV stock values in database are likely incorrect and too high
- **Affected Users**: All users tracking MDV medications

### Migration Consideration
No automatic migration possible - existing stock values for MDV medications are corrupted. Users will need to manually adjust their active vial stock values.

## Related Documentation

- `docs/product-design.md` - MDV UI specifications
- `docs/MDV_RECONSTITUTION_ENHANCEMENT_SPEC.md` - MDV architecture
- `lib/src/features/medications/domain/medication.dart` - Domain model with active/backup vial fields

---

**Fixed**: November 10, 2025
**Committer**: GitHub Copilot
