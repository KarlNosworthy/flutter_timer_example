import 'package:flutter/material.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// e.g. "Sat 10 Oct, 18:45" (respecting the device's 12/24h setting).
String formatDateTime(BuildContext context, DateTime dt) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(dt),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );
  return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}, $time';
}

/// e.g. "2h 05m 09s" or "45s".
String formatCountdown(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${_two(m)}m ${_two(s)}s';
  if (m > 0) return '${m}m ${_two(s)}s';
  return '${s}s';
}
