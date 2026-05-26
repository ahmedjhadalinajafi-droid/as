import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_time.dart';
import 'location_service.dart';

class PrayerService extends ChangeNotifier {
  List<PrayerTimeModel> _prayers = [];
  String _cityName = 'Locating...';
  bool _loading = true;
  String? _error;
  DateTime? _nextPrayerTime;
  String _nextPrayerName = '';
  bool _isManual = false;

  List<PrayerTimeModel> get prayers => _prayers;
  String get cityName => _cityName;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get nextPrayerTime => _nextPrayerTime;
  String get nextPrayerName => _nextPrayerName;
  bool get isManual => _isManual;

  static const _manualKey = 'manual_prayer_times';
  static const _manualModeKey = 'manual_mode';
  static const _cityKey = 'city_name';

  static const List<String> prayerNames = [
    'Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'
  ];
  static const List<String> prayerArabic = [
    'الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'
  ];

  PrayerService() {
    load();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isManual = prefs.getBool(_manualModeKey) ?? false;

    if (_isManual) {
      await _loadManual(prefs);
    } else {
      await _loadGps(prefs);
    }
  }

  Future<void> _loadGps(SharedPreferences prefs) async {
    try {
      final position = await LocationService.getCurrentPosition();
      double lat, lon;
      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;
        _cityName = '${lat.toStringAsFixed(2)}°N, ${lon.toStringAsFixed(2)}°E';
      } else {
        lat = 33.3152; // Baghdad default
        lon = 44.3661;
        _cityName = 'Baghdad (default)';
      }
      await prefs.setString(_cityKey, _cityName);

      final coordinates = Coordinates(lat, lon);
      final params = CalculationMethod.muslimWorldLeague.getParameters();
      params.madhab = Madhab.shafi;
      final dateComponents = DateComponents.from(DateTime.now());
      final pt = PrayerTimes(coordinates, dateComponents, params);

      final times = [
        pt.fajr, pt.sunrise, pt.dhuhr, pt.asr, pt.maghrib, pt.isha
      ];

      // Save to prefs as manual override baseline
      final encoded = times.map((t) => t.toIso8601String()).toList();
      await prefs.setStringList(_manualKey, encoded);

      _buildFromTimes(times, pt.nextPrayer());
    } catch (e) {
      _error = 'Could not load prayer times.\nPlease check location permissions.';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadManual(SharedPreferences prefs) async {
    final saved = prefs.getStringList(_manualKey);
    _cityName = prefs.getString(_cityKey) ?? 'Manual';

    if (saved != null && saved.length == 6) {
      final times = saved.map((s) => DateTime.parse(s)).toList();
      _buildFromTimesManual(times);
    } else {
      _isManual = false;
      await _loadGps(prefs);
    }
  }

  int _prayerIndex(Prayer p) {
    const order = [
      Prayer.fajr, Prayer.sunrise, Prayer.dhuhr,
      Prayer.asr, Prayer.maghrib, Prayer.isha
    ];
    return order.indexOf(p);
  }

  void _buildFromTimes(List<DateTime> times, Prayer next) {
    final nextIdx = _prayerIndex(next);
    _prayers = List.generate(6, (i) {
      return PrayerTimeModel(
        name: prayerNames[i],
        arabicName: prayerArabic[i],
        time: times[i],
        isNext: i == nextIdx,
      );
    });
    _updateNext();
    _loading = false;
    notifyListeners();
  }

  void _buildFromTimesManual(List<DateTime> times) {
    final now = DateTime.now();
    int nextIndex = -1;
    for (int i = 0; i < times.length; i++) {
      if (times[i].isAfter(now)) {
        nextIndex = i;
        break;
      }
    }
    _prayers = List.generate(6, (i) {
      return PrayerTimeModel(
        name: prayerNames[i],
        arabicName: prayerArabic[i],
        time: times[i],
        isNext: i == nextIndex,
      );
    });
    _updateNext();
    _loading = false;
    notifyListeners();
  }

  void _updateNext() {
    final next = _prayers.where((p) => p.isNext).firstOrNull;
    _nextPrayerName = next?.name ?? '';
    _nextPrayerTime = next?.time;
  }

  Future<void> saveManualTimes(List<DateTime> times, String city) async {
    final prefs = await SharedPreferences.getInstance();
    _isManual = true;
    _cityName = city;
    await prefs.setBool(_manualModeKey, true);
    await prefs.setString(_cityKey, city);
    await prefs.setStringList(_manualKey, times.map((t) => t.toIso8601String()).toList());
    _buildFromTimesManual(times);
  }

  Future<void> switchToGps() async {
    final prefs = await SharedPreferences.getInstance();
    _isManual = false;
    await prefs.setBool(_manualModeKey, false);
    await load();
  }

  List<DateTime> get currentRawTimes =>
      _prayers.map((p) => p.time).toList();

  String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);
}
