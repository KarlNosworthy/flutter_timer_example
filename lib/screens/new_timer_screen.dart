import 'package:flutter/material.dart';

import '../models/timer_entry.dart';
import '../services/alarm_service.dart';
import '../util/format.dart';

class NewTimerScreen extends StatefulWidget {
  const NewTimerScreen({super.key, required this.alarmService});

  final AlarmService alarmService;

  @override
  State<NewTimerScreen> createState() => _NewTimerScreenState();
}

class _NewTimerScreenState extends State<NewTimerScreen> {
  final _labelController = TextEditingController();
  TimeOfDay? _time;
  TimerAction _action = TimerAction.notification;
  bool _saving = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  /// The next occurrence of [_time]: today if still ahead, otherwise tomorrow.
  DateTime? get _nextOccurrence {
    final time = _time;
    if (time == null) return null;
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ??
          TimeOfDay.fromDateTime(
              DateTime.now().add(const Duration(minutes: 1))),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final when = _nextOccurrence;
    if (when == null) return;
    setState(() => _saving = true);
    final label = _labelController.text.trim();
    try {
      await widget.alarmService.schedule(
        when: when,
        label: label.isEmpty ? 'Timer' : label,
        action: _action,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not set timer: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = _nextOccurrence;

    return Scaffold(
      appBar: AppBar(title: const Text('New timer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickTime,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _time?.format(context) ?? '--:--',
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      when == null
                          ? 'Tap to choose a time'
                          : '${formatDateTime(context, when)}  ·  in '
                              '${formatCountdown(when.difference(DateTime.now()))}',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _labelController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'Timer',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Action', style: theme.textTheme.titleMedium),
          RadioGroup<TimerAction>(
            groupValue: _action,
            onChanged: (v) => setState(() => _action = v!),
            child: Column(
              children: [
                for (final action in TimerAction.values)
                  RadioListTile<TimerAction>(
                    value: action,
                    title: Text(action.label),
                    subtitle: Text(action.description),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: when == null || _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.alarm_add),
            label: const Text('Set timer'),
          ),
        ],
      ),
    );
  }
}
