import 'dart:async';

import 'package:flutter/material.dart';

import '../models/timer_entry.dart';
import '../services/alarm_service.dart';
import '../util/format.dart';
import 'new_timer_screen.dart';

class TimerListScreen extends StatefulWidget {
  const TimerListScreen({super.key});

  @override
  State<TimerListScreen> createState() => _TimerListScreenState();
}

class _TimerListScreenState extends State<TimerListScreen>
    with WidgetsBindingObserver {
  final _alarms = AlarmService();
  List<TimerEntry> _timers = [];
  bool _loading = true;
  Timer? _ticker;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AlarmService.requestPermissions();
    _reload();
    // Tick every second to update countdowns; re-read storage when a timer
    // is due so we pick up the "fired" flag written by the background isolate.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final anyDue =
          _timers.any((t) => !t.hasFired && !t.scheduledFor.isAfter(now));
      if (anyDue) _reload();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<void> _reload() async {
    if (_reloading) return;
    _reloading = true;
    try {
      final timers = await _alarms.loadAll();
      // Upcoming first (soonest at the top), then fired ones most-recent first.
      timers.sort((a, b) {
        if (a.hasFired != b.hasFired) return a.hasFired ? 1 : -1;
        return a.hasFired
            ? b.firedAt!.compareTo(a.firedAt!)
            : a.scheduledFor.compareTo(b.scheduledFor);
      });
      if (!mounted) return;
      setState(() {
        _timers = timers;
        _loading = false;
      });
    } finally {
      _reloading = false;
    }
  }

  Future<void> _openNewTimer() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NewTimerScreen(alarmService: _alarms)),
    );
    if (created == true) _reload();
  }

  Future<void> _cancel(TimerEntry entry) async {
    await _alarms.cancel(entry.id);
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(entry.hasFired
          ? 'Removed "${entry.label}"'
          : 'Cancelled "${entry.label}"'),
    ));
  }

  Future<void> _clearFired() async {
    await _alarms.clearFired();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final hasFired = _timers.any((t) => t.hasFired);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Timer'),
        actions: [
          if (hasFired)
            IconButton(
              tooltip: 'Clear fired timers',
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFired,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _timers.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: _timers.length,
                    itemBuilder: (context, i) {
                      final t = _timers[i];
                      return Dismissible(
                        key: ValueKey(t.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Icon(Icons.delete),
                        ),
                        onDismissed: (_) {
                          setState(() => _timers.removeAt(i));
                          _cancel(t);
                        },
                        child: _TimerTile(entry: t),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewTimer,
        icon: const Icon(Icons.add_alarm),
        label: const Text('New timer'),
      ),
    );
  }
}

class _TimerTile extends StatelessWidget {
  const _TimerTile({required this.entry});

  final TimerEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = entry.timeRemaining();
    final pending = !entry.hasFired;

    final String status;
    if (entry.hasFired) {
      status = 'Fired ${formatDateTime(context, entry.firedAt!)}';
    } else if (remaining.isNegative || remaining == Duration.zero) {
      status = 'Firing…';
    } else {
      status = 'Triggers in ${formatCountdown(remaining)}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              pending ? Icons.alarm : Icons.alarm_on,
              color: pending ? theme.colorScheme.primary : theme.disabledColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: pending
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detail(context, 'Alarm',
                      formatDateTime(context, entry.scheduledFor)),
                  _detail(context, 'Created',
                      formatDateTime(context, entry.createdAt)),
                  _detail(context, 'Action', entry.action.label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: '$label: ',
            style: style?.copyWith(fontWeight: FontWeight.w600)),
        TextSpan(text: value, style: style),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm_add, size: 64, color: theme.disabledColor),
          const SizedBox(height: 12),
          Text('No timers yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Tap "New timer" to schedule one.'),
        ],
      ),
    );
  }
}
