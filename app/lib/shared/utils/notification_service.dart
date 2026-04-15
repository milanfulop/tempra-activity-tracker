import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

enum ReminderMode { interval, daily }

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'tempra_reminders';
  static const _channelName = 'Tempra Reminders';
  static const _batchSize = 5;

  static const _keyEnabled = 'notif_enabled';
  static const _keyMode = 'notif_mode';
  static const _keyIntervalMinutes = 'notif_interval_minutes';
  static const _keyStartHour = 'notif_start_hour';
  static const _keyEndHour = 'notif_end_hour';
  static const _keyDailyHour = 'notif_daily_hour';
  static const _keyDailyMinute = 'notif_daily_minute';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) => _onNotificationFired(),
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
    );
  }

  // Called when a notification fires while app is in foreground
  void _onNotificationFired() {
    rescheduleIfNeeded();
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
    final canNotify = await android?.requestNotificationsPermission();
    final ios = await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

  // Ask user to exempt app from battery optimization
  final deviceInfo = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await deviceInfo?.requestExactAlarmsPermission();

  // Also request battery optimization exemption
  if (Platform.isAndroid) {
    await Permission.ignoreBatteryOptimizations.request();
  }

    return canNotify ?? ios ?? false;
  }

  /// Schedules the next [_batchSize] interval notifications from now,
  /// skipping slots outside [startHour]..[endHour].
  Future<void> scheduleIntervalReminders({
    required int intervalMinutes,
    required int startHour,
    required int endHour,
  }) async {
    await cancelAllReminders();

    final now = tz.TZDateTime.now(tz.local);
    final futures = <Future>[];
    int id = 100;

    tz.TZDateTime candidate = now.add(Duration(minutes: intervalMinutes));
    int scheduled = 0;

    // Walk forward until we've queued _batchSize valid slots
    while (scheduled < _batchSize) {
      final h = candidate.hour;
      if (h >= startHour && h < endHour) {
        final body = intervalMinutes < 60
            ? 'What have you been up to the last $intervalMinutes minutes?'
            : 'What have you been up to the last ${intervalMinutes ~/ 60} '
                'hour${intervalMinutes > 60 ? 's' : ''}?';

        futures.add(_plugin.zonedSchedule(
          id++,
          'Time to log! ⏱',
          body,
          candidate,
          _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        ));
        scheduled++;
      }
      candidate = candidate.add(Duration(minutes: intervalMinutes));

      // Safety guard: don't loop forever if window is too narrow
      if (candidate.difference(now).inDays > 7) break;
    }

    await Future.wait(futures);
  }

  /// Schedules one daily notification at [hour]:[minute] (repeating).
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await cancelAllReminders();

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      200,
      'Daily log reminder 📋',
      'Take a moment to fill in your day.',
      scheduledTime,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Call on app start and whenever a notification fires.
  /// Tops up the batch if fewer than 2 are left pending.
  Future<void> rescheduleIfNeeded() async {
    try {
      final settings = await loadSettings();
      if (!(settings['enabled'] as bool)) return;

      final mode = settings['mode'] as ReminderMode;

      // Daily mode manages itself via matchDateTimeComponents
      if (mode == ReminderMode.daily) {
        final pending = await _plugin.pendingNotificationRequests();
        if (pending.any((n) => n.id == 200)) return; // already scheduled
        await scheduleDailyReminder(
          hour: settings['dailyHour'] as int,
          minute: settings['dailyMinute'] as int,
        );
        return;
      }

      // Interval mode: top up when running low
      final pending = await _plugin.pendingNotificationRequests();
      if (pending.length >= 2) return;

      await scheduleIntervalReminders(
        intervalMinutes: settings['intervalMinutes'] as int,
        startHour: settings['startHour'] as int,
        endHour: settings['endHour'] as int,
      );
    } catch (e) {
      print('rescheduleIfNeeded failed: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    await Future.wait([
      for (int i = 100; i < 100 + _batchSize; i++) _plugin.cancel(i),
      _plugin.cancel(200),
    ]);
  }

  Future<void> saveSettings({
    required bool enabled,
    required ReminderMode mode,
    required int intervalMinutes,
    required int startHour,
    required int endHour,
    required int dailyHour,
    required int dailyMinute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setString(_keyMode, mode.name);
    await prefs.setInt(_keyIntervalMinutes, intervalMinutes);
    await prefs.setInt(_keyStartHour, startHour);
    await prefs.setInt(_keyEndHour, endHour);
    await prefs.setInt(_keyDailyHour, dailyHour);
    await prefs.setInt(_keyDailyMinute, dailyMinute);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_keyEnabled) ?? false,
      'mode': ReminderMode.values.byName(
        prefs.getString(_keyMode) ?? ReminderMode.interval.name,
      ),
      'intervalMinutes': () {
        final saved = prefs.getInt(_keyIntervalMinutes) ?? 60;
        const validValues = [15, 60, 120, 240];
        return validValues.contains(saved) ? saved : 60;
      }(),
      'startHour': prefs.getInt(_keyStartHour) ?? 8,
      'endHour': prefs.getInt(_keyEndHour) ?? 22,
      'dailyHour': prefs.getInt(_keyDailyHour) ?? 20,
      'dailyMinute': prefs.getInt(_keyDailyMinute) ?? 0,
    };
  }
}

@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse response) {
  NotificationService.instance.rescheduleIfNeeded();


/*
  Future<void> scheduleTestNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(const Duration(seconds: 15));
    // print('now: $now');
    // print('scheduled for: $scheduled');

    await _plugin.zonedSchedule(
      999,
      'Test! ⏱',
      'Working.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // final pending = await _plugin.pendingNotificationRequests();
    // print('pending count: ${pending.length}');
    // for (final n in pending) {
    //   print('pending: ${n.id} ${n.title}');
    // }
  }
  */
}