# flutter_timer_example
A example of how to trigger alarms within a flutter app

## Alarm Timer

An Android and iOS app that schedules alarms. On Android it uses
[android_alarm_manager_plus](https://pub.dev/packages/android_alarm_manager_plus);
on iOS it uses scheduled local notifications.

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
permission to schedule exact alarms. On iOS it asks for notification permission.

### iOS differences

iOS has no equivalent of Android's AlarmManager: an app can't run its own code at
a chosen time. So on iOS the notification is handed to the system when the timer
is created, and iOS delivers it at the alarm time even if the app is closed.

- **Log only** isn't offered, because no app code runs when the alarm fires.
- A timer is shown as fired once its time has passed (recorded the next time the
  list loads), rather than by a callback.
- iOS allows at most 64 pending notifications per app, sounds are limited to
  30 seconds, and Focus or silent mode can mute them.

### Code layout

- `lib/services/alarm_service.dart`: creates, cancels and lists timers using the
  platform's `AlarmScheduler` (`lib/services/alarm_scheduler.dart`).
- `lib/services/android_alarm_scheduler.dart`: AlarmManager scheduling;
  `alarmCallback` runs in a background isolate when an alarm fires.
- `lib/services/ios_notification_scheduler.dart`: scheduled notifications on iOS.
- `lib/services/timer_store.dart`: persists timers with shared_preferences.
- `lib/models/timer_entry.dart`: the timer model and available actions.
- `lib/screens/`: the timer list and new-timer screens.
