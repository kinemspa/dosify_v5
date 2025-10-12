# Change Proposal: Add Schedule Summary Card

## Why

The Add/Edit Schedule screen currently lacks a visual summary card that shows the selected medication details and schedule configuration at a glance. Users have to scroll through multiple form sections to review their choices before saving, making it difficult to verify correctness. Adding a floating summary card (similar to Add Medication screens) will provide immediate visual feedback and improve the schedule creation experience.

## What Changes

- Add floating `SummaryHeaderCard` widget to Add/Edit Schedule screen
- Display selected medication details (name, manufacturer, strength, form, stock status)
- Show schedule-specific information (dose amount/unit, times, frequency pattern)
- Card appears after medication selection and updates dynamically as user edits fields
- Use neutral (surface) styling for non-intrusive appearance
- Position card below app bar, above form sections (similar to Add Medication pattern)

## Impact

- **Affected specs**: `schedules` capability
- **Affected code**:
  - `lib/src/features/schedules/presentation/add_edit_schedule_page.dart` - Main schedule form page
  - `lib/src/widgets/summary_header_card.dart` - Existing reusable widget (no changes needed)
- **User impact**: Improved UX - better visibility of medication and schedule details during creation/editing
- **Breaking changes**: None - additive feature only
- **Performance**: Negligible - single widget rebuild on state changes

## Dependencies

- Existing `SummaryHeaderCard` widget (already implemented)
- Medication model access (already available in schedule page)
- No new packages required

## Alternatives Considered

1. **Sticky header within scroll view** - Rejected due to complexity with form scrolling
2. **Bottom sheet summary** - Rejected as it hides form fields
3. **Inline summary sections** - Rejected as they're not visible while editing other sections
4. **Floating card (selected)** - Provides best visibility without obstructing content

## Migration Plan

No migration needed - additive feature with no data model changes.

## Open Questions

- [ ] Should the summary card be collapsible/expandable?
  - **Recommendation**: Keep it fixed for consistency with medication screens
- [ ] Should we show schedule preview (e.g., "Every Monday, Wednesday at 9:00 AM")?
  - **Recommendation**: Yes, include in `additionalInfo` field of summary card
