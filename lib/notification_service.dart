import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  // Navigation stream — emits page keys like 'events', 'announcements', 'prayer'
  static final _navController = StreamController<String>.broadcast();
  static Stream<String> get navStream => _navController.stream;

  // Only the three main prayers exist in the bundled times.
  static const _prayerOrder = ['fajr', 'dhuhr', 'maghrib'];
  static const _prayerNames = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'maghrib': 'المغرب',
  };

  Future<void> initialize() async {
    if (kIsWeb) return;
    // Local-only setup — works fully offline, safe to await.
    await _initTimezone();
    await _initLocal();
    await _requestPermissions();
    // Schedule prayer alarms FIRST, before any FCM/network call, so nothing
    // can block or delay them.
    await schedulePrayerNotifications();
    _listenForeground();
    // Network-dependent FCM calls — never block on these. They hang with no
    // internet, so run them detached and let them fail quietly offline.
    _setupTapHandlers();
    _subscribeTopics();
    _logToken();
  }

  Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    // Mosque is in Baghdad — fixed timezone
    tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final page = response.payload;
        if (page != null && page.isNotEmpty) _navController.add(page);
      },
    );

    // Channel for push announcements (matches AndroidManifest default)
    const announcementsChannel = AndroidNotificationChannel(
      'announcements',
      'الإعلانات',
      description: 'إعلانات وأخبار المسجد',
      importance: Importance.high,
    );

    // Channel for scheduled prayer times
    const prayerChannel = AndroidNotificationChannel(
      'prayer_times',
      'أوقات الصلاة',
      description: 'تنبيهات مواعيد الصلاة اليومية',
      importance: Importance.high,
    );

    final androidImpl =
        _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(announcementsChannel);
    await androidImpl?.createNotificationChannel(prayerChannel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _local
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // Shows FCM notifications when the app is open in the foreground.
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif == null) return;

      final page = message.data['page']?.toString() ?? '';
      _local.show(
        message.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'announcements',
            'الإعلانات',
            channelDescription: 'إعلانات وأخبار المسجد',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: page,
      );
    });
  }

  // Handles notification taps that open or resume the app.
  Future<void> _setupTapHandlers() async {
    // App resumed from background by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message.data);
    });

    // App launched from terminated state by tapping a notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Small delay to ensure the widget tree is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNavigation(initial.data);
      });
    }
  }

  void _handleNavigation(Map<String, dynamic> data) {
    final page = data['page']?.toString();
    if (page != null && page.isNotEmpty) _navController.add(page);
  }

  Future<void> _subscribeTopics() async {
    try {
      await _messaging.subscribeToTopic('announcements');
      await _messaging.subscribeToTopic('prayer_times');
    } catch (e) {
      debugPrint('Topic subscription failed (offline?): $e');
    }
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

  // Schedules local prayer notifications for the next 7 days.
  Future<void> schedulePrayerNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = await rootBundle.loadString('assets/prayer_times_2026.json');
      final allTimes = json.decode(raw) as Map<String, dynamic>;

      // Cancel only prayer-time notifications (IDs 0–69), keep push ones
      for (int i = 0; i < 70; i++) {
        await _local.cancel(i);
      }

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

          await _scheduleOne(
            id: day * 10 + i,
            title: 'حان وقت ${_prayerNames[prayerKey]}',
            body: 'مسجد وحسينية أهل البيت - بغداد المنصور',
            when: scheduled,
          );
        }
      }
      debugPrint('Prayer notifications scheduled');
    } catch (e) {
      debugPrint('Schedule notifications error: $e');
    }
  }

  // Schedules a single notification. Tries exact mode first; if the device
  // denies exact alarms (Android 12+ without the "Alarms & reminders"
  // permission), falls back to inexact so the alarm is still delivered.
  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_times',
        'أوقات الصلاة',
        channelDescription: 'تنبيهات مواعيد الصلاة اليومية',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    for (final mode in [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _local.zonedSchedule(
          id, title, body, when, details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        return; // success
      } catch (e) {
        debugPrint('zonedSchedule ($mode) failed: $e');
        // Loop falls through to inexact mode on the next iteration.
      }
    }
  }

  // Fires an immediate notification so the user can confirm notifications
  // are enabled and working on their device.
  Future<void> showTestNotification() async {
    try {
      await _local.show(
        999,
        'تم تفعيل التنبيهات ✅',
        'ستصلك تنبيهات أوقات الصلاة في وقتها',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_times',
            'أوقات الصلاة',
            channelDescription: 'تنبيهات مواعيد الصلاة اليومية',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Test notification error: $e');
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
