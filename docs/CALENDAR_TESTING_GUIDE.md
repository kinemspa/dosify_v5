# Calendar Testing Quick Start Guide

**Date**: November 9, 2025  
**Purpose**: Manual testing instructions for Phase 8

---

## Prerequisites

1. **App Running**: Launch dosifi_v5 on emulator or device
2. **Test Data**: Create at least 3 schedules with different patterns
3. **Documentation**: Have PHASE_8_TEST_SUITE.md open for reference

---

## Quick Test Scenarios

### 🏃 Test 1: Basic Calendar Access (5 minutes)

**Goal**: Verify all 4 calendar entry points work

**Steps**:
1. Launch app → Home page
2. Tap **"Calendar"** button → ✅ Should open full calendar
3. Go back → Tap **Calendar icon** in bottom nav → ✅ Should open calendar
4. Go to **Medications** → Tap any med → Scroll down
   - ✅ Should see "Dose Calendar" section
5. Go to **Schedules** → Tap any schedule → Scroll down
   - ✅ Should see "Dose Calendar" section

**Expected**: All 4 entry points functional

---

### 🏃 Test 2: View Switching (3 minutes)

**Goal**: Test Day/Week/Month view toggle

**Steps**:
1. Open Calendar page
2. Default view: Week or Month (depends on config)
3. Tap **View Toggle** button → Switch to Day view
   - ✅ See hourly timeline (6 AM - 11 PM)
   - ✅ See red line at current time (if today)
4. Tap toggle again → Switch to Week view
   - ✅ See 7 columns (Mon-Sun)
   - ✅ Today's column highlighted
5. Tap toggle again → Switch to Month view
   - ✅ See calendar grid
   - ✅ Other month dates grayed out

**Expected**: All 3 views render correctly

---

### 🏃 Test 3: Date Navigation (5 minutes)

**Goal**: Test arrows, swipes, and "Today" button

**Steps**:
1. In Day view:
   - Tap **right arrow** → Next day
   - Tap **left arrow** → Previous day
   - Swipe left → Next day
   - Swipe right → Previous day
   - Tap **"Today"** → Return to today
   
2. In Week view:
   - Arrows/swipes navigate by week
   - "Today" returns to current week
   
3. In Month view:
   - Arrows/swipes navigate by month
   - "Today" returns to current month

**Expected**: All navigation methods work smoothly

---

### 🏃 Test 4: Dose Display (10 minutes)

**Setup**: Create 3 test schedules

**Schedule 1: Daily Vitamin**
```
Name: Vitamin D
Medication: Vitamin D 5000 IU
Dose: 1 capsule
Time: 9:00 AM
Frequency: Every day
Status: Active
```

**Schedule 2: Weekly Pattern**
```
Name: Workout Supplement
Medication: Creatine
Dose: 5g
Time: 6:00 PM
Frequency: Mon, Wed, Fri
Status: Active
```

**Schedule 3: Cycle Pattern**
```
Name: Peptide
Medication: BCP-157
Dose: 500mcg
Time: 8:00 AM
Frequency: 5 days on, 2 days off
Anchor Date: Last Monday
Status: Active
```

**Test Steps**:
1. Go to **Day view** for today
   - ✅ See "Vitamin D" at 9:00 AM slot
   - ✅ See "Peptide" at 8:00 AM (if on cycle day)
   - ✅ See "Creatine" at 6:00 PM (if Mon/Wed/Fri)

2. Go to **Week view**
   - ✅ "Vitamin D" appears all 7 days
   - ✅ "Creatine" appears only Mon/Wed/Fri
   - ✅ "Peptide" appears 5 days, skips 2 days

3. Go to **Month view**
   - ✅ Daily schedule: dots on all dates
   - ✅ Weekly schedule: dots only on matching weekdays
   - ✅ Cycle schedule: correct 5-on-2-off pattern

**Expected**: Dose calculations accurate for all patterns

---

### 🏃 Test 5: Dose Status Colors (5 minutes)

**Goal**: Verify color coding

**Setup**: Use existing schedule

**Steps**:
1. Find a **future dose** (pending)
   - ✅ Should be gray/blue
   
2. Tap dose → Mark as **"Taken"**
   - ✅ Should turn green
   - ✅ Should show checkmark badge
   
3. Create another test → Mark as **"Skipped"**
   - ✅ Should turn red
   
4. Create another test → Mark as **"Snoozed"**
   - ✅ Should turn orange
   
5. Wait for a dose to become **overdue** (past time, not taken)
   - ✅ Should turn red with warning icon

**Expected**: 5 distinct statuses with correct colors

---

### 🏃 Test 6: Filtering (5 minutes)

**Goal**: Test medication/schedule filters

**Steps**:
1. Go to **Medication Detail** page
   - Scroll to "Dose Calendar" section
   - ✅ Should only show doses for THIS medication
   - ✅ Other medications' doses hidden
   
2. Go to **Schedule Detail** page
   - Scroll to "Dose Calendar" section
   - ✅ Should only show doses for THIS schedule
   - ✅ Other schedules' doses hidden
   
3. Go to main **Calendar** page
   - ✅ Should show ALL schedules combined

**Expected**: Filtering works correctly

---

### 🏃 Test 7: Edge Cases (10 minutes)

**Test 7.1: Month Boundaries**
1. Navigate to last week of month (e.g., Nov 24-30)
2. Week view should show Nov 30 + Dec 1-2
3. ✅ Doses appear correctly across boundary

**Test 7.2: Midnight Dose**
1. Create schedule at 12:00 AM (midnight)
2. Day view: Won't show (6 AM - 11 PM range)
3. Week/Month views: Should still count dose
4. ✅ No errors or crashes

**Test 7.3: Multiple Doses Same Time**
1. Create 3 schedules all at 9:00 AM
2. Day view: Should stack vertically
3. Week view: Should show all 3 indicators
4. ✅ All independently tappable

**Expected**: App handles edge cases gracefully

---

## Critical Bugs to Watch For

### 🐛 Calculation Errors
- Cycle schedules not respecting anchor date
- Weekly schedules showing on wrong days
- Doses missing across month/year boundaries

### 🐛 Performance Issues
- Lag when scrolling Day view with 50+ doses
- Slow view switching (target: <500ms)
- Memory spikes (target: <200MB)

### 🐛 UI Glitches
- Dose blocks overlapping incorrectly
- Current time indicator in wrong position
- Month view dots missing or duplicated
- Other month dates not grayed out

### 🐛 Navigation Bugs
- "Today" button not working
- Swipes too sensitive or not detected
- View toggle not updating properly
- Wrong date after navigation

### 🐛 Integration Issues
- Bottom nav icon not highlighting
- Compact calendars not filtering correctly
- Dose detail dialog not opening
- Actions (mark taken) not updating calendar

---

## Reporting Results

### Format:
```
Test: [Test Name]
Status: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
Issues Found: [List any bugs]
Notes: [Additional observations]
```

### Example:
```
Test: Basic Calendar Access
Status: ✅ PASS
Issues Found: None
Notes: All 4 entry points worked perfectly

Test: Dose Status Colors  
Status: ❌ FAIL
Issues Found: Overdue doses showing blue instead of red
Notes: Needs to check date comparison logic
```

---

## Next Steps After Testing

1. **Document bugs** in PHASE_8_TEST_SUITE.md
2. **Prioritize fixes**: Critical → High → Medium → Low
3. **Create bug fix plan** with estimated time
4. **Retest after fixes** to verify resolution
5. **Move to Phase 9** (Polish & UX) when all critical bugs fixed

---

## Quick Checklist

Before moving to Phase 9, verify:

- [ ] All 4 calendar entry points work
- [ ] Day/Week/Month views render correctly
- [ ] Navigation (arrows, swipes, "Today") functional
- [ ] Dose calculations accurate for daily/weekly/cycle
- [ ] Status colors correct (pending/taken/skipped/snoozed/overdue)
- [ ] Filtering works (medication/schedule specific views)
- [ ] No crashes or errors in normal usage
- [ ] Performance acceptable (<1s load, <500ms switch)
- [ ] Edge cases handled (month boundaries, midnight doses)
- [ ] Integration points working (home, detail pages, bottom nav)

---

*Happy Testing! 🧪*
