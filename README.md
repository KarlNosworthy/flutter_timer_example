# flutter_timer_example
A example of how to trigger alarms within a flutter app

## Alarm Timer

An Android app that schedules alarms with
[android_alarm_manager_plus](https://pub.dev/packages/android_alarm_manager_plus).

- Pick a time (if it has already passed today, the alarm is set for tomorrow),
  an optional label, and an action: notification, silent notification, or log only.
- The list shows every timer with its alarm time, when it was created, and a live
  countdown until it triggers (or when it fired). Swipe left to cancel or remove one.

### Running

```sh
flutter pub get
flutter run
```

On Android 13+ the app asks for notification permission, and on Android 14+ for
permission to schedule exact alarms.

### Code layout

- `lib/services/alarm_service.dart`: schedules and cancels alarms; `alarmCallback`
  runs in a background isolate when an alarm fires.
- `lib/services/timer_store.dart`: persists timers with shared_preferences.
- `lib/models/timer_entry.dart`: the timer model and available actions.
- `lib/screens/`: the timer list and new-timer screens.
