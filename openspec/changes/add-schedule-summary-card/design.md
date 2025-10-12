# Design: Add Schedule Summary Card

## Context

The Add/Edit Schedule screen currently lacks the floating summary card pattern used successfully in Add Medication screens. Users need to see medication details and schedule configuration at a glance while filling out the form. The existing `SummaryHeaderCard` widget is already implemented and proven, making this primarily an integration task.

**Stakeholders**: End users creating/editing schedules  
**Constraints**:
- Must maintain consistency with existing medication screen patterns
- Must not obstruct form inputs or save button
- Must update reactively as user makes changes
- Must handle all medication forms (Tablet, Capsule, Injections)

## Goals / Non-Goals

**Goals:**
- Provide immediate visual feedback of medication and schedule details
- Reuse existing `SummaryHeaderCard` widget for consistency
- Show dose, times, and frequency pattern in human-readable format
- Maintain responsive layout for various screen sizes

**Non-Goals:**
- Redesigning the SummaryHeaderCard widget itself (use as-is)
- Adding collapsible/expandable functionality (keep simple for v1)
- Showing calendar preview or next dose calculations (future enhancement)
- Modifying schedule data model or persistence layer

## Decisions

### 1. Widget Reuse: SummaryHeaderCard

**Decision**: Use existing `SummaryHeaderCard.fromMedication()` factory constructor with `additionalInfo` parameter for schedule details.

**Rationale**:
- Already proven in Add Medication screens
- Handles all medication forms consistently
- Supports neutral styling for non-primary backgrounds
- Has `additionalInfo` field perfect for schedule description

**Alternatives considered**:
- Create new `ScheduleSummaryCard` widget → Rejected: unnecessary duplication
- Use plain Card widget → Rejected: inconsistent with app patterns

### 2. Layout Strategy: Floating Overlay with Stack

**Decision**: Use `Stack` with positioned summary card + dynamic spacer approach (same as Add Medication).

**Code pattern**:
```dart
Stack(
  children: [
    // Positioned summary card
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SummaryHeaderCard(...),
    ),
    // ScrollView with spacer
    SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: _summaryHeight), // Dynamic spacer
          // Form sections...
        ],
      ),
    ),
  ],
)
```

**Rationale**:
- Proven pattern from medication screens
- Card stays visible during scroll
- Clean separation of concerns
- No z-index or gesture conflicts

**Alternatives considered**:
- SliverPersistentHeader → Rejected: over-engineered for this use case
- Column with card at top → Rejected: card scrolls away
- Bottom sheet → Rejected: hides form fields

### 3. Schedule Description Format

**Decision**: Format schedule details as natural language in `additionalInfo` field.

**Format examples**:
- `"2.5 tablets • Every Monday, Wednesday, Friday at 9:00 AM, 6:00 PM"`
- `"150 mg • Every day at 8:00 AM"`
- `"1 syringe • Every 3 days at 10:00 AM"`

**Rationale**:
- Human-readable and scannable
- Separates dose from frequency with bullet (•)
- Mirrors existing summary patterns in app
- Fits well in single-line `additionalInfo` display

**Implementation approach**:
```dart
String _buildScheduleDescription() {
  final dose = '${_doseValue.text} ${_doseUnit.text}';
  final freq = _formatFrequencyPattern(); // "Every Monday, Wednesday at..."
  return '$dose • $freq';
}
```

### 4. Update Triggers

**Decision**: Rebuild summary card on any state change affecting medication or schedule fields.

**Triggers**:
- Medication selection change → Full card rebuild
- Dose value/unit change → Update `additionalInfo` only
- Times/days change → Update `additionalInfo` only
- Mode change (weekly/daily/cycle) → Update `additionalInfo` only

**Implementation**: Wrap card in `setState()` calls for all relevant controllers/fields.

### 5. Null Medication Handling

**Decision**: Hide summary card entirely when no medication is selected.

**Rationale**:
- No meaningful data to display without medication
- Cleaner than showing placeholder card
- Encourages medication selection first (natural workflow)

**Implementation**:
```dart
if (_selectedMed != null)
  Positioned(
    child: SummaryHeaderCard.fromMedication(_selectedMed!, ...),
  ),
```

## Risks / Trade-offs

### Risk: Summary Height Calculation
**Risk**: Dynamic spacer requires accurate height calculation to prevent overlap.  
**Mitigation**: Use `GlobalKey` to measure card height after render (proven pattern from medications).

### Risk: Performance on Low-End Devices
**Risk**: Frequent rebuilds during typing could cause lag.  
**Mitigation**: 
- Use `const` constructors where possible
- Debounce text field updates if needed (unlikely to be necessary)
- Summary only rebuilds on state changes, not every frame

### Trade-off: Screen Real Estate
**Trade-off**: Summary card takes ~120-150px of vertical space.  
**Justification**: Users on small screens can scroll; benefit of always-visible context outweighs space cost.

## Migration Plan

**No migration needed** - purely additive UI feature.

**Rollout**:
1. Implement and test on development build
2. Deploy to production in normal release cycle
3. No feature flag required (low risk, easy to revert)

**Rollback**: Simple revert of single file change if issues found.

## Implementation Notes

### Code Organization
- Add helper method `_buildScheduleDescription()` at bottom of `_AddEditSchedulePageState`
- Add `GlobalKey` field: `final _summaryKey = GlobalKey();`
- Measure height in `build()` after first frame

### Styling
- Use `neutral: true` for surface-colored background (consistent with edit screens)
- Use `outlined: false` (no border needed)
- Inherit medication icon from `SummaryHeaderCard.fromMedication()`

### Edge Cases
- Long medication names → Card handles with `TextOverflow.ellipsis`
- Multiple times (4+) → Truncate with "at 9:00 AM, 2:00 PM, +2 more"
- All days of week → Show "Every day" instead of listing days
- Editing existing schedule → Show current values immediately

## Open Questions

1. **Should we show end date in summary if set?**
   - **Status**: Deferred - keep v1 simple, add in future if requested
   
2. **Should we show schedule name in summary?**
   - **Status**: No - name field is already visible in form; redundant
   
3. **Should summary be tappable to jump to specific sections?**
   - **Status**: Deferred - nice-to-have for future enhancement
