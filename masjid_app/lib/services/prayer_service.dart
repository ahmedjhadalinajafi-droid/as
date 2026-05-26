import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import '../models/prayer_time.dart';
import 'location_service.dart';

class PrayerService extends ChangeNotifier {
  List<PrayerTimeModel> _prayers = [];
  String _cityName = 'Locating...';
  bool _loading = true;
  String? _error;
  DateTime? _nextPrayerTime;
  String _nextPrayerName = '';

  List<PrayerTimeModel> get prayers => _prayers;
  String get cityName => _cityName;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get nextPrayerTime => _nextPrayerTime;
  String get nextPrayerName => _nextPrayerName;

  PrayerService() {
    load();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentPosition();

      double lat, lon;
      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;
        _cityName = '${lat.toStringAsFixed(2)}°N, ${lon.toStringAsFixed(2)}°E';
      } else {
        // Default to Mecca
        lat = 21.3891;
        lon = 39.8579;
        _cityName = 'Mecca (default)';
      }

      final coordinates = Coordinates(lat, lon);
      final params = CalculationMethod.muslimWorldLeague().getParameters();
      params.madhab = Madhab.shafi;

      final now = DateTime.now();
      final dateComponents = DateComponents.from(now);
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

      final nextPrayer = prayerTimes.nextPrayer();
      _nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);
      _nextPrayerName = _prayerLabel(nextPrayer);

      _prayers = [
        _build('Fajr', 'الفجر', prayerTimes.fajr, Prayer.fajr, nextPrayer),
        _build('Sunrise', 'الشروق', prayerTimes.sunrise, Prayer.sunrise, nextPrayer),
        _build('Dhuhr', 'الظهر', prayerTimes.dhuhr, Prayer.dhuhr, nextPrayer),
        _build('Asr', 'العصر', prayerTimes.asr, Prayer.asr, nextPrayer),
        _build('Maghrib', 'المغرب', prayerTimes.maghrib, Prayer.maghrib, nextPrayer),
        _build('Isha', 'العشاء', prayerTimes.isha, Prayer.isha, nextPrayer),
      ];

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Could not load prayer times.\nPlease check location permissions.';
      _loading = false;
      notifyListeners();
    }
  }

  PrayerTimeModel _build(
    String name, String arabic, DateTime time, Prayer prayer, Prayer next,
  ) {
    final now = DateTime.now();
    return PrayerTimeModel(
      name: name,
      arabicName: arabic,
      time: time,
      isNext: prayer == next,
      isCurrent: time.isBefore(now) &&
          (prayer.index == Prayer.values.length - 1 ||
              _prayers.isEmpty ||
              now.isBefore(time.add(const Duration(hours: 2)))),
    );
  }

  String _prayerLabel(Prayer p) {
    switch (p) {
      case Prayer.fajr: return 'Fajr';
      case Prayer.sunrise: return 'Sunrise';
      case Prayer.dhuhr: return 'Dhuhr';
      case Prayer.asr: return 'Asr';
      case Prayer.maghrib: return 'Maghrib';
      case Prayer.isha: return 'Isha';
      default: return '';
    }
  }

  String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);
}
