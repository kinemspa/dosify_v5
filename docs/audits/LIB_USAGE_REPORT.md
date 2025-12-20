# lib/ Usage Report

Roots used for reachability:
- `lib/main.dart`
- all `test/**/*.dart`

Legend:
- **Reachable**: reachable via import/export/part graph from roots
- **Entry-point**: contains `vm:entry-point` pragma (keep even if unreachable)

| File | Reachable | Entry-point | Inbound (lib) | Suggestion |
|---|---:|---:|---:|---|
| lib/main.dart | TRUE | FALSE | 0 | KEEP |
| lib/src/app/app.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/app/nav_items.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/app/router.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/app/shell_scaffold.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/app/theme_mode_controller.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/core/design_system.dart | TRUE | FALSE | 37 | KEEP |
| lib/src/core/hive/hive_bootstrap.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/core/hive/hive_migration_manager.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/core/notifications/notification_service.dart | TRUE | FALSE | 6 | KEEP |
| lib/src/core/utils/format.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/features/analytics/presentation/analytics_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/home/presentation/home_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/data/medication_repository.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/features/medications/domain/enums.dart | TRUE | FALSE | 26 | KEEP |
| lib/src/features/medications/domain/inventory_log.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/features/medications/domain/medication.dart | TRUE | FALSE | 31 | KEEP |
| lib/src/features/medications/domain/services/expiry_tracking_service.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/domain/services/medication_stock_service.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/features/medications/presentation/add_capsule_wizard_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/add_mdv_wizard_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/add_prefilled_syringe_wizard_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/add_single_dose_vial_wizard_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/add_tablet_wizard_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/controllers/medication_detail_controller.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/med_editor_template_demo_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/medication_detail_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/medication_display_helpers.dart | TRUE | FALSE | 4 | KEEP |
| lib/src/features/medications/presentation/medication_list_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/providers.dart | TRUE | FALSE | 5 | KEEP |
| lib/src/features/medications/presentation/reconstitution_calculator_dialog.dart | TRUE | FALSE | 5 | KEEP |
| lib/src/features/medications/presentation/reconstitution_calculator_helpers.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/reconstitution_calculator_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/reconstitution_calculator_widget.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/features/medications/presentation/select_injection_type_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/select_medication_type_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/ui_consts.dart | TRUE | FALSE | 8 | KEEP |
| lib/src/features/medications/presentation/widgets/medication_header_widget.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/widgets/medication_reports_widget.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/medications/presentation/widgets/medication_wizard_base.dart | TRUE | FALSE | 4 | KEEP |
| lib/src/features/medications/presentation/widgets/next_dose_card.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/data/dose_calculation_service.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/data/dose_log_repository.dart | TRUE | FALSE | 6 | KEEP |
| lib/src/features/schedules/data/schedule_scheduler.dart | TRUE | FALSE | 7 | KEEP |
| lib/src/features/schedules/domain/calculated_dose.dart | TRUE | FALSE | 9 | KEEP |
| lib/src/features/schedules/domain/dose_calculator.dart | TRUE | FALSE | 4 | KEEP |
| lib/src/features/schedules/domain/dose_log.dart | TRUE | FALSE | 14 | KEEP |
| lib/src/features/schedules/domain/schedule_occurrence_service.dart | TRUE | FALSE | 3 | KEEP |
| lib/src/features/schedules/domain/schedule.dart | TRUE | FALSE | 22 | KEEP |
| lib/src/features/schedules/presentation/add_edit_schedule_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/presentation/calendar_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/presentation/controllers/schedule_form_controller.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/presentation/pages/add_schedule_wizard_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/presentation/schedule_detail_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/presentation/schedules_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/presentation/select_medication_for_schedule_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/presentation/widgets/enhanced_schedule_card.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/presentation/widgets/schedule_card.dart | TRUE | FALSE | 0 | KEEP |
| lib/src/features/schedules/presentation/widgets/schedule_summary_card.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/schedules/presentation/widgets/schedule_wizard_base.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/settings/presentation/bottom_nav_settings_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/settings/presentation/debug_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/settings/presentation/settings_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/settings/presentation/wide_card_samples_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/supplies/data/supply_repository.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/features/supplies/domain/stock_movement.dart | TRUE | FALSE | 3 | KEEP |
| lib/src/features/supplies/domain/supply.dart | TRUE | FALSE | 3 | KEEP |
| lib/src/features/supplies/presentation/supplies_page.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/app_header.dart | TRUE | FALSE | 16 | KEEP |
| lib/src/widgets/calendar/calendar_day_cell.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/calendar/calendar_day_view.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/calendar/calendar_dose_block.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/widgets/calendar/calendar_header.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/widgets/calendar/calendar_month_view.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/calendar/calendar_week_view.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/calendar/dose_calendar_widget.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/widgets/detail_page_scaffold.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/dose_action_sheet.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/widgets/dose_input_field.dart | TRUE | FALSE | 2 | KEEP |
| lib/src/widgets/field36.dart | TRUE | FALSE | 11 | KEEP |
| lib/src/widgets/glass_card_surface.dart | TRUE | FALSE | 3 | KEEP |
| lib/src/widgets/large_card.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/med_editor_template.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/reconstitution_summary_card.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/smart_expiry_picker.dart | TRUE | FALSE | 6 | KEEP |
| lib/src/widgets/stock_donut_gauge.dart | TRUE | FALSE | 3 | KEEP |
| lib/src/widgets/summary_header_card.dart | TRUE | FALSE | 1 | KEEP |
| lib/src/widgets/unified_form.dart | TRUE | FALSE | 15 | KEEP |
| lib/src/widgets/white_syringe_gauge.dart | TRUE | FALSE | 5 | KEEP |
