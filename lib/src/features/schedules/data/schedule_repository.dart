import 'package:hive_flutter/hive_flutter.dart';
import '../domain/schedule.dart';

class ScheduleRepository {
  ScheduleRepository(this._box);
  final Box<Schedule> _box;

  List<Schedule> getAll() => _box.values.toList(growable: false);
  Future<void> upsert(Schedule s) => _box.put(s.id, s);
  Future<void> delete(String id) => _box.delete(id);
}
