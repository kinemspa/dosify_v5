# Dosifi v5 - Project Context

**App Metadata**
- **Project Name**: Dosifi v5
- **Application ID**: com.dosifi.app
- **Android Package**: com.dosifi.dosifi_v5
- **Current Version**: 1.0.0+1
- **Platform**: Android-only (minSdk 24, targetSdk 36)
- **Design Tokens**:
  - Primary Gradient: `#09A8BD` → `#18537D`
  - Secondary Color: `#EC873F`
  - Design System: Material 3

---

## Purpose

Dosifi v5 is an Android Flutter application for comprehensive medication tracking and management. The app helps users:

- **Track Multiple Medication Forms**: Tablets, Capsules, and various Injection types (Pre-Filled Syringes, Single/Multi Dose Vials, Lyophilized Vials)
- **Manage Medication Schedules**: Create weekly schedules with multiple daily times, timezone-aware handling, and automated stock deduction
- **Monitor Inventory**: Track medication stock levels with low-stock alerts, expiry dates, and reserve stock management
- **Calculate Dosages**: Built-in reconstitution calculator for multi-dose vials with comprehensive formula support
- **Manage Supplies**: Track consumable medical supplies with stock movements and alerts
- **View Calendar**: Agenda-first calendar views aligned with medication schedules

**Project Status**: Actively developed. Immediate notifications work; scheduled delivery is de-prioritized pending OS/AlarmManager behavior investigation.

---

## Tech Stack

### Core Framework
- **Flutter**: 3.24.x (tested)
- **Dart SDK**: ^3.8.1 (Dart 3.8.x tested)
- **Build Target**: Android APK/App Bundle

### State Management & Navigation
- **[flutter_riverpod](https://pub.dev/packages/flutter_riverpod)**: ^2.5.1 - State management via Riverpod Notifiers
- **[go_router](https://pub.dev/packages/go_router)**: ^14.2.5 - Declarative routing with type-safe navigation

### Storage & Persistence
- **[hive](https://pub.dev/packages/hive)**: ^2.2.3 - NoSQL local database
- **[hive_flutter](https://pub.dev/packages/hive_flutter)**: ^1.1.0 - Flutter integration for Hive
- **[shared_preferences](https://pub.dev/packages/shared_preferences)**: ^2.2.2 - Key-value storage for app preferences

### Code Generation & Serialization
- **[freezed](https://pub.dev/packages/freezed)**: ^2.4.7 - Immutable data classes with unions
- **[freezed_annotation](https://pub.dev/packages/freezed_annotation)**: ^2.4.1
- **[json_serializable](https://pub.dev/packages/json_serializable)**: ^6.8.0 - JSON serialization
- **[json_annotation](https://pub.dev/packages/json_annotation)**: ^4.9.0
- **[hive_generator](https://pub.dev/packages/hive_generator)**: ^2.0.1 - Hive TypeAdapter generation
- **[build_runner](https://pub.dev/packages/build_runner)**: ^2.4.8 - Code generation orchestration

### Notifications & Permissions
- **[flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)**: ^17.2.1 - Local notification support
- **[permission_handler](https://pub.dev/packages/permission_handler)**: ^11.3.1 - Runtime permission management
- **[android_intent_plus](https://pub.dev/packages/android_intent_plus)**: ^5.1.0 - Android intents for settings navigation

### Date/Time & Internationalization
- **[intl](https://pub.dev/packages/intl)**: ^0.19.0 - Internationalization and localization
- **[timezone](https://pub.dev/packages/timezone)**: ^0.9.2 - Timezone database
- **[flutter_timezone](https://pub.dev/packages/flutter_timezone)**: ^4.1.1 - Device timezone detection

### UI & Design
- **[google_fonts](https://pub.dev/packages/google_fonts)**: ^6.2.1 - Google Fonts integration
- **[flutter_svg](https://pub.dev/packages/flutter_svg)**: ^2.0.10 - SVG rendering
- **[material_design_icons_flutter](https://pub.dev/packages/material_design_icons_flutter)**: ^7.0.7296 - Extended Material Design icons
- **[cupertino_icons](https://pub.dev/packages/cupertino_icons)**: ^1.0.8 - iOS-style icons
- **Material 3**: Modern design system with color roles and dynamic theming

### Development & Testing
- **[very_good_analysis](https://pub.dev/packages/very_good_analysis)**: ^5.1.0 - Strict lint rules (with `public_member_api_docs: false`)
- **flutter_test**: Built-in testing framework
- **[package_info_plus](https://pub.dev/packages/package_info_plus)**: ^8.0.0 - App version and build info

### MCP Integration
- **[mcp_toolkit](https://pub.dev/packages/mcp_toolkit)**: ^0.3.0 - MCP bridge for Flutter inspector, widget trees, and screenshots

### Android-Specific
- **Kotlin**: Android build configuration
- **Gradle**: Build system (Kotlin DSL)
- **NDK Version**: 27.0.12077973
- **Compile SDK**: 36
- **Java Version**: 17 (source/target compatibility)
- **Core Library Desugaring**: Enabled for API level compatibility

---

## Project Conventions

### Code Style

**Linting & Analysis**
- Use [very_good_analysis](https://pub.dev/packages/very_good_analysis) rules
- Exception: `public_member_api_docs: false` (API docs not required for internal code)
- Run `flutter analyze` before committing
- Suppress error underlines in inputs to prevent height changes during validation

**Formatting**
- Use `dart format .` for consistent code formatting
- Line length warnings are acceptable (non-breaking)
- Prefer explicit types for clarity in complex state management

**Naming Conventions**
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Functions/Variables: `camelCase`
- Private members: prefix with `_`
- Constants: `kConstantName` or `SCREAMING_SNAKE_CASE` for static finals
- Riverpod Providers: descriptive names ending in `Provider` (e.g., `medicationRepositoryProvider`)

**Widget Organization**
- Extract reusable widgets to separate files in `lib/src/widgets/`
- Use `const` constructors wherever possible for performance
- Prefer composition over inheritance
- Keep build methods concise; extract complex subtrees

**Code Generation**
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after model changes
- Freezed for immutable data classes with copyWith and unions
- JsonSerializable for JSON serialization
- Hive TypeAdapters for database models

**Deprecation Handling**
- Replace deprecated APIs promptly
- Use `withValues(alpha: ...)` instead of `withOpacity(...)`
- Use `WidgetStatePropertyAll` instead of `MaterialStatePropertyAll`

### Architecture Patterns

**Feature-First Structure**
```
lib/
├── main.dart
├── src/
│   ├── app/                    # App-level configuration
│   │   └── app.dart            # Root MaterialApp with routing
│   ├── core/                   # Shared infrastructure
│   │   ├── hive/               # Hive initialization & migrations
│   │   ├── notifications/      # Notification service
│   │   ├── prefs/              # SharedPreferences utilities
│   │   └── utils/              # General utilities
│   ├── features/               # Feature modules
│   │   ├── medications/        # Medication tracking
│   │   ├── schedules/          # Schedule management
│   │   ├── calendar/           # Calendar views
│   │   ├── supplies/           # Supply tracking
│   │   ├── analytics/          # Usage analytics
│   │   ├── settings/           # App settings
│   │   └── home/               # Home dashboard
│   └── widgets/                # Shared UI components
```

**Feature Layer Structure** (per feature)
- `data/`: Models, repositories, data sources (Hive boxes)
- `domain/`: Business logic, use cases (minimal - mostly handled by Notifiers)
- `presentation/`: Pages, widgets, Riverpod Notifiers/Providers

**State Management Principles**
- **Riverpod Notifiers** for complex state with side effects
- **Local StatefulWidget state** for simple UI interactions (e.g., text field focus)
- **Providers** for dependency injection and read-only state
- Immutable state objects using Freezed
- No global mutable state

**Data Flow**
1. UI triggers action → Notifier method
2. Notifier updates state & persists to Hive
3. UI rebuilds reactively via `ref.watch`

**Persistence Strategy**
- **Hive Boxes**: Medications, Schedules, Supplies, Stock Movements
- **SharedPreferences**: Theme mode, layout preferences, UI settings
- **UTC Storage**: All timestamps stored in UTC, converted to local timezone at runtime
- **Stable IDs**: Use UUID-like stable IDs for schedules and relationships

**Navigation**
- Declarative routing via go_router
- Type-safe route parameters
- Deep linking support prepared (not yet fully utilized)

**Error Handling**
- Use `runZonedGuarded` in main.dart for global error capture
- MCP Toolkit integration for error reporting during development
- Graceful degradation for missing permissions (notifications, battery optimization)

### Testing Strategy

**Current State**
- Limited automated test coverage (to be expanded)
- Manual testing on physical devices and emulators
- Primary testing on Android (minSdk 24 through targetSdk 36)

**Testing Roadmap**
- **Unit Tests**: Repository logic, data transformations, utility functions
- **Widget Tests**: Reusable widgets, form validation, state transitions
- **Integration Tests**: End-to-end flows (add medication → create schedule → verify calendar)
- **Mocking**: Use mocktail or mockito for dependencies
- **Golden Tests**: UI regression testing for critical screens (future consideration)

**Testing Tools**
- `flutter_test` package (built-in)
- Run tests: `flutter test`
- Coverage: `flutter test --coverage` (future use)

**Pre-Release Checklist**
- Run `flutter analyze` (no errors)
- Manual smoke test on debug build
- Verify notifications work (immediate only, scheduled still de-prioritized)
- Check low-stock alerts trigger correctly
- Validate schedule-based stock deduction

### Git Workflow

**Branching Strategy**
- Currently using `main` branch for development (small team/solo)
- No formal branching strategy yet (can adopt feature branches as team grows)

**Commit Conventions**
- **Always commit to local git** after completing work
- Use descriptive commit messages with context
- Format: `<type>: <description>` or just descriptive sentence
- Types (informal):
  - `docs:` - Documentation updates
  - `fix:` - Bug fixes
  - `feat:` - New features
  - Descriptive: "Add schedule dose and time info to summary card"
  - Descriptive: "Fix build errors: nullable endDate and missing controller parameters"

**Documentation Policy**
- **Always update technical documentation** after significant changes
- Canonical docs:
  - `docs/CHANGELOG.md` - All release notes and technical updates
  - `docs/product-design.md` - Full UI/UX spec and module specifications
  - `docs/NOTIFICATIONS.md` - Notification scheduling behavior and diagnostics
  - `README.md` - Quick start guide and project overview
- Update CHANGELOG.md in the "Unreleased" section during development
- Document architectural decisions inline via code comments for complex logic

**Pre-Commit Actions**
- Run `flutter analyze` to catch lint issues
- Ensure code compiles (`flutter build apk --debug` or `flutter run`)
- Update relevant documentation
- No formal pre-commit hooks currently (can add via Husky/Lefthook if needed)

---

## Domain Context

### Medication Management

**Medication Forms**
1. **Tablets**: Can be halved or quartered; stock tracked in tablets/mass units
2. **Capsules**: Whole units only; no subdivision
3. **Injections**:
   - **Pre-Filled Syringe (PFS)**: Ready-to-use single-dose syringes
   - **Single Dose Vial (SDV)**: One-time use vials
   - **Multi Dose Vial (MDV)**: Liquid vials for multiple doses with volume tracking
   - **Lyophilized Vial**: Powder requiring reconstitution with sterile liquid

**Medication Properties**
- **Identity**: Name, manufacturer, description, notes
- **Strength**: Value + unit (mcg, mg, g, units, or per-mL variants)
- **Inventory**: Stock quantity, unit, low-stock alert threshold, expiry date, reserve stock
- **Storage**: Batch number, lot number, refrigeration requirement, frozen requirement, dark storage, special instructions

**Stock Management**
- Automatic stock deduction when taking scheduled doses
- Low-stock alerts with customizable thresholds
- Support for reserve stock (not counted toward active inventory)
- Multiple stock units: count (tablets/capsules/syringes) or mass (mcg, mg, g) or volume (mL)
- Stock conversion: e.g., 100 tablets × 10mg/tablet = 1000mg total

### Schedule Management

**Schedule Features**
- **Weekly Patterns**: Select specific days of the week
- **Multiple Daily Times**: Multiple dose times per day (e.g., 8am, 2pm, 8pm)
- **Every N Days**: Alternative to weekly (e.g., every 3 days)
- **Timezone Aware**: Stored in UTC, displayed in local timezone
- **Stable IDs**: UUID-like identifiers for reliable relationships
- **Auto-Naming**: Automatically generate schedule names from medication and frequency

**Dose Tracking**
- **Typed Dose Input**: Per-medication-form UI with appropriate units
- **Dose Formula Display**: Live calculation showing total dose per administration
- **Normalized Storage**: Doses stored in standardized units (micrograms, microliters, tablet quarters, whole counts, IU)
- **Stock Deduction**: "Take" action decrements medication stock according to dose and unit conversions

**Schedule Types**
- As-needed (PRN) - Not yet fully implemented
- Regular recurring schedules (primary focus)

### Supply Management

**Supply Tracking**
- Track consumable medical supplies (e.g., needles, alcohol swabs, bandages)
- Stock movements (add, adjust, consume)
- Low-stock indicators
- Expiry tracking
- Quantity units customizable per supply type

### Reconstitution Calculator

**Purpose**: Calculate dosages for multi-dose vials requiring reconstitution

**Inputs**
- Vial concentration (strength per vial)
- Diluent volume added
- Desired dose

**Outputs**
- Volume to draw
- Total doses available
- Concentration after reconstitution

**Formula Documentation**: See `docs/RECONSTITUTION_CALCULATOR_FORMULA.md`

### Calendar & Agenda Views

**Calendar Features**
- Agenda-first views showing scheduled doses
- Aligned with medication schedules
- Progressive enhancement planned (future)
- Timezone-aware display

### Notifications

**Current Behavior**
- **Immediate Notifications**: Work correctly
- **Scheduled Notifications**: De-prioritized due to Android AlarmManager behavior inconsistencies
- **Permissions Required**: POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS

**Investigation Status**
- See `docs/NOTIFICATIONS.md` for detailed diagnostics
- OS-level behavior varies by device manufacturer and Android version
- Future work may involve WorkManager or alternative scheduling strategies

---

## Important Constraints

### Platform Constraints
- **Android-Only**: No iOS, Web, or Desktop support at this time
- **Minimum SDK**: 24 (Android 7.0 Nougat, released 2016)
- **Target SDK**: 36 (latest Android version)
- **NDK Version**: 27.0.12077973 (for native code dependencies)

### Technical Constraints
- **Local-Only Storage**: No cloud sync or remote backend (Hive + SharedPreferences only)
- **Single Device**: Data not shared across devices
- **No Authentication**: No user accounts or login system
- **Scheduled Notifications De-prioritized**: Immediate notifications work; scheduled delivery paused pending investigation

### Design Constraints
- **Material 3 Only**: UI follows Material 3 design system strictly
- **Primary Gradient**: `#09A8BD` → `#18537D` (must be used for key UI elements)
- **Secondary Color**: `#EC873F` (accent color)
- **Google Fonts**: Custom typography via Google Fonts package
- **Responsive**: Must work on various Android screen sizes and densities

### Business/Regulatory Constraints
- **Not a Medical Device**: App is for personal tracking only, not for medical diagnosis or treatment decisions
- **No Medical Advice**: Does not provide medication recommendations or dosage guidance
- **User Responsibility**: Users responsible for accuracy of data entry
- **Privacy**: All data stored locally on device; no data collection or telemetry (except during MCP development sessions)

### Performance Constraints
- **Hive Database**: Suitable for small-to-medium datasets (hundreds of medications/schedules)
- **Local Notifications**: Limited by Android OS notification limits and battery optimization policies

---

## External Dependencies

### Flutter Ecosystem
- **Flutter SDK**: Requires Flutter 3.24.x or compatible version
- **Dart SDK**: Requires Dart 3.8.x or compatible version
- **pub.dev Packages**: All dependencies resolved via pub.dev

### Android Platform Services
- **Notification Service**: Android notification channels and local notifications
- **Alarm Manager**: For scheduled notifications (currently de-prioritized)
- **Battery Optimization**: Requests exemption for reliable background operation
- **Intent System**: For navigating to system settings (battery, notifications)

### Development Tools
- **Android SDK**: Required for building APKs and App Bundles
- **Android Emulator / Physical Device**: For testing
- **Visual Studio Code / Android Studio**: Recommended IDEs
- **Git**: Version control (local repository)

### Design Resources
- **Material 3 Spec**: [material.io](https://m3.material.io/) - Design guidelines
- **Google Fonts**: Typography via [fonts.google.com](https://fonts.google.com/)
- **Material Design Icons**: Icon library from [materialdesignicons.com](https://materialdesignicons.com/)

### MCP Integration (Development)
- **MCP Toolkit**: Model Context Protocol bridge for AI-assisted development
- **Dart Tooling Daemon**: For widget inspection and debugging
- **Flutter DevTools**: Enhanced debugging with MCP support

### No External Services
- **No Backend API**: No REST or GraphQL services
- **No Cloud Storage**: No Firebase, AWS, or other cloud providers
- **No Analytics**: No Google Analytics, Mixpanel, or telemetry services (in production)
- **No Crash Reporting**: No Sentry, Crashlytics, or error tracking services (in production)
- **No Authentication**: No Auth0, Firebase Auth, or identity providers

---

## Appendix

### Quick Start (Windows PowerShell)
```powershell
# Verify Flutter and Dart versions
flutter --version

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run app on connected device/emulator
flutter run
```

### Build Commands
```powershell
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Play Store App Bundle
flutter build appbundle --release
```

### Key File Paths
- **App Entry Point**: `lib/main.dart`
- **Root Widget**: `lib/src/app/app.dart`
- **Features**: `lib/src/features/<feature>/`
- **Shared Widgets**: `lib/src/widgets/`
- **Core Services**: `lib/src/core/`
- **Documentation**: `docs/`
- **Android Config**: `android/app/build.gradle.kts`
- **Dependencies**: `pubspec.yaml`
- **Lint Rules**: `analysis_options.yaml`

### Related Documentation
- **README.md**: Project overview and quick start
- **docs/CHANGELOG.md**: Detailed release notes and technical changes
- **docs/product-design.md**: Complete UI/UX specification
- **docs/NOTIFICATIONS.md**: Notification system diagnostics
- **docs/technical.md**: Additional technical details

### Android Permissions (AndroidManifest.xml)
- `POST_NOTIFICATIONS` - Local notifications
- `SCHEDULE_EXACT_ALARM` - Exact alarm scheduling (de-prioritized)
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` - Background reliability

---

**Last Updated**: 2025-10-12
**Document Version**: 1.0
