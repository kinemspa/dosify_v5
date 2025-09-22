import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../features/home/presentation/home_page.dart';
import '../features/medications/presentation/medication_list_page.dart';
import '../features/medications/presentation/medication_detail_page.dart';
import '../features/medications/presentation/select_medication_type_page.dart';
import '../features/medications/presentation/select_injection_type_page.dart';
import '../features/medications/presentation/add_edit_capsule_page.dart';
import '../features/medications/presentation/add_edit_tablet_hybrid_page.dart';
import '../features/medications/presentation/add_edit_tablet_page.dart';
import '../features/medications/presentation/add_tablet_debug_page.dart';
import '../features/medications/presentation/add_edit_tablet_general_page.dart';
import '../features/medications/presentation/add_edit_injection_pfs_page.dart';
import '../features/medications/presentation/add_edit_injection_single_vial_page.dart';
import '../features/medications/presentation/add_edit_injection_multi_vial_page.dart';
import '../features/medications/presentation/reconstitution_calculator_page.dart';
import '../features/medications/presentation/reconstitution_calculator_dialog.dart';
import '../features/medications/domain/medication.dart';
import '../features/schedules/presentation/schedules_page.dart';
import '../features/schedules/presentation/add_edit_schedule_page.dart';
import '../features/schedules/presentation/select_medication_for_schedule_page.dart';
import '../features/schedules/domain/schedule.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/settings/presentation/large_card_styles_page.dart';
import '../features/settings/presentation/strength_input_styles_page.dart';
import '../features/settings/presentation/form_field_styles_page.dart';
import '../features/settings/presentation/bottom_nav_settings_page.dart';
import '../features/supplies/presentation/supplies_page.dart';
// Removed incorrect import
import '../features/calendar/presentation/calendar_page.dart';
import '../features/analytics/presentation/analytics_page.dart';
import 'shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  // Start at home by default
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/medications',
          name: 'medications',
          builder: (context, state) => const MedicationListPage(),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) => const CalendarPage(),
        ),
        GoRoute(
          path: '/schedules',
          name: 'schedules',
          builder: (context, state) => const SchedulesPage(),
        ),
        GoRoute(
          path: '/supplies',
          name: 'supplies',
          builder: (context, state) => const SuppliesPage(),
        ),
        GoRoute(
          path: '/supplies/add',
          name: 'addSupply',
          builder: (context, state) => const AddEditSupplyPage(),
        ),
        GoRoute(
          path: '/schedules/add',
          name: 'addSchedule',
          builder: (context, state) => const AddEditSchedulePage(),
        ),
        GoRoute(
          path: '/schedules/select-medication',
          name: 'selectMedicationForSchedule',
          builder: (context, state) => const SelectMedicationForSchedulePage(),
        ),
        GoRoute(
          path: '/schedules/edit/:id',
          name: 'editSchedule',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            if (id == null) return const AddEditSchedulePage();
            final box = Hive.box<Schedule>('schedules');
            final initial = box.get(id);
            return AddEditSchedulePage(initial: initial);
          },
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/settings/bottom-nav',
          name: 'bottomNavSettings',
          builder: (context, state) => const BottomNavSettingsPage(),
        ),
        GoRoute(
          path: '/settings/large-card-styles',
          name: 'largeCardStyles',
          builder: (context, state) => const LargeCardStylesPage(),
        ),
        GoRoute(
          path: '/settings/strength-input-styles',
          name: 'strengthInputStyles',
          builder: (context, state) => const StrengthInputStylesPage(),
        ),
        GoRoute(
          path: '/settings/form-field-styles',
          name: 'formFieldStyles',
          builder: (context, state) => const FormFieldStylesPage(),
        ),
        // Nested under shell so bottom nav persists
        GoRoute(
          path: '/medications/select-type',
          name: 'selectMedicationType',
          builder: (context, state) => const SelectMedicationTypePage(),
        ),
        GoRoute(
          path: '/medications/select-injection-type',
          name: 'selectInjectionType',
          builder: (context, state) => const SelectInjectionTypePage(),
        ),
        GoRoute(
          path: '/medications/add/tablet',
          name: 'addTablet',
          // TEMP: route to minimal page with ONLY General card to isolate render
          builder: (context, state) {
            debugPrint('[ROUTER] /medications/add/tablet -> AddEditTabletGeneralPage');
            return const AddEditTabletGeneralPage();
          },
        ),
// removed details-style add route
        GoRoute(
          path: '/medications/add/tablet/hybrid',
          name: 'addTabletHybrid',
          builder: (context, state) => const AddEditTabletHybridPage(),
        ),
        GoRoute(
          path: '/medications/add/capsule',
          name: 'addCapsule',
          builder: (context, state) {
            debugPrint('[ROUTER] /medications/add/capsule -> AddEditCapsulePage');
            return const AddEditCapsulePage();
          },
        ),
        GoRoute(
          path: '/medications/add/injection/pfs',
          name: 'addInjectionPfs',
          builder: (context, state) => const AddEditInjectionPfsPage(),
        ),
        GoRoute(
          path: '/medications/add/injection/single',
          name: 'addInjectionSingle',
          builder: (context, state) => const AddEditInjectionSingleVialPage(),
        ),
        GoRoute(
          path: '/medications/add/injection/multi',
          name: 'addInjectionMulti',
          builder: (context, state) => const AddEditInjectionMultiVialPage(),
        ),
        // Edit routes must come before the dynamic detail route so they don't get swallowed by '/medications/:id'
        GoRoute(
          path: '/medications/edit/tablet/:id',
          name: 'editTablet',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            final box = Hive.box<Medication>('medications');
            final med = id != null ? box.get(id) : null;
            return AddEditTabletGeneralPage(initial: med);
          },
        ),
// removed details-style edit route
        GoRoute(
          path: '/medications/edit/tablet/hybrid/:id',
          name: 'editTabletHybrid',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            final box = Hive.box<Medication>('medications');
            final med = id != null ? box.get(id) : null;
            return AddEditTabletHybridPage(initial: med);
          },
        ),
        GoRoute(
          path: '/medications/edit/capsule/:id',
          name: 'editCapsule',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            final box = Hive.box<Medication>('medications');
            final med = id != null ? box.get(id) : null;
            return AddEditCapsulePage(initial: med);
          },
        ),
        GoRoute(
          path: '/medications/edit/injection/pfs/:id',
          name: 'editInjectionPfs',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            final box = Hive.box<Medication>('medications');
            final med = id != null ? box.get(id) : null;
            return AddEditInjectionPfsPage(initial: med);
          },
        ),
        GoRoute(
          path: '/medications/edit/injection/single/:id',
          name: 'editInjectionSingle',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            final box = Hive.box<Medication>('medications');
            final med = id != null ? box.get(id) : null;
            return AddEditInjectionSingleVialPage(initial: med);
          },
        ),
        GoRoute(
          path: '/medications/edit/injection/multi/:id',
          name: 'editInjectionMulti',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            final box = Hive.box<Medication>('medications');
            final med = id != null ? box.get(id) : null;
            return AddEditInjectionMultiVialPage(initial: med);
          },
        ),
        // Reconstitution calculator must be above the dynamic '/medications/:id' route
        GoRoute(
          path: '/medications/reconstitution',
          name: 'reconstitutionCalculator',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ReconstitutionCalculatorPage(
              initialStrengthValue: (extra?['strength'] as double?) ?? 0,
              unitLabel: (extra?['unit'] as String?) ?? 'mg',
              initialDoseValue: extra?['dose'] as double?,
              initialDoseUnit: extra?['doseUnit'] as String?,
              initialSyringeSize: extra?['syringe'] as SyringeSizeMl?,
              initialVialSize: extra?['vialSize'] as double?,
            );
          },
        ),
        // Dynamic detail route LAST so it doesn't eat specific paths like 'reconstitution' or 'edit/...'
        GoRoute(
          path: '/medications/:id',
          name: 'medicationDetail',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            final box = Hive.box<Medication>('medications');
            final med = id != null ? box.get(id) : null;
            return MedicationDetailPage(medicationId: id, initial: med);
          },
        ),
      ],
    ),
    // Analytics placeholder route
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const AnalyticsPage(),
    ),
  ],
);

