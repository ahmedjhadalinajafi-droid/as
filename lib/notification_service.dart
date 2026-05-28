import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _prayerChannelId = 'prayer_times';
  static const _announcementChannelId = 'announcements';

  Future<void> initialize() async {
    if (kIsWeb) return;
    await _requestPermissions();
    await _initLocalNotifications();
    _listenForeground();
    await _subscribeTopics();
    _logToken();
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: false,
    );
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _prayerChannelId,
            'أوقات الصلاة',
            description: 'تذكير بأوقات الصلاة',
            importance: Importance.max,
            playSound: true,
          ),
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _announcementChannelId,
            'إعلانات المسجد',
            description: 'إعلانات وأخبار مسجد أهل البيت',
            importance: Importance.high,
          ),
        );
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;
      final isAnnouncement = message.data['type'] == 'announcement';
      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'مسجد أهل البيت',
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            isAnnouncement ? _announcementChannelId : _prayerChannelId,
            isAnnouncement ? 'إعلانات المسجد' : 'أوقات الصلاة',
            importance: Importance.max,
            priority: Priority.max,
            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
            ),
          ),
        ),
      );
    });
  }

  Future<void> _subscribeTopics() async {
    await _messaging.subscribeToTopic('announcements');
    await _messaging.subscribeToTopic('prayer_times');
  }

  Future<void> _logToken() async {
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token ?? '');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> showPrayerNotification(String prayerName) async {
    if (kIsWeb) return;
    await _localNotifications.show(
      prayerName.hashCode,
      'حان وقت $prayerName',
      'مسجد وحسينية أهل البيت - بغداد المنصور',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          'أوقات الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'وقت الصلاة',
        ),
      ),
    );
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _localNotifications.cancelAll();
  }
}
