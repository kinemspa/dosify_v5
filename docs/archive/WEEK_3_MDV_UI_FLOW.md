# Week 3: MDV Integration - Visual Summary

## UI Flow: Multi-Dose Vial (MDV) Input

### 1. Mode Toggle (3-Way)
```
┌─────────────────────────────────────────────┐
│  [Strength]  [Volume]  [Units]              │
│   Selected    Normal   Normal               │
└─────────────────────────────────────────────┘
```

### 2. Input Row with Steppers
```
┌─────────────────────────────────────────────┐
│  [-]    [ 500 ]    [+]                      │
│        e.g., 500                            │
└─────────────────────────────────────────────┘
```

### 3. Syringe Graphic (Visual Feedback)
```
┌─────────────────────────────────────────────┐
│  0───────────────|25|────────────────30     │
│  │███████████████████░░░░░░░░░░░│           │
│  0ml                          0.3ml         │
└─────────────────────────────────────────────┘
                  ↑ 25 units filled
```

### 4. 3-Value Display (Always Visible)
```
┌─────────────────────────────────────────────┐
│    500mcg   •   0.25ml   •   25.0 Units    │
│    ^BOLD        normal       normal         │
│  (active)                                   │
└─────────────────────────────────────────────┘
```

### 5. Result Display (Standard)
```
┌─────────────────────────────────────────────┐
│  500mcg (0.25ml / 25.0U)                    │
│  ✓ Success                                  │
└─────────────────────────────────────────────┘
```

## Interaction Modes

### Mode 1: Input Strength (mcg/mg)
**User enters**: 500mcg  
**System calculates**:
- Volume: 500 / 2000 × 1000 = 0.25ml
- Units: 0.25 × 100 = 25 units

### Mode 2: Input Volume (ml)
**User enters**: 0.25ml  
**System calculates**:
- Strength: 0.25 / 1.0 × 2000 = 500mcg
- Units: 0.25 × 100 = 25 units

### Mode 3: Input Units (U)
**User enters**: 25 units  
**System calculates**:
- Volume: 25 / 100 = 0.25ml
- Strength: 0.25 / 1.0 × 2000 = 500mcg

## Syringe Types Supported

| Syringe | Total Volume | Total Units | Units/ml |
|---------|--------------|-------------|----------|
| 0.3ml   | 0.3ml        | 30 U        | 100 U/ml |
| 0.5ml   | 0.5ml        | 50 U        | 100 U/ml |
| 1.0ml   | 1.0ml        | 100 U       | 100 U/ml |
| 3.0ml   | 3.0ml        | 300 U       | 100 U/ml |
| 5.0ml   | 5.0ml        | 500 U       | 100 U/ml |
| 10.0ml  | 10.0ml       | 1000 U      | 100 U/ml |

## Example Calculation Flow

### Scenario: 2mg vial in 1ml, using 0.3ml (30 unit) syringe

```
Vial Configuration:
├─ Total Strength: 2000mcg (2mg)
├─ Total Volume: 1000µL (1ml)
└─ Concentration: 2mcg/µL

Syringe Configuration:
├─ Type: 0.3ml (30 unit)
├─ Max Volume: 0.3ml (300µL)
├─ Max Units: 30 U
└─ Units per ml: 100 U/ml

Input: 500mcg (Strength Mode)
├─ Calculate Volume: 500 / 2000 × 1000 = 250µL (0.25ml)
├─ Calculate Units: 0.25 × 100 = 25 U
└─ Validate: 25 U < 30 U max ✓

Output:
├─ Display: "500mcg (0.25ml / 25.0U)"
├─ Syringe: Fill to 25 units (83% full)
└─ 3-Value: "500mcg • 0.25ml • 25.0 Units"
```

## State Management

```
DoseInputFieldState
├─ _mdvMode: MdvInputMode
│   ├─ strength (default)
│   ├─ volume
│   └─ units
├─ _controller: TextEditingController
│   └─ Current input value
└─ _result: DoseCalculationResult?
    ├─ doseMassMcg: 500
    ├─ doseVolumeMicroliter: 250
    └─ syringeUnits: 25
```

## Widget Tree

```
DoseInputField
├─ Column
│   ├─ MdvModeToggle (3 buttons)
│   │   ├─ [Strength] - _mdvMode == strength
│   │   ├─ [Volume]   - _mdvMode == volume
│   │   └─ [Units]    - _mdvMode == units
│   │
│   ├─ InputRow (with steppers)
│   │   ├─ [-] IconButton (decrement)
│   │   ├─ TextField (value input)
│   │   └─ [+] IconButton (increment)
│   │
│   ├─ SyringeGraphic (if MDV + result available)
│   │   └─ WhiteSyringeGauge
│   │       ├─ totalUnits: syringeType.maxUnits
│   │       ├─ fillUnits: result.syringeUnits
│   │       └─ interactive: false (Week 4: true)
│   │
│   ├─ MdvThreeValueDisplay (if MDV + result available)
│   │   └─ Row (with bullets)
│   │       ├─ "500mcg" (bold if active)
│   │       ├─ "•"
│   │       ├─ "0.25ml" (bold if active)
│   │       ├─ "•"
│   │       └─ "25.0 Units" (bold if active)
│   │
│   └─ ResultDisplay (standard)
│       └─ Container (styled card)
│           └─ "500mcg (0.25ml / 25.0U)"
```

## Integration Points

### 1. From Reconstitution Calculator
```dart
// User reconstitutes vial: 2mg in 1ml
// Calculator passes to DoseInputField:
DoseInputField(
  medicationForm: MedicationForm.multiDoseVial,
  totalVialStrengthMcg: 2000,
  totalVialVolumeMicroliter: 1000,
  syringeType: SyringeType.ml_0_3,
  initialStrengthMcg: 500, // Pre-filled from last dose
  // ...
)
```

### 2. To Schedule Creation
```dart
// User confirms dose
onDoseChanged: (result) {
  // Save to schedule:
  schedule.prescribedDoseStrengthMcg = result.doseMassMcg;
  schedule.prescribedDoseVolumeMicroliter = result.doseVolumeMicroliter;
  schedule.prescribedSyringeUnits = result.syringeUnits;
}
```

### 3. To Dose Logging
```dart
// User logs dose
onLogDose: () {
  doseLog.actualDoseStrengthMcg = result.doseMassMcg;
  doseLog.actualDoseVolumeMicroliter = result.doseVolumeMicroliter;
  doseLog.actualSyringeUnits = result.syringeUnits;
}
```

## Week 4 Preview: Fine-Tuning

### Interactive Syringe Drag
```
Current (Week 3):
  Syringe graphic is display-only
  User adjusts via [-]/[+] buttons or text input

Week 4:
  Syringe graphic becomes interactive
  User can drag to adjust (±10%)
  Real-time 3-value update
  
  0───────────|●|─────────30
  │███████████████░░░░░░░│
           ↑ Drag here
```

### Adjustment Flow
1. User drags syringe marker
2. Calculate new units from drag position
3. Recalculate strength + volume from new units
4. Update all three displays in real-time
5. Call `onDoseChanged` with updated result

## Design System Usage

### Spacing
- `kFieldGroupSpacing` - Between mode toggle and input
- `kCardInnerSpacing` - Between input and syringe
- `kButtonSpacing` - Between mode buttons

### Border Radius
- `kBorderRadiusMedium` - Mode buttons, containers
- `kBorderRadiusSmall` - Stepper buttons

### Colors
- `Theme.of(context).colorScheme.primary` - Active mode
- `Theme.of(context).colorScheme.primaryContainer` - Active button bg
- `Theme.of(context).colorScheme.surfaceContainerHighest` - 3-value display bg
- `Theme.of(context).colorScheme.outlineVariant` - Borders

### Typography
- `bodyTextStyle(context)` - Value display
- `buttonTextStyle(context)` - Mode buttons
- `kFontWeightBold` - Active value
- `kFontWeightMedium` - Inactive values

---

**Status**: Week 3 Complete ✅  
**Next**: Week 4 - Interactive Fine-Tuning
