import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService() {
    tz.initializeTimeZones();
  }

  /// Initializes notifications and requests necessary permissions
  Future<void> init() async {
    await _requestNotificationPermission();
    await _configureNotifications();
  }

  /// Request notification & exact alarm permission (Android 12+)
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Android 12+ requires exact alarms permission
    if (await Permission.scheduleExactAlarm.isDenied) {
      await openAppSettings(); // Direct user to settings if permission is not granted
    }
  }

  /// Configures notifications with initialization settings
  Future<void> _configureNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  /// Schedules a notification at a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'fitness_tracker_channel',
        'Fitness Tracker Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        platformDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      if (kDebugMode) {
        print("Notification scheduled for: $scheduledTime");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error scheduling notification: $e");
      }
    }
  }

  /// Schedule a daily reminder at 8:00 PM
  Future<void> scheduleDailyReminder() async {
    final tz.TZDateTime scheduledTime = _nextInstanceOfTime(hour: 20, minute: 00);

    await scheduleNotification(
      id: 0,
      title: 'Daily Fitness Goal',
      body: 'Don\'t forget to complete your daily fitness goals! 💪',
      scheduledTime: scheduledTime,
    );
  }

  /// Helper function to get next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1)); // Schedule for the next day if past time
    }

    return scheduledTime;
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    print('Showing test notification...');
    await _notificationsPlugin.show(
      0,
      'Daily Fitness Goal',
      'Don\'t forget to complete your daily fitness goals! 💪',
      details,
    );
  }
}
