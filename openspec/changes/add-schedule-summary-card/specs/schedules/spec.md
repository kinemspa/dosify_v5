# Schedules Capability - Spec Delta

## ADDED Requirements

### Requirement: Schedule Summary Card

The schedule creation/editing interface SHALL display a floating summary card that shows selected medication details and schedule configuration.

#### Scenario: Summary card appears after medication selection
- **GIVEN** user is on Add/Edit Schedule screen
- **WHEN** user selects a medication from the medication picker
- **THEN** a summary card appears at the top of the screen showing medication name, manufacturer, strength, form, and current stock status
- **AND** the summary card remains visible while scrolling through form sections

#### Scenario: Summary card updates with dose changes
- **GIVEN** user has selected a medication and summary card is visible
- **WHEN** user changes the dose value or dose unit fields
- **THEN** the summary card updates to show the new dose information in the format "{value} {unit}"
- **AND** the update occurs immediately without requiring save action

#### Scenario: Summary card updates with schedule time changes
- **GIVEN** user has selected a medication and summary card is visible
- **WHEN** user adds, removes, or modifies schedule times
- **THEN** the summary card updates to show all configured times in the format "at 9:00 AM, 2:00 PM, 8:00 PM"
- **AND** times are displayed in chronological order

#### Scenario: Summary card updates with frequency pattern changes
- **GIVEN** user has selected a medication and summary card is visible
- **WHEN** user changes the schedule frequency pattern (days of week, every day, or cycle pattern)
- **THEN** the summary card updates to show the frequency in natural language
- **AND** weekly patterns show as "Every Monday, Wednesday, Friday"
- **AND** daily patterns show as "Every day"
- **AND** cycle patterns show as "Every N days"

#### Scenario: Summary card shows complete schedule description
- **GIVEN** user has configured all schedule fields (medication, dose, times, frequency)
- **WHEN** viewing the summary card
- **THEN** the card displays medication details in the main section
- **AND** the card displays schedule details in the additional info line as "{dose} • {frequency} at {times}"
- **AND** all information is formatted in human-readable natural language

#### Scenario: Summary card hidden when no medication selected
- **GIVEN** user is on Add/Edit Schedule screen
- **WHEN** no medication has been selected yet
- **THEN** the summary card is not displayed
- **AND** the form sections appear at the top of the screen without spacer

#### Scenario: Summary card uses neutral styling
- **GIVEN** summary card is displayed on schedule screen
- **WHEN** rendering the card appearance
- **THEN** the card uses surface-colored background (neutral mode)
- **AND** the card uses onSurface text colors for readability
- **AND** the card maintains consistent styling with other summary cards in the app

#### Scenario: Summary card displays correct medication form icon
- **GIVEN** user has selected a medication
- **WHEN** viewing the summary card
- **THEN** the card displays the appropriate icon for the medication form
- **AND** Tablet medications show medication icon
- **AND** Capsule medications show pill icon
- **AND** Injection medications show appropriate injection-specific icon

#### Scenario: Summary card layout prevents content overlap
- **GIVEN** summary card is displayed
- **WHEN** user scrolls through form sections
- **THEN** form content begins below the summary card with appropriate spacing
- **AND** no form elements are obscured by the summary card
- **AND** spacing adjusts dynamically based on summary card height

#### Scenario: Summary card persists during edit mode
- **GIVEN** user is editing an existing schedule
- **WHEN** the edit screen loads
- **THEN** the summary card displays immediately with current schedule values
- **AND** the card shows the associated medication details
- **AND** the card shows the current dose and frequency configuration

## MODIFIED Requirements

None - this is a purely additive feature with no modifications to existing behavior.

## REMOVED Requirements

None - no existing functionality is being removed.
