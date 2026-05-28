import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

  static const _prayerNames = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  static const _prayerIcons = {
    'fajr': Icons.brightness_3,
    'sunrise': Icons.wb_twilight,
    'dhuhr': Icons.wb_sunny,
    'asr': Icons.brightness_5,
    'maghrib': Icons.brightness_4,
    'isha': Icons.nights_stay,
  };

  @override
  void initState() {
    super.initState();
    _load();
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

    return Scaffold(
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
                    Card(
                      color: cs.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الصلاة القادمة',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(_nextPrayer,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('الوقت المتبقي',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(_countdown,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Today's prayer times
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
                              'أوقات الصلاة - اليوم',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary),
                            ),
                          ),
                          const Divider(),
                          ..._buildTodayRows(cs),
                        ],
                      ),
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
    );
  }

  List<Widget> _buildTodayRows(ColorScheme cs) {
    final times = _todayTimes;
    final now = TimeOfDay.now();
    final order = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

    return order.map((key) {
      final time = times[key] ?? '--:--';
      final name = _prayerNames[key] ?? key;
      final icon = _prayerIcons[key] ?? Icons.access_time;

      // Is this the next prayer?
      bool isNext = false;
      final parts = time.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        isNext = name == _nextPrayer &&
            (h > now.hour || (h == now.hour && m > now.minute));
      }

      return ListTile(
        leading: Icon(icon,
            color: isNext ? cs.primary : Colors.grey, size: 22),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            color: isNext ? cs.primary : null,
          ),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isNext
                ? cs.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isNext ? cs.primary : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: isNext ? cs.primary : null,
              letterSpacing: 1.5,
            ),
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
