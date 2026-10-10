import 'dart:developer' as developer;
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/timer_entry.dart';
import 'alarm_scheduler.dart';
import 'timer_store.dart';

const _channelId = 'alarm_timer_alarms';
const _silentChannelId = 'alarm_timer_silent';

/// Entry point invoked by AlarmManager in a background isolate.
///
/// Must be a top-level function annotated with `vm:entry-point` so it
/// survives tree shaking in release builds.
@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  DartPluginRegistrant.ensureInitialized();

  final entry = await TimerStore().markFired(id, DateTime.now());
  final label = entry?.label ?? params['label'] as String? ?? 'Timer';
  final action = entry?.action ??
      TimerAction.values.byName(
          params['action'] as String? ?? TimerAction.notification.name);

  developer.log('Alarm $id fired: "$label" (${action.name})',
      name: 'alarm_timer');

  switch (action) {
    case TimerAction.notification:
      await _showNotification(id, label, silent: false);
    case TimerAction.silentNotification:
      await _showNotification(id, label, silent: true);
    case TimerAction.logOnly:
      break;
  }
}

Future<void> _showNotification(int id, String label,
    {required bool silent}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await plugin.show(
    id: id,
    title: 'Alarm Timer',
    body: label,
    notificationDetails: NotificationDetails(
      android: silent
          ? const AndroidNotificationDetails(
              _silentChannelId,
              'Silent timers',
              importance: Importance.low,
              priority: Priority.low,
              playSound: false,
              enableVibration: false,
            )
          : const AndroidNotificationDetails(
              _channelId,
              'Timers',
              importance: Importance.max,
              priority: Priority.high,
              category: AndroidNotificationCategory.alarm,
            ),
    ),
  );
}

/// Uses AlarmManager so [alarmCallback] runs at the exact alarm time, even
/// if the app has been closed.
class AndroidAlarmScheduler implements AlarmScheduler {
  @override
  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  /// Asks for notification and exact-alarm permissions (Android 13/14+).
  @override
  Future<void> requestPermissions() async {
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.requestNotificationsPermission();
    if (await android.canScheduleExactNotifications() != true) {
      await android.requestExactAlarmsPermission();
    }
  }

  @override
  List<TimerAction> get supportedActions => TimerAction.values;

  @override
  bool get runsCodeWhenFired => true;

  @override
  Future<bool> schedule(TimerEntry entry) => AndroidAlarmManager.oneShotAt(
        entry.scheduledFor,
        entry.id,
        alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: {'label': entry.label, 'action': entry.action.name},
      );

  @override
  Future<void> cancel(int id) => AndroidAlarmManager.cancel(id);
}
