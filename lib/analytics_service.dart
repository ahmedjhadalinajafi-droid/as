import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around Google Analytics for Firebase (Firebase Analytics).
///
/// Provides a single shared [FirebaseAnalytics] instance, a navigator
/// [observer] for automatic screen-view tracking, and small helpers for the
/// custom events we care about. Every call is wrapped so analytics can never
/// crash the app or block on the network.
class Analytics {
  Analytics._();

  static final FirebaseAnalytics instance = FirebaseAnalytics.instance;

  /// Attach this to MaterialApp.navigatorObservers so each pushed route is
  /// logged automatically as a screen_view.
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: instance);

  /// Turns collection on (no-op on web / if it fails).
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await instance.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('Analytics init failed: $e');
    }
  }

  /// Logs a custom event. [params] values must be String or num.
  static Future<void> log(String name, [Map<String, Object>? params]) async {
    try {
      await instance.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics log "$name" failed: $e');
    }
  }

  // ── Convenience events for the mosque app ──────────────────────────────────

  static Future<void> appOpened() => log('app_opened');

  static Future<void> screen(String name) async {
    try {
      await instance.logScreenView(screenName: name);
    } catch (e) {
      debugPrint('Analytics screen "$name" failed: $e');
    }
  }

  static Future<void> eventPosted() => log('event_posted');
  static Future<void> tripPosted() => log('trip_posted');
  static Future<void> announcementPosted() => log('announcement_posted');
  static Future<void> questionAsked() => log('question_asked');
  static Future<void> tripBooked(String destination) =>
      log('trip_booked', {'destination': destination});
}
