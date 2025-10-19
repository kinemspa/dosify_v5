class CalendarEvent {
  CalendarEvent({required this.scheduleId, required this.title, required this.when});
  final String scheduleId;
  final String title;
  final DateTime when; // local time
}
