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

final router = GoRouter(
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
  ],
);

