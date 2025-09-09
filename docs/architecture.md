# Architecture

This document describes the final structure and decisions for the app. Use it to rebuild from scratch.

- Layers per feature: data, domain, presentation
- State: Riverpod Notifiers
- Navigation: go_router with typed route names
- Storage: Hive boxes per aggregate (in progress)
  - Box: medications (Medication)
  - Adapters: Unit(1), StockUnit(2), MedicationForm(3), Medication(10)
- UI flows implemented: Home, Medication List, Select Type, Add/Edit Tablet, Add/Edit Capsule, Add/Edit Injection (PFS, Single, Multi Vial), Reconstitution Calculator (dialog + full-screen route)
- Notifications: flutter_local_notifications + permission_handler. Channels: upcoming_dose, low_stock, expiry. Request runtime permission on startup.

