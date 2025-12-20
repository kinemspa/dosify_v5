# MDV Reconstitution and Inventory Management Enhancement Specification

## Overview
This document outlines the comprehensive enhancement of the Multi-Dose Vial (MDV) reconstitution calculator and inventory management system for Dosifi v5.

## Implementation Phases

### Phase 1: Reconstitution Calculator Fixes (Immediate)
**Priority: HIGH | Estimated Time: 2-3 hours**

#### 1.1 Syringe Slider Constraint Snackbar
- **Issue**: Increment buttons don't show snackbar when hitting constraints
- **Solution**: Add constraint check and snackbar trigger to button onPressed handlers
- **Files**: `reconstitution_calculator_widget.dart`

#### 1.2 Dynamic Vial Volume Updates
- **Current**: Vial volume only updates when calculator is open
- **Required**: Real-time updates from sliders, options, and steppers
- **Solution**: Update vial volume field on every `_selectedUnits` change
- **Files**: `reconstitution_calculator_widget.dart`

#### 1.3 Vial Volume Precision
- **Current**: Variable decimal places
- **Required**: Always 2 decimal places
- **Solution**: Use `.toStringAsFixed(2)` consistently
- **Files**: `mdv_volume_reconstitution_section.dart`

#### 1.4 Keep Summary Visible After Save
- **Current**: Summary hidden when saved
- **Required**: Summary stays visible
- **Solution**: Don't switch `_showCalculator` to false, show both summary and close button
- **Files**: `mdv_volume_reconstitution_section.dart`

#### 1.5 Allow Vial Volume Editing on Saved Recon
- **Current**: Field locked when reconstitution saved
- **Required**: Always editable, show warning if outside constraints
- **Solution**: Remove `isLocked` check, add constraint validation
- **Files**: `mdv_volume_reconstitution_section.dart`

###Phase 2: MDV Dynamic Summary Card (Medium Priority)
**Priority: MEDIUM | Estimated Time: 4-6 hours**

#### 2.1 Component Structure
```dart
class MdvDynamicSummaryCard extends StatelessWidget {
  // Display at top of medication editor
  // Shows current active vial status
}
```

#### 2.2 Content Requirements
- **Medication Name**: Large, prominent
- **Strength per Vial**: e.g., "10 mg per vial"
- **Active Vial Status**: "Active 10 mg Vial Reconstituted at 5 mL"
- **Vial Inventory**: "2/5 Vials in Stock" or "3 Backup Vials Available"
- **Remove**: "Draw X U" row (belongs in calculator)

#### 2.3 Visual Design
- Gradient background (primary color)
- Clear hierarchy (medication name biggest)
- Status indicators (reconstituted, expiring soon, low stock)
- Compact but informative

### Phase 3: Inventory Management Expansion (High Priority)
**Priority: HIGH | Estimated Time: 8-12 hours**

#### 3.1 Active Vial Tracking
New fields required:
- `activeVialReconstitutedDate`: DateTime?
- `activeVialExpiryDate`: DateTime?
- `activeVialVolume`: double? (current volume remaining)
- `activeVialLowStockThreshold`: double? (alert when below)
- `activeVialStorageLocation`: String?
- `activeVialStorageConditions`: String? (e.g., "Refrigerate 2-8°C")

#### 3.2 Stock Vials Tracking
New fields required:
- `stockVialsCount`: int (total unopened vials)
- `stockVialsLowStockThreshold`: int (alert when below)
- `stockVialsExpiryDate`: DateTime? (earliest expiry)
- `stockVialsStorageLocation`: String?
- `stockVialsStorageConditions`: String?

#### 3.3 Inventory Card Redesign
**Active Vial Section:**
- Volume Remaining: X.XX mL
- Reconstituted: [Date]
- Expires: [Date] (with warning if < 7 days)
- Low Stock Alert: [Threshold] mL
- Storage: [Location] | [Conditions]

**Stock Vials Section:**
- Unopened Vials: X
- Low Stock Alert: [Threshold] vials
- Next Expiry: [Date]
- Storage: [Location] | [Conditions]

### Phase 4: Database Schema Updates
**Priority: CRITICAL | Estimated Time: 3-4 hours**

#### 4.1 Medication Model Updates
```dart
// Add to Medication model
@HiveField(XX) DateTime? activeVialReconstitutedDate;
@HiveField(XX) DateTime? activeVialExpiryDate;
@HiveField(XX) double? activeVialVolume;
@HiveField(XX) double? activeVialLowStockThreshold;
@HiveField(XX) String? activeVialStorageLocation;
@HiveField(XX) String? activeVialStorageConditions;

@HiveField(XX) int? stockVialsCount;
@HiveField(XX) int? stockVialsLowStockThreshold;
@HiveField(XX) DateTime? stockVialsExpiryDate;
@HiveField(XX) String? stockVialsStorageLocation;
@HiveField(XX) String? stockVialsStorageConditions;
```

#### 4.2 Migration Strategy
1. Add new fields with nullable types
2. Run `build_runner` to regenerate type adapters
3. Existing data remains valid (nulls for new fields)
4. No data loss risk

#### 4.3 Files to Update
- `lib/src/features/medications/domain/medication.dart`
- Run: `flutter packages pub run build_runner build --delete-conflicting-outputs`

## Implementation Order

### Sprint 1 (Day 1-2): Critical Fixes
1. ✅ Fix syringe slider snackbar
2. ✅ Dynamic vial volume updates
3. ✅ Vial volume precision (2 decimals)
4. ✅ Keep summary visible
5. ✅ Allow vial volume editing

### Sprint 2 (Day 3-4): Database & Model
1. ✅ Update Medication model with new fields
2. ✅ Regenerate Hive adapters
3. ✅ Test data persistence
4. ✅ Create migration tests

### Sprint 3 (Day 5-6): UI Components
1. ✅ Create MDV Dynamic Summary Card
2. ✅ Update Inventory Card layout
3. ✅ Add storage fields UI
4. ✅ Add expiry date pickers

### Sprint 4 (Day 7-8): Integration & Testing
1. ✅ Integrate all components
2. ✅ Add validation logic
3. ✅ Test constraint warnings
4. ✅ Test low stock alerts
5. ✅ End-to-end testing

## Testing Checklist

### Unit Tests
- [ ] Vial volume constraint validation
- [ ] Active vial expiry calculations
- [ ] Low stock threshold triggers
- [ ] Storage condition validation

### Integration Tests
- [ ] Reconstitution save flow
- [ ] Vial inventory updates
- [ ] Expiry date warnings
- [ ] Stock depletion scenarios

### UI Tests
- [ ] Summary card display
- [ ] Constraint snackbars
- [ ] Inventory card layout
- [ ] Storage fields input

## Risk Assessment

### High Risk
- **Database migration**: Field additions require careful testing
- **Data consistency**: Active vial tracking must stay in sync

### Medium Risk
- **UI complexity**: Many new fields to display elegantly
- **Validation logic**: Complex constraints between fields

### Low Risk
- **Snackbar fixes**: Simple UI updates
- **Dynamic updates**: State management already in place

## Success Criteria

1. ✅ All constraint violations show snackbars
2. ✅ Vial volume updates in real-time
3. ✅ Summary card always visible when saved
4. ✅ New MDV summary card provides clear overview
5. ✅ Inventory tracking comprehensive and intuitive
6. ✅ No data loss during migration
7. ✅ All tests pass
8. ✅ Performance remains acceptable

## Notes
- Maintain backward compatibility
- All new fields nullable for gradual adoption
- Focus on user experience and clarity
- Prioritize data integrity over feature completeness

## Files Affected

### Core Files
- `lib/src/features/medications/domain/medication.dart`
- `lib/src/features/medications/presentation/reconstitution_calculator_widget.dart`
- `lib/src/features/medications/presentation/sections/mdv_volume_reconstitution_section.dart`

### New Files
- `lib/src/features/medications/presentation/widgets/mdv_dynamic_summary_card.dart`
- `lib/src/features/medications/presentation/sections/mdv_inventory_section.dart` (refactor)

### Test Files
- `test/features/medications/domain/medication_test.dart`
- `test/features/medications/presentation/reconstitution_calculator_test.dart`

## Conclusion
This is a significant enhancement requiring careful, phased implementation. The specification provides clear milestones and testing criteria to ensure quality delivery.
