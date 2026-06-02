import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _error;
  Timer? _timer;
  String _countdown = '';
  String _nextPrayer = '';
  Map<String, bool> _notifSettings = {
    'fajr': true,
    'dhuhr': true,
    'maghrib': true,
  };

  static const _navy = Color(0xFF1B3D6F);
  static const _gold = Color(0xFFC9A843);
  static const _green = Color(0xFF4CAF50);

  static const _prayerNames = {
    'fajr':     'الفجر',
    'sunrise':  'الشروق',
    'dhuhr':    'الظهر',
    'sunset':   'الغروب',
    'maghrib':  'المغرب',
    'midnight': 'منتصف الليل',
  };

  static const _prayerIcons = {
    'fajr':     Icons.brightness_3,
    'sunrise':  Icons.wb_twilight,
    'dhuhr':    Icons.wb_sunny,
    'sunset':   Icons.brightness_4,
    'maghrib':  Icons.nights_stay,
    'midnight': Icons.bedtime,
  };

  // Informational entries — no notification bell
  static const _infoOnly = {'sunrise', 'sunset', 'midnight'};

  static String _toArabicTime(String t) {
    const arDigits = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    final parts = t.split(':');
    if (parts.length < 2) return t;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final suffix = h < 12 ? 'ص' : 'م';
    if (h == 0) h = 12;
    else if (h > 12) h -= 12;
    String conv(int n) =>
        n.toString().split('').map((c) => arDigits[int.parse(c)]).join();
    return '${conv(h)}:${conv(m).padLeft(2, '٠')} $suffix';
  }

  static String _stripTz(String t) => t.split(' ').first;

  @override
  void initState() {
    super.initState();
    _load();
    _loadNotifSettings();
  }

  Future<void> _loadNotifSettings() async {
    final settings = await NotificationService().getNotificationSettings();
    if (mounted) {
      setState(() {
        _notifSettings = Map.from(settings)
          ..removeWhere((k, _) => !_prayerNames.containsKey(k) || _infoOnly.contains(k));
      });
    }
  }

  Future<void> _toggleNotif(String key) async {
    final newVal = !(_notifSettings[key] ?? true);
    setState(() => _notifSettings[key] = newVal);
    await NotificationService().setPrayerNotification(key, newVal);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // SharedPreferences key for this month's cached data
  String get _cacheKey {
    final now = DateTime.now();
    return 'pt_${now.year}_${now.month}';
  }

  Future<void> _saveCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
    } catch (_) {}
  }

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return false;
      final decoded = json.decode(raw) as Map<String, dynamic>;
      if (decoded.isEmpty) return false;
      if (!mounted) return true;
      setState(() { _allTimes = decoded; _loading = false; });
      _startCountdown();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    // 1 — Try Firestore (admin overrides / edits)
    if (await _loadFromFirestore()) return;

    // 2 — Bundled official Karkh times (works offline, always present)
    if (await _loadFromAsset()) return;

    // 3 — aladhan.com API (only if the bundled year is missing)
    if (await _loadFromApi()) return;

    // 4 — Last-saved cache
    if (await _loadFromCache()) return;

    // 5 — Nothing available
    if (mounted) setState(() { _loading = false; _error = 'لا يوجد اتصال بالإنترنت'; });
  }

  // Official مواقيت الكرخ، بغداد bundled in the app (assets/prayer_times_2026.json)
  Future<bool> _loadFromAsset() async {
    try {
      // Only use the asset if it covers today's year
      final now = DateTime.now();
      final raw = await rootBundle.loadString('assets/prayer_times_2026.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      if (decoded.isEmpty) return false;
      // Asset is for 2026 — skip if device year is different so API takes over
      if (!decoded.keys.first.startsWith('${now.year}')) return false;
      if (!mounted) return true;
      setState(() { _allTimes = decoded; _loading = false; });
      _saveCache(decoded);
      _startCountdown();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadFromFirestore() async {
    try {
      final now = DateTime.now();
      // Fetch from the 1st of this month through the end of NEXT month, so the
      // app always has at least the next ~15 days cached even near month-end.
      final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final end =
          '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-31';
      final snap = await FirebaseFirestore.instance
          .collection('prayer_times')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: start)
          .where(FieldPath.documentId, isLessThanOrEqualTo: end)
          .get()
          .timeout(const Duration(seconds: 6));
      if (snap.docs.isEmpty) return false;
      final Map<String, dynamic> result = {};
      for (final doc in snap.docs) {
        result[doc.id] =
            Map<String, String>.from(doc.data().map((k, v) => MapEntry(k, v.toString())));
      }
      if (!mounted) return true;
      setState(() { _allTimes = result; _loading = false; });
      _saveCache(result);
      _startCountdown();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadFromApi() async {
    final now = DateTime.now();
    try {
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/calendar/${now.year}/${now.month}'
        '?latitude=33.3152&longitude=44.3661&method=13',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return false;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as List;
        final Map<String, dynamic> result = {};
        for (final day in data) {
          final greg = day['date']['gregorian'];
          final p = (greg['date'] as String).split('-');
          final key = '${p[2]}-${p[1]}-${p[0]}';
          final timings = day['timings'] as Map<String, dynamic>;
          result[key] = {
            'fajr':     _stripTz(timings['Fajr']     as String? ?? ''),
            'sunrise':  _stripTz(timings['Sunrise']  as String? ?? ''),
            'dhuhr':    _stripTz(timings['Dhuhr']    as String? ?? ''),
            'sunset':   _stripTz(timings['Sunset']   as String? ?? ''),
            'maghrib':  _stripTz(timings['Maghrib']  as String? ?? ''),
            'midnight': _stripTz(timings['Midnight'] as String? ?? ''),
          };
        }
        setState(() { _allTimes = result; _loading = false; });
        _saveCache(result);
        _startCountdown();
        return true;
      }
      return false;
    } catch (_) {
      return false;
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
    _timer?.cancel();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    final times = _todayTimes;
    final now = DateTime.now();
    const order = ['fajr', 'dhuhr', 'maghrib'];

    for (final key in order) {
      final t = times[key];
      if (t == null || t.isEmpty) continue;
      final parts = t.split(':');
      if (parts.length < 2) continue;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final pTime = DateTime(now.year, now.month, now.day, h, m);
      if (pTime.isAfter(now)) {
        final diff = pTime.difference(now);
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('أوقات الصلاة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 52, color: cs.error),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: TextStyle(color: cs.error, fontSize: 16)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                      children: [
                        _DateHeader(),
                        const SizedBox(height: 16),

                        // ── Countdown card ──────────────────────────────
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
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

                        // ── Today's prayer list ─────────────────────────
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
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 6),
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

                        // ── Monthly table ───────────────────────────────
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
    const order = ['fajr', 'sunrise', 'dhuhr', 'sunset', 'maghrib', 'midnight'];
    final isDark = cs.brightness == Brightness.dark;

    return order.map((key) {
      final time = times[key] ?? '--:--';
      final name = _prayerNames[key] ?? key;
      final icon = _prayerIcons[key] ?? Icons.access_time;
      final isInfo = _infoOnly.contains(key);
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
              BoxShadow(
                  color: _green.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1),
            ],
          ),
          child: const Icon(Icons.notifications_active,
              size: 20, color: _green),
        );
      } else if (isInfo) {
        bellWidget = Icon(icon,
            size: 20, color: cs.onSurface.withOpacity(0.25));
      } else {
        bellWidget = GestureDetector(
          onTap: () => _toggleNotif(key),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              notifEnabled
                  ? Icons.notifications
                  : Icons.notifications_off_outlined,
              key: ValueKey(notifEnabled),
              size: 20,
              color:
                  notifEnabled ? _gold : cs.onSurface.withOpacity(0.3),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isNext
                      ? _green.withOpacity(0.15)
                      : (isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.06)),
                ),
                child: Icon(icon,
                    size: 20,
                    color: isNext
                        ? _green
                        : cs.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(width: 12),

              // Arabic name only
              Expanded(
                child: Row(
                  children: [
                    bellWidget,
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isNext ? FontWeight.bold : FontWeight.normal,
                        color: isNext ? _green : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Arabic time
              Text(
                _toArabicTime(time),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      isNext ? FontWeight.bold : FontWeight.normal,
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
    const headers = ['يوم', 'فجر', 'ظهر', 'غروب', 'مغرب', 'منتصف'];
    const keys = ['', 'fajr', 'dhuhr', 'sunset', 'maghrib', 'midnight'];
    const style = TextStyle(fontSize: 10);
    const hStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.bold);

    return Table(
      defaultColumnWidth: const FlexColumnWidth(),
      border: TableBorder(
        horizontalInside:
            BorderSide(color: cs.outline.withOpacity(0.15)),
      ),
      children: [
        TableRow(
          decoration:
              BoxDecoration(color: cs.primary.withOpacity(0.1)),
          children: headers
              .map((h) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 2),
                    child: Text(h,
                        textAlign: TextAlign.center, style: hStyle),
                  ))
              .toList(),
        ),
        ...List.generate(daysInMonth, (i) {
          final day = i + 1;
          final k =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final times = _allTimes[k];
          final Map<String, String> t = times is Map
              ? Map<String, String>.from(
                  times.map((a, b) =>
                      MapEntry(a.toString(), b.toString())))
              : {};
          final isToday = day == today;
          final rowColor =
              isToday ? cs.primary.withOpacity(0.08) : null;

          return TableRow(
            decoration: rowColor != null
                ? BoxDecoration(color: rowColor)
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 2),
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
          Icon(Icons.calendar_today,
              size: 18, color: cs.onPrimaryContainer),
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
