import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Writes prayer times to the home-screen widget storage and refreshes it.
///
/// Works on Android (AppWidgetProvider) and iOS (WidgetKit). All values are
/// written as strings; the native widgets read them with safe defaults so a
/// missing value never crashes the widget.
class PrayerWidgetService {
  // Must match the App Group id configured in the iOS widget target and the
  // Runner entitlements.
  static const _appGroupId = 'group.com.ahmed.najafi.masjid';
  static const _androidWidgetName = 'MasjidWidgetProvider';
  static const _iosWidgetName = 'MasjidWidget';

  static bool _initialized = false;

  static Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      _initialized = true;
    } catch (e) {
      debugPrint('Widget init failed: $e');
    }
  }

  /// Pushes the latest prayer data into the widget.
  ///
  /// [times] uses the same keys as the app: fajr, dhuhr, maghrib.
  /// [dayName] and [date] are shown in the widget header and prayer page.
  static Future<void> update({
    required Map<String, String> times,
    required String nextPrayer,
    required String nextPrayerTime,
    String dayName = '',
    String date = '',
  }) async {
    if (kIsWeb) return;
    try {
      await _ensureInit();
      await HomeWidget.saveWidgetData<String>('fajr', times['fajr'] ?? '--:--');
      await HomeWidget.saveWidgetData<String>('dhuhr', times['dhuhr'] ?? '--:--');
      await HomeWidget.saveWidgetData<String>(
          'maghrib', times['maghrib'] ?? '--:--');
      await HomeWidget.saveWidgetData<String>(
          'next_prayer', nextPrayer.isEmpty ? 'الفجر' : nextPrayer);
      await HomeWidget.saveWidgetData<String>(
          'next_prayer_time', nextPrayerTime.isEmpty ? '--:--' : nextPrayerTime);
      await HomeWidget.saveWidgetData<String>('day_name', dayName);
      await HomeWidget.saveWidgetData<String>('date', date);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}
