// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/app/app_navigator.dart';
import 'package:dosifi_v5/src/features/disclaimer/data/disclaimer_preferences.dart';
import 'package:dosifi_v5/src/features/disclaimer/presentation/disclaimer_page.dart';
import 'package:dosifi_v5/src/features/settings/presentation/legal_page.dart';
import 'package:dosifi_v5/src/app/shell_scaffold.dart';
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/monetization/entitlement_service.dart';
import 'package:dosifi_v5/src/features/analytics/presentation/analytics_page.dart';
import 'package:dosifi_v5/src/features/inventory/presentation/inventory_page.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/calendar_page.dart';
import 'package:dosifi_v5/src/features/home/presentation/home_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/med_editor_template_demo_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_detail_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_list_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_dialog.dart';
import 'package:dosifi_v5/src/features/medications/presentation/reconstitution_calculator_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/select_injection_type_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/select_medication_type_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/add_mdv_wizard_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/add_tablet_wizard_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/add_capsule_wizard_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/add_prefilled_syringe_wizard_page.dart';
import 'package:dosifi_v5/src/features/medications/presentation/add_single_dose_vial_wizard_page.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/pages/add_schedule_wizard_page.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedule_detail_page.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/schedules_page.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/select_medication_for_schedule_page.dart';
import 'package:dosifi_v5/src/features/settings/presentation/bottom_nav_settings_page.dart';
import 'package:dosifi_v5/src/features/settings/presentation/debug_page.dart';
import 'package:dosifi_v5/src/features/settings/presentation/settings_page.dart';
import 'package:dosifi_v5/src/features/supplies/presentation/supplies_page.dart';

// Removed incorrect import
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Singleton notifier driving the first-run disclaimer gate.
/// Initialised via [initDisclaimerNotifier] in main.dart before runApp.
final disclaimerNotifier = DisclaimerNotifier();

Future<String?> _guardMedicationAddRoutes() async {
  final prefs = await SharedPreferences.getInstance();
  final isPro = prefs.getBool(kEntitlementIsProPrefsKey) ?? false;
  if (isPro) return null;

  final medicationsBox = Hive.box<Medication>('medications');
  if (medicationsBox.length < kFreeTierMedicationLimit) return null;
  return '/medications';
}

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  // Start at home by default
  initialLocation: '/',
  refreshListenable: disclaimerNotifier,
  redirect: (context, state) {
    if (!disclaimerNotifier.isAccepted &&
        state.matchedLocation != '/disclaimer' &&
        state.matchedLocation != '/legal') {
      return '/disclaimer';
    }
    return null;
  },
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
          path: '/reconstitution',
          name: 'reconstitutionAlias',
          redirect: (context, state) => '/medications/reconstitution',
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CalendarPage(
              initialDate: extra?['initialDate'] as DateTime?,
              scheduleId: extra?['scheduleId'] as String?,
              medicationId: extra?['medicationId'] as String?,
            );
          },
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
          path: '/inventory',
          name: 'inventory',
          builder: (context, state) => const InventoryPage(),
        ),
        GoRoute(
          path: '/supplies/add',
          name: 'addSupply',
          builder: (context, state) => const AddEditSupplyPage(),
        ),
        GoRoute(
          path: '/schedules/add',
          name: 'addSchedule',
          builder: (context, state) => const AddScheduleWizardPage(),
        ),
        GoRoute(
          path: '/schedules/detail/:id',
          name: 'scheduleDetail',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            if (id == null || id.trim().isEmpty) {
              return Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(kSpacingXXL),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: kEmptyStateIconSize,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: kSpacingM),
                          Text(
                            'Invalid schedule link',
                            style: sectionTitleStyle(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: kSpacingM),
                          FilledButton(
                            onPressed: () => context.pop(),
                            child: const Text('Back'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return ScheduleDetailPage(scheduleId: id);
          },
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
            if (id == null) return const AddScheduleWizardPage();
            return AddScheduleWizardPage(initialScheduleId: id);
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
          path: '/settings/debug',
          name: 'debug',
          redirect: (context, state) => kDebugMode ? null : '/settings',
          builder: (context, state) => const DebugPage(),
        ),
        // Nested under shell so bottom nav persists
        GoRoute(
          path: '/medications/select-type',
          name: 'selectMedicationType',
          redirect: (context, state) => _guardMedicationAddRoutes(),
          builder: (context, state) => const SelectMedicationTypePage(),
        ),
        GoRoute(
          path: '/medications/add/template',
          name: 'addTemplatePreview',
          redirect: (context, state) => _guardMedicationAddRoutes(),
          builder: (context, state) => const EditorTemplatePreviewPage(),
        ),
        GoRoute(
          path: '/medications/select-injection-type',
          name: 'selectInjectionType',
          builder: (context, state) => const SelectInjectionTypePage(),
        ),
        // Wizard routes (preferred)
        GoRoute(
          path: '/medications/add/tablet',
          name: 'addTablet',
          redirect: (context, state) => _guardMedicationAddRoutes(),
          builder: (context, state) => const AddTabletWizardPage(),
        ),
        GoRoute(
          path: '/medications/add/capsule',
          name: 'addCapsule',
          redirect: (context, state) => _guardMedicationAddRoutes(),
          builder: (context, state) => const AddCapsuleWizardPage(),
        ),
        GoRoute(
          path: '/medications/add/injection/pfs',
          name: 'addInjectionPfs',
          redirect: (context, state) => _guardMedicationAddRoutes(),
          builder: (context, state) => const AddPrefilledSyringeWizardPage(),
        ),
        GoRoute(
          path: '/medications/add/injection/single',
          name: 'addInjectionSingle',
          redirect: (context, state) => _guardMedicationAddRoutes(),
          builder: (context, state) => const AddSingleDoseVialWizardPage(),
        ),
        GoRoute(
          path: '/medications/add/injection/multi',
          name: 'addInjectionMulti',
          redirect: (context, state) => _guardMedicationAddRoutes(),
          builder: (context, state) => const AddMdvWizardPage(),
        ),
        // Edit routes must come before the dynamic detail route so they don't get swallowed by '/medications/:id'
        GoRoute(
          path: '/medications/edit/tablet/:id',
          name: 'editTablet',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return AddTabletWizardPage(initialMedicationId: id);
          },
        ),
        GoRoute(
          path: '/medications/edit/capsule/:id',
          name: 'editCapsule',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return AddCapsuleWizardPage(initialMedicationId: id);
          },
        ),
        GoRoute(
          path: '/medications/edit/injection/pfs/:id',
          name: 'editInjectionPfs',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return AddPrefilledSyringeWizardPage(initialMedicationId: id);
          },
        ),
        GoRoute(
          path: '/medications/edit/injection/single/:id',
          name: 'editInjectionSingle',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return AddSingleDoseVialWizardPage(initialMedicationId: id);
          },
        ),
        GoRoute(
          path: '/medications/edit/injection/multi/:id',
          name: 'editInjectionMulti',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return AddMdvWizardPage(initialMedicationId: id);
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
            return MedicationDetailPage(medicationId: id);
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
    // Disclaimer gate — full-screen, outside ShellRoute (no bottom nav)
    // Pass `extra: true` when navigating from Settings (read-only mode).
    GoRoute(
      path: '/disclaimer',
      name: 'disclaimer',
      builder: (context, state) {
        final readOnly = state.extra as bool? ?? false;
        return DisclaimerPage(
          notifier: disclaimerNotifier,
          readOnly: readOnly,
          onAcknowledged: readOnly ? null : () => context.go('/'),
          onClose: readOnly ? () => context.pop() : null,
          onNavigateToLegal: () => context.push('/legal'),
        );
      },
    ),
    // Legal page — full-screen, outside ShellRoute (no bottom nav)
    GoRoute(
      path: '/legal',
      name: 'legal',
      builder: (context, state) => const LegalPage(),
    ),
  ],
);
