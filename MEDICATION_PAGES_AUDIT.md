# Medication Pages Audit

## 🎯 ACTIVE PAGES (Currently Used in Router)

### ✅ **add_edit_medication_page.dart** (formerly `unified_add_edit_medication_page_template.dart`)
- **Status**: ACTIVE - This is the ONLY page actually used in production
- **Class**: `AddEditMedicationPage` (formerly `UnifiedAddEditMedicationPageTemplate`)
- **Purpose**: Universal page for all medication types
- **Routes**: 
  - `/medications/add/tablet` → `MedicationForm.tablet`
  - `/medications/add/capsule` → `MedicationForm.capsule`
  - `/medications/add/injection/pfs` → `MedicationForm.injectionPreFilledSyringe`
  - `/medications/add/injection/single` → `MedicationForm.injectionSingleDoseVial`
  - `/medications/add/injection/multi` → `MedicationForm.injectionMultiDoseVial`
  - Plus all corresponding `/medications/edit/.../:id` routes
- **Migrated**: ✅ Yes - Uses design system
- **Renamed**: ✅ 2025-01-24 - Follows Flutter naming conventions

---

## ⚠️ OBSOLETE/UNUSED PAGES (NOT in Router)

These files exist but are **NOT referenced in router.dart** and are likely legacy/experimental:

### 1. **add_edit_tablet_general_page.dart**
- **Status**: OBSOLETE - Not used in routing
- **Why "general"**: Likely an early iteration or specific variant
- **Migrated**: Yes (but pointless since unused)
- **Action**: DELETE or clearly mark as legacy

### 2. **add_edit_tablet_hybrid_page.dart**
- **Status**: OBSOLETE - Not used in routing
- **What is it**: Unknown - possibly experimental tablet variant
- **Migrated**: Yes (but pointless since unused)
- **Action**: DELETE or clearly mark as legacy

### 3. **add_edit_tablet_page.dart**
- **Status**: OBSOLETE - Not used in routing
- **Migrated**: NOT checked
- **Action**: DELETE or clearly mark as legacy

### 4. **add_edit_tablet_details_style_page.dart**
- **Status**: OBSOLETE - Not used in routing
- **What is it**: Unknown - possibly styling experiment
- **Migrated**: NOT checked
- **Action**: DELETE or clearly mark as legacy

### 5. **add_edit_injection_pfs_page.dart**
- **Status**: OBSOLETE - Replaced by template
- **What is PFS**: Pre-Filled Syringe (but template handles this now)
- **Migrated**: Yes (but pointless since unused)
- **Action**: DELETE or clearly mark as legacy

### 6. **add_edit_injection_single_vial_page.dart**
- **Status**: OBSOLETE - Replaced by template
- **Migrated**: Yes (but pointless since unused)
- **Action**: DELETE or clearly mark as legacy

### 7. **add_edit_injection_multi_vial_page.dart**
- **Status**: OBSOLETE - Replaced by template
- **Migrated**: NOT checked
- **Action**: DELETE or clearly mark as legacy

### 8. **add_edit_injection_unified_page.dart**
- **Status**: OBSOLETE - Not used in routing
- **What is it**: Likely an earlier attempt at unification
- **Migrated**: Yes (but pointless since unused)
- **Action**: DELETE or clearly mark as legacy

### 9. **add_edit_capsule_page.dart**
- **Status**: OBSOLETE - Replaced by template
- **Migrated**: Yes (but pointless since unused)
- **Action**: DELETE or clearly mark as legacy

### 10. **unified_add_edit_medication_page.dart**
- **Status**: OBSOLETE - Not used in routing
- **What is it**: Earlier unified attempt (replaced by template)
- **Migrated**: Yes (but pointless since unused)
- **Action**: DELETE or clearly mark as legacy

### 11. **add_tablet_debug_page.dart**
- **Status**: DEBUG/DEV ONLY - Not in router
- **What is it**: Debug/testing page
- **Migrated**: Yes
- **Action**: Keep for development, or delete if not needed

---

## 📋 Summary

### The Reality:
- **1 page** is actually used: `unified_add_edit_medication_page_template.dart`
- **10+ pages** are obsolete legacy code that should be deleted
- We migrated 9 pages, but **8 of them are not even used!**

### Why the Confusion:
The project has accumulated multiple iterations/experiments:
1. Individual pages per form (tablet, capsule, each injection type)
2. Unified pages (first attempt)
3. Template-based unified page (current, working solution)

### Recommended Actions:

#### Immediate:
1. **DELETE** all obsolete pages OR move to `/archive` folder
2. **RENAME** if needed: The template file is well-named
3. **DOCUMENT** in code: Add deprecation warnings to unused files

#### File Cleanup Script:
```bash
# Move obsolete files to archive
mkdir -p lib/src/features/medications/presentation/archive
mv lib/src/features/medications/presentation/add_edit_tablet_general_page.dart lib/src/features/medications/presentation/archive/
mv lib/src/features/medications/presentation/add_edit_tablet_hybrid_page.dart lib/src/features/medications/presentation/archive/
# ... etc for all obsolete files
```

---

## 🔍 Your Specific Questions Answered:

1. **Why "general"?** → Unknown. Legacy naming. Not used.
2. **What is PFS?** → Pre-Filled Syringe. But that page is obsolete.
3. **What is hybrid?** → Unknown variant. Obsolete.
4. **What is unified?** → Earlier unification attempt. Obsolete.
5. **What is template?** → **Current active page** - the only one that matters!
6. **What is debug?** → Debug page. Keep or delete based on need.

---

## ✅ What Actually Needs to Work:

**ONLY** `add_edit_medication_page.dart` needs to:
- Have consistent borders across all sections (General, Strength, Inventory, Storage)
- Use design system decorations everywhere
- Work for all 5 medication forms

### Current Issue:
> "add tablet page still hasn't got the same borders around the fields in the strength card"

This refers to `add_edit_medication_page.dart` - we should check the stepper fields vs regular fields for border consistency.

---

**Last Updated**: 2025-01-24  
**Status**: 
- ✅ Cleanup Complete - 11 obsolete files deleted
- ✅ Renamed to follow Flutter conventions
- ⚠️ Border consistency issue remains
