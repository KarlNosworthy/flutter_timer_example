import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/timer_entry.dart';
import 'alarm_scheduler.dart';

/// iOS has no AlarmManager equivalent: apps can't run code at a chosen time.
/// Instead the notification is handed to the system up front, and iOS
/// delivers it at the alarm time even if the app is closed.
class IosNotificationScheduler implements AlarmScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        // Permissions are requested explicitly in [requestPermissions].
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
  }

  /// "Log only" needs code to run at fire time, which iOS doesn't allow.
  @override
  List<TimerAction> get supportedActions =>
      [TimerAction.notification, TimerAction.silentNotification];

  @override
  bool get runsCodeWhenFired => false;

  @override
  Future<bool> schedule(TimerEntry entry) async {
    final silent = entry.action == TimerAction.silentNotification;
    await _plugin.zonedSchedule(
      id: entry.id,
      title: 'Alarm Timer',
      body: entry.label,
      // A one-off alarm is a single instant, so UTC avoids needing the
      // device's time zone name.
      scheduledDate: tz.TZDateTime.from(entry.scheduledFor, tz.UTC),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: !silent,
          // Passive notifications go straight to Notification Centre
          // without sound or lighting the screen.
          interruptionLevel:
              silent ? InterruptionLevel.passive : InterruptionLevel.active,
        ),
      ),
    );
    return true;
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
