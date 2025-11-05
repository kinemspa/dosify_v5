<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

---

# CRITICAL DEVELOPMENT RULE: CENTRALIZED DESIGN SYSTEM

## **ALWAYS check centralized files BEFORE writing any UI code**

**Before implementing ANY UI element (card, button, text, spacing, color):**

### 1. Check Existing Centralized Code FIRST:
- `lib/src/core/design_system.dart` - spacing, radii, opacity, colors, text styles
- `lib/src/widgets/` - reusable widgets (cards, buttons, scaffolds, forms)
- `lib/src/widgets/detail_page_scaffold.dart` - detail page layouts
- `lib/src/widgets/unified_form.dart` - form layouts

### 2. If It Doesn't Exist, CREATE It Centrally FIRST:
- Add spacing constants to `design_system.dart`
- Add color constants to `design_system.dart`
- Create reusable widget in `lib/src/widgets/`
- THEN use it in your feature implementation

### 3. FORBIDDEN - Never Do This:
❌ `Colors.blue`, `Color(0xFF...)` - Use `design_system.dart` colors
❌ `EdgeInsets.all(12)` - Use `kSpacingS`, `kSpacingM`, etc.
❌ `BorderRadius.circular(8)` - Use `kBorderRadiusS`, `kBorderRadiusM`
❌ Material 3 colors: `primaryContainer`, `secondaryContainer`, `surfaceContainerHighest`
❌ Duplicate widgets across files - Create ONE centralized version
❌ Inline `Container` decorations - Create reusable card/button widget

### 4. Correct Pattern:
✅ Import design_system: `import 'package:dosifi_v5/src/core/design_system.dart';`
✅ Use constants: `padding: EdgeInsets.all(kSpacingM)`
✅ Use constants: `borderRadius: BorderRadius.circular(kBorderRadiusM)`
✅ Use theme colors: `Theme.of(context).colorScheme.primary`
✅ Import widgets: `import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';`
✅ Reuse widgets: `DetailPageScaffold(...)`, `buildDetailInfoRow(...)`

## **This applies to EVERY change. No exceptions.**

---