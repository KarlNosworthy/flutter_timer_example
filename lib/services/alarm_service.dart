import '../models/timer_entry.dart';
import 'alarm_scheduler.dart';
import 'timer_store.dart';

/// Schedules and cancels alarms, keeping [TimerStore] in sync.
class AlarmService {
  AlarmService({TimerStore? store}) : _store = store ?? TimerStore();

  static final AlarmScheduler _scheduler = AlarmScheduler.forPlatform();

  final TimerStore _store;

  static Future<void> initialize() => _scheduler.initialize();

  static Future<void> requestPermissions() => _scheduler.requestPermissions();

  static List<TimerAction> get supportedActions => _scheduler.supportedActions;

  Future<TimerEntry> schedule({
    required DateTime when,
    required String label,
    required TimerAction action,
  }) async {
    final entry = TimerEntry(
      id: await _store.nextId(),
      label: label,
      action: action,
      createdAt: DateTime.now(),
      scheduledFor: when,
    );
    await _store.add(entry);

    if (!await _scheduler.schedule(entry)) {
      await _store.remove(entry.id);
      throw StateError('The system refused to schedule the alarm');
    }
    return entry;
  }

  Future<void> cancel(int id) async {
    await _scheduler.cancel(id);
    await _store.remove(id);
  }

  Future<List<TimerEntry>> loadAll() async {
    // Without a fire-time callback, record overdue timers as fired here.
    if (!_scheduler.runsCodeWhenFired) {
      return _store.markOverdueFired(DateTime.now());
    }
    return _store.loadAll();
  }

  Future<void> clearFired() => _store.clearFired();
}
