# Fix: Dose Action Sheet Save Button Obscured by Android Navigation Bar

## Issue
When opening the dose action sheet from a notification on Android, the save button at the bottom of the sheet was being obscured by the Android system navigation bar, making it impossible to tap and save changes.

## Root Cause
The `DoseActionSheet` widget uses a `DraggableScrollableSheet` inside a modal bottom sheet. While `useSafeArea: true` was set on the `showModalBottomSheet`, the content inside the `DraggableScrollableSheet` was not respecting the safe area insets properly.

The previous approach attempted to manually add `MediaQuery.of(context).viewPadding.bottom` to the button padding, but this was insufficient and unreliable with the draggable sheet container.

## Solution
Wrapped the entire content of the `DraggableScrollableSheet` with a `SafeArea` widget.

### Before
```dart
return DraggableScrollableSheet(
  builder: (context, scrollController) {
    return Container(
      child: Column(
        children: [
          // ... header and content ...
          Padding(
            padding: kBottomSheetContentPadding.copyWith(
              bottom: kBottomSheetContentPadding.bottom +
                  MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Row(
              children: [
                OutlinedButton(...), // Close button
                FilledButton.icon(...), // Save button
              ],
            ),
          ),
        ],
      ),
    );
  },
);
```

### After
```dart
return DraggableScrollableSheet(
  builder: (context, scrollController) {
    return Container(
      child: SafeArea(  // ← Added SafeArea wrapper
        child: Column(
          children: [
            // ... header and content ...
            Padding(
              padding: kBottomSheetContentPadding,  // ← Simplified padding
              child: Row(
                children: [
                  OutlinedButton(...), // Close button
                  FilledButton.icon(...), // Save button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
```

## Benefits of SafeArea

The `SafeArea` widget automatically:
1. **Detects system UI intrusions**: Navigation bars, status bars, notches, camera cutouts
2. **Adds appropriate padding**: Only where needed, based on the actual device
3. **Handles orientation changes**: Automatically adjusts when rotating the device
4. **Works with gesture navigation**: Properly accounts for gesture areas on modern Android

## Testing
This fix should be tested on Android devices with:

### Navigation Types
- ✅ **Gesture navigation** (swipe up from bottom)
- ✅ **Button navigation** (back, home, recents buttons)

### Screen Configurations
- ✅ Various screen sizes (small, medium, large)
- ✅ Portrait and landscape orientations
- ✅ Devices with and without notches

### Verification Points
1. **Save button visibility**: Fully visible above navigation bar
2. **Save button tappability**: Can be tapped without interference
3. **Close button accessibility**: Also remains accessible
4. **Sheet appearance**: No visual regressions
5. **Drag behavior**: Draggable scrollable sheet still works smoothly
6. **Content layout**: All content fits properly within safe area

## Impact
- **Primary fix**: Resolves the issue reported in the problem statement
- **No breaking changes**: Existing functionality preserved
- **Better UX**: More reliable across different Android devices and configurations
- **Code quality**: Simpler, more maintainable code (removed manual padding calculation)

## Files Modified
1. `lib/src/widgets/dose_action_sheet.dart` - Applied SafeArea wrapper (lines 1316, 1363, 1395)
2. `docs/CHANGELOG.md` - Documented the fix

## Related Code
- Entry point: `lib/src/app/notification_deep_link_handler.dart` (handles notification taps)
- Helper function: `lib/src/widgets/show_dose_action_sheet.dart` (shows the sheet)
- Test file: `test/widgets/dose_action_sheet_affordance_test.dart` (existing tests)
