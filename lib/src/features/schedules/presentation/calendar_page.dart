import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/calendar/dose_calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Full-screen calendar page.
///
/// This page provides a complete calendar view of all scheduled doses.
/// Features:
/// - Full calendar widget with all views (Day/Week/Month)
/// - Tap dose → show dose detail dialog
/// - FAB → add new schedule
/// - Deep linking support (navigate to specific date)
/// - Navigation from bottom bar or drawer
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => CalendarPage()),
/// );
///
/// // Navigate to specific date
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => CalendarPage(initialDate: DateTime(2025, 12, 25)),
///   ),
/// );
/// ```
class CalendarPage extends StatelessWidget {
  const CalendarPage({
    this.initialDate,
    this.scheduleId,
    this.medicationId,
    super.key,
  });

  final DateTime? initialDate;
  final String? scheduleId;
  final String? medicationId;

  void _navigateToAddSchedule(BuildContext context) {
    context.push('/schedules/add');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Calendar', forceBackButton: true),
      body: SafeArea(
        child: DoseCalendarWidget(
          variant: CalendarVariant.full,
          startDate: initialDate,
          scheduleId: scheduleId,
          medicationId: medicationId,
          showUpNextCard: false,
          requireHourSelectionInDayView: false,
          // Use default bottom sheet handler (removed onDoseTap override)
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddSchedule(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Schedule'),
      ),
    );
  }
}
