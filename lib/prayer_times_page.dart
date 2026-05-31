import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';
import 'islamic_background.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  Map<String, dynamic> _allTimes = {};
  bool _loading = true;
  Timer? _timer;
  String _countdown = '';
  String _nextPrayer = '';
  Map<String, bool> _notifSettings = {
    'fajr': true, 'dhuhr': true, 'asr': true, 'maghrib': true, 'isha': true,
  };

  static const _navy = Color(0xFF1B3D6F);
  static const _gold = Color(0xFFC9A843);
  static const _green = Color(0xFF4CAF50);

  static const _prayerNames = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  static const _prayerNamesEn = {
    'fajr': 'Morning Prayer',
    'sunrise': 'Sunrise',
    'dhuhr': 'Midday Prayer',
    'asr': 'Afternoon Prayer',
    'maghrib': 'Evening Prayer',
    'isha': 'Night Prayer',
  };

  static const _prayerIcons = {
    'fajr': Icons.brightness_3,
    'sunrise': Icons.wb_twilight,
    'dhuhr': Icons.wb_sunny,
    'asr': Icons.brightness_5,
    'maghrib': Icons.brightness_4,
    'isha': Icons.nights_stay,
  };

  // Convert "HH:mm" 24h to Arabic 12h with ص/م
  static String _toArabicTime(String t) {
    const arDigits = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    final parts = t.split(':');
    if (parts.length < 2) return t;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final suffix = h < 12 ? 'ص' : 'م';
    if (h == 0) h = 12;
    else if (h > 12) h -= 12;
    String convert(int n) =>
        n.toString().split('').map((c) => arDigits[int.parse(c)]).join();
    return '${convert(h)}:${convert(m).padLeft(2, '٠')} $suffix';
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadNotifSettings();
  }

  Future<void> _loadNotifSettings() async {
    final settings = await NotificationService().getNotificationSettings();
    if (mounted) setState(() => _notifSettings = settings);
  }

  Future<void> _toggleNotif(String prayerKey) async {
    final newVal = !(_notifSettings[prayerKey] ?? true);
    setState(() => _notifSettings[prayerKey] = newVal);
    await NotificationService().setPrayerNotification(prayerKey, newVal);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/prayer_times_2026.json');
      final decoded = json.decode(raw);
      if (!mounted) return;
      setState(() {
        _allTimes = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
        _loading = false;
      });
      _startCountdown();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Map<String, String> get _todayTimes {
    final data = _allTimes[_todayKey];
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v.toString()));
    return {};
  }

  void _startCountdown() {
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    final times = _todayTimes;
    final now = DateTime.now();
    const order = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

    for (final key in order) {
      final t = times[key];
      if (t == null) continue;
      final parts = t.split(':');
      if (parts.length < 2) continue;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final prayerTime = DateTime(now.year, now.month, now.day, h, m);
      if (prayerTime.isAfter(now)) {
        final diff = prayerTime.difference(now);
        final hrs = diff.inHours;
        final mins = diff.inMinutes.remainder(60);
        if (!mounted) return;
        setState(() {
          _nextPrayer = _prayerNames[key] ?? key;
          _countdown = hrs > 0 ? '${hrs}س ${mins}د' : '${mins} دقيقة';
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _nextPrayer = 'الفجر';
      _countdown = 'الغد';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IslamicPatternBackground(
      child: Scaffold( backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('أوقات الصلاة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {},
            tooltip: 'اليوم',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date header
                  _DateHeader(),
                  const SizedBox(height: 16),

                  // Countdown card
                  if (_nextPrayer.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_navy, Color(0xFF2A5BA8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _navy.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الصلاة القادمة',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(_nextPrayer,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('الوقت المتبقي',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(_countdown,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Today's prayer times — dark-themed list card
                  Container(
                    decoration: BoxDecoration(
                      color: cs.brightness == Brightness.dark
                          ? const Color(0xFF0D1B2E)
                          : const Color(0xFF1B3D6F).withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _gold.withOpacity(0.25), width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_filled,
                                  size: 16, color: _gold),
                              const SizedBox(width: 8),
                              Text(
                                'أوقات الصلاة - اليوم',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: cs.brightness == Brightness.dark
                                        ? Colors.white
                                        : _navy),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            color: _gold.withOpacity(0.2),
                            thickness: 0.8,
                            indent: 16,
                            endIndent: 16),
                        ..._buildTodayRows(cs),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Monthly view
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'أوقات الشهر الحالي',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary),
                            ),
                          ),
                          const Divider(),
                          _buildMonthlyTable(cs),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    ),
    );
  }

  List<Widget> _buildTodayRows(ColorScheme cs) {
    final times = _todayTimes;
    final now = TimeOfDay.now();
    final order = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final isDark = cs.brightness == Brightness.dark;

    return order.map((key) {
      final time = times[key] ?? '--:--';
      final name = _prayerNames[key] ?? key;
      final nameEn = _prayerNamesEn[key] ?? key;
      final icon = _prayerIcons[key] ?? Icons.access_time;
      final isSunrise = key == 'sunrise';
      final notifEnabled = _notifSettings[key] ?? true;

      bool isNext = false;
      final parts = time.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        isNext = name == _nextPrayer &&
            (h > now.hour || (h == now.hour && m > now.minute));
      }

      final rowBg = isNext
          ? (isDark ? const Color(0xFF1A2F1A) : const Color(0xFFE8F5E9))
          : Colors.transparent;

      Widget bellWidget;
      if (isNext) {
        bellWidget = AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _green.withOpacity(0.5), blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: const Icon(Icons.notifications_active, size: 20, color: _green),
        );
      } else if (isSunrise) {
        bellWidget = Icon(Icons.wb_twilight, size: 20, color: cs.onSurface.withOpacity(0.25));
      } else {
        bellWidget = GestureDetector(
          onTap: () => _toggleNotif(key),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              notifEnabled ? Icons.notifications : Icons.notifications_off_outlined,
              key: ValueKey(notifEnabled),
              size: 20,
              color: notifEnabled ? _gold : cs.onSurface.withOpacity(0.3),
            ),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(12),
          border: isNext
              ? Border.all(color: _green.withOpacity(0.4), width: 1)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Left: prayer icon in circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isNext
                      ? _green.withOpacity(0.15)
                      : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                ),
                child: Icon(icon,
                    size: 20,
                    color: isNext ? _green : cs.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(width: 12),

              // Center: bell + names
              Expanded(
                child: Row(
                  children: [
                    bellWidget,
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameEn,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'sans-serif',
                            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                            color: isNext ? _green : cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                            color: isNext ? _green : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Arabic time
              Text(
                _toArabicTime(time),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  color: isNext ? _green : cs.onSurface,
                  fontFamily: 'ScheherazadeNew',
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMonthlyTable(ColorScheme cs) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final today = now.day;
    const headers = ['يوم', 'فجر', 'ظهر', 'عصر', 'مغرب', 'عشاء'];
    const keys = ['', 'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    const style = TextStyle(fontSize: 11);
    const hStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold);

    return Table(
      defaultColumnWidth: const FlexColumnWidth(),
      border: TableBorder(
        horizontalInside: BorderSide(color: cs.outline.withOpacity(0.15)),
      ),
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: cs.primary.withOpacity(0.1)),
          children: headers
              .map((h) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 2),
                    child: Text(h,
                        textAlign: TextAlign.center, style: hStyle),
                  ))
              .toList(),
        ),
        // Data rows
        ...List.generate(daysInMonth, (i) {
          final day = i + 1;
          final k =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final times = _allTimes[k];
          final Map<String, String> t = times is Map
              ? Map<String, String>.from(
                  times.map((a, b) => MapEntry(a.toString(), b.toString())))
              : {};
          final isToday = day == today;
          final rowColor =
              isToday ? cs.primary.withOpacity(0.08) : null;

          return TableRow(
            decoration:
                rowColor != null ? BoxDecoration(color: rowColor) : null,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text('$day',
                    textAlign: TextAlign.center,
                    style: style.copyWith(
                      fontWeight: isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isToday ? cs.primary : null,
                    )),
              ),
              ...keys.skip(1).map((key) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 2),
                    child: Text(t[key] ?? '-',
                        textAlign: TextAlign.center, style: style),
                  )),
            ],
          );
        }),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final gregorian = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 18, color: cs.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            gregorian,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
