# Implementation Tasks: Add Schedule Summary Card

## 1. UI Integration

- [ ] 1.1 Add import for `SummaryHeaderCard` widget in `add_edit_schedule_page.dart`
- [ ] 1.2 Create helper method `_buildScheduleSummary()` to generate schedule description string
- [ ] 1.3 Add `SummaryHeaderCard.fromMedication()` widget to layout (positioned after app bar)
- [ ] 1.4 Wrap layout with `Stack` to position summary card as floating overlay
- [ ] 1.5 Add dynamic spacer below summary to prevent content overlap

## 2. Schedule Description Logic

- [ ] 2.1 Implement frequency pattern formatting (e.g., "Every Monday, Wednesday, Friday")
- [ ] 2.2 Implement time formatting for multiple daily times (e.g., "at 9:00 AM, 2:00 PM, 8:00 PM")
- [ ] 2.3 Handle "Every Day" and "Every N Days" patterns
- [ ] 2.4 Format dose information (value + unit) for display
- [ ] 2.5 Create complete `additionalInfo` string combining dose and schedule pattern

## 3. State Management

- [ ] 3.1 Ensure summary card rebuilds when medication selection changes
- [ ] 3.2 Ensure summary card updates when dose value/unit changes
- [ ] 3.3 Ensure summary card updates when schedule times change
- [ ] 3.4 Ensure summary card updates when frequency pattern changes
- [ ] 3.5 Handle null/empty medication selection gracefully (hide card or show placeholder)

## 4. Visual Polish

- [ ] 4.1 Use `neutral: true` parameter for surface-colored background
- [ ] 4.2 Ensure proper padding/margins around card
- [ ] 4.3 Verify card doesn't obstruct FAB or other interactive elements
- [ ] 4.4 Test card layout on various screen sizes (small phones, tablets)
- [ ] 4.5 Ensure text wrapping works correctly for long medication names

## 5. Testing & Validation

- [ ] 5.1 Manual test: Create new schedule and verify summary updates correctly
- [ ] 5.2 Manual test: Edit existing schedule and verify summary shows current values
- [ ] 5.3 Manual test: Change medication selection and verify summary updates
- [ ] 5.4 Manual test: Verify summary displays correctly for all medication forms (Tablet, Capsule, Injections)
- [ ] 5.5 Manual test: Test on different screen sizes and orientations
- [ ] 5.6 Run `flutter analyze` and fix any warnings
- [ ] 5.7 Verify no visual regression in existing schedule form functionality

## 6. Documentation

- [ ] 6.1 Update `docs/CHANGELOG.md` with summary card feature in "Unreleased" section
- [ ] 6.2 Add inline code comments for schedule description logic
- [ ] 6.3 Update `docs/product-design.md` if needed to document new UX pattern

## 7. Commit & Archive

- [ ] 7.1 Commit changes with descriptive message: "feat: add summary card to schedule add/edit screen"
- [ ] 7.2 Run `openspec validate add-schedule-summary-card --strict` to verify proposal
- [ ] 7.3 After deployment, archive change proposal using `openspec archive add-schedule-summary-card`
