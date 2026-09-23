import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    final android = await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
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
      title: '🧠 Flex is ready!',
      body: streakWarning
          ? 'Your streak is still alive. Today’s workout takes about 4 minutes.'
          : 'A small brain boost is waiting in the lab.',
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_brainflex',
          'Daily BrainFlex',
          channelDescription: 'One gentle daily workout reminder',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    if (!kIsWeb) await plugin.cancel(id: 0);
  }
}
