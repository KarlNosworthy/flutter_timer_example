import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer_example/models/timer_entry.dart';
import 'package:flutter_timer_example/services/timer_store.dart';
import 'package:flutter_timer_example/util/format.dart';

void main() {
  test('TimerEntry round-trips through JSON', () {
    final entry = TimerEntry(
      id: 7,
      label: 'Tea',
      action: TimerAction.silentNotification,
      createdAt: DateTime(2026, 10, 10, 9, 0),
      scheduledFor: DateTime(2026, 10, 10, 9, 5),
    );
    final copy = TimerEntry.fromJson(entry.toJson());
    expect(copy.id, 7);
    expect(copy.label, 'Tea');
    expect(copy.action, TimerAction.silentNotification);
    expect(copy.scheduledFor, entry.scheduledFor);
    expect(copy.hasFired, isFalse);
  });

  test('formatCountdown', () {
    expect(formatCountdown(const Duration(seconds: 9)), '9s');
    expect(formatCountdown(const Duration(minutes: 3, seconds: 4)), '3m 04s');
    expect(formatCountdown(const Duration(hours: 2, minutes: 5, seconds: 9)),
        '2h 05m 09s');
    expect(formatCountdown(const Duration(seconds: -5)), '0s');
  });

  test('markOverdue marks only past, unfired timers as fired', () {
    final now = DateTime(2026, 10, 10, 12, 0);
    TimerEntry make(int id, DateTime at, {DateTime? firedAt}) => TimerEntry(
          id: id,
          label: 't$id',
          action: TimerAction.notification,
          createdAt: DateTime(2026, 10, 10, 9, 0),
          scheduledFor: at,
          firedAt: firedAt,
        );
    final earlier = DateTime(2026, 10, 10, 11, 0);
    final result = markOverdue([
      make(1, earlier),
      make(2, DateTime(2026, 10, 10, 13, 0)),
      make(3, earlier, firedAt: DateTime(2026, 10, 10, 11, 0, 5)),
    ], now);

    expect(result.changed, isTrue);
    expect(result.entries[0].firedAt, earlier);
    expect(result.entries[1].hasFired, isFalse);
    expect(result.entries[2].firedAt, DateTime(2026, 10, 10, 11, 0, 5));
    expect(markOverdue([make(2, DateTime(2026, 10, 10, 13, 0))], now).changed,
        isFalse);
  });
}
