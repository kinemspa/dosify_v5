import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_page.dart';
import '../features/medications/presentation/medication_list_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_page.dart';
import '../features/medications/presentation/medication_list_page.dart';
import '../features/medications/presentation/select_medication_type_page.dart';
import '../features/medications/presentation/select_injection_type_page.dart';
import '../features/medications/presentation/add_edit_tablet_page.dart';
import '../features/medications/presentation/add_edit_capsule_page.dart';
import '../features/medications/presentation/add_edit_injection_pfs_page.dart';
import '../features/medications/presentation/add_edit_injection_single_vial_page.dart';
import '../features/medications/presentation/add_edit_injection_multi_vial_page.dart';
import '../features/medications/presentation/reconstitution_calculator_page.dart';
import '../features/schedules/presentation/schedules_page.dart';
import '../features/settings/presentation/settings_page.dart';
import 'shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
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
          path: '/schedules',
          name: 'schedules',
          builder: (context, state) => const SchedulesPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
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
          builder: (context, state) => const AddEditTabletPage(),
        ),
        GoRoute(
          path: '/medications/add/capsule',
          name: 'addCapsule',
          builder: (context, state) => const AddEditCapsulePage(),
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
      ],
    ),
  ],
);

