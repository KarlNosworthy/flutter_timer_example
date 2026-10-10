import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_entry.dart';

/// Persists timers in shared preferences.
///
/// Uses [SharedPreferencesAsync] (no in-memory cache) because the alarm
/// callback runs in a separate background isolate and writes to the same
/// store; a cached instance in the UI isolate would go stale.
class TimerStore {
  static const _timersKey = 'timers';
  static const _nextIdKey = 'next_timer_id';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<List<TimerEntry>> loadAll() async {
    final raw = await _prefs.getString(_timersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TimerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<TimerEntry> timers) =>
      _prefs.setString(
          _timersKey, jsonEncode(timers.map((t) => t.toJson()).toList()));

  /// Alarm IDs must fit in 32 bits, so hand out small sequential ints.
  Future<int> nextId() async {
    final id = await _prefs.getInt(_nextIdKey) ?? 1;
    await _prefs.setInt(_nextIdKey, id + 1);
    return id;
  }

  Future<void> add(TimerEntry entry) async {
    final timers = await loadAll();
    timers.add(entry);
    await _saveAll(timers);
  }

  Future<void> remove(int id) async {
    final timers = await loadAll();
    timers.removeWhere((t) => t.id == id);
    await _saveAll(timers);
  }

  Future<TimerEntry?> markFired(int id, DateTime firedAt) async {
    final timers = await loadAll();
    final index = timers.indexWhere((t) => t.id == id);
    if (index == -1) return null;
    timers[index] = timers[index].copyWith(firedAt: firedAt);
    await _saveAll(timers);
    return timers[index];
  }

  Future<void> clearFired() async {
    final timers = await loadAll();
    timers.removeWhere((t) => t.hasFired);
    await _saveAll(timers);
  }
}
