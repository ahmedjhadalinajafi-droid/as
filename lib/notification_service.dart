import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const _prayerOrder = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const _prayerNames = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  Future<void> initialize() async {
    if (kIsWeb) return;
    await _initTimezone();
    await _initLocal();
    await _requestPermissions();
    _listenForeground();
    await _subscribeTopics();
    _logToken();
    await schedulePrayerNotifications();
  }

  Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
    }
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(const InitializationSettings(android: android, iOS: ios));

    const channel = AndroidNotificationChannel(
      'prayer_times',
      'أوقات الصلاة',
      description: 'تنبيهات مواعيد الصلاة اليومية',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _local
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: false, sound: true);
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM: ${message.notification?.title}');
    });
  }

  Future<void> _subscribeTopics() async {
    await _messaging.subscribeToTopic('announcements');
    await _messaging.subscribeToTopic('prayer_times');
  }

  Future<void> _logToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token ?? '');
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  // Schedules prayer notifications for the next 7 days based on stored prefs.
  Future<void> schedulePrayerNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = await rootBundle.loadString('assets/prayer_times_2026.json');
      final allTimes = json.decode(raw) as Map<String, dynamic>;

      await _local.cancelAll();

      final now = tz.TZDateTime.now(tz.local);

      for (int day = 0; day < 7; day++) {
        final date = now.add(Duration(days: day));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final times = allTimes[key];
        if (times == null || times is! Map) continue;

        for (int i = 0; i < _prayerOrder.length; i++) {
          final prayerKey = _prayerOrder[i];
          final enabled = prefs.getBool('notif_$prayerKey') ?? true;
          if (!enabled) continue;

          final timeStr = times[prayerKey]?.toString();
          if (timeStr == null) continue;
          final parts = timeStr.split(':');
          if (parts.length < 2) continue;

          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          final scheduled = tz.TZDateTime(tz.local, date.year, date.month, date.day, h, m);
          if (scheduled.isBefore(now)) continue;

          await _local.zonedSchedule(
            day * 10 + i,
            'حان وقت ${_prayerNames[prayerKey]}',
            'مسجد وحسينية أهل البيت - بغداد المنصور',
            scheduled,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'prayer_times',
                'أوقات الصلاة',
                channelDescription: 'تنبيهات مواعيد الصلاة اليومية',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: false,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
      debugPrint('Prayer notifications scheduled');
    } catch (e) {
      debugPrint('Schedule notifications error: $e');
    }
  }

  Future<void> setPrayerNotification(String prayerKey, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$prayerKey', enabled);
    await schedulePrayerNotifications();
  }

  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {for (final k in _prayerOrder) k: prefs.getBool('notif_$k') ?? true};
  }
}
