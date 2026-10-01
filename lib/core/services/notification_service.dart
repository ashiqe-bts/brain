import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final plugin = FlutterLocalNotificationsPlugin();
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    if (kIsWeb) return;
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final android = await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return android ?? true;
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required bool streakWarning,
  }) async {
    if (kIsWeb) return;
    await plugin.cancel(id: 0);
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await plugin.zonedSchedule(
      id: 0,
      title: AppText.notifications.title,
      body: streakWarning
          ? AppText.notifications.streakBody
          : AppText.notifications.body,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_brainflex',
          AppText.notifications.channelName,
          channelDescription: AppText.notifications.channelDescription,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    if (!kIsWeb) await plugin.cancel(id: 0);
  }
}
