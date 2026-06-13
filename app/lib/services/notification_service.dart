import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../firebase_options.dart';
import 'backend_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    await Firebase.initializeApp(options: options);
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _streak = 0;
  static String _goal = 'maintain';
  static int _proteinShort = 0;

  /// Refresh reminder copy from the signed-in user (call after login / data load).
  static Future<void> refreshPersonalizedReminders({
    int streak = 0,
    String goal = 'maintain',
    int proteinShort = 0,
  }) async {
    _streak = streak;
    _goal = goal;
    _proteinShort = proteinShort;
    if (_initialized) await scheduleAllReminders();
  }

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _requestPermissions();
    }

    if (BackendConfig.hasFirebase) {
      await _initFirebaseMessaging();
    }

    await scheduleAllReminders();
    _initialized = true;
  }

  /// 8am morning brief, 8pm check-in, Sunday weekly insights.
  static Future<void> scheduleAllReminders() async {
    await scheduleMorningBrief();
    await scheduleEveningCheckIn();
    await scheduleWeeklyInsights();
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
    await _local
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> _initFirebaseMessaging() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission();

      FirebaseMessaging.onMessage.listen((message) {
        _showLocalNotification(
          title: message.notification?.title ?? 'Gym Companion',
          body: message.notification?.body ?? '',
        );
      });

      await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Firebase messaging init skipped: $e');
    }
  }

  static Future<void> scheduleMorningBrief() async {
    final body = _streak >= 3
        ? '$_streak-day streak — check your workout and meals for today'
        : 'Mara has your workout and meal plan ready';
    await _scheduleDaily(
      id: 1,
      hour: 8,
      title: '🌅 Morning brief',
      body: body,
      channel: 'morning',
    );
  }

  static Future<void> scheduleEveningCheckIn() async {
    final body = _proteinShort > 20
        ? "You're ${_proteinShort}g protein short — log dinner to protect your streak"
        : _streak > 0
            ? "Don't break your $_streak-day streak — log food or training"
            : 'Log your workout or meals to stay on track';
    await _scheduleDaily(
      id: 2,
      hour: 20,
      title: '💪 Evening check-in',
      body: body,
      channel: 'evening',
    );
  }

  static Future<void> scheduleWeeklyInsights() async {
    try {
      await _local.cancel(3);
      final scheduled = _nextSundayNineAm();
      final goalLine = _goal == 'cut' ? 'cutting' : _goal == 'bulk' ? 'bulking' : 'maintaining';
      await _local.zonedSchedule(
        3,
        '📊 Weekly recap',
        'See how your $goalLine week went and plan the next one',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails('weekly', 'Weekly Insights'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Weekly reminder skipped: $e');
    }
  }

  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required String title,
    required String body,
    required String channel,
  }) async {
    try {
      await _local.cancel(id);
      final scheduled = _nextAt(hour);
      await _local.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(channel, channel),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Schedule $channel skipped: $e');
    }
  }

  static tz.TZDateTime _nextAt(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  static tz.TZDateTime _nextSundayNineAm() {
    final now = tz.TZDateTime.now(tz.local);
    var daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) daysUntilSunday += 7;
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day + daysUntilSunday, 9);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 7));
    return scheduled;
  }

  static Future<void> _showLocalNotification({required String title, required String body}) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails('general', 'General'),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
