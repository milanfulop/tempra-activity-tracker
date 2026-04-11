import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

enum ReminderMode { interval, daily }

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'tempra_reminders';
  static const _channelName = 'Tempra Reminders';

  static const _keyEnabled = 'notif_enabled';
  static const _keyMode = 'notif_mode';
  static const _keyIntervalMinutes = 'notif_interval_minutes';
  static const _keyStartHour = 'notif_start_hour';
  static const _keyEndHour = 'notif_end_hour';
  static const _keyDailyHour = 'notif_daily_hour';
  static const _keyDailyMinute = 'notif_daily_minute';

  Future<void> init() async {
    tz.initializeTimeZones();
    final String localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<bool> requestPermission() async {
    final android = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? false;
  }

  /// Schedules interval reminders every [intervalHours] hours,
  /// only firing between [startHour] and [endHour] (24h).
  Future<void> scheduleIntervalReminders({
    required int intervalMinutes,
    required int startHour,
    required int endHour,
  }) async {
    await cancelAllReminders();

    final now = tz.TZDateTime.now(tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    int id = 100;

    tz.TZDateTime candidate = now.add(Duration(minutes: intervalMinutes));
    int scheduled = 0;
    while (scheduled < 48) {
      final h = candidate.hour;
      if (h >= startHour && h < endHour) {
        await _plugin.zonedSchedule(
          id++,
          'Time to log! ⏱',
          intervalMinutes < 60
              ? 'What have you been up to the last $intervalMinutes minutes?'
              : 'What have you been up to the last ${intervalMinutes ~/ 60} hour${intervalMinutes > 60 ? 's' : ''}?',
          candidate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        scheduled++;
      }
      candidate = candidate.add(Duration(minutes: intervalMinutes));
    }
  }

  /// Schedules one notification per day at [hour]:[minute].
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await cancelAllReminders();

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

    tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // if today's time already passed, start tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      200,
      'Daily log reminder 📋',
      'Take a moment to fill in your day.',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  Future<void> cancelAllReminders() async {
    for (int i = 100; i < 150; i++) await _plugin.cancel(i);
    await _plugin.cancel(200);
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
      'intervalMinutes': prefs.getInt(_keyIntervalMinutes) ?? 60,
      'startHour': prefs.getInt(_keyStartHour) ?? 8,
      'endHour': prefs.getInt(_keyEndHour) ?? 22,
      'dailyHour': prefs.getInt(_keyDailyHour) ?? 20,
      'dailyMinute': prefs.getInt(_keyDailyMinute) ?? 0,
    };
  }

  /*Future<void> scheduleTestNotification() async {
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
    print('now: $now');
    print('scheduled for: $scheduled');

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

    final pending = await _plugin.pendingNotificationRequests();
    print('pending count: ${pending.length}');
    for (final n in pending) {
      print('pending: ${n.id} ${n.title}');
    }
  }*/
}