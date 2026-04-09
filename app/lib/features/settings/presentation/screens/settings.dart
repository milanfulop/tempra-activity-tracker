import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/utils/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  ReminderMode _mode = ReminderMode.interval;
  int _intervalMinutes = 60;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dailyTime = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final saved = await NotificationService.instance.loadSettings();
    setState(() {
      _notificationsEnabled = saved['enabled'];
      _mode = saved['mode'];
      _intervalMinutes = saved['intervalMinutes'];
      _startTime = TimeOfDay(hour: saved['startHour'], minute: 0);
      _endTime = TimeOfDay(hour: saved['endHour'], minute: 0);
      _dailyTime = TimeOfDay(hour: saved['dailyHour'], minute: saved['dailyMinute']);
    });
  }

  Future<void> _saveSettings() async {
    await NotificationService.instance.saveSettings(
      enabled: _notificationsEnabled,
      mode: _mode,
      intervalMinutes: _intervalMinutes,
      startHour: _startTime.hour,
      endHour: _endTime.hour,
      dailyHour: _dailyTime.hour,
      dailyMinute: _dailyTime.minute,
    );
  }

  Future<void> _applySettings() async {
    if (!_notificationsEnabled) return;
    await _saveSettings();
    if (_mode == ReminderMode.interval) {
      await NotificationService.instance.scheduleIntervalReminders(
        intervalMinutes: _intervalMinutes,
        startHour: _startTime.hour,
        endHour: _endTime.hour,
      );
    } else {
      await NotificationService.instance.scheduleDailyReminder(
        hour: _dailyTime.hour,
        minute: _dailyTime.minute,
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _loading = true);
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
        setState(() => _loading = false);
        return;
      }
      await _applySettings();
    } else {
      await NotificationService.instance.cancelAllReminders();
      await _saveSettings();
    }
    setState(() {
      _notificationsEnabled = value;
      _loading = false;
    });
  }

  Future<void> _pickTime(TimeOfDay initial, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      onPicked(picked);
      await _applySettings();
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('Reminders'),
            subtitle: const Text('Remind me to log my activity'),
            value: _notificationsEnabled,
            onChanged: _loading ? null : _toggleNotifications,
          ),
          if (_notificationsEnabled) ...[
            // mode toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ReminderMode>(
                segments: const [
                  ButtonSegment(
                    value: ReminderMode.interval,
                    label: Text('Interval'),
                    icon: Icon(Icons.repeat),
                  ),
                  ButtonSegment(
                    value: ReminderMode.daily,
                    label: Text('Once a day'),
                    icon: Icon(Icons.schedule),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) async {
                  setState(() => _mode = s.first);
                  await _applySettings();
                },
              ),
            ),

            if (_mode == ReminderMode.interval) ...[
              ListTile(
                title: const Text('Every'),
                trailing: DropdownButton<int>(
                  value: _intervalMinutes,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('Every 15 minutes')),
                    DropdownMenuItem(value: 60, child: Text('Every hour')),
                    DropdownMenuItem(value: 120, child: Text('Every 2 hours')),
                    DropdownMenuItem(value: 240, child: Text('Every 4 hours')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _intervalMinutes = v);
                    await _applySettings();
                  },
                ),
              ),
              ListTile(
                title: const Text('From'),
                trailing: TextButton(
                  child: Text(_startTime.format(context)),
                  onPressed: () => _pickTime(
                    _startTime,
                    (t) => setState(() => _startTime = t),
                  ),
                ),
              ),
              ListTile(
                title: const Text('Until'),
                trailing: TextButton(
                  child: Text(_endTime.format(context)),
                  onPressed: () => _pickTime(
                    _endTime,
                    (t) => setState(() => _endTime = t),
                  ),
                ),
              ),
            ],

            if (_mode == ReminderMode.daily)
              ListTile(
                title: const Text('Remind me at'),
                trailing: TextButton(
                  child: Text(_dailyTime.format(context)),
                  onPressed: () => _pickTime(
                    _dailyTime,
                    (t) => setState(() => _dailyTime = t),
                  ),
                ),
              ),
          ],
          const Divider(),
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: _signOut,
          ),
          /*ElevatedButton(
            child: const Text('Test'),
            onPressed: () => NotificationService.instance.scheduleTestNotification(),
          ),*/
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}