import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler;
import 'package:timezone/standalone.dart' as tz;
import 'package:workmanager/workmanager.dart';

class Notifications {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  static final onNotification = BehaviorSubject<String?>();

  static Future<NotificationDetails> _notificationDetails() async {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'channel id',
        'channel name',
        channelDescription: 'channel description',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  static Future<void> init({bool initScheduled = false}) async {
    await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings()),
        onDidReceiveNotificationResponse: (payload) async {
          onNotification.add(payload.payload);
        });
  }

  static Future<void> registerDailyForecastNotifications(
      {required TimeOfDay? time}) async {
    final int minutesNow = DateTime.now().minute + DateTime.now().hour;
    final int minutesThen = time == null ? 540 : time.hour + time.minute; //default time - 8AM
    int dur = 0;
    dur = minutesNow > minutesThen
        ? 1440 - minutesNow + minutesThen
        : minutesThen - minutesNow;
    await Workmanager().registerPeriodicTask(
        'dailyForecastNotifications', 'schedule_weather_notification_task',
        frequency: Duration(days: 1),
        initialDelay: Duration(minutes: dur),
        constraints: Constraints(networkType: NetworkType.connected));
  }

  static Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async =>
      flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        await _notificationDetails(),
        payload: payload,
      );

  static void showScheduledDailyNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    required Time time,
    //required DateTime scheduleDateTime,
  }) async =>
      flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _scheduleDaily(time),
        await _notificationDetails(),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

  static tz.TZDateTime _scheduleDaily(Time time) {
    final now = tz.TZDateTime.now(tz.getLocation('Europe/Warsaw'));
    final scheduledDate = tz.TZDateTime(
      tz.getLocation('Europe/Warsaw'),
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );
    return scheduledDate.isBefore(now)
        ? scheduledDate.add(const Duration(days: 1))
        : scheduledDate;
  }

  static void requestNotificationPermissions() async{
    final perm_handler.PermissionStatus status = await perm_handler.Permission.notification.request();
    if (status.isGranted) {
      // Notification permissions granted
    } else if (status.isDenied) {
      // Notification permissions denied
    } else if (status.isPermanentlyDenied) {
      // Notification permissions permanently denied, open app settings
    }
  }

  static Future<bool> checkNotificationPermissions() async{
    final perm_handler.PermissionStatus status = await perm_handler.Permission.notification.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      return false;
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return false;
  }
}
