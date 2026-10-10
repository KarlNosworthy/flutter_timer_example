/// The thing that happens when an alarm fires.
enum TimerAction {
  notification('Show notification', 'Notification with sound and vibration'),
  silentNotification('Silent notification', 'Notification without sound'),
  logOnly('Log only', 'Just record that the alarm fired');

  const TimerAction(this.label, this.description);

  final String label;
  final String description;
}

/// A single scheduled alarm, persisted so it can be listed later.
class TimerEntry {
  TimerEntry({
    required this.id,
    required this.label,
    required this.action,
    required this.createdAt,
    required this.scheduledFor,
    this.firedAt,
  });

  final int id;
  final String label;
  final TimerAction action;
  final DateTime createdAt;
  final DateTime scheduledFor;
  final DateTime? firedAt;

  bool get hasFired => firedAt != null;

  Duration timeRemaining([DateTime? now]) =>
      scheduledFor.difference(now ?? DateTime.now());

  TimerEntry copyWith({DateTime? firedAt}) => TimerEntry(
        id: id,
        label: label,
        action: action,
        createdAt: createdAt,
        scheduledFor: scheduledFor,
        firedAt: firedAt ?? this.firedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'action': action.name,
        'createdAt': createdAt.toIso8601String(),
        'scheduledFor': scheduledFor.toIso8601String(),
        'firedAt': firedAt?.toIso8601String(),
      };

  factory TimerEntry.fromJson(Map<String, dynamic> json) => TimerEntry(
        id: json['id'] as int,
        label: json['label'] as String,
        action: TimerAction.values.byName(json['action'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        firedAt: json['firedAt'] == null
            ? null
            : DateTime.parse(json['firedAt'] as String),
      );
}
