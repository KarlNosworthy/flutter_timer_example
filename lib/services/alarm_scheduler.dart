import 'dart:io';

import '../models/timer_entry.dart';
import 'android_alarm_scheduler.dart';
import 'ios_notification_scheduler.dart';

/// Platform-specific way of making something happen at a given time.
abstract class AlarmScheduler {
  factory AlarmScheduler.forPlatform() =>
      Platform.isIOS ? IosNotificationScheduler() : AndroidAlarmScheduler();

  Future<void> initialize();

  Future<void> requestPermissions();

  /// Actions this platform can perform when an alarm fires.
  List<TimerAction> get supportedActions;

  /// Whether app code runs at fire time and records `firedAt` itself.
  ///
  /// When false (iOS), timers are treated as fired once their time passes.
  bool get runsCodeWhenFired;

  /// Returns false if the platform refused to schedule the alarm.
  Future<bool> schedule(TimerEntry entry);

  Future<void> cancel(int id);
}
