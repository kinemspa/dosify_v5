import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../schedules/domain/schedule.dart';
import '../data/calendar_utils.dart';
import '../data/calendar_event.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

enum _CalView { month, week, day }

class _CalendarPageState extends State<CalendarPage> {
  _CalView _view = _CalView.month;
  DateTime _anchor = DateTime.now(); // selected month/week/day anchor (local)
  DateTime? _selectedDay; // for month selection accordion

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Schedule>('schedules');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
IconButton(
            tooltip: 'Schedules',
            onPressed: () => context.push('/schedules'),
            icon: const Icon(Icons.list_alt),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Schedule> b, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
child: Row(
                  children: [
                    SegmentedButton<_CalView>(
                      segments: const [
                        ButtonSegment(value: _CalView.month, label: Text('Month')),
                        ButtonSegment(value: _CalView.week, label: Text('Week')),
                        ButtonSegment(value: _CalView.day, label: Text('Day')),
                      ],
                      selected: {_view},
                      onSelectionChanged: (s) => setState(() => _view = s.first),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat.yMMMM().format(_anchor),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Previous',
                      onPressed: () => setState(() {
                        _anchor = _prev(_view, _anchor);
                        _selectedDay = null;
                      }),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Next',
                      onPressed: () => setState(() {
                        _anchor = _next(_view, _anchor);
                        _selectedDay = null;
                      }),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildView(b)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildView(Box<Schedule> b) {
    switch (_view) {
      case _CalView.month:
        return _MonthView(
          month: DateTime(_anchor.year, _anchor.month, 1),
          schedules: b,
          selectedDay: _selectedDay,
          onSelectDay: (d) => setState(() => _selectedDay = _selectedDay == d ? null : d),
        );
      case _CalView.week:
        final start = _weekStart(_anchor);
        return _WeekView(weekStart: start, schedules: b);
      case _CalView.day:
        final day = DateTime(_anchor.year, _anchor.month, _anchor.day);
        final events = CalendarUtils.eventsForDay(day, b);
        return _DayView(day: day, events: events);
    }
  }

  static DateTime _prev(_CalView v, DateTime a) => switch (v) {
        _CalView.month => DateTime(a.year, a.month - 1, 1),
        _CalView.week => a.subtract(const Duration(days: 7)),
        _CalView.day => a.subtract(const Duration(days: 1)),
      };
  static DateTime _next(_CalView v, DateTime a) => switch (v) {
        _CalView.month => DateTime(a.year, a.month + 1, 1),
        _CalView.week => a.add(const Duration(days: 7)),
        _CalView.day => a.add(const Duration(days: 1)),
      };
  static DateTime _weekStart(DateTime a) => a.subtract(Duration(days: a.weekday - 1));
}

class _MonthView extends StatelessWidget {
  const _MonthView({required this.month, required this.schedules, required this.selectedDay, required this.onSelectDay});
  final DateTime month; // first day of month
  final Box<Schedule> schedules;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = first.weekday; // 1..7
    final leadingBlanks = firstWeekday - 1;
    final totalDays = last.day;

    final events = CalendarUtils.eventsForMonth(month, schedules);
    final map = <int, List<CalendarEvent>>{};
    for (final e in events) {
      final key = DateTime(e.when.year, e.when.month, e.when.day).day;
      (map[key] ??= []).add(e);
    }

    final weekdayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekdayLabels
                .map((w) => Expanded(
                      child: Center(child: Text(w, style: Theme.of(context).textTheme.labelLarge)),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemCount: leadingBlanks + totalDays,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final date = DateTime(month.year, month.month, day);
              final list = map[day] ?? const <CalendarEvent>[];
              final isSelected = selectedDay != null &&
                  selectedDay!.year == date.year &&
                  selectedDay!.month == date.month &&
                  selectedDay!.day == date.day;
              return InkWell(
                onTap: () => onSelectDay(date),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$day', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: list.take(3).map((e) => _dot(context)).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (selectedDay != null)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            height: 220,
            child: _DayView(day: selectedDay!, events: CalendarUtils.eventsForDay(selectedDay!, schedules)),
          ),
      ],
    );
  }

  Widget _dot(BuildContext context) => Container(width: 6, height: 6, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle));
}

class _WeekView extends StatelessWidget {
  const _WeekView({required this.weekStart, required this.schedules});
  final DateTime weekStart; // Monday
  final Box<Schedule> schedules;

  @override
  Widget build(BuildContext context) {
    final labels = List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      return '${['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i]} ${d.day}';
    });
    final events = CalendarUtils.eventsForWeek(weekStart, schedules);
    final map = <int, List<CalendarEvent>>{};
    for (final e in events) {
      final key = DateTime(e.when.year, e.when.month, e.when.day).difference(weekStart).inDays;
      (map[key] ??= []).add(e);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: labels.map((l) => Expanded(child: Center(child: Text(l)))).toList(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: List.generate(7, (i) {
              final dayEvents = (map[i] ?? [])..sort((a, b) => a.when.compareTo(b.when));
              return Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, idx) {
                    final e = dayEvents[idx];
                    final t = TimeOfDay.fromDateTime(e.when).format(context);
                    return Card(
                      child: ListTile(
                        dense: true,
                        title: Text(e.title),
                        subtitle: Text(t),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DayView extends StatelessWidget {
  const _DayView({required this.day, required this.events});
  final DateTime day;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final list = [...events]..sort((a, b) => a.when.compareTo(b.when));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = list[i];
        final t = TimeOfDay.fromDateTime(e.when).format(context);
        return ListTile(
          leading: const Icon(Icons.medication)
,          title: Text(e.title),
          subtitle: Text(t),
        );
      },
    );
  }
}

