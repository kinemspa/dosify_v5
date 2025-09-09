import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_page.dart';
import '../features/medications/presentation/medication_list_page.dart';
import '../features/medications/presentation/select_medication_type_page.dart';
import '../features/medications/presentation/add_edit_tablet_page.dart';
import '../features/medications/presentation/add_edit_capsule_page.dart';

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
      path: '/medications/add/tablet',
      name: 'addTablet',
      builder: (context, state) => const AddEditTabletPage(),
    ),
    GoRoute(
      path: '/medications/add/capsule',
      name: 'addCapsule',
      builder: (context, state) => const AddEditCapsulePage(),
    ),
  ],
);

