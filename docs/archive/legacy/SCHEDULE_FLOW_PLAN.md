# Complete Schedule Flow: Add → Save → View → Take

**Date**: November 6, 2025  
**Status**: Planning Document

---

## Overview

This document maps the entire user journey for medication schedules in Dosifi v5, from creation to dose recording. It identifies all touchpoints, data flow, UI components, and technical implementation details.

---

## 1. Add Schedule Flow

### Entry Points
1. **Schedules Page** → FAB "Add Schedule" button
2. **Medication Detail Page** → "Create Schedule" button
3. **Home Dashboard** → Quick action (future)

### Step-by-Step User Journey

#### **Step 1: Select Medication**
**Page**: `add_edit_schedule_page.dart`

**Initial State**:
- Empty form with centered "Select a medication" button
- Helper text: "Select a medication to schedule"
- No summary card visible yet

**User Action**: Tap "Select a medication" button

**Navigation**: → `select_medication_for_schedule_page.dart`

**Medication Selection Page**:
- **List Display**:
  - All medications from Hive `medications` box
  - Grouped by category/form
  - Each card shows:
    - Medication name + manufacturer
    - Form icon (tablet, injection, MDV, etc.)
    - Strength (e.g., "50 mg per tablet")
    - Stock status (color-coded: green/yellow/red)
    - Low stock warning badge if applicable
    - Expiry warning for reconstituted MDVs
- **Search**: Filter by name/manufacturer
- **Empty State**: "No medications. Add one first."

**User Action**: Tap medication card

**Result**:
- Returns to Add Schedule page
- Selected medication stored in state: `_medicationId`, `_selectedMedication`
- Medication display appears (collapsible card)
- **Summary Card appears** (floating, below app bar)

---

#### **Step 2: Summary Card Display**
**Component**: `ScheduleSummaryCard` (using `SummaryHeaderCard.fromMedication()`)

**Content**:
- **Medication Info**:
  - Name, manufacturer, strength, form
  - Stock status indicator
  - Expiry warnings (if reconstituted)
- **Schedule Info** (updates live as form changes):
  - Dose: "2 tablets × 50mg = 100mg total"
  - Times: "9:00 AM, 9:00 PM"
  - Frequency: "Every day" / "Mon, Wed, Fri" / "Every 5 days"

**Position**: Fixed below app bar, above scrollable form

**Behavior**:
- Appears after medication selection
- Updates reactively on ANY form field change
- Collapses on scroll (optional - TBD)
- Uses neutral surface color (not primary)

---

#### **Step 3: Fill Schedule Details**
**Page**: `add_edit_schedule_page.dart` - Main form sections

**Form Structure** (Scrollable, with sections):

##### **Section 1: General Info**
- **Schedule Name** (TextField, optional)
  - **Auto-generates in real-time** as user fills dose: "{DoseAmount} - {MedicationName}"
  - Examples:
    - Tablets: "2 tablets - Panadol"
    - MDV: "500mcg - BCP-157"
    - Capsules: "3 capsules - Fish Oil"
  - Updates live when dose or medication changes
  - User can override and type custom name
  - Helper: "Auto-generated from dose. Tap to customize."
  - **CRITICAL**: Name must be easily scannable in calendar view
  
- **Medication Display** (Expandable card)
  - When collapsed: Shows name + form icon + expand icon
  - When expanded: Full medication details card
  - Clear button to deselect and pick different medication

**Design System Integration** (ENFORCED):
- ✅ All spacing: `kSpacingXS`, `kSpacingS`, `kSpacingM`, `kSpacingL`
- ✅ All radii: `kBorderRadiusS`, `kBorderRadiusM`, `kBorderRadiusL`
- ✅ All colors: `Theme.of(context).colorScheme.primary`, `surface`, etc.
- ✅ NO hardcoded values: `EdgeInsets.all(12)` → `EdgeInsets.all(kSpacingM)`
- ✅ NO inline decorations: Extract to reusable widgets
- ✅ All form fields: Use `UnifiedFormField` widget
- ✅ All sections: Use `UnifiedFormSection` widget

##### **Section 2: Dose** ⚠️ COMPLEX CALCULATION LOGIC

**Dose Input Mode** (auto-detected from medication form):

---

**MODE 1: TABLETS** 🔢
- **Input Options** (toggle or dropdown):
  - Option A: "Tablets" (e.g., 2 tablets)
  - Option B: "Strength" (e.g., 100mg)

- **Option A: Tablets Selected**:
  - Input: Number of tablets (supports 1/4 increments: 0.25, 0.5, 0.75, 1.0, etc.)
  - Validation: Must be multiple of 0.25
  - Controls: 
    - Number field with stepper (+/- buttons)
    - Quick buttons: "1/4", "1/2", "3/4", "1", "1.5", "2"
  - **Live Calculation**: 
    - "2.5 tablets × 50mg = **125mg total**"
    - Shows both tablet count AND calculated strength

- **Option B: Strength Selected**:
  - Input: Dose in mg/mcg/g
  - Validation: Must result in valid tablet increment (1/4 increments)
  - Controls: Number field
  - **Live Calculation**:
    - "100mg ÷ 50mg = **2 tablets**"
    - If invalid increment: Show warning "⚠️ Dose requires 2.3 tablets (not a 1/4 increment)"
    - Round to nearest 1/4 or require exact match

- **Display Summary** (always shows both):
  - "**2 tablets** (100mg total)" OR
  - "**100mg** (2 tablets)"

---

**MODE 2: CAPSULES** 💊
- **Input Options**:
  - Option A: "Capsules" (whole numbers only)
  - Option B: "Strength" (must calculate to whole capsules)

- **Option A: Capsules Selected**:
  - Input: Number of capsules (integers only: 1, 2, 3, etc.)
  - Validation: Must be whole number
  - Controls: Number field with stepper
  - **Live Calculation**:
    - "3 capsules × 25mg = **75mg total**"

- **Option B: Strength Selected**:
  - Input: Dose in mg/mcg/g
  - Validation: Must result in whole number of capsules
  - **Live Calculation**:
    - "75mg ÷ 25mg = **3 capsules**"
    - If invalid: "⚠️ Dose requires 2.3 capsules (must be whole number)"

- **Display Summary**:
  - "**3 capsules** (75mg total)"

---

**MODE 3: PRE-FILLED INJECTION** 💉 (Single Dose)
- **Input**: Number of injections (whole numbers: 1, 2, 3, etc.)
- **Characteristics**:
  - Each injection is pre-filled, single-use
  - User may need multiple for higher doses
  - Example: "2 injections" if protocol requires double dose

- **Live Calculation**:
  - "2 injections × 50mg = **100mg total**"
  - "2 injections × 0.5ml = **1.0ml total**"

- **Display Summary**:
  - "**2 injections** (100mg, 1.0ml total)"

---

**MODE 4: SINGLE DOSE VIAL** 🧪 (One-time use)
- **Input**: Number of vials (whole numbers: 1, 2, 3, etc.)
- **Characteristics**:
  - Each vial is single-use
  - User may need multiple vials for higher doses
  - Example: "3 vials" if drawing from multiple

- **Live Calculation**:
  - "3 vials × 10mg = **30mg total**"
  - "3 vials × 2ml = **6ml total**"

- **Display Summary**:
  - "**3 vials** (30mg, 6ml total)"

---

**MODE 5: MULTI-DOSE VIAL (MDV)** 🎯 **MAIN SELLING POINT**

**This is the most complex and critical mode - the app's primary differentiator.**

**Initial State Check**:
1. Check if MDV has reconstitution calculation saved
   - YES → Use reconstitution result as **default dose** (pre-filled)
   - NO → Start with empty dose

**Input Options** (3-way toggle):
- Option A: "Strength" (mg/mcg)
- Option B: "Volume" (ml)
- Option C: "Syringe Units" (U)

**Data Required from Medication**:
- Total strength in vial (e.g., 10mg)
- Total volume after reconstitution (e.g., 5ml)
- Concentration (auto-calculated: 10mg ÷ 5ml = 2mg/ml)
- Syringe type (determines unit scale: 0.3ml, 0.5ml, 1ml, 3ml, 5ml, 10ml)

**Option A: Strength Selected** (e.g., "500mcg"):
- Input: Dose in mg or mcg
- **Calculations**:
  - Volume = Strength ÷ Concentration
    - 500mcg = 0.5mg
    - 0.5mg ÷ 2mg/ml = **0.25ml**
  - Syringe Units = Volume × (Units per ml based on syringe)
    - 0.25ml × 100U/ml (for 0.5ml syringe) = **25 Units**
- **Display All Three**:
  - "**500mcg** (0.25ml / 25 Units)"
  - Syringe graphic showing 25U filled on 50U scale

**Option B: Volume Selected** (e.g., "0.25ml"):
- Input: Volume in ml
- **Calculations**:
  - Strength = Volume × Concentration
    - 0.25ml × 2mg/ml = **0.5mg** = **500mcg**
  - Syringe Units = Volume × (Units per ml)
    - 0.25ml × 100U/ml = **25 Units**
- **Display All Three**:
  - "**0.25ml** (500mcg / 25 Units)"
  - Syringe graphic showing 25U filled

**Option C: Syringe Units Selected** (e.g., "25U"):
- Input: Units on syringe scale
- **Calculations**:
  - Volume = Units ÷ (Units per ml)
    - 25U ÷ 100U/ml = **0.25ml**
  - Strength = Volume × Concentration
    - 0.25ml × 2mg/ml = **500mcg**
- **Display All Three**:
  - "**25 Units** (500mcg / 0.25ml)"
  - Syringe graphic showing 25U filled

**Visual Components** (MDV ONLY):

1. **Syringe Graphic** (Interactive SVG):
   - Barrel shows total capacity based on syringe type
   - Fill level animates to show dose
   - Scale markings show units
   - Color-coded fill (blue for dose, white for air)
   - Example: 0.5ml syringe (50U scale) with 25U filled

2. **Fine-Tune Slider** (Below graphic):
   - Allows micro-adjustments (±10% in small increments)
   - Real-time updates all three values
   - Slider thumb shows current value
   - Min/Max based on vial capacity
   - **This is the killer feature** - precision dosing with visual feedback

3. **Three-Value Display** (Always visible):
   ```
   ┌─────────────────────────────────────┐
   │  500mcg  •  0.25ml  •  25 Units     │
   │  [Syringe Graphic: ████▁▁▁▁▁▁]      │
   │  ◄─────────●──────────────────►     │
   │           Slider                     │
   └─────────────────────────────────────┘
   ```

**Calculation Example** (10mg vial, 5ml volume):
- Concentration: 10mg ÷ 5ml = 2mg/ml
- User selects: "500mcg"
- Calculations:
  - 500mcg = 0.5mg
  - Volume: 0.5mg ÷ 2mg/ml = 0.25ml
  - Units (0.5ml syringe @ 100U/ml): 0.25ml × 100 = 25U
- Display: "**500mcg** (0.25ml / 25 Units)" + syringe at 25U
- User adjusts slider to 27U:
  - Volume: 27U ÷ 100U/ml = 0.27ml
  - Strength: 0.27ml × 2mg/ml = 0.54mg = 540mcg
  - Updates to: "**540mcg** (0.27ml / 27 Units)"

**Validation**:
- Cannot exceed vial capacity (5ml max in example)
- Cannot exceed vial strength (10mg max in example)
- Warning if dose uses >80% of vial: "⚠️ High dose - verify calculation"

**Reconstitution Integration**:
- If MDV was reconstituted with custom calculation:
  - Use those values as defaults
  - Show "From reconstitution" badge
  - Link to reconstitution calculator: "Recalculate" button
  - Update schedule if reconstitution changes

---

**Display Summary Formatting** (All Modes):

- **Tablets**: "**2 tablets** (100mg total)"
- **Capsules**: "**3 capsules** (75mg total)"
- **Pre-filled**: "**1 injection** (50mg, 0.5ml)"
- **Single Vial**: "**2 vials** (20mg, 4ml total)"
- **MDV**: "**500mcg** (0.25ml / 25 Units)" + syringe graphic

##### **Section 3: Times**
- **Add Time** button
- **Time Chips** (dismissible):
  - Each shows time in 12h format
  - Tap to edit via time picker
  - Delete icon to remove
  - Sorted automatically (earliest → latest)
- Minimum: 1 time required
- Example: "9:00 AM" + "Add Time" button

##### **Section 4: Frequency**
**Mode Selector** (Segmented buttons or radio):
- Every Day
- Days of Week
- Days On/Off (Cycle)
- Days of Month

**Mode 1: Every Day**
- No additional controls
- Summary: "Every day"

**Mode 2: Days of Week**
- 7 toggle chips: Mon, Tue, Wed, Thu, Fri, Sat, Sun
- Multi-select
- Summary: "Mon, Wed, Fri"

**Mode 3: Days On/Off (Cycle)**
- **Days On** (Number TextField): "5"
- **Days Off** (Number TextField): "2"
- **Anchor Date** (Date picker): "Nov 5, 2025"
- Summary: "5 days on, 2 days off (starting Nov 5)"

**Mode 4: Days of Month**
- 31 filter chips (1-31)
- Multi-select specific dates
- Summary: "1st, 15th of each month"

##### **Section 5: Schedule Range** (Optional)
- **Start Date** (Date picker, default: today)
- **End Date** (Date picker, optional)
- **No End Date** checkbox (default: checked)

---

#### **Step 4: Validation & Save**
**Save Button**: Fixed at bottom (always visible)

**Validation Rules**:
1. Medication selected ✓
2. Dose value > 0 ✓
3. At least 1 time selected ✓
4. Frequency mode has valid selection:
   - Every Day: auto-valid
   - Days of Week: at least 1 day selected ✓
   - Cycle: daysOn > 0, daysOff >= 0 ✓
   - Days of Month: at least 1 date selected ✓

**Save Flow**:
```dart
1. Validate form
2. Generate schedule ID (UUID)
3. Auto-generate name if empty
4. Create Schedule object
5. Save to Hive box('schedules')
6. Schedule notifications via ScheduleScheduler
7. Navigate back to Schedules list
8. Show success snackbar
```

**Error Handling**:
- Invalid fields: Show red validation errors
- Save fails: Show error snackbar, keep form open
- Notification scheduling fails: Log error, still save schedule

---

## 2. Schedule Data Model

### Dose Calculation Architecture 🎯

**Core Principle**: Every dose must store **typed dose fields** to enable precise calculations and display across all views.

#### Typed Dose Storage

**Schedule Model Fields** (already in domain model):
```dart
// Primary dose fields (user-facing)
doseValue: double         // e.g., 2.0, 500.0, 0.25
doseUnit: String          // e.g., "tablets", "mg", "ml", "U"
doseUnitCode: String?     // Enum code for typed dose

// Typed dose fields (calculated, for precision)
doseMassMcg: double?           // Dose in micrograms (all strengths normalized)
doseVolumeMicroliter: double?  // Volume in microliters
doseTabletQuarters: int?       // Tablets in 1/4 increments (e.g., 10 = 2.5 tablets)
doseCapsules: int?             // Whole capsules only
doseSyringes: int?             // Pre-filled syringes count
doseVials: int?                // Vials count
doseIU: double?                // International Units

// Display preferences
displayUnitCode: String?       // How to show in UI (mg vs mcg)
inputModeCode: String?         // How user entered (tablets, mass, volume, units)
```

#### Calculation Service (New Component Needed)

**File**: `lib/src/features/schedules/domain/dose_calculator.dart`

**Purpose**: Convert between dose formats and validate increments

**Key Methods**:

```dart
class DoseCalculator {
  // TABLETS
  static DoseCalculationResult calculateFromTablets({
    required double tabletCount,
    required double strengthPerTablet,  // in mcg
    required String strengthUnit,       // "mg", "mcg", "g"
  }) {
    // Validate tablet count is 1/4 increment
    if ((tabletCount * 4) % 1 != 0) {
      return DoseCalculationResult.error("Must be 1/4 increment");
    }
    
    final totalMcg = tabletCount * strengthPerTablet;
    final tabletQuarters = (tabletCount * 4).toInt();
    
    return DoseCalculationResult.success(
      doseMassMcg: totalMcg,
      doseTabletQuarters: tabletQuarters,
      displayText: "${tabletCount} tablets (${formatMass(totalMcg)})",
    );
  }
  
  static DoseCalculationResult calculateFromStrength({
    required double strengthMcg,
    required double strengthPerTablet,
  }) {
    final tabletCount = strengthMcg / strengthPerTablet;
    
    // Validate results in 1/4 increment
    if ((tabletCount * 4) % 1 != 0) {
      final rounded = (tabletCount * 4).round() / 4;
      return DoseCalculationResult.warning(
        doseMassMcg: strengthMcg,
        doseTabletQuarters: (rounded * 4).toInt(),
        displayText: "${rounded} tablets",
        warning: "⚠️ Dose requires ${tabletCount.toStringAsFixed(2)} tablets (rounded to ${rounded})",
      );
    }
    
    return calculateFromTablets(
      tabletCount: tabletCount,
      strengthPerTablet: strengthPerTablet,
      strengthUnit: "mcg",
    );
  }
  
  // CAPSULES
  static DoseCalculationResult calculateFromCapsules({
    required int capsuleCount,
    required double strengthPerCapsule,
  }) {
    final totalMcg = capsuleCount * strengthPerCapsule;
    
    return DoseCalculationResult.success(
      doseMassMcg: totalMcg,
      doseCapsules: capsuleCount,
      displayText: "${capsuleCount} capsules (${formatMass(totalMcg)})",
    );
  }
  
  // MDV - The main feature
  static DoseCalculationResult calculateFromStrength_MDV({
    required double strengthMcg,
    required double totalStrengthMcg,     // Total in vial
    required double totalVolumeMicroliter, // Total volume
    required SyringeType syringeType,      // Determines unit scale
  }) {
    // Calculate concentration (mcg per microliter)
    final concentration = totalStrengthMcg / totalVolumeMicroliter;
    
    // Calculate volume needed
    final volumeMicroliter = strengthMcg / concentration;
    
    // Calculate syringe units
    final volumeMl = volumeMicroliter / 1000;
    final syringeUnits = volumeMl * syringeType.unitsPerMl;
    
    // Validate doesn't exceed vial
    if (volumeMicroliter > totalVolumeMicroliter) {
      return DoseCalculationResult.error(
        "Dose exceeds vial capacity (${totalVolumeMicroliter / 1000}ml)",
      );
    }
    
    if (strengthMcg > totalStrengthMcg) {
      return DoseCalculationResult.error(
        "Dose exceeds vial strength (${formatMass(totalStrengthMcg)})",
      );
    }
    
    return DoseCalculationResult.success(
      doseMassMcg: strengthMcg,
      doseVolumeMicroliter: volumeMicroliter,
      syringeUnits: syringeUnits,
      displayText: "${formatMass(strengthMcg)} (${formatVolume(volumeMicroliter)} / ${syringeUnits.toStringAsFixed(1)}U)",
    );
  }
  
  static DoseCalculationResult calculateFromVolume_MDV({
    required double volumeMicroliter,
    required double totalStrengthMcg,
    required double totalVolumeMicroliter,
    required SyringeType syringeType,
  }) {
    final concentration = totalStrengthMcg / totalVolumeMicroliter;
    final strengthMcg = volumeMicroliter * concentration;
    
    return calculateFromStrength_MDV(
      strengthMcg: strengthMcg,
      totalStrengthMcg: totalStrengthMcg,
      totalVolumeMicroliter: totalVolumeMicroliter,
      syringeType: syringeType,
    );
  }
  
  static DoseCalculationResult calculateFromUnits_MDV({
    required double syringeUnits,
    required double totalStrengthMcg,
    required double totalVolumeMicroliter,
    required SyringeType syringeType,
  }) {
    final volumeMl = syringeUnits / syringeType.unitsPerMl;
    final volumeMicroliter = volumeMl * 1000;
    
    return calculateFromVolume_MDV(
      volumeMicroliter: volumeMicroliter,
      totalStrengthMcg: totalStrengthMcg,
      totalVolumeMicroliter: totalVolumeMicroliter,
      syringeType: syringeType,
    );
  }
  
  // Formatting helpers
  static String formatMass(double mcg) {
    if (mcg >= 1000000) return "${(mcg / 1000000).toStringAsFixed(1)}g";
    if (mcg >= 1000) return "${(mcg / 1000).toStringAsFixed(1)}mg";
    return "${mcg.toStringAsFixed(0)}mcg";
  }
  
  static String formatVolume(double microliter) {
    return "${(microliter / 1000).toStringAsFixed(2)}ml";
  }
}

enum SyringeType {
  ml_0_3(unitsPerMl: 30, maxUnits: 30, maxMl: 0.3),
  ml_0_5(unitsPerMl: 50, maxUnits: 50, maxMl: 0.5),
  ml_1_0(unitsPerMl: 100, maxUnits: 100, maxMl: 1.0),
  ml_3_0(unitsPerMl: 100, maxUnits: 300, maxMl: 3.0),
  ml_5_0(unitsPerMl: 100, maxUnits: 500, maxMl: 5.0),
  ml_10_0(unitsPerMl: 100, maxUnits: 1000, maxMl: 10.0);
  
  const SyringeType({
    required this.unitsPerMl,
    required this.maxUnits,
    required this.maxMl,
  });
  
  final double unitsPerMl;
  final double maxUnits;
  final double maxMl;
}

class DoseCalculationResult {
  final bool success;
  final String? error;
  final String? warning;
  final double? doseMassMcg;
  final double? doseVolumeMicroliter;
  final int? doseTabletQuarters;
  final int? doseCapsules;
  final double? syringeUnits;
  final String displayText;
  
  // Factory constructors
  DoseCalculationResult.success({...});
  DoseCalculationResult.error(String message);
  DoseCalculationResult.warning({...});
}
```

#### Syringe Graphic Component (New Widget Needed)

**File**: `lib/src/widgets/syringe_graphic.dart`

**Purpose**: Visual representation of dose in syringe

```dart
class SyringeGraphic extends StatelessWidget {
  final double currentUnits;
  final SyringeType syringeType;
  final bool interactive;  // If true, tap to adjust
  final ValueChanged<double>? onUnitsChanged;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SVG syringe with fill animation
        CustomPaint(
          painter: SyringePainter(
            fillLevel: currentUnits / syringeType.maxUnits,
            syringeType: syringeType,
          ),
          size: Size(60, 200),
        ),
        
        // Scale markings
        _buildScaleMarkings(),
        
        // Current value display
        Text(
          "${currentUnits.toStringAsFixed(1)} Units",
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
```

#### Integration with Add Schedule Form

**State Management** (in `add_edit_schedule_page.dart`):

```dart
// Input mode tracking
DoseInputMode _doseInputMode = DoseInputMode.tablets;  // or strength, volume, units

// Current values (one source of truth)
double? _currentDoseMcg;
double? _currentVolumeMicroliter;
double? _currentTabletQuarters;
double? _currentSyringeUnits;

// When user changes input
void _onDoseInputChanged(String input, DoseInputMode mode) {
  final medication = _selectedMedication;
  if (medication == null) return;
  
  DoseCalculationResult result;
  
  switch (medication.form) {
    case MedicationForm.tablet:
      if (mode == DoseInputMode.tablets) {
        result = DoseCalculator.calculateFromTablets(...);
      } else {
        result = DoseCalculator.calculateFromStrength(...);
      }
      break;
      
    case MedicationForm.mdv:
      if (mode == DoseInputMode.strength) {
        result = DoseCalculator.calculateFromStrength_MDV(...);
      } else if (mode == DoseInputMode.volume) {
        result = DoseCalculator.calculateFromVolume_MDV(...);
      } else {
        result = DoseCalculator.calculateFromUnits_MDV(...);
      }
      break;
  }
  
  if (result.success) {
    setState(() {
      _currentDoseMcg = result.doseMassMcg;
      _currentVolumeMicroliter = result.doseVolumeMicroliter;
      _currentTabletQuarters = result.doseTabletQuarters;
      _currentSyringeUnits = result.syringeUnits;
      _doseDisplayText = result.displayText;
    });
  } else {
    // Show error
    _showDoseError(result.error ?? result.warning);
  }
}
```

#### Saving to Database

**When creating Schedule object**:

```dart
final schedule = Schedule(
  // ... other fields
  
  // User-facing
  doseValue: _getDoseValue(),  // Could be tablets, mg, ml, etc.
  doseUnit: _getDoseUnit(),
  doseUnitCode: _doseInputMode.code,
  
  // Typed fields (for calculations)
  doseMassMcg: _currentDoseMcg,
  doseVolumeMicroliter: _currentVolumeMicroliter,
  doseTabletQuarters: _currentTabletQuarters?.toDouble(),
  doseCapsules: _currentCapsules?.toDouble(),
  doseIU: _currentSyringeUnits,
  
  // Display
  displayUnitCode: _getPreferredDisplayUnit(),
  inputModeCode: _doseInputMode.code,
);
```

---

### Schedule Object Structure
```dart
Schedule {
  id: String (UUID)
  name: String
  medicationId: String? (link to medication)
  medicationName: String
  
  // Dose
  doseValue: double (e.g., 2.0)
  doseUnit: String (e.g., "tablets")
  
  // Timing
  timesOfDay: List<int>? (minutes from midnight, local)
  timesOfDayUtc: List<int>? (minutes from midnight, UTC)
  minutesOfDay: int (legacy, single time)
  
  // Frequency
  daysOfWeek: List<int> (1=Mon...7=Sun, local)
  daysOfWeekUtc: List<int>? (UTC)
  cycleEveryNDays: int? (e.g., 5)
  cycleAnchorDate: DateTime? (start of cycle)
  daysOfMonth: List<int>? (1-31)
  
  // Status
  active: bool (default: true)
  createdAt: DateTime
  
  // Typed dose fields (advanced)
  doseUnitCode, doseMassMcg, doseVolumeMicroliter,
  doseTabletQuarters, doseCapsules, etc.
}
```

### Storage
- **Hive Box**: `schedules`
- **Type ID**: 40
- **Adapter**: `ScheduleAdapter` (auto-generated)

---

## 3. Notification Scheduling

### ScheduleScheduler Service

**Location**: `lib/src/features/schedules/data/schedule_scheduler.dart`

**Key Methods**:

#### `scheduleFor(Schedule schedule)`
1. Cancel existing notifications for schedule ID
2. Calculate next 30 days of doses based on:
   - Times of day
   - Frequency pattern (every day, days of week, cycle, monthly)
   - Active status
3. For each dose time:
   - Generate unique notification ID
   - Schedule notification via `NotificationService`
   - Store notification metadata

**Notification Details**:
- **Title**: "{ScheduleName}" (e.g., "500mcg - BCP-157" or "2 tablets - Panadol")
- **Body**: Comprehensive dose instructions
  - Tablets: "Take 2 tablets (100mg total) at 9:00 AM"
  - MDV: "Take 500mcg (0.25ml / 25 Units) at 9:00 AM"
  - Multiple items: "Time for 2 medications - tap to view"
- **Channel**: "Medication Reminders"
- **Mode**: `AndroidScheduleMode.alarmClock` (can trigger during Doze)
- **Priority**: HIGH (heads-up display)
- **Sound**: Custom per medication (optional) or default alert
- **Vibration**: Pattern based on urgency

**Action Buttons** (Android/iOS):
1. **"Take"** 
   - Records dose with current timestamp
   - Saves to dose_logs with action: DoseAction.taken
   - Dismisses notification
   - Shows quick confirmation toast
   - NO app open required
   
2. **"Snooze"**
   - Reschedules notification for +15 minutes (configurable)
   - Records snooze log entry
   - Shows "Snoozed until [time]" toast
   
3. **"Skip"**
   - Records dose with action: DoseAction.skipped
   - Dismisses notification
   - Shows "Dose skipped" toast
   
4. **"Add Note"**
   - Opens mini dialog (notification expanded view)
   - Text input for quick note (e.g., "Took with food")
   - For injections: Quick injection site picker (dropdown)
   - Saves note with dose log
   - Falls back to opening app if mini dialog not supported

**Implementation Details**:
```dart
// Notification action handling
NotificationAction.take => {
  DoseLogRepository.record(
    scheduleId: notificationData.scheduleId,
    scheduledTime: notificationData.scheduledTime,
    action: DoseAction.taken,
    actionTime: DateTime.now(),
  ),
  NotificationService.dismiss(notificationId),
  ToastService.show("Dose taken"),
}

NotificationAction.snooze => {
  NotificationService.reschedule(
    notificationId,
    delay: Duration(minutes: 15),
  ),
  DoseLogRepository.recordSnooze(...),
  ToastService.show("Snoozed until ${newTime}"),
}
```

---

### Multiple Schedules at Same Time 🔔🔔🔔

**Problem**: User has 3 schedules all at 9:00 AM (Vitamin D, BCP-157, Panadol)

**Solution Options**:

#### **Option A: Single Grouped Notification** (RECOMMENDED)
**Pros**: Less intrusive, cleaner notification tray, easier to manage  
**Cons**: Can't take actions on individual items directly

**Notification Display**:
```
╔════════════════════════════════════════╗
║ 🏥 3 Medications Due - 9:00 AM         ║
╠════════════════════════════════════════╣
║ • 500mcg - BCP-157 (0.25ml / 25U)      ║
║ • 2 tablets - Panadol (100mg)          ║
║ • 5000 IU - Vitamin D                  ║
╠════════════════════════════════════════╣
║ [Open App] [Snooze All] [Skip All]     ║
╚════════════════════════════════════════╝
```

**Expanded View** (tap notification):
```
╔════════════════════════════════════════╗
║ 🏥 3 Medications Due - 9:00 AM         ║
╠════════════════════════════════════════╣
║ ☑ 500mcg - BCP-157                     ║
║   0.25ml / 25 Units                    ║
║   [✓] [Snooze] [Skip] [Note]           ║
║                                        ║
║ ☑ 2 tablets - Panadol                  ║
║   100mg total                          ║
║   [✓] [Snooze] [Skip] [Note]           ║
║                                        ║
║ ☑ 5000 IU - Vitamin D                  ║
║   1 capsule                            ║
║   [✓] [Snooze] [Skip] [Note]           ║
╠════════════════════════════════════════╣
║ [Take All] [Snooze All] [Open App]     ║
╚════════════════════════════════════════╝
```

**Implementation**:
- Group notifications by scheduled time (within 1-minute window)
- Create single notification with grouped data
- Allow individual actions in expanded view
- "Take All" button records all at once
- Notification dismisses only when all items handled

#### **Option B: Separate Notifications**
**Pros**: Individual control, clear per-medication actions  
**Cons**: Notification spam (3+ notifications), overwhelming

**Notification Display**:
```
╔════════════════════════════════════════╗
║ 500mcg - BCP-157 - 9:00 AM             ║
║ Take 0.25ml / 25 Units                 ║
║ [Take] [Snooze] [Skip] [Note]          ║
╚════════════════════════════════════════╝

╔════════════════════════════════════════╗
║ 2 tablets - Panadol - 9:00 AM          ║
║ Take 100mg total                       ║
║ [Take] [Snooze] [Skip] [Note]          ║
╚════════════════════════════════════════╝

╔════════════════════════════════════════╗
║ 5000 IU - Vitamin D - 9:00 AM          ║
║ Take 1 capsule                         ║
║ [Take] [Snooze] [Skip] [Note]          ║
╚════════════════════════════════════════╝
```

#### **Option C: Hybrid (Smart Grouping)** (BEST UX)
**Logic**:
- 1 schedule at time → Single notification with full details + actions
- 2-3 schedules → Grouped notification with expandable individual actions
- 4+ schedules → Grouped summary + "Open app to view all"

**User Setting**:
- Allow user to choose preference: "Always group" vs "Separate" vs "Smart"
- Default: Smart grouping

**Recommendation**: **Option C (Hybrid)** - Best balance of clarity and usability

---

### Notification Grouping Service

**File**: `lib/src/features/schedules/data/notification_grouping_service.dart`

```dart
class NotificationGroupingService {
  // Groups schedules by time window (1 minute tolerance)
  Map<DateTime, List<Schedule>> groupByTime(List<Schedule> schedules) {
    final groups = <DateTime, List<Schedule>>{};
    
    for (final schedule in schedules) {
      final roundedTime = _roundToMinute(schedule.nextOccurrence);
      groups.putIfAbsent(roundedTime, () => []).add(schedule);
    }
    
    return groups;
  }
  
  // Decides notification strategy based on group size
  NotificationStrategy getStrategy(int count, UserPreference pref) {
    if (pref == UserPreference.alwaysGroup) {
      return NotificationStrategy.grouped;
    }
    if (pref == UserPreference.alwaysSeparate) {
      return NotificationStrategy.individual;
    }
    
    // Smart grouping (default)
    if (count == 1) return NotificationStrategy.individual;
    if (count <= 3) return NotificationStrategy.groupedExpandable;
    return NotificationStrategy.groupedSummary;
  }
  
  // Creates grouped notification
  Future<void> scheduleGroupedNotification({
    required DateTime time,
    required List<Schedule> schedules,
  }) async {
    final groupId = _generateGroupId(time);
    
    final notification = GroupedNotification(
      id: groupId,
      title: "${schedules.length} Medications Due - ${formatTime(time)}",
      body: schedules.map((s) => "• ${s.name}").join("\n"),
      scheduledTime: time,
      schedules: schedules,
      actions: [
        NotificationAction(id: "take_all", label: "Take All"),
        NotificationAction(id: "snooze_all", label: "Snooze All"),
        NotificationAction(id: "open_app", label: "Open App"),
      ],
      expandedActions: schedules.map((s) => [
        NotificationAction(id: "take_${s.id}", label: "✓"),
        NotificationAction(id: "snooze_${s.id}", label: "Snooze"),
        NotificationAction(id: "skip_${s.id}", label: "Skip"),
        NotificationAction(id: "note_${s.id}", label: "Note"),
      ]).toList(),
    );
    
    await NotificationService.schedule(notification);
  }
}
```

---

### Notification Content Examples

**Single Tablet Medication**:
```
Title: 2 tablets - Panadol
Body: Take 100mg total at 9:00 AM
Actions: [Take] [Snooze] [Skip] [Note]
```

**Single MDV Medication**:
```
Title: 500mcg - BCP-157
Body: Draw 0.25ml (25 Units) at 9:00 AM
Expanded: [Syringe icon showing 25U fill level]
Actions: [Take] [Snooze] [Skip] [Note]
```

**Grouped (2 medications)**:
```
Title: 2 Medications Due - 9:00 AM
Body: 
  • 500mcg - BCP-157 (0.25ml / 25U)
  • 2 tablets - Panadol (100mg)
Actions: [Take All] [Snooze All] [Open App]
Expanded: Individual checkboxes + actions per medication
```

**Grouped (4+ medications)**:
```
Title: 4 Medications Due - 9:00 AM
Body: Tap to view details
Actions: [Open App] [Snooze All]
```

#### `cancelFor(String scheduleId)`
- Cancels all notifications for schedule
- Called on: schedule delete, schedule pause, schedule edit

#### `reschedule(Schedule schedule)`
- Convenience: cancel + schedule

---

## 4. Calendar View System 📅

### Overview
Outlook-style calendar with three view modes: Day, Week, Month. Shows scheduled doses as blocks on timeline. Reusable across multiple screens (standalone page, medication detail, schedule detail, home widget).

---

### Calendar Page (Full Screen)
**Page**: `lib/src/features/schedules/presentation/calendar_page.dart`

**Header**:
- Month/Year title (e.g., "November 2025")
- View mode toggle: `[ Day | Week | Month ]` (segmented control)
- Navigation arrows: `[<] November 2025 [>]`
- "Today" button (jumps to current date)

**Design System Integration**:
- ✅ All spacing: `kSpacingXS`, `kSpacingS`, `kSpacingM`, `kSpacingL`
- ✅ Toggle buttons: Reusable `SegmentedToggle` widget
- ✅ Colors: `Theme.of(context).colorScheme.primary`, `surface`, etc.
- ✅ Radii: `kBorderRadiusS`, `kBorderRadiusM`

---

### View Mode 1: Day View 📆

**Layout**: Vertical hourly scroll (like Outlook calendar)

**Structure**:
```
┌─────────────────────────────────────────┐
│ ← Nov 6, 2025 (Today) →     [☰ Month]  │
├─────────────────────────────────────────┤
│                                         │
│ 6 AM  ┌──────────────────────────┐     │
│       │                          │     │
│ 7 AM  ├──────────────────────────┤     │
│       │                          │     │
│ 8 AM  ├──────────────────────────┤     │
│       │ ┌──────────────────────┐ │     │
│ 9 AM  │ │ 500mcg - BCP-157     │ │ ←── Dose block
│       │ │ 0.25ml / 25U         │ │
│       │ │ ✓ TAKEN (9:03 AM)    │ │
│       │ └──────────────────────┘ │     │
│       │ ┌──────────────────────┐ │     │
│       │ │ 2 tablets - Panadol  │ │ ←── Another dose
│       │ │ 100mg total          │ │     │
│       │ │ [Take] [Snooze]      │ │     │
│       │ └──────────────────────┘ │     │
│ 10 AM ├──────────────────────────┤     │
│       │                          │     │
│ 11 AM ├──────────────────────────┤     │
│       │                          │     │
│ 12 PM ├──────────────────────────┤     │
│       │ ┌──────────────────────┐ │     │
│       │ │ 5000 IU - Vitamin D  │ │     │
│       │ │ 1 capsule            │ │     │
│ 1 PM  │ └──────────────────────┘ │     │
│       │                          │     │
└─────────────────────────────────────────┘
```

**Features**:
- **Hourly Grid**: 24 hours (12 AM - 11 PM) with divider lines
- **Scroll Position**: Auto-scroll to current hour on load
- **Current Time Indicator**: Red line showing "now" (updates every minute)
- **Dose Blocks**:
  - Positioned at scheduled hour
  - Height: 60-80px (fixed, doesn't scale with hour)
  - Background: Color-coded by status
    - Not taken: `primary` with opacity
    - Taken: `success` (green) with checkmark
    - Snoozed: `warning` (orange)
    - Skipped: `error` (red) with X
    - Overdue: `error` with pulsing animation
  - Content:
    - Schedule name (bold): "500mcg - BCP-157"
    - Dose details: "0.25ml / 25 Units"
    - Status badge: "✓ TAKEN" or action buttons
    - Tap to expand → Shows notes, injection site, time taken
  - Multiple doses at same time: Stack vertically with small gap

**Interaction**:
- **Tap dose block** → Opens dose detail dialog
  - If not taken: Shows [Take] [Snooze] [Skip] [Add Note] buttons
  - If taken: Shows notes, injection site, time taken, [Edit] button
- **Long press dose block** → Quick actions menu (Take/Snooze/Skip)
- **Swipe left/right** → Navigate to previous/next day

**Empty State**:
- "No doses scheduled for this day"
- "Add schedule" button

---

### View Mode 2: Week View 📅📅📅📅📅📅📅

**Layout**: 7 columns (Mon-Sun), horizontal hours

**Structure**:
```
┌───────────────────────────────────────────────────────────────────────┐
│ ← Nov 3-9, 2025 →                                      [☰ Month]      │
├─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────────┤
│Time │ Mon │ Tue │ Wed │ Thu │ Fri │ Sat │ Sun │                      │
│     │  3  │  4  │  5  │  6  │  7  │  8  │  9  │                      │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤                      │
│ 6AM │     │     │     │     │     │     │     │                      │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤                      │
│ 9AM │ [B] │ [B] │ [B] │ [B] │ [B] │     │     │ ← Dose blocks       │
│     │ [P] │ [P] │ [P] │ [P] │ [P] │     │     │    (compact)        │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤                      │
│12PM │ [V] │ [V] │ [V] │ [V] │ [V] │ [V] │ [V] │                      │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤                      │
│ 9PM │ [B] │ [B] │ [B] │ [B] │ [B] │     │     │                      │
│     │ [P] │ [P] │ [P] │ [P] │ [P] │     │     │                      │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘

[B] = BCP-157, [P] = Panadol, [V] = Vitamin D (abbreviated)
```

**Features**:
- **7 Day Columns**: Current week (configurable: Sun-Sat or Mon-Sun)
- **Hourly Rows**: Major hours only (6 AM, 9 AM, 12 PM, 3 PM, 6 PM, 9 PM)
- **Dose Blocks** (Compact):
  - Small colored rectangles (40x40px)
  - Initials or icon only: "BCP" or syringe icon
  - Color: Medication category or status
  - Badge overlay: ✓ (taken), ! (overdue)
  - Tap → Opens dose detail dialog
  - Multiple doses: Stack as tiny pills (max 3 visible, then "+2")

**Interaction**:
- **Tap day column header** → Switches to Day view for that date
- **Tap dose block** → Opens dose detail dialog
- **Swipe left/right** → Navigate to previous/next week
- **Pinch zoom** → Adjusts hour row spacing (accessibility)

**Current Day Highlight**: 
- Column background: `primary.withOpacity(0.1)`
- Header: Bold + "TODAY" badge

---

### View Mode 3: Month View 🗓️

**Layout**: Traditional calendar grid (like Outlook month view)

**Structure**:
```
┌─────────────────────────────────────────────────────┐
│ ← November 2025 →                    [☰ Day]        │
├──────┬──────┬──────┬──────┬──────┬──────┬──────────┤
│ Sun  │ Mon  │ Tue  │ Wed  │ Thu  │ Fri  │ Sat      │
├──────┼──────┼──────┼──────┼──────┼──────┼──────────┤
│      │      │      │      │      │  1   │  2       │
│      │      │      │      │      │ ●●●  │ ●●       │
├──────┼──────┼──────┼──────┼──────┼──────┼──────────┤
│  3   │  4   │  5   │  6   │  7   │  8   │  9       │
│ ●●●  │ ●●●  │ ●●●  │ ●●●● │ ●●●  │      │          │
├──────┼──────┼──────┼──────┼──────┼──────┼──────────┤
│ 10   │ 11   │ 12   │ 13   │ 14   │ 15   │ 16       │
│ ●●●  │ ●●●  │ ●●●  │ ●●●  │ ●●●  │ ●●●  │ ●●●      │
├──────┼──────┼──────┼──────┼──────┼──────┼──────────┤
│ ... more weeks ...                                  │
└─────────────────────────────────────────────────────┘

● = Dose indicator (color-coded by status)
```

**Features**:
- **Calendar Grid**: 6 weeks (ensures all dates visible)
- **Date Numbers**: Top-left of each cell
- **Dose Indicators** (Dots/Pills):
  - Each scheduled dose = 1 colored dot (max 5 visible, then "+3")
  - Colors:
    - Green: All doses taken
    - Blue: Not taken (upcoming)
    - Orange: Some taken, some pending
    - Red: Overdue doses
    - Gray: Skipped/snoozed
  - Position: Bottom of cell, horizontally centered
  - Size: 6px diameter, 2px gap

**Interaction**:
- **Tap date cell** → Switches to Day view for that date
- **Tap date with doses** → Shows popover with dose list:
  ```
  ┌─────────────────────────────┐
  │ November 6, 2025            │
  ├─────────────────────────────┤
  │ 9:00 AM                     │
  │  • 500mcg - BCP-157 ✓       │
  │  • 2 tablets - Panadol      │
  │ 12:00 PM                    │
  │  • 5000 IU - Vitamin D ✓    │
  ├─────────────────────────────┤
  │ [View Day] [Take Pending]   │
  └─────────────────────────────┘
  ```
- **Swipe left/right** → Navigate to previous/next month
- **Double-tap date** → Opens Day view + scrolls to first dose

**Current Day Highlight**:
- Circle around date number: `primary` border
- Background: `primary.withOpacity(0.1)`

**Other Months**:
- Dates outside current month: Gray text (opacity 0.5)
- Still interactive (tap to switch month + view day)

---

### Reusable Calendar Widget 🔧

**Widget**: `DoseCalendarWidget`  
**File**: `lib/src/widgets/dose_calendar_widget.dart`

**Purpose**: Embeddable calendar for other screens (trimmed-down version)

**Variants**:

#### **Variant 1: Medication Detail Screen**
**Filter**: Only doses for THIS medication  
**Default View**: Week (compact)  
**Size**: Half-screen height (300-400px)  
**Features**:
- Shows only this medication's doses
- Switch between Week/Month (no Day view - tap opens full calendar)
- "View Full Calendar" button → Opens calendar page filtered to this med

**Example**:
```
┌─────────────────────────────────────────┐
│ BCP-157 Schedule                        │
├─────────────────────────────────────────┤
│ [Week | Month]           [Full Calendar]│
├───┬───┬───┬───┬───┬───┬───┬─────────────┤
│Mon│Tue│Wed│Thu│Fri│Sat│Sun│             │
│ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │             │
├───┼───┼───┼───┼───┼───┼───┤             │
│9AM│9AM│9AM│9AM│9AM│   │   │             │
│[✓]│[✓]│[✓]│[ ]│   │   │   │             │
└───┴───┴───┴───┴───┴───┴───┴─────────────┘
```

#### **Variant 2: Schedule Detail Screen**
**Filter**: Only doses for THIS schedule  
**Default View**: Week (compact)  
**Size**: Half-screen height  
**Features**:
- Shows only this schedule's doses
- Color-coded by status (taken/pending/overdue)
- Quick stats: "12 of 14 taken this week (86%)"

#### **Variant 3: Home Page Widget**
**Filter**: ALL schedules (global view)  
**Default View**: Day (today only, horizontal strip)  
**Size**: 150-200px height  
**Features**:
- Today's doses only
- Horizontal timeline (6 AM - 10 PM)
- Compact dose pills with time + name
- "View Calendar" button → Opens full calendar page
- Next dose highlighted with countdown

**Example**:
```
┌───────────────────────────────────────────────┐
│ Today's Doses          [View Full Calendar]   │
├───────────────────────────────────────────────┤
│ 6AM      9AM       12PM      6PM       9PM    │
│          ┌──┐      ┌──┐               ┌──┐   │
│          │✓B│      │✓V│               │ P│   │
│          └──┘      └──┘               └──┘   │
│        BCP-157   Vitamin D           Panadol  │
│         TAKEN      TAKEN            In 6h 23m │
└───────────────────────────────────────────────┘
```

**Widget API**:
```dart
class DoseCalendarWidget extends StatelessWidget {
  final CalendarFilter filter;  // all, medicationId, scheduleId
  final CalendarVariant variant; // full, compact, mini
  final CalendarDefaultView defaultView; // day, week, month
  final bool showViewToggle;  // true for full, false for compact
  final VoidCallback? onViewFullCalendar;
  
  // Height constraints
  final double? height;  // null = expand, 300 = fixed, etc.
  
  // Date range
  final DateTime? startDate;  // null = today
  final DateTime? endDate;    // null = +7 days
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Schedule>>(
      valueListenable: Hive.box<Schedule>('schedules').listenable(),
      builder: (context, box, _) {
        final schedules = _filterSchedules(box, filter);
        final doses = _calculateDoses(schedules, startDate, endDate);
        
        return _buildCalendarView(variant, defaultView, doses);
      },
    );
  }
}
```

**Usage Examples**:
```dart
// Full calendar page
DoseCalendarWidget(
  filter: CalendarFilter.all(),
  variant: CalendarVariant.full,
  defaultView: CalendarDefaultView.week,
  showViewToggle: true,
);

// Medication detail (compact)
DoseCalendarWidget(
  filter: CalendarFilter.medication(medicationId: 'abc123'),
  variant: CalendarVariant.compact,
  defaultView: CalendarDefaultView.week,
  height: 300,
  onViewFullCalendar: () => navigateToCalendar(medicationId: 'abc123'),
);

// Home widget (mini)
DoseCalendarWidget(
  filter: CalendarFilter.all(),
  variant: CalendarVariant.mini,
  defaultView: CalendarDefaultView.day,
  height: 180,
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 1)),
  onViewFullCalendar: () => navigateToCalendar(),
);
```

---

### Calendar Data Loading

**Performance Optimization**:
- Only load visible date range (don't calculate all future doses)
- Cache dose calculations (invalidate on schedule change)
- Lazy load as user scrolls/swipes

**Dose Calculation**:
```dart
class DoseCalculationService {
  // Calculates all dose times for schedules in date range
  List<CalculatedDose> calculateDoses({
    required List<Schedule> schedules,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final doses = <CalculatedDose>[];
    
    for (final schedule in schedules.where((s) => s.active)) {
      final scheduleDoses = _calculateScheduleDoses(
        schedule,
        startDate,
        endDate,
      );
      doses.addAll(scheduleDoses);
    }
    
    return doses..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }
  
  // Gets existing dose log for calculated dose
  DoseLog? getExistingLog(CalculatedDose dose) {
    final logs = Hive.box<DoseLog>('dose_logs');
    
    return logs.values.firstWhereOrNull(
      (log) => log.scheduleId == dose.scheduleId &&
               _isSameScheduledTime(log.scheduledTime, dose.scheduledTime),
    );
  }
}

class CalculatedDose {
  final String scheduleId;
  final String scheduleName;
  final DateTime scheduledTime;
  final String doseDescription;
  final DoseLog? existingLog;  // null if not taken
  
  DoseStatus get status {
    if (existingLog != null) {
      return DoseStatus.fromAction(existingLog!.action);
    }
    if (scheduledTime.isBefore(DateTime.now())) {
      return DoseStatus.overdue;
    }
    return DoseStatus.pending;
  }
}
```

---

### Design System Components (Enforced)

**All calendar widgets MUST use**:
- `CalendarDayCell` widget (reusable day cell)
- `CalendarDoseBlock` widget (reusable dose block)
- `CalendarHeader` widget (month/year + navigation)
- `CalendarViewToggle` widget (Day/Week/Month segmented control)
- Constants from `design_system.dart`:
  - `kCalendarDayHeight = 80.0`
  - `kCalendarHourHeight = 60.0`
  - `kCalendarDoseBlockHeight = 60.0`
  - `kCalendarDoseIndicatorSize = 6.0`
  - All spacing: `kSpacingXS`, `kSpacingS`, `kSpacingM`
  - All radii: `kBorderRadiusS`, `kBorderRadiusM`
  - Colors: `Theme.of(context).colorScheme.*`

**NO hardcoded values allowed**:
- ❌ `Container(height: 80)` → ✅ `Container(height: kCalendarDayHeight)`
- ❌ `EdgeInsets.all(12)` → ✅ `EdgeInsets.all(kSpacingM)`
- ❌ `Color(0xFF...)` → ✅ `Theme.of(context).colorScheme.primary`

---

## 4B. Viewing Schedules (Updated)

### Schedules List Page
**Page**: `schedules_page.dart`

**Display**:
- All schedules from Hive box
- Grouped by medication (optional)
- Each card shows:
  - Schedule name
  - Medication name + icon
  - Dose summary: "2 tablets — 100mg"
  - Next dose time: "Next: 9:00 AM"
  - Frequency badge: "Daily" / "3x/week"
  - Active/Paused toggle
- **Tap card** → Schedule Detail Page
- **Long press** → Quick actions (Edit, Pause, Delete)

### Schedule Detail Page
**Page**: `schedule_detail_page.dart`

**Header** (Colored banner):
- Schedule name
- Medication name + dose calculation:
  - "100mg of Panadol" (tablets)
  - "50mg (0.5ml / 50 Units) — BCP-157" (injection)
- Active/Paused badge
- **Next Dose Card**:
  - Time: "9:00 AM"
  - Dose instructions (comprehensive):
    - Tablets: "2 tablets" + "100mg total"
    - Injections: "1 injection" + "50mg" + "0.5ml" + "50 Units" + syringe icon
  - Status badge if already recorded
  - **Action Buttons**:
    - "Take" → Opens dose dialog
    - "Snooze" → Records snooze (hidden if taken)
    - "Skip" → Records skip (hidden if taken)
    - "Edit" → Opens dose dialog (only shows if taken)

**Dose Timeline** (Current: Vertical list, Planned: Horizontal week):

**CURRENT IMPLEMENTATION**:
- Vertical scrollable list
- Shows 7 days (3 past + today + 3 future)
- Each day displays:
  - Date header with "TODAY" badge
  - All doses for that day
  - Status badges (Taken/Snoozed/Skipped)
  - Notes and injection sites (if recorded)
  - Action buttons (Take/Snooze/Skip)

**PLANNED REDESIGN** (To Do #3):
- Horizontal week view (7 day blocks)
- Click day block → Shows doses below
- Each day block:
  - Day abbreviation (Mon, Tue, etc.)
  - Date number
  - Dot indicator if has doses
  - Selected state (highlighted)
- Selected day's doses:
  - Time + comprehensive dose info
  - Medication name, strength, method
  - For injections: syringe graphic + units
  - Status + notes + action buttons

**Schedule Details Section**:
- Dose: "2 tablets (100mg total)"
- Frequency: "Every day" / "Mon, Wed, Fri"
- Times: "9:00 AM, 9:00 PM"

---

## 5. Taking a Dose

### Trigger Points
1. **Notification** → Tap → Opens app → Schedule Detail
2. **Schedule Detail** → "Take" button
3. **Home Dashboard** → Quick take card (future)
4. **Timeline** → Date's "Take" button

### Dose Recording Flow

#### **Step 1: Open Dose Dialog**
**Trigger**: User taps "Take" (or "Edit" if already taken)

**Dialog**: `_DoseRecordDialog`

**Content**:
- **Title**: "Take Dose" / "Edit Dose"
- **Notes Field** (TextFormField):
  - Label: "Notes (optional)"
  - Placeholder: "Add any notes about this dose..."
  - Multiline (3 rows)
- **Injection Site Field** (conditional - only for injections):
  - Label: "Injection Site (optional)"
  - Placeholder: "e.g., Left arm, Right thigh..."
  - Auto-detects injection based on:
    - Medication name contains "injection"
    - Dose unit contains "syringe" or "vial"
- **Actions**:
  - "Cancel" button
  - "Delete" button (only if editing existing log)
  - "Save" button

#### **Step 2: Save Dose Log**
**Data Model**: `DoseLog`

```dart
DoseLog {
  id: String (UUID)
  scheduleId: String
  scheduleName: String
  medicationId: String
  medicationName: String
  scheduledTime: DateTime (UTC)
  actionTime: DateTime (UTC, when user recorded)
  doseValue: double
  doseUnit: String
  action: DoseAction (taken, snoozed, skipped)
  notes: String? (includes injection site if applicable)
}
```

**Save Flow**:
```dart
1. Parse notes and injection site
2. Combine: "User notes\nSite: Left arm"
3. Create/update DoseLog
4. Save to Hive box('dose_logs')
5. Update UI (refresh schedule detail)
6. Show snackbar: "Dose taken" / "Dose snoozed" / "Dose skipped"
```

**Injection Site Parsing**:
- Saved as: `notes: "My note\nSite: Left arm"`
- Displayed as:
  - Note text: "My note"
  - Location icon + "Left arm"

#### **Step 3: UI Updates**
**Schedule Detail Page**:
- Status badge appears on Next Dose card
- Timeline updates dose card with:
  - Green badge: "TAKEN"
  - Orange badge: "SNOOZED"
  - Red badge: "SKIPPED"
  - Notes displayed below
  - Injection site with location icon
  - Action buttons change:
    - Taken: Only "Edit" button
    - Snoozed/Skipped: All buttons remain

**Schedules List**:
- "Next dose" updates to next scheduled time
- Recent activity indicator (optional)

---

## 6. Advanced Features

### Edit Schedule
**Entry**: Schedule Detail → Edit button

**Flow**:
1. Navigate to `add_edit_schedule_page.dart?id={scheduleId}`
2. Load existing schedule data
3. Pre-fill all form fields
4. Edit mode: "Save Changes" button
5. On save:
   - Update schedule in Hive
   - **Cancel old notifications**
   - **Reschedule new notifications**
   - Navigate back

### Delete Schedule
**Entry**: Schedule Detail → Delete button (hamburger menu)

**Flow**:
1. Show confirmation dialog:
   - "Delete schedule?"
   - "Delete '{schedule.name}'? This will cancel its notifications."
2. On confirm:
   - **Cancel notifications first** (`ScheduleScheduler.cancelFor`)
   - Delete from Hive box
   - Delete associated dose logs (optional - TBD)
   - Navigate back to list
   - Show snackbar: "Deleted '{schedule.name}'"

### Pause/Resume Schedule
**Entry**: Schedule Detail → Toggle in header OR List → Toggle

**Flow**:
1. Update `schedule.active = !schedule.active`
2. Save to Hive
3. If paused:
   - Cancel all notifications
   - Show badge: "Paused"
4. If resumed:
   - Reschedule notifications
   - Show badge: "Active"

### Untake/Cancel Dose
**Entry**: Dose dialog → "Delete" button

**Flow**:
1. Delete DoseLog from Hive
2. Update UI (remove status badge)
3. Show snackbar: "Dose log removed"

---

## 7. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    ADD SCHEDULE FLOW                         │
└─────────────────────────────────────────────────────────────┘
                              ▼
                    ┌──────────────────┐
                    │ Schedules Page   │
                    │   (List View)    │
                    └────────┬─────────┘
                             │ Tap FAB
                             ▼
              ┌──────────────────────────────┐
              │  Add Schedule Page (Empty)   │
              │  "Select a medication" btn   │
              └─────────────┬────────────────┘
                            │ Tap button
                            ▼
            ┌────────────────────────────────────┐
            │  Select Medication Page (List)     │
            │  - All meds with full details      │
            │  - Search/filter                   │
            └────────────┬───────────────────────┘
                         │ Tap medication
                         ▼
         ┌───────────────────────────────────────────┐
         │  Add Schedule Page (Medication Selected)  │
         │  ┌─────────────────────────────────┐     │
         │  │  SUMMARY CARD (Floating)        │     │
         │  │  - Medication details           │     │
         │  │  - Live schedule summary        │     │
         │  └─────────────────────────────────┘     │
         │                                           │
         │  FORM SECTIONS:                           │
         │  1. General (name, medication card)       │
         │  2. Dose (value, unit, calculation)       │
         │  3. Times (list of times)                 │
         │  4. Frequency (mode selector + options)   │
         │  5. Range (start, end dates)              │
         │                                           │
         │  [Save Button - Always Visible]           │
         └────────────┬──────────────────────────────┘
                      │ Tap Save
                      ▼
              ┌──────────────────┐
              │  Validate Form   │
              └────────┬─────────┘
                       │ Valid ✓
                       ▼
         ┌──────────────────────────────┐
         │  Create Schedule Object      │
         │  - Generate ID               │
         │  - Auto-generate name        │
         │  - Map all fields            │
         └─────────────┬────────────────┘
                       │
                       ▼
         ┌──────────────────────────────┐
         │  Save to Hive box            │
         │  box('schedules').put(...)   │
         └─────────────┬────────────────┘
                       │
                       ▼
         ┌──────────────────────────────┐
         │  Schedule Notifications      │
         │  ScheduleScheduler.          │
         │    scheduleFor(schedule)     │
         └─────────────┬────────────────┘
                       │
                       ▼
         ┌──────────────────────────────┐
         │  Navigate Back + Snackbar    │
         │  "Schedule created"          │
         └─────────────┬────────────────┘
                       ▼
              ┌──────────────────┐
              │ Schedules Page   │
              │ (Shows new item) │
              └──────────────────┘


┌─────────────────────────────────────────────────────────────┐
│                   VIEW & TAKE DOSE FLOW                      │
└─────────────────────────────────────────────────────────────┘

    ┌──────────────────┐
    │ Notification     │ ──────────┐
    │ "Panadol - 2 tb" │           │
    └──────────────────┘           │ Tap notification
                                   │ OR tap schedule card
    ┌──────────────────┐           │
    │ Schedules List   │ ──────────┘
    │ Tap schedule →   │
    └──────────────────┘
              │
              ▼
    ┌─────────────────────────────────────┐
    │    Schedule Detail Page             │
    │                                     │
    │  [HEADER BANNER]                    │
    │  - Name, medication                 │
    │  - Dose calculation                 │
    │  - Active badge                     │
    │                                     │
    │  [NEXT DOSE CARD]                   │
    │  - Time: 9:00 AM                    │
    │  - Comprehensive dose info:         │
    │    • 2 tablets                      │
    │    • 100mg total                    │
    │    • 0.5ml (for injections)         │
    │    • 50 Units (for injections)      │
    │    • Syringe icon                   │
    │  - [Take] [Snooze] [Skip] buttons   │
    │                                     │
    │  [DOSE TIMELINE]                    │
    │  - 7 days (3 past + today + 3 fut)  │
    │  - Each dose with status            │
    │  - Notes + injection sites          │
    │                                     │
    │  [SCHEDULE DETAILS]                 │
    │  - Dose, frequency, times           │
    └─────────────┬───────────────────────┘
                  │ Tap "Take"
                  ▼
        ┌───────────────────────┐
        │  Dose Recording Dialog │
        │  - Notes field         │
        │  - Injection site      │
        │  - [Cancel] [Delete]   │
        │    [Save] buttons      │
        └─────────┬─────────────┘
                  │ Tap Save
                  ▼
        ┌───────────────────────┐
        │  Create/Update        │
        │  DoseLog object       │
        │  - scheduledTime      │
        │  - actionTime         │
        │  - action (taken)     │
        │  - notes + site       │
        └─────────┬─────────────┘
                  │
                  ▼
        ┌───────────────────────┐
        │  Save to Hive         │
        │  box('dose_logs').    │
        │    put(doseLog)       │
        └─────────┬─────────────┘
                  │
                  ▼
        ┌───────────────────────┐
        │  Update UI            │
        │  - Add status badge   │
        │  - Show notes         │
        │  - Hide snooze/skip   │
        │  - Show "Edit" only   │
        └─────────┬─────────────┘
                  │
                  ▼
        ┌───────────────────────┐
        │  Show Snackbar        │
        │  "Dose taken"         │
        └───────────────────────┘
```

---

## 8. Technical Implementation Checklist

### Files Involved

#### Domain (Models)
- ✅ `lib/src/features/schedules/domain/schedule.dart` - Schedule model
- ✅ `lib/src/features/schedules/domain/dose_log.dart` - DoseLog model
- ❌ **NEW**: `lib/src/features/schedules/domain/dose_calculator.dart` - Dose calculation service
- ❌ **NEW**: `lib/src/features/schedules/domain/calculated_dose.dart` - Calculated dose model for calendar

#### Data Layer
- ✅ `lib/src/features/schedules/data/schedule_scheduler.dart` - Notification scheduling
- ✅ `lib/src/features/schedules/data/dose_log_repository.dart` - Dose CRUD
- ✅ `lib/src/features/schedules/data/schedule_repository.dart` - Schedule CRUD (if exists)
- ❌ **NEW**: `lib/src/features/schedules/data/notification_grouping_service.dart` - Groups notifications by time
- ❌ **NEW**: `lib/src/features/schedules/data/dose_calculation_service.dart` - Calendar dose calculations

#### Presentation
- ✅ `lib/src/features/schedules/presentation/add_edit_schedule_page.dart` - Main form
- ✅ `lib/src/features/schedules/presentation/select_medication_for_schedule_page.dart` - Med picker
- ✅ `lib/src/features/schedules/presentation/schedule_detail_page.dart` - Detail view
- ✅ `lib/src/features/schedules/presentation/schedules_page.dart` - List view
- ✅ `lib/src/features/schedules/presentation/widgets/schedule_summary_card.dart` - Summary widget
- ❌ **NEW**: `lib/src/features/schedules/presentation/calendar_page.dart` - Full calendar screen

#### Widgets (Shared)
- ✅ `lib/src/widgets/summary_header_card.dart` - Reusable summary card
- ✅ `lib/src/widgets/unified_form.dart` - Form sections
- ✅ `lib/src/widgets/detail_page_scaffold.dart` - Detail page layout
- ❌ **NEW**: `lib/src/widgets/syringe_graphic.dart` - Syringe visualization (SVG/CustomPaint)
- ❌ **NEW**: `lib/src/widgets/dose_input_field.dart` - Smart dose input with mode switching
- ❌ **NEW**: `lib/src/widgets/dose_slider.dart` - Fine-tune slider for MDV

#### Calendar Widgets (NEW)
- ❌ **NEW**: `lib/src/widgets/calendar/dose_calendar_widget.dart` - Main reusable calendar widget
- ❌ **NEW**: `lib/src/widgets/calendar/calendar_day_view.dart` - Hourly day view
- ❌ **NEW**: `lib/src/widgets/calendar/calendar_week_view.dart` - 7-day week view
- ❌ **NEW**: `lib/src/widgets/calendar/calendar_month_view.dart` - Month grid view
- ❌ **NEW**: `lib/src/widgets/calendar/calendar_header.dart` - Month/year + navigation
- ❌ **NEW**: `lib/src/widgets/calendar/calendar_view_toggle.dart` - Day/Week/Month segmented control
- ❌ **NEW**: `lib/src/widgets/calendar/calendar_day_cell.dart` - Reusable day cell (month view)
- ❌ **NEW**: `lib/src/widgets/calendar/calendar_dose_block.dart` - Reusable dose block (day/week view)
- ❌ **NEW**: `lib/src/widgets/calendar/calendar_dose_indicator.dart` - Dot indicator (month view)

#### Design System Updates
- ❌ **UPDATE**: `lib/src/core/design_system.dart` - Add calendar constants:
  ```dart
  // Calendar dimensions
  const kCalendarDayHeight = 80.0;
  const kCalendarHourHeight = 60.0;
  const kCalendarDoseBlockHeight = 60.0;
  const kCalendarDoseBlockMinHeight = 40.0;
  const kCalendarDoseIndicatorSize = 6.0;
  const kCalendarWeekColumnWidth = 80.0;
  
  // Calendar colors (use existing colorScheme)
  // Status colors already defined: success, warning, error
  ```

---

### New Components Required 🚀

#### 1. DoseCalculator Service (CRITICAL)
**Priority**: HIGH  
**File**: `lib/src/features/schedules/domain/dose_calculator.dart`

**Responsibilities**:
- Convert between dose formats (tablets ↔ strength, volume ↔ units)
- Validate tablet/capsule increments
- Calculate MDV doses with 3-way conversion (strength ↔ volume ↔ units)
- Format display strings with proper units
- Handle edge cases (exceeds vial capacity, invalid increments)

**Methods Needed**:
- `calculateFromTablets()` - Tablets to strength
- `calculateFromStrength()` - Strength to tablets (with 1/4 validation)
- `calculateFromCapsules()` - Capsules to strength (whole number only)
- `calculateFromStrength_MDV()` - Strength to volume + units
- `calculateFromVolume_MDV()` - Volume to strength + units
- `calculateFromUnits_MDV()` - Units to strength + volume
- `formatMass()` - Display mcg/mg/g properly
- `formatVolume()` - Display ml properly

**Key Algorithm** (MDV):
```dart
// Given: Total vial strength, total volume, syringe type
concentration = totalStrengthMcg / totalVolumeMicroliter

// If user enters strength (e.g., 500mcg):
volumeMicroliter = strengthMcg / concentration
syringeUnits = (volumeMicroliter / 1000) * syringeType.unitsPerMl

// If user enters volume (e.g., 0.25ml):
strengthMcg = (volumeMl * 1000) * concentration
syringeUnits = volumeMl * syringeType.unitsPerMl

// If user enters units (e.g., 25U):
volumeMl = syringeUnits / syringeType.unitsPerMl
strengthMcg = (volumeMl * 1000) * concentration
```

---

#### 2. SyringeGraphic Widget (KILLER FEATURE)
**Priority**: HIGH  
**File**: `lib/src/widgets/syringe_graphic.dart`

**Purpose**: Visual syringe with fill level, scale markings, and dose indicator

**Components**:
- SVG syringe barrel (or CustomPaint)
- Fill level animation (blue liquid)
- Scale markings (0-50U for 0.5ml, 0-100U for 1ml, etc.)
- Current dose indicator line
- Tap/drag for adjustment (optional)

**Visual Design**:
```
     ═══════
     ║     ║  ← Plunger
     ║     ║
     ╔═════╗
     ║     ║ 50U ←
     ║█████║ 40U
     ║█████║ 30U
     ║█████║ 25U ← Current (filled to here)
     ║     ║ 20U
     ║     ║ 10U
     ║     ║  0U
     ╚═════╝
       ▼ Needle
```

**Props**:
- `currentUnits`: Current dose in units
- `syringeType`: Determines scale (0.3ml, 0.5ml, 1ml, etc.)
- `interactive`: Allow tap/drag adjustment
- `onUnitsChanged`: Callback when user adjusts

**Inspiration**: Reconstitution calculator syringe (already exists in app)

---

#### 3. DoseInputField Widget (SMART INPUT)
**Priority**: MEDIUM  
**File**: `lib/src/widgets/dose_input_field.dart`

**Purpose**: Unified dose input that switches between modes (tablets/strength, volume/units)

**UI Structure**:
```
┌────────────────────────────────────────┐
│ Dose                                   │
│ ┌────────────┬────────────────────┐   │
│ │  Tablets   │  Strength (mg)     │   │ ← Toggle
│ └────────────┴────────────────────┘   │
│                                        │
│ ┌──────────────────────────────────┐  │
│ │  2.5                    [+ -]    │  │ ← Input + Stepper
│ └──────────────────────────────────┘  │
│                                        │
│ Quick: [ 1/4 ] [ 1/2 ] [ 1 ] [ 2 ]    │ ← Quick buttons
│                                        │
│ ✓ 2.5 tablets × 50mg = 125mg total    │ ← Live calculation
└────────────────────────────────────────┘
```

**Props**:
- `medication`: Medication object (for strength, form, etc.)
- `initialValue`: Pre-filled dose
- `inputMode`: Current mode (tablets, strength, volume, units)
- `onDoseChanged`: Callback with DoseCalculationResult

---

#### 4. DoseSlider Widget (MDV FINE-TUNING)
**Priority**: MEDIUM  
**File**: `lib/src/widgets/dose_slider.dart`

**Purpose**: Precision slider for adjusting MDV doses (±10% with visual feedback)

**UI Structure**:
```
┌────────────────────────────────────────┐
│  Fine-Tune Dose                        │
│                                        │
│  ◄───────────●─────────────────────►  │
│         22U  25U  28U                  │
│              ▲ Current                 │
│                                        │
│  500mcg • 0.25ml • 25 Units           │
└────────────────────────────────────────┘
```

**Props**:
- `minUnits`, `maxUnits`: Range (e.g., 22.5U - 27.5U for ±10% of 25U)
- `currentUnits`: Current value
- `syringeType`: For unit calculations
- `onChanged`: Real-time updates
- `onChangeEnd`: Final value when user releases

**Features**:
- Haptic feedback on drag
- Snap to whole/half units
- Real-time calculation updates
- Min/max indicators

---

#### 5. Calendar Widget System (NEW - MAJOR COMPONENT)
**Priority**: MEDIUM-HIGH (MVP Nice-to-Have)  
**Files**: See "Calendar Widgets" section above

**Components**:
1. **DoseCalendarWidget** - Main reusable calendar
2. **CalendarDayView** - Hourly timeline with dose blocks
3. **CalendarWeekView** - 7-column week grid
4. **CalendarMonthView** - Month grid with indicators
5. **CalendarHeader** - Navigation and view toggle
6. **CalendarDoseBlock** - Individual dose display
7. **CalendarDayCell** - Day cell in month view
8. **CalendarDoseIndicator** - Dot indicators

**Key Features**:
- Three view modes (Day/Week/Month)
- Reusable across screens (full page, medication detail, schedule detail, home widget)
- Filtered views (all schedules, specific medication, specific schedule)
- Interactive dose blocks (tap to record, long-press for quick actions)
- Performance optimized (lazy loading, cached calculations)

---

#### 6. Notification Grouping Service (NEW)
**Priority**: MEDIUM  
**File**: `lib/src/features/schedules/data/notification_grouping_service.dart`

**Purpose**: Groups multiple schedules at same time into single notification

**Responsibilities**:
- Detect schedules within 1-minute window
- Create grouped notification UI
- Handle individual actions within group
- Support user preference (always group, separate, smart)

**Grouping Strategies**:
- 1 schedule → Individual notification with full details
- 2-3 schedules → Grouped with expandable individual actions
- 4+ schedules → Grouped summary + "Open app"

---

#### 7. Notification Action Handlers (NEW)
**Priority**: MEDIUM-HIGH  
**File**: `lib/src/features/schedules/data/notification_action_handler.dart`

**Purpose**: Handle notification button presses without opening app

**Actions**:
- **Take**: Record dose, dismiss notification, show toast
- **Snooze**: Reschedule +15min, record snooze, show toast
- **Skip**: Record skip, dismiss notification, show toast
- **Add Note**: Open mini dialog or fallback to app

**Background Execution**:
- Must work when app is closed
- Use background isolates for dose recording
- Update Hive database directly
- Schedule new notifications if snoozed

---

#### 8. Medication Model Updates (IF NEEDED)
**Priority**: LOW (may already exist)  
**File**: `lib/src/features/medications/domain/medication.dart`

**Fields to Verify Exist**:
```dart
// For strength-based calculations
strengthValue: double?         // e.g., 50.0
strengthUnit: String?          // e.g., "mg"
strengthPerUnit: double?       // e.g., 50mg per tablet

// For MDV
totalVolumeAfterReconstitution: double?  // e.g., 5.0 (ml)
syringeType: SyringeType?                // e.g., ml_0_5

// Reconstitution link
reconstitutionCalculationId: String?  // Link to saved calculation
```

If these don't exist, they need to be added to support dose calculations.

---

### New Components Required 🚀

#### 1. DoseCalculator Service (CRITICAL)
**Priority**: HIGH  
**File**: `lib/src/features/schedules/domain/dose_calculator.dart`

**Responsibilities**:
- Convert between dose formats (tablets ↔ strength, volume ↔ units)
- Validate tablet/capsule increments
- Calculate MDV doses with 3-way conversion (strength ↔ volume ↔ units)
- Format display strings with proper units
- Handle edge cases (exceeds vial capacity, invalid increments)

**Methods Needed**:
- `calculateFromTablets()` - Tablets to strength
- `calculateFromStrength()` - Strength to tablets (with 1/4 validation)
- `calculateFromCapsules()` - Capsules to strength (whole number only)
- `calculateFromStrength_MDV()` - Strength to volume + units
- `calculateFromVolume_MDV()` - Volume to strength + units
- `calculateFromUnits_MDV()` - Units to strength + volume
- `formatMass()` - Display mcg/mg/g properly
- `formatVolume()` - Display ml properly

**Key Algorithm** (MDV):
```dart
// Given: Total vial strength, total volume, syringe type
concentration = totalStrengthMcg / totalVolumeMicroliter

// If user enters strength (e.g., 500mcg):
volumeMicroliter = strengthMcg / concentration
syringeUnits = (volumeMicroliter / 1000) * syringeType.unitsPerMl

// If user enters volume (e.g., 0.25ml):
strengthMcg = (volumeMl * 1000) * concentration
syringeUnits = volumeMl * syringeType.unitsPerMl

// If user enters units (e.g., 25U):
volumeMl = syringeUnits / syringeType.unitsPerMl
strengthMcg = (volumeMl * 1000) * concentration
```

---

#### 2. SyringeGraphic Widget (KILLER FEATURE)
**Priority**: HIGH  
**File**: `lib/src/widgets/syringe_graphic.dart`

**Purpose**: Visual syringe with fill level, scale markings, and dose indicator

**Components**:
- SVG syringe barrel (or CustomPaint)
- Fill level animation (blue liquid)
- Scale markings (0-50U for 0.5ml, 0-100U for 1ml, etc.)
- Current dose indicator line
- Tap/drag for adjustment (optional)

**Visual Design**:
```
     ═══════
     ║     ║  ← Plunger
     ║     ║
     ╔═════╗
     ║     ║ 50U ←
     ║█████║ 40U
     ║█████║ 30U
     ║█████║ 25U ← Current (filled to here)
     ║     ║ 20U
     ║     ║ 10U
     ║     ║  0U
     ╚═════╝
       ▼ Needle
```

**Props**:
- `currentUnits`: Current dose in units
- `syringeType`: Determines scale (0.3ml, 0.5ml, 1ml, etc.)
- `interactive`: Allow tap/drag adjustment
- `onUnitsChanged`: Callback when user adjusts

**Inspiration**: Reconstitution calculator syringe (already exists in app)

---

#### 3. DoseInputField Widget (SMART INPUT)
**Priority**: MEDIUM  
**File**: `lib/src/widgets/dose_input_field.dart`

**Purpose**: Unified dose input that switches between modes (tablets/strength, volume/units)

**UI Structure**:
```
┌────────────────────────────────────────┐
│ Dose                                   │
│ ┌────────────┬────────────────────┐   │
│ │  Tablets   │  Strength (mg)     │   │ ← Toggle
│ └────────────┴────────────────────┘   │
│                                        │
│ ┌──────────────────────────────────┐  │
│ │  2.5                    [+ -]    │  │ ← Input + Stepper
│ └──────────────────────────────────┘  │
│                                        │
│ Quick: [ 1/4 ] [ 1/2 ] [ 1 ] [ 2 ]    │ ← Quick buttons
│                                        │
│ ✓ 2.5 tablets × 50mg = 125mg total    │ ← Live calculation
└────────────────────────────────────────┘
```

**Props**:
- `medication`: Medication object (for strength, form, etc.)
- `initialValue`: Pre-filled dose
- `inputMode`: Current mode (tablets, strength, volume, units)
- `onDoseChanged`: Callback with DoseCalculationResult

---

#### 4. DoseSlider Widget (MDV FINE-TUNING)
**Priority**: MEDIUM  
**File**: `lib/src/widgets/dose_slider.dart`

**Purpose**: Precision slider for adjusting MDV doses (±10% with visual feedback)

**UI Structure**:
```
┌────────────────────────────────────────┐
│  Fine-Tune Dose                        │
│                                        │
│  ◄───────────●─────────────────────►  │
│         22U  25U  28U                  │
│              ▲ Current                 │
│                                        │
│  500mcg • 0.25ml • 25 Units           │
└────────────────────────────────────────┘
```

**Props**:
- `minUnits`, `maxUnits`: Range (e.g., 22.5U - 27.5U for ±10% of 25U)
- `currentUnits`: Current value
- `syringeType`: For unit calculations
- `onChanged`: Real-time updates
- `onChangeEnd`: Final value when user releases

**Features**:
- Haptic feedback on drag
- Snap to whole/half units
- Real-time calculation updates
- Min/max indicators

---

#### 5. Medication Model Updates (IF NEEDED)
**Priority**: LOW (may already exist)  
**File**: `lib/src/features/medications/domain/medication.dart`

**Fields to Verify Exist**:
```dart
// For strength-based calculations
strengthValue: double?         // e.g., 50.0
strengthUnit: String?          // e.g., "mg"
strengthPerUnit: double?       // e.g., 50mg per tablet

// For MDV
totalVolumeAfterReconstitution: double?  // e.g., 5.0 (ml)
syringeType: SyringeType?                // e.g., ml_0_5

// Reconstitution link
reconstitutionCalculationId: String?  // Link to saved calculation
```

If these don't exist, they need to be added to support dose calculations.

---

### Implementation Order (Recommended)

**Phase 1: Foundation** (Week 1)
1. Create `DoseCalculator` service with all conversion methods
2. Write unit tests for all calculation paths
3. Add new typed dose fields to `Schedule` model (if not present)
4. Update Hive adapter
5. **NEW**: Add calendar constants to `design_system.dart`
6. **NEW**: Update `add_edit_schedule_page.dart` to auto-generate schedule name from dose

**Phase 2: Basic UI** (Week 2)
1. Create `DoseInputField` widget for tablets/capsules
2. Update `add_edit_schedule_page.dart` to use calculator
3. Test tablet/capsule mode switching
4. Add validation and error display
5. **ENFORCE**: All new widgets use design system constants (no hardcoded values)

**Phase 3: MDV Core** (Week 3)
1. Extend `DoseInputField` for MDV mode (3-way toggle)
2. Implement strength ↔ volume ↔ units conversion
3. Add real-time calculation display
4. Test with various vial configurations

**Phase 4: Visual Polish** (Week 4)
1. Create `SyringeGraphic` widget
2. Integrate with MDV dose input
3. Create `DoseSlider` for fine-tuning
4. Add animations and haptics

**Phase 5: Reconstitution Integration** (Week 5)
1. Link MDV doses to reconstitution calculations
2. Pre-fill from reconstitution data
3. Add "Recalculate" flow
4. Update when reconstitution changes

**Phase 6: Notifications** (Week 6) 🔔
1. **NEW**: Create `NotificationGroupingService`
   - Detect schedules within 1-minute window
   - Implement grouping strategies (individual, grouped, smart)
   - User preference setting
2. **NEW**: Create `NotificationActionHandler`
   - Implement background action handlers (Take/Snooze/Skip/Note)
   - Set up background isolates for database access
   - Add toast/feedback without opening app
3. Update `ScheduleScheduler` to use grouping service
4. Design notification layouts:
   - Single dose notification
   - Grouped notification (2-3 doses)
   - Summary notification (4+ doses)
5. Test notification actions (Take/Snooze/Skip work without app open)
6. Test grouped notifications with multiple schedules
7. Debug notification cancellation on delete (existing bug)

**Phase 7: Calendar System** (Week 7-8) 📅
1. **Week 7 - Core Calendar**:
   - Create `CalendarDoseBlock` widget (reusable dose block)
   - Create `CalendarDayCell` widget (month view cell)
   - Create `CalendarHeader` widget (navigation + view toggle)
   - Create `CalendarViewToggle` widget (Day/Week/Month segmented control)
   - Create `DoseCalculationService` (calculate doses for date range)
   
2. **Week 8 - Calendar Views**:
   - Create `CalendarDayView` (hourly timeline)
   - Create `CalendarWeekView` (7-column grid)
   - Create `CalendarMonthView` (month grid with dots)
   - Create `DoseCalendarWidget` (main reusable wrapper)
   - Create `CalendarPage` (full-screen calendar)
   
3. **Integration**:
   - Add calendar to navigation (bottom bar or hamburger menu)
   - Add compact calendar to medication detail screen
   - Add compact calendar to schedule detail screen
   - Add mini calendar widget to home page
   - Test all variants (full, compact, mini)
   - Performance optimization (lazy loading, caching)

**Phase 8: Testing & Bug Fixes** (Week 9)
1. End-to-end testing of all medication forms
2. Edge case validation (exceeds vial, invalid increments)
3. Performance optimization
4. Notification testing (grouped, individual, actions)
5. Calendar testing (all views, filtering, interactions)
6. Accessibility testing
7. Fix notification cancellation bug (existing)

**Phase 9: Documentation & Polish** (Week 10)
1. User documentation for dose calculations
2. Help text for MDV input
3. Tooltips for syringe visualization
4. Calendar user guide
5. Notification settings explanation
6. Loading states and error messages
7. Animations and transitions

---

### Development Timeline Summary

**Weeks 1-5**: Dose calculation system (CRITICAL PATH)  
**Week 6**: Notification enhancements (action buttons + grouping)  
**Weeks 7-8**: Calendar system (MVP nice-to-have)  
**Week 9**: Testing and bug fixes  
**Week 10**: Polish and documentation  

**Total to MVP**: ~10 weeks of focused development

**Alternative Fast-Track** (6 weeks to MVP):
- Weeks 1-3: Dose calculations (MUST HAVE)
- Week 4: Syringe graphic + slider (MUST HAVE)
- Week 5: Reconstitution integration (MUST HAVE)
- Week 6: Basic notification actions (skip calendar for v1.0)
- **Ship MVP without calendar** (add calendar in v1.1)

---

## 9. Current Status & Remaining Work

### ✅ Completed
1. Schedule data model with all frequency modes
2. Add/Edit schedule form with basic UI structure
3. Medication selection page
4. Schedule summary card (floating)
5. Notification scheduling system
6. Schedule detail page with header
7. Comprehensive dose instructions display (Next Dose card)
8. Dose recording dialog with notes + injection sites
9. Dose log storage and display
10. Recent doses section with parsed notes
11. Typed dose fields in Schedule model (doseMassMcg, doseVolumeMicroliter, etc.)

### 🔄 In Progress
1. **Timeline Redesign** (To Do #3):
   - Current: Vertical list of days
   - Planned: Horizontal week view with clickable day blocks
   - Needs: Complete refactor of timeline UI

### ❌ Not Started / Critical for MVP

#### **PHASE 1: Dose Calculation System** (HIGHEST PRIORITY - App's Core Value)
1. **DoseCalculator Service**:
   - Create calculation engine for all medication forms
   - Implement conversion algorithms (tablets ↔ strength, volume ↔ units)
   - Add validation logic (1/4 increments, whole capsules, vial capacity)
   - Write comprehensive unit tests

2. **Dose Input UI Components**:
   - Smart dose input field with mode switching (tablets vs strength)
   - Three-way input for MDV (strength vs volume vs units)
   - Quick buttons for common doses (1/4, 1/2, 1, 2 tablets)
   - Live calculation display with all values

3. **MDV Syringe Visualization**:
   - Interactive syringe graphic (SVG/CustomPaint)
   - Real-time fill level animation
   - Scale markings based on syringe type
   - Tap/drag for dose adjustment

4. **Fine-Tune Slider**:
   - Precision adjustment for MDV doses
   - ±10% range with visual feedback
   - Real-time updates to all three values
   - Haptic feedback

5. **Reconstitution Integration**:
   - Link MDV schedules to reconstitution calculations
   - Pre-fill dose from reconstitution data
   - "Recalculate" button to update
   - Sync changes between calculator and schedules

**Why This Is Critical**: This is the app's main differentiator. Users need to see exactly what to draw in their syringe with visual confirmation. Without this, the app is just another medication tracker.

#### **PHASE 2: UI Polish** (After calculations work)
1. **Notification Action Buttons**:
   - Add "Take", "Snooze", "Skip" to notifications
   - Deep link to dose recording dialog
   
2. **Home Dashboard Integration**:
   - Quick take card for next dose
   - Daily adherence summary
   
3. **Batch Dose Recording**:
   - Record multiple doses at once
   
4. **Schedule Templates**:
   - Pre-built patterns (Daily AM/PM, 3x daily, etc.)

#### **PHASE 3: Advanced Features** (Future)
1. **Adherence Analytics**:
   - Compliance percentage
   - Missed dose alerts
   - Streak tracking

2. **Calendar View**:
   - Month view with dose indicators
   - Visual schedule planning

3. **Stock Management Integration**:
   - Auto-decrement vial usage on dose recording
   - Warn when vial running low based on scheduled doses
   - Link to inventory system

---

### 🎯 MVP Definition (What's Needed for Launch)

**Must Have**:
1. ✅ Create schedules with all frequency modes
2. ✅ Select medications and link to schedules
3. ✅ Record doses with notes/injection sites
4. ❌ **Dose calculations for ALL medication forms** (tablets, capsules, injections, MDV)
5. ❌ **MDV syringe visualization with 3-way input** (strength/volume/units)
6. ❌ **Fine-tune slider for precision dosing**
7. ✅ Notifications for scheduled doses
8. ✅ View schedule details and dose history
9. ❌ Horizontal week timeline (compact, scannable)
10. ✅ Edit/delete schedules with notification management

**Should Have** (Launch Week 2):
1. Reconstitution integration (pre-fill doses)
2. Notification action buttons (Take/Snooze/Skip)
3. Home dashboard quick take
4. Schedule templates

**Could Have** (Post-Launch):
1. Adherence analytics
2. Calendar view
3. Batch dose recording
4. Stock auto-decrement on dose

---

### 📊 Effort Estimates

**Dose Calculation System**: 2-3 weeks
- DoseCalculator service: 3-4 days
- Unit tests: 2 days
- Dose input UI: 4-5 days
- MDV 3-way input: 3-4 days
- Syringe graphic: 5-7 days (complex SVG/animation)
- Fine-tune slider: 2-3 days
- Integration testing: 2-3 days

**Timeline Redesign**: 1 week
- Horizontal week layout: 2-3 days
- Day selection interaction: 1-2 days
- Responsive dose display: 2 days
- Testing: 1 day

**Total to MVP**: ~4-5 weeks of focused development

---

## 10. Key User Flows Summary

### Happy Path: Create Schedule
1. Tap "Add Schedule"
2. Select medication → Summary card appears
3. Fill dose (auto-calculated total)
4. Add time(s)
5. Select frequency
6. Tap Save
7. View in list with "Next: 9:00 AM"

### Happy Path: Take Dose
1. Notification arrives
2. Tap notification → Opens detail
3. Tap "Take" button
4. Add optional notes/injection site
5. Tap Save
6. See "TAKEN" badge + notes

### Edge Cases Handled
- Medication deleted while schedule exists → Shows name only
- Notifications fail to schedule → Log error, still save
- Edit schedule → Re-schedules all notifications
- Delete schedule → Cancels all notifications first
- Untake dose → Removes log, restores action buttons

---

## 12. Dose Calculation Examples (User Scenarios)

### Scenario 1: Tablet Medication
**Medication**: Panadol (Paracetamol) 50mg tablets

**User Journey**:
1. User selects "Panadol" medication
2. Dose section shows toggle: "Tablets" vs "Strength"
3. User selects "Tablets" mode
4. User enters "2.5" tablets (using stepper or quick buttons)
5. **Live Calculation Display**:
   ```
   ✓ 2.5 tablets × 50mg = 125mg total
   ```
6. User switches to "Strength" mode
7. User enters "150mg"
8. **Validation Error**:
   ```
   ⚠️ Dose requires 3.0 tablets (OK - valid 1/4 increment)
   ```
   OR
   ```
   ⚠️ Dose requires 2.3 tablets (not a 1/4 increment - rounded to 2.25)
   ```

**Saved to Database**:
```dart
doseValue: 2.5
doseUnit: "tablets"
doseUnitCode: "TABLET"
doseMassMcg: 125000.0  // 125mg in mcg
doseTabletQuarters: 10  // 2.5 * 4 = 10 quarters
inputModeCode: "TABLETS"
displayUnitCode: "mg"
```

---

### Scenario 2: Capsule Medication
**Medication**: Fish Oil 500mg capsules

**User Journey**:
1. User selects "Fish Oil" medication
2. Dose section shows toggle: "Capsules" vs "Strength"
3. User enters "3 capsules"
4. **Live Calculation Display**:
   ```
   ✓ 3 capsules × 500mg = 1500mg total
   ```
5. User switches to "Strength" mode
6. User enters "2000mg"
7. **Validation Error**:
   ```
   ⚠️ Dose requires 4 capsules (OK - whole number)
   ```
   OR for "1250mg":
   ```
   ⚠️ Dose requires 2.5 capsules (must be whole number - rounded to 3)
   ```

**Saved to Database**:
```dart
doseValue: 3
doseUnit: "capsules"
doseUnitCode: "CAPSULE"
doseMassMcg: 1500000.0  // 1500mg in mcg
doseCapsules: 3
inputModeCode: "CAPSULES"
```

---

### Scenario 3: Pre-Filled Injection
**Medication**: EpiPen 0.3mg pre-filled syringe

**User Journey**:
1. User selects "EpiPen" medication
2. Dose section shows: "Number of Injections"
3. User enters "1 injection" (default)
4. **Live Calculation Display**:
   ```
   ✓ 1 injection (0.3mg, 0.3ml)
   ```
5. For higher dose protocol, user enters "2 injections"
6. **Live Calculation Display**:
   ```
   ✓ 2 injections (0.6mg, 0.6ml total)
   ```

**Saved to Database**:
```dart
doseValue: 1
doseUnit: "injection"
doseUnitCode: "PREFILLED_SYRINGE"
doseMassMcg: 300.0  // 0.3mg in mcg
doseVolumeMicroliter: 300.0  // 0.3ml
doseSyringes: 1
```

---

### Scenario 4: Multi-Dose Vial (THE MAIN FEATURE)
**Medication**: BCP-157 10mg vial, reconstituted to 5ml
**Reconstitution**: Already calculated (10mg in 5ml = 2mg/ml concentration)
**Syringe**: 0.5ml (50 Unit scale, 100U/ml)

**User Journey - Method 1 (Strength Input)**:
1. User selects "BCP-157" MDV medication
2. Dose section shows 3-way toggle: "Strength" | "Volume" | "Units"
3. Reconstitution dose pre-filled: "500mcg" (from calculator)
4. **Live Display** (all three values shown):
   ```
   ┌─────────────────────────────────────┐
   │  500mcg  •  0.25ml  •  25 Units     │
   │  [Syringe: ████▁▁▁▁▁▁ 25U/50U]      │
   │  ◄─────────●──────────────────►     │
   │  22.5U    25U (current)    27.5U    │
   └─────────────────────────────────────┘
   ```
5. User adjusts slider to 27 Units
6. **Live Update** (all values recalculate):
   ```
   540mcg  •  0.27ml  •  27 Units
   [Syringe: ████▁▁▁▁▁▁ 27U/50U]
   ```

**Calculation Steps** (auto-performed):
```
Concentration = 10mg ÷ 5ml = 2mg/ml = 2000mcg/ml

Input: 500mcg
→ Volume = 500mcg ÷ 2000mcg/ml = 0.25ml
→ Units = 0.25ml × 100U/ml = 25U

Slider adjusted to 27U:
→ Volume = 27U ÷ 100U/ml = 0.27ml
→ Strength = 0.27ml × 2000mcg/ml = 540mcg
```

**User Journey - Method 2 (Volume Input)**:
1. User switches toggle to "Volume"
2. User enters "0.3ml"
3. **Live Calculation**:
   ```
   600mcg  •  0.3ml  •  30 Units
   [Syringe: ████▁▁▁▁▁▁ 30U/50U]
   ```

**User Journey - Method 3 (Units Input)**:
1. User switches toggle to "Units"
2. User enters "20U" (using number pad or tapping syringe)
3. **Live Calculation**:
   ```
   400mcg  •  0.2ml  •  20 Units
   [Syringe: ███▁▁▁▁▁▁▁ 20U/50U]
   ```

**Validation Examples**:

Exceeds vial capacity:
```
Input: 6ml
⚠️ ERROR: Dose exceeds vial capacity (5ml max)
```

Exceeds vial strength:
```
Input: 12mg
⚠️ ERROR: Dose exceeds vial strength (10mg max)
```

High dose warning:
```
Input: 4.5ml (90% of vial)
⚠️ WARNING: High dose - verify calculation
```

**Saved to Database**:
```dart
doseValue: 500  // As entered by user (mcg)
doseUnit: "mcg"
doseUnitCode: "MASS_MCG"
doseMassMcg: 500.0
doseVolumeMicroliter: 250.0  // 0.25ml
doseIU: 25.0  // Syringe units
inputModeCode: "STRENGTH"  // How user entered it
displayUnitCode: "mcg"
medicationId: "abc123"
reconstitutionCalculationId: "xyz789"  // Link to recon calc
```

---

### Scenario 5: MDV with Different Syringe Types

**Same Medication**: BCP-157 10mg vial, 5ml volume
**Different Syringes**: User changes syringe type

**0.3ml Syringe** (30 Unit scale, 100U/ml):
```
Input: 500mcg
→ 0.25ml (EXCEEDS 0.3ml max - ERROR)

Input: 200mcg
→ 0.1ml  •  10 Units
[Syringe: ███▁▁▁▁▁▁▁ 10U/30U]
```

**1ml Syringe** (100 Unit scale, 100U/ml):
```
Input: 500mcg
→ 0.25ml  •  25 Units
[Syringe: ██▁▁▁▁▁▁▁▁ 25U/100U]
```

**3ml Syringe** (300 Unit scale, 100U/ml):
```
Input: 500mcg
→ 0.25ml  •  25 Units
[Syringe: █▁▁▁▁▁▁▁▁▁ 25U/300U]
```

**Key Point**: Same dose (500mcg, 0.25ml) appears at different positions on different syringe scales. The app must visualize this correctly so users draw the right amount.

---

### Scenario 6: Reconstitution Integration

**Flow**:
1. User adds BCP-157 vial to inventory
2. User opens reconstitution calculator:
   - Vial strength: 10mg
   - Desired concentration: 2mg/ml
   - Calculator suggests: Add 5ml BAC water
3. User confirms reconstitution → Saved to medication
4. **Later**, user creates schedule for BCP-157:
   - Schedule form opens
   - Dose section auto-detects MDV with reconstitution
   - **Pre-filled dose** from reconstitution calculation appears
   - Badge shows: "📊 From Reconstitution"
   - User can adjust or keep default

**If Reconstitution Changes**:
1. User updates reconstitution (now 10ml total, 1mg/ml concentration)
2. App detects linked schedules
3. Shows dialog: "3 schedules use this medication. Update doses?"
4. User confirms → All schedules recalculate:
   - Old: 500mcg = 0.25ml (@ 2mg/ml)
   - New: 500mcg = 0.5ml (@ 1mg/ml)
   - Syringe units update automatically

---

## 13. User Experience Flow (Visual Mockup)

### MDV Dose Input Screen

```
┌─────────────────────────────────────────────┐
│ ← Add Schedule                              │
├─────────────────────────────────────────────┤
│                                             │
│  [SUMMARY CARD - BCP-157]                   │
│  10mg vial • 5ml • 2mg/ml                   │
│  Reconstituted Nov 5, 2025                  │
│                                             │
├─────────────────────────────────────────────┤
│                                             │
│  Dose                    📊 From Recon      │
│  ┌─────────┬─────────┬──────────┐          │
│  │Strength │ Volume  │  Units   │  Toggle  │
│  └─────────┴─────────┴──────────┘          │
│                                             │
│  ┌──────────────────────────────────┐      │
│  │  500              [mcg ▼] [+ -]  │      │
│  └──────────────────────────────────┘      │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │                                      │  │
│  │          ═══════                     │  │
│  │          ║     ║  ← Plunger          │  │
│  │          ║     ║                     │  │
│  │          ╔═════╗                     │  │
│  │          ║     ║ 50U ←               │  │
│  │          ║     ║ 40U                 │  │
│  │          ║█████║ 30U                 │  │
│  │          ║█████║ 25U ← You draw here │  │
│  │          ║     ║ 20U                 │  │
│  │          ║     ║ 10U                 │  │
│  │          ║     ║  0U                 │  │
│  │          ╚═════╝                     │  │
│  │            ▼                         │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  Fine-Tune Dose                             │
│  ◄─────────────●───────────────────►       │
│       22.5U   25U   27.5U                   │
│                                             │
│  ✓ 500mcg  •  0.25ml  •  25 Units          │
│                                             │
│  [ Recalculate Reconstitution ]             │
│                                             │
├─────────────────────────────────────────────┤
│                                             │
│  Times                                      │
│  ... (rest of form)                         │
│                                             │
│  [Save Schedule]                            │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 11. Next Steps (Priority Order)

### PHASE 1: Dose Calculation System (Weeks 1-3) 🎯 CRITICAL
This is the app's core value proposition. Must be completed before launch.

**Week 1: Foundation**
1. ✅ Review existing `Schedule` model - verify typed dose fields exist
2. ❌ Create `DoseCalculator` service (`dose_calculator.dart`)
   - Implement tablet/capsule calculations with increment validation
   - Implement MDV 3-way conversion (strength ↔ volume ↔ units)
   - Add formatting helpers (formatMass, formatVolume)
   - Handle edge cases (exceeds vial, invalid increments)
3. ❌ Write comprehensive unit tests (>90% coverage)
4. ❌ Document calculation algorithms with examples

**Week 2: Basic Dose Input**
1. ❌ Create `DoseInputField` widget
   - Mode toggle (Tablets vs Strength, Volume vs Units)
   - Number input with steppers
   - Quick buttons (1/4, 1/2, 1, 2 tablets)
   - Live calculation display
2. ❌ Update `add_edit_schedule_page.dart`:
   - Replace basic dose input with `DoseInputField`
   - Integrate `DoseCalculator` service
   - Handle validation errors
   - Save typed dose fields to Schedule
3. ❌ Test with tablets and capsules

**Week 3: MDV Implementation**
1. ❌ Extend `DoseInputField` for MDV:
   - 3-way toggle (Strength | Volume | Units)
   - Link to medication reconstitution data
   - Pre-fill from reconstitution calculation
   - Display all three values simultaneously
2. ❌ Create `SyringeGraphic` widget:
   - SVG/CustomPaint syringe barrel
   - Fill level animation based on units
   - Scale markings (dynamic based on syringe type)
   - Current dose indicator
3. ❌ Create `DoseSlider` widget:
   - Fine-tune range (±10%)
   - Real-time updates to all values
   - Haptic feedback
   - Snap to increments
4. ❌ Integration testing with real MDV medications

---

### PHASE 2: Timeline Redesign (Week 4) 📅
1. ❌ Design horizontal week layout
   - 7 day blocks (Mon-Sun)
   - Date numbers with "TODAY" indicator
   - Dot indicators for scheduled doses
   - Selected state styling
2. ❌ Implement day selection interaction:
   - Tap day → Show doses below
   - Scroll horizontal week strip
   - Auto-select today on load
3. ❌ Build selected day's dose display:
   - Time + comprehensive dose info
   - Status badges (Taken/Snoozed/Skipped)
   - Notes + injection sites
   - Action buttons
4. ❌ Replace vertical timeline in `schedule_detail_page.dart`
5. ❌ Test responsiveness and scrolling

---

### PHASE 3: Reconstitution Integration (Week 5) 🔗
1. ❌ Link MDV schedules to reconstitution calculations:
   - Add `reconstitutionCalculationId` to Schedule model
   - Query reconstitution on schedule load
   - Pre-fill dose from calculation
2. ❌ Add "From Reconstitution" badge and indicator
3. ❌ Create "Recalculate" button flow:
   - Opens reconstitution calculator
   - Updates medication
   - Prompts to update schedule dose
4. ❌ Handle reconstitution changes:
   - Detect linked schedules
   - Show update dialog
   - Recalculate all doses with new concentration
5. ❌ Test sync between calculator and schedules

---

### PHASE 4: Polish & Bug Fixes (Week 6) ✨
1. ❌ Test notification cancellation (existing bug):
   - Verify `ScheduleScheduler.cancelFor()` works
   - Debug why notifications persist after delete
   - Add logging for troubleshooting
2. ❌ Performance optimization:
   - Lazy load dose logs
   - Cache medication lookups
   - Optimize syringe graphic rendering
3. ❌ Error handling and validation:
   - Better error messages
   - Loading states during calculations
   - Prevent invalid dose saves
4. ❌ Accessibility:
   - Screen reader labels for syringe graphic
   - Semantic labels for dose values
   - Color contrast validation
5. ❌ User testing with real medications:
   - Test all medication forms
   - Verify calculations with medical accuracy
   - Gather feedback on syringe visualization

---

### PHASE 5: MVP Launch Preparation (Week 7) 🚀
1. ❌ End-to-end testing:
   - Full schedule flow (add → save → view → take)
   - All medication forms (tablets, capsules, injections, MDV)
   - Edge cases (invalid doses, exceeded vials, etc.)
2. ❌ Documentation:
   - User guide for dose calculations
   - Help text for MDV input
   - Tooltips for syringe visualization
3. ❌ Performance testing:
   - Load testing with 100+ schedules
   - Calculation speed benchmarks
   - UI responsiveness on low-end devices
4. ❌ Launch checklist:
   - All critical bugs fixed
   - Dose calculations validated by medical professionals
   - User testing complete with positive feedback
   - App store assets ready

---

### POST-MVP (Future Iterations)

**Notification Enhancements**:
- Add "Take", "Snooze", "Skip" action buttons
- Deep link to dose recording dialog
- Custom notification sounds per medication

**Home Dashboard**:
- Quick take card for next dose
- Daily adherence summary
- Upcoming doses list

**Advanced Features**:
- Schedule templates (Daily AM/PM, 3x daily, etc.)
- Adherence analytics (compliance %, streaks)
- Calendar month view
- Batch dose recording
- Stock auto-decrement on dose

**Integration**:
- Export dose logs (CSV, PDF)
- Sync across devices (cloud backup)
- Share schedules with caregivers
- Integration with health apps (Apple Health, Google Fit)

---

## 14. Success Metrics 📊

### Technical Metrics
- ✅ Dose calculations accurate to ±0.01ml
- ✅ Syringe graphic renders in <100ms
- ✅ Schedule form validates in real-time (<50ms delay)
- ✅ 95%+ unit test coverage on DoseCalculator
- ✅ Zero calculation errors in production

### User Experience Metrics
- ✅ Users can create MDV schedule in <2 minutes
- ✅ 90%+ of users understand syringe visualization without help
- ✅ <5% dose entry errors (validated via logs)
- ✅ Positive feedback on "killer feature" (slider + syringe)
- ✅ Users prefer this app over competitors for MDV dosing

### Business Metrics
- ✅ 80%+ of beta users use MDV functionality
- ✅ 4.5+ star rating in app stores
- ✅ <10% churn rate after 30 days
- ✅ 50%+ of users create multiple schedules
- ✅ Featured in "Best Medical Apps" lists

---

## 15. Comprehensive Test Plan 🧪

### Test Plan Structure
For each feature, test across: **Happy Path**, **Edge Cases**, **Error Handling**, **UI/UX**, **Performance**

---

### PHASE 1: Dose Calculator Service (Week 1)

#### Unit Tests (Automated)
**File**: `test/domain/dose_calculator_test.dart`

**Tablets - Happy Path**:
- ✅ 2 tablets × 50mg = 100mg ✓
- ✅ 0.25 tablets × 100mg = 25mg ✓
- ✅ 2.75 tablets × 40mg = 110mg ✓

**Tablets - Edge Cases**:
- ✅ 0.25, 0.5, 0.75, 1.0, 1.25 increments work ✓
- ❌ 0.3 tablets → Error "Must be 1/4 increment" ✓
- ❌ 2.33 tablets → Rounds to 2.25 with warning ✓

**Tablets - Strength to Tablets**:
- ✅ 100mg ÷ 50mg = 2 tablets ✓
- ❌ 115mg ÷ 50mg = 2.3 tablets → Warning ✓

**Capsules - Happy Path**:
- ✅ 3 capsules × 500mg = 1500mg ✓
- ✅ 1 capsule × 25mg = 25mg ✓

**Capsules - Edge Cases**:
- ❌ 2.5 capsules → Error "Must be whole number" ✓
- ❌ 1250mg ÷ 500mg = 2.5 capsules → Rounds to 3 ✓

**MDV - Happy Path (10mg vial, 5ml, 0.5ml syringe)**:
- ✅ 500mcg → 0.25ml, 25U ✓
- ✅ 0.25ml → 500mcg, 25U ✓
- ✅ 25U → 500mcg, 0.25ml ✓

**MDV - Edge Cases**:
- ❌ 12mg (exceeds 10mg vial) → Error ✓
- ❌ 6ml (exceeds 5ml volume) → Error ✓
- ⚠️ 9mg (90% of vial) → Warning "High dose" ✓

**MDV - Different Syringes**:
- ✅ 500mcg on 0.3ml syringe → Error (exceeds capacity) ✓
- ✅ 500mcg on 1ml syringe → 0.25ml, 25U ✓
- ✅ 500mcg on 3ml syringe → 0.25ml, 25U ✓

**Formatting Tests**:
- ✅ 500mcg → "500mcg" ✓
- ✅ 1000mcg → "1.0mg" ✓
- ✅ 1000000mcg → "1.0g" ✓
- ✅ 250ul → "0.25ml" ✓

---

### PHASE 2: Dose Input Field Widget (Week 2)

#### Manual Testing Checklist

**Tablet Mode - Basic**:
- [ ] Toggle switches between "Tablets" and "Strength"
- [ ] Number input accepts decimals (0.25, 0.5, 0.75, etc.)
- [ ] Stepper [+] [-] buttons increment by 0.25
- [ ] Quick buttons [1/4][1/2][1][2] work
- [ ] Live calculation shows: "2 tablets × 50mg = 100mg total"
- [ ] Calculation updates in real-time on input change

**Tablet Mode - Validation**:
- [ ] Entering 2.3 tablets shows warning
- [ ] Switching to strength mode with 100mg shows "2 tablets"
- [ ] Entering 115mg shows "2.3 tablets" warning
- [ ] Error message is red and clear

**Capsule Mode**:
- [ ] Only whole numbers allowed (1, 2, 3, etc.)
- [ ] Entering 2.5 shows error
- [ ] Live calculation: "3 capsules × 500mg = 1500mg total"

**MDV Mode - 3-Way Toggle**:
- [ ] Toggle shows: [Strength | Volume | Units]
- [ ] Entering 500mcg updates volume AND units
- [ ] Entering 0.25ml updates strength AND units
- [ ] Entering 25U updates strength AND volume
- [ ] All three values always visible

**Design System Compliance**:
- [ ] Uses `kSpacingM` for padding (not hardcoded)
- [ ] Uses `kBorderRadiusM` for container border
- [ ] Uses `Theme.of(context).colorScheme.primary` for toggle
- [ ] Uses `UnifiedFormField` for inputs
- [ ] NO Color(0xFF...) anywhere in code

---

### PHASE 3: Syringe Graphic Widget (Week 4)

#### Visual Testing Checklist

**Rendering**:
- [ ] Syringe displays correctly (barrel, plunger, needle)
- [ ] Scale markings match syringe type (0-50U for 0.5ml)
- [ ] Fill level animates smoothly when value changes
- [ ] Current dose indicator line is visible

**Different Syringe Types**:
- [ ] 0.3ml syringe: 0-30U scale, correct proportions
- [ ] 0.5ml syringe: 0-50U scale, correct proportions
- [ ] 1ml syringe: 0-100U scale, correct proportions
- [ ] 3ml syringe: 0-300U scale, larger barrel
- [ ] 5ml syringe: 0-500U scale, larger barrel

**Fill Levels**:
- [ ] 0U: Empty (no blue)
- [ ] 25U (on 50U syringe): Filled to 50%
- [ ] 50U (on 50U syringe): Filled to 100%
- [ ] 10U (on 100U syringe): Filled to 10%

**Performance**:
- [ ] Renders in <100ms on device
- [ ] Animation is smooth (60fps)
- [ ] No jank when updating rapidly (slider drag)

**Accessibility**:
- [ ] Screen reader announces "25 Units of 50"
- [ ] Semantic labels present
- [ ] Color contrast sufficient (blue fill on white)

---

### PHASE 4: Add/Edit Schedule Integration (Weeks 2-3)

#### End-to-End Testing

**Schedule Name Auto-Generation**:
- [ ] Selecting medication shows empty name field
- [ ] Entering "2" tablets updates name to "2 tablets - [Med]"
- [ ] Entering "500mcg" updates name to "500mcg - [Med]"
- [ ] User can override and type custom name
- [ ] Custom name persists after dose changes
- [ ] Switching medications updates med name in auto-gen

**Tablets Schedule**:
- [ ] Select tablet medication (e.g., Panadol 50mg)
- [ ] Enter 2 tablets
- [ ] See "2 tablets × 50mg = 100mg total"
- [ ] Add time: 9:00 AM
- [ ] Save schedule
- [ ] Check Hive: `doseMassMcg = 100000`, `doseTabletQuarters = 8`
- [ ] Name saved as "2 tablets - Panadol"

**MDV Schedule**:
- [ ] Select MDV (BCP-157 10mg, 5ml reconstituted)
- [ ] Enter 500mcg (strength mode)
- [ ] See "500mcg • 0.25ml • 25 Units"
- [ ] Syringe graphic shows 25U fill
- [ ] Adjust slider to 27U
- [ ] See "540mcg • 0.27ml • 27 Units" update
- [ ] Save schedule
- [ ] Check Hive: `doseMassMcg = 540`, `doseVolumeMicroliter = 270`, `doseIU = 27`
- [ ] Name saved as "540mcg - BCP-157"

**Design System Validation**:
- [ ] Open `add_edit_schedule_page.dart`
- [ ] Search for `EdgeInsets.all(12)` → Should be 0 results
- [ ] Search for `BorderRadius.circular(8)` → Should be 0 results
- [ ] Search for `Color(0xFF` → Should be 0 results
- [ ] All spacing uses `kSpacing*`
- [ ] All radii use `kBorderRadius*`
- [ ] All colors use `Theme.of(context).colorScheme.*`

---

### PHASE 5: Notifications (Week 6)

#### Notification Testing

**Single Schedule Notification**:
- [ ] Create schedule for 9:00 AM
- [ ] Wait for notification (or set time to 1 min ahead)
- [ ] Notification shows: Title = "500mcg - BCP-157"
- [ ] Body shows: "Draw 0.25ml (25 Units) at 9:00 AM"
- [ ] Action buttons visible: [Take][Snooze][Skip][Note]

**Notification Actions (App Closed)**:
- [ ] Close app completely
- [ ] Tap "Take" on notification
- [ ] Notification dismisses
- [ ] Toast shows: "Dose taken"
- [ ] Reopen app → Dose log exists with action=taken
- [ ] Schedule detail shows "✓ TAKEN" badge

**Grouped Notification (2-3 schedules)**:
- [ ] Create 3 schedules all at 9:00 AM
- [ ] Notification shows: "3 Medications Due - 9:00 AM"
- [ ] Body lists all 3 doses
- [ ] Expand notification → Individual checkboxes
- [ ] Tap checkmark on BCP-157 → Marks taken
- [ ] Other doses remain pending

**Grouped Notification (4+ schedules)**:
- [ ] Create 5 schedules all at 9:00 AM
- [ ] Notification shows: "5 Medications Due - 9:00 AM"
- [ ] Body: "Tap to view details"
- [ ] No individual actions (too many)
- [ ] [Open App] button works

**Notification Cancellation**:
- [ ] Create schedule
- [ ] Verify notification scheduled (check logs)
- [ ] Delete schedule
- [ ] Verify notification cancelled (check logs)
- [ ] Notification does NOT appear at scheduled time

---

### PHASE 6: Calendar System (Weeks 7-8)

#### Calendar Day View

**Layout**:
- [ ] Hourly grid shows 6 AM - 11 PM
- [ ] Current time indicator (red line) visible
- [ ] Auto-scrolls to current hour on load
- [ ] Swipe left → Previous day
- [ ] Swipe right → Next day

**Dose Blocks**:
- [ ] Dose at 9:00 AM appears in 9 AM hour
- [ ] Block shows: "500mcg - BCP-157", "0.25ml / 25 Units"
- [ ] Not taken: Blue background, [Take][Snooze][Skip] buttons
- [ ] Taken: Green background, "✓ TAKEN 9:03 AM"
- [ ] Overdue: Red background, pulsing animation
- [ ] Multiple doses at same time: Stacked vertically

**Interactions**:
- [ ] Tap dose block → Opens detail dialog
- [ ] Long-press → Quick actions menu
- [ ] Tap [Take] → Records dose, updates UI
- [ ] Empty day shows: "No doses scheduled"

#### Calendar Week View

**Layout**:
- [ ] 7 columns (Mon-Sun) visible
- [ ] Hourly rows (6 AM, 9 AM, 12 PM, etc.)
- [ ] Current day highlighted
- [ ] Swipe left/right → Previous/next week

**Dose Blocks (Compact)**:
- [ ] Small colored rectangles (40x40px)
- [ ] Shows initials: "BCP", "PAN", "VIT"
- [ ] Badge overlay: ✓ (taken), ! (overdue)
- [ ] Tap block → Opens detail dialog
- [ ] Tap day header → Switches to day view

#### Calendar Month View

**Layout**:
- [ ] 6 weeks grid (all dates visible)
- [ ] Current day: Circle border, highlighted
- [ ] Dates outside month: Gray, opacity 0.5
- [ ] Swipe left/right → Previous/next month

**Dose Indicators**:
- [ ] 1 dose: 1 colored dot (6px)
- [ ] 3 doses: 3 colored dots
- [ ] 6+ doses: 5 dots + "+2" text
- [ ] All taken: Green dots
- [ ] Pending: Blue dots
- [ ] Overdue: Red dots

**Interactions**:
- [ ] Tap date → Switches to day view
- [ ] Tap date with doses → Shows popover with list
- [ ] Double-tap → Day view + scroll to first dose

#### Calendar Reusable Widget

**Medication Detail (Compact)**:
- [ ] Embeds in medication detail page
- [ ] Height: 300-400px
- [ ] Shows only this medication's doses
- [ ] Week view by default
- [ ] "View Full Calendar" button → Opens full page

**Schedule Detail (Compact)**:
- [ ] Embeds in schedule detail page
- [ ] Shows only this schedule's doses
- [ ] Color-coded by status
- [ ] Stats: "12 of 14 taken this week (86%)"

**Home Widget (Mini)**:
- [ ] Embeds in home page
- [ ] Height: 150-200px
- [ ] Today's doses only
- [ ] Horizontal timeline
- [ ] Next dose highlighted with countdown

---

### PHASE 7: Reconstitution Integration (Week 5)

**Pre-Fill from Reconstitution**:
- [ ] Add BCP-157 vial to inventory
- [ ] Open reconstitution calculator
- [ ] Calculate: 10mg in 5ml = 2mg/ml
- [ ] Confirm → Saves to medication
- [ ] Create schedule for BCP-157
- [ ] Dose field auto-fills with reconstitution dose
- [ ] Badge shows: "📊 From Reconstitution"

**Update on Reconstitution Change**:
- [ ] Update reconstitution: 10mg in 10ml (1mg/ml)
- [ ] Dialog: "3 schedules use this medication. Update?"
- [ ] Confirm → All schedules recalculate
- [ ] Old: 500mcg = 0.25ml
- [ ] New: 500mcg = 0.5ml
- [ ] Verify all schedules updated

**Recalculate Button**:
- [ ] In schedule form, tap "Recalculate"
- [ ] Opens reconstitution calculator
- [ ] Make changes, save
- [ ] Returns to schedule form
- [ ] Dose updates automatically

---

### PHASE 8: Bug Fixes & Polish (Week 9)

**Notification Cancellation Bug**:
- [ ] Create schedule
- [ ] Wait 1 minute (notification scheduled)
- [ ] Delete schedule
- [ ] Check logs: `ScheduleScheduler.cancelFor()` called
- [ ] Check notification service: Notification cancelled
- [ ] Verify notification does NOT appear
- [ ] If bug persists: Debug `cancelFor()` method

**Performance**:
- [ ] Load app with 100+ schedules
- [ ] Navigate to schedules list: <500ms load time
- [ ] Open add schedule: <200ms
- [ ] Dose calculation: <50ms response
- [ ] Syringe render: <100ms
- [ ] Calendar month view: <300ms load
- [ ] No frame drops during scrolling

**Error Handling**:
- [ ] Enter invalid dose → Clear error message
- [ ] Exceeds vial capacity → Shows error, blocks save
- [ ] Network timeout (if using API) → Graceful fallback
- [ ] Database error → User-friendly message

**Accessibility**:
- [ ] All buttons have semantic labels
- [ ] Screen reader navigates forms correctly
- [ ] Color contrast meets WCAG AA (4.5:1)
- [ ] Font sizes respect system settings
- [ ] Tap targets ≥48×48 dp

---

### Final MVP Test (Week 10)

#### Complete User Journey

**Scenario**: User takes BCP-157 injection daily

1. **Add Medication**:
   - [ ] Create BCP-157 10mg MDV
   - [ ] Reconstitute to 5ml (2mg/ml)
   - [ ] Save with 0.5ml syringe

2. **Create Schedule**:
   - [ ] Open add schedule
   - [ ] Select BCP-157
   - [ ] Dose pre-fills: 500mcg
   - [ ] See syringe: 25U on 50U scale
   - [ ] Adjust slider: 27U → Updates to 540mcg
   - [ ] Name auto-generated: "540mcg - BCP-157"
   - [ ] Add time: 9:00 AM
   - [ ] Frequency: Every day
   - [ ] Save

3. **Receive Notification**:
   - [ ] Notification arrives at 9:00 AM
   - [ ] Shows: "540mcg - BCP-157"
   - [ ] Body: "Draw 0.27ml (27 Units) at 9:00 AM"
   - [ ] Tap [Take] → Records dose

4. **View Schedule**:
   - [ ] Open schedule detail
   - [ ] Next dose card shows comprehensive info
   - [ ] Calendar shows today's dose as "✓ TAKEN"
   - [ ] Switch to week view → See full week
   - [ ] Switch to month view → See month with dots

5. **Verify Data**:
   - [ ] Dose log exists in Hive
   - [ ] Schedule still active
   - [ ] Next notification scheduled for tomorrow 9 AM

**Success Criteria**:
- ✅ All steps complete without errors
- ✅ Dose accurately calculated and visualized
- ✅ Notification works without opening app
- ✅ Calendar shows correct dose status
- ✅ User can complete journey in <5 minutes

---

### Regression Test Suite (Before Each Release)

**Core Functions** (30 min):
- [ ] Create schedule (tablets, capsules, MDV)
- [ ] Record dose (Take, Snooze, Skip)
- [ ] Edit schedule
- [ ] Delete schedule
- [ ] View calendar (Day, Week, Month)
- [ ] Notification actions work

**Edge Cases** (15 min):
- [ ] Invalid tablet increments (2.33 → warning)
- [ ] Exceeds vial capacity → error
- [ ] Multiple schedules at same time → grouped
- [ ] Reconstitution update → schedules update

**Design System** (10 min):
- [ ] No hardcoded spacing values
- [ ] No hardcoded colors
- [ ] All widgets use design system
- [ ] Consistent UI across screens

---

## 16. Agent Instructions (CRITICAL - READ BEFORE EVERY TASK)

### Before Starting ANY Implementation:

1. **ALWAYS** open and read `@/docs/SCHEDULE_FLOW_PLAN.md`
2. **VERIFY** the current phase and task from the plan
3. **CHECK** the test plan for acceptance criteria
4. **ENSURE** design system compliance (no hardcoded values)

### During Implementation:

- ✅ Reference plan for requirements
- ✅ Follow exact file structure from plan
- ✅ Use specified widget/service names
- ✅ Implement all methods listed in plan
- ✅ Use design system constants (`kSpacing*`, `kBorderRadius*`, theme colors)
- ❌ DO NOT deviate from plan without discussing
- ❌ DO NOT hardcode spacing, colors, radii
- ❌ DO NOT skip validation/error handling

### After Implementation:

1. Run relevant tests from test plan
2. Check design system compliance
3. Update plan with ✅ checkmarks
4. Document any deviations or issues
5. Move to next task in sequence

### If Stuck or Confused:

1. Re-read the relevant section in `SCHEDULE_FLOW_PLAN.md`
2. Check similar implementations in codebase
3. Review design system for correct constants
4. Ask for clarification if requirements unclear

**This plan is the source of truth. Follow it religiously.**

---

## END OF PLAN

### 🎯 Core Features (MUST HAVE for MVP)
1. **Dose Calculation System** - Tablets, capsules, injections, MDV with 3-way conversion
2. **Syringe Visualization** - Interactive graphic showing exact dose to draw
3. **Fine-Tune Slider** - Precision adjustments for MDV (±10%)
4. **Auto-Generated Schedule Names** - "{DoseAmount} - {MedicationName}" (user editable)
5. **Reconstitution Integration** - Pre-fill doses from reconstitution calculations
6. **Design System Compliance** - ALL widgets use constants from design_system.dart

### 🔔 Notification Enhancements (MVP Nice-to-Have)
1. **Grouped Notifications** - Multiple schedules at same time → single notification
2. **Action Buttons** - Take/Snooze/Skip/Note without opening app
3. **Smart Grouping** - 1 = individual, 2-3 = grouped expandable, 4+ = summary
4. **Background Processing** - Actions work when app closed

### 📅 Calendar System (MVP Nice-to-Have, or v1.1)
1. **Three View Modes** - Day (hourly), Week (7-column), Month (grid with dots)
2. **Reusable Widget** - Full page, compact (medication/schedule detail), mini (home)
3. **Interactive Dose Blocks** - Tap to record, long-press for quick actions
4. **Filtered Views** - All schedules, specific medication, specific schedule
5. **Outlook-Style UX** - Professional calendar experience

### 🎨 Design System Rules (ENFORCED)
- ❌ NO `EdgeInsets.all(12)` → ✅ `EdgeInsets.all(kSpacingM)`
- ❌ NO `BorderRadius.circular(8)` → ✅ `BorderRadius.circular(kBorderRadiusM)`
- ❌ NO `Color(0xFF...)` → ✅ `Theme.of(context).colorScheme.primary`
- ❌ NO inline decorations → ✅ Extract to reusable widgets
- ✅ ALL form fields use `UnifiedFormField`
- ✅ ALL sections use `UnifiedFormSection`
- ✅ ALL calendar widgets use calendar constants

### 📊 Development Timeline
- **Fast-Track MVP** (6 weeks): Dose calculations + syringe + reconstitution + basic notifications
- **Full MVP** (10 weeks): + notification grouping + full calendar system
- **Recommended**: Fast-track to ship core value (MDV dosing), add calendar in v1.1

### 🚀 Killer Features (What Makes This App Special)
1. **MDV Syringe Visualization** - Users see exactly what to draw (0.25ml = 25U on 0.5ml syringe)
2. **3-Way Dose Input** - Enter strength, volume, OR units → all values update
3. **Fine-Tune Slider** - Micro-adjustments with real-time visual feedback
4. **Reconstitution Integration** - Seamless flow from reconstitution → scheduling → dosing
5. **Professional Calendar** - Outlook-quality scheduling experience (if included)

---

## END OF PLAN
