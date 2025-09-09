# Architecture

This document will grow with the implementation. Initial notes:

- Layers per feature: data, domain, presentation
- State: Riverpod Notifiers
- Navigation: go_router with typed route names
- Storage: Hive boxes per aggregate (in progress)
  - Box: medications (Medication)
  - Adapters: Unit(1), StockUnit(2), MedicationForm(3), Medication(10)
- UI flows implemented: Home, Medication List, Select Type, Add/Edit Tablet, Add/Edit Capsule
- Notifications: flutter_local_notifications with timezone (planned)

