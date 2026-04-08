import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'tempra_reminders';
  static const _channelName = 'Tempra Reminders';

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // we'll request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<bool> requestPermission() async {
    // Android 13+
    final android = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return android ?? ios ?? false;
  }

  /// Schedules a notification every [intervalHours] hours starting from now.
  /// Uses IDs 100, 101, 102... so you can schedule multiple intervals.
  Future<void> scheduleHourlyReminders({int intervalHours = 1}) async {
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

    // Schedule 48 notifications (covers 2 days for hourly, more for longer intervals)
    // OS will fire them one by one. You re-schedule on app open.
    for (int i = 1; i <= 48; i++) {
      final scheduledTime = now.add(Duration(hours: intervalHours * i));
      await _plugin.zonedSchedule(
        100 + i,
        'Time to log! ⏱',
        'What have you been up to the last $intervalHours hour${intervalHours > 1 ? 's' : ''}?',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelAllReminders() async {
    for (int i = 1; i <= 48; i++) {
      await _plugin.cancel(100 + i);
    }
  }
}