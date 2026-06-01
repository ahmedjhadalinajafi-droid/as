import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'announcements_page.dart';
import 'campaigns_page.dart';
import 'date_converter_page.dart';
import 'events_page.dart';
import 'hijri_calendar_page.dart';
import 'islamic_background.dart';
import 'mafatih_page.dart';
import 'notification_service.dart';
import 'prayer_times_page.dart';
import 'qibla_page.dart';
import 'quran_page.dart';
import 'social_media_page.dart';
import 'ziyarat_page.dart';

// ─── Theme Provider ───────────────────────────────────────────────────────────

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDark);
    notifyListeners();
  }
}

// ─── Entry Point ─────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyATN8cckOCKAt-DZtxgHcovH_J7hf2wBK0',
          authDomain: 'masjid-405c1.firebaseapp.com',
          projectId: 'masjid-405c1',
          storageBucket: 'masjid-405c1.firebasestorage.app',
          messagingSenderId: '658803064168',
          appId: '1:658803064168:web:410dacdec0e839da54eadd',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // Enable Firestore offline persistence — all Firestore pages (announcements,
  // events, campaigns, social media, home slider) cache their last data and
  // keep working without internet.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firestore persistence setup failed: $e');
  }

  try {
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MasjidApp(),
    ),
  );
}

// ─── Root App ─────────────────────────────────────────────────────────────────

class MasjidApp extends StatelessWidget {
  const MasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'مسجد وحسينية أهل البيت',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'IQ')],
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainShell(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const navy = Color(0xFF1B3D6F);
    const gold = Color(0xFFC9A843);
    final isDark = brightness == Brightness.dark;

    final primary = isDark ? gold : navy;
    final onPrimary = isDark ? Colors.black : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: isDark ? navy : gold,
        tertiary: isDark ? navy : gold,
      ),
      fontFamily: 'ScheherazadeNew',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF0A1628) : navy,
        foregroundColor: isDark ? gold : Colors.white,
        elevation: 3,
        shadowColor: navy.withOpacity(0.4),
        titleTextStyle: TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? gold : Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: isDark ? const Color(0xFF1E2D4A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? gold.withOpacity(0.25) : const Color(0xFFE8D8A0),
            width: 0.8,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0D1B2E) : Colors.white,
        indicatorColor: primary.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : Colors.grey,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : Colors.grey,
            fontFamily: 'ScheherazadeNew',
            fontSize: 13,
          ),
        ),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF5F5F0),
      dividerColor: primary.withOpacity(0.12),
    );
  }
}

// ─── Main Shell with Bottom Nav ──────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  // Pages are built lazily — only when first visited
  final Map<int, Widget> _pageCache = {};
  StreamSubscription<String>? _navSub;

  static const _pageBuilders = [
    HomePage.new,
    PrayerTimesPage.new,
    SocialMediaPage.new,
    EventsPage.new,
    CampaignsPage.new,
    MorePage.new,
  ];

  // Maps FCM data['page'] values to tab indices
  static const _pageIndexMap = {
    'home': 0,
    'prayer': 1,
    'social': 2,
    'events': 3,
    'campaigns': 4,
    'more': 5,
    'announcements': 5,
    'mafatih': 5,
    'ziyarat': 5,
    'quran': 5,
  };

  Widget _page(int i) => _pageCache.putIfAbsent(i, () => _pageBuilders[i]());

  @override
  void initState() {
    super.initState();
    _navSub = NotificationService.navStream.listen((page) {
      final idx = _pageIndexMap[page];
      if (idx != null && mounted) setState(() => _currentIndex = idx);
    });
  }

  @override
  void dispose() {
    _navSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A1628) : const Color(0xFFF5F5F0),
        extendBody: true,
        body: Stack(
          children: [
            for (int i = 0; i < _pageBuilders.length; i++)
              if (_pageCache.containsKey(i) || i == _currentIndex)
                Offstage(
                  offstage: i != _currentIndex,
                  child: _page(i),
                ),
          ],
        ),
        bottomNavigationBar: _FloatingNavBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─── Floating Animated Nav Bar ────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}

class _FloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar>
    with TickerProviderStateMixin {
  static const _items = [
    _NavItem(icon: Icons.home_outlined,       selectedIcon: Icons.home_rounded,         label: 'الرئيسية'),
    _NavItem(icon: Icons.access_time_outlined,selectedIcon: Icons.access_time_filled,   label: 'الصلاة'),
    _NavItem(icon: Icons.people_outline,      selectedIcon: Icons.people_rounded,       label: 'تواصل'),
    _NavItem(icon: Icons.event_outlined,      selectedIcon: Icons.event_rounded,        label: 'الفعاليات'),
    _NavItem(icon: Icons.volunteer_activism_outlined, selectedIcon: Icons.volunteer_activism, label: 'الحملات'),
    _NavItem(icon: Icons.grid_view_outlined,  selectedIcon: Icons.grid_view_rounded,    label: 'المزيد'),
  ];

  late final List<AnimationController> _bounceCtrl;
  late final List<Animation<double>> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = List.generate(
      _items.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
        value: i == widget.currentIndex ? 1.0 : 0.0,
      ),
    );
    _bounceAnim = _bounceCtrl
        .map((c) => Tween<double>(begin: 1.0, end: 1.25).animate(
              CurvedAnimation(parent: c, curve: Curves.elasticOut),
            ))
        .toList();
  }

  @override
  void didUpdateWidget(_FloatingNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _bounceCtrl[old.currentIndex].reverse();
      _bounceCtrl[widget.currentIndex].forward(from: 0);
    }
  }

  @override
  void dispose() {
    for (final c in _bounceCtrl) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1B3D6F);
    const gold = Color(0xFFC9A843);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2E) : Colors.white;
    final activeColor = isDark ? gold : navy;
    final activeGradient = isDark
        ? [const Color(0xFF3D2B00), const Color(0xFF5C4200)]
        : [navy, const Color(0xFF2A5BA8)];
    final activeIconColor = isDark ? gold : gold;
    final activeLabelColor = isDark ? Colors.black : Colors.white;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: activeColor.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: activeColor.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final selected = i == widget.currentIndex;
            return GestureDetector(
              onTap: () => widget.onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 14 : 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: activeGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _bounceAnim[i],
                      child: Icon(
                        selected ? _items[i].selectedIcon : _items[i].icon,
                        color: selected ? activeIconColor : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: selected
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 7),
                                Text(
                                  _items[i].label,
                                  style: TextStyle(
                                    color: activeLabelColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'ScheherazadeNew',
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Home Page ────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, String> _todayPrayers = {};
  String _nextPrayer = '';
  String _nextPrayerTime = '';
  bool _loading = true;
  Timer? _countdownTimer;
  String _countdown = '';

  static const _navy = Color(0xFF1B3D6F);
  static const _gold = Color(0xFFC9A843);

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  static String _stripTz(String t) => t.split(' ').first;

  String get _todayCacheKey {
    final now = DateTime.now();
    return 'pt_today_${now.year}_${now.month}_${now.day}';
  }

  Future<void> _saveTodayCache(Map<String, String> times) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_todayCacheKey, json.encode(times));
    } catch (_) {}
  }

  Future<bool> _loadTodayFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_todayCacheKey);
      if (raw == null) return false;
      final decoded = json.decode(raw) as Map<String, dynamic>;
      if (decoded.isEmpty) return false;
      _setPrayerTimes(decoded.map((k, v) => MapEntry(k, v.toString())));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadPrayerTimes() async {
    if (!mounted) return;
    setState(() => _loading = true);

    // 1 — Try Firestore
    if (await _loadTodayFromFirestore()) return;

    // 2 — Try aladhan API
    if (await _loadTodayFromApi()) return;

    // 3 — Offline: use cached data from last successful load
    if (await _loadTodayFromCache()) return;

    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _loadTodayFromFirestore() async {
    try {
      final now = DateTime.now();
      final docId =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final doc = await FirebaseFirestore.instance
          .collection('prayer_times')
          .doc(docId)
          .get()
          .timeout(const Duration(seconds: 5));
      if (!doc.exists || doc.data() == null) return false;
      final times =
          Map<String, String>.from(doc.data()!.map((k, v) => MapEntry(k, v.toString())));
      _setPrayerTimes(times);
      _saveTodayCache(times);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadTodayFromApi() async {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    try {
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings/$dateStr'
        '?latitude=33.3152&longitude=44.3661&method=13',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final timings = decoded['data']['timings'] as Map<String, dynamic>;
        final times = {
          'fajr':     _stripTz(timings['Fajr']     as String? ?? ''),
          'sunrise':  _stripTz(timings['Sunrise']  as String? ?? ''),
          'dhuhr':    _stripTz(timings['Dhuhr']    as String? ?? ''),
          'sunset':   _stripTz(timings['Sunset']   as String? ?? ''),
          'maghrib':  _stripTz(timings['Maghrib']  as String? ?? ''),
          'midnight': _stripTz(timings['Midnight'] as String? ?? ''),
        };
        _setPrayerTimes(times);
        _saveTodayCache(times);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Prayer times API error: $e');
      return false;
    }
  }

  void _setPrayerTimes(Map<String, String> times) {
    if (!mounted) return;
    setState(() {
      _todayPrayers = times;
      _loading = false;
    });
    _findNextPrayer(times);
    _updateWidget(times);
  }

  void _findNextPrayer(Map<String, String> times) {
    final now = TimeOfDay.now();
    const order = ['fajr', 'dhuhr', 'maghrib'];
    const names = {
      'fajr':    'الفجر',
      'dhuhr':   'الظهر',
      'maghrib': 'المغرب',
    };

    for (final key in order) {
      final t = times[key];
      if (t == null || t.isEmpty) continue;
      final parts = t.split(':');
      if (parts.length < 2) continue;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      if (h > now.hour || (h == now.hour && m > now.minute)) {
        if (!mounted) return;
        setState(() {
          _nextPrayer = names[key] ?? key;
          _nextPrayerTime = t;
        });
        _startCountdown(h, m);
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _nextPrayer = 'الفجر';
      _nextPrayerTime = times['fajr'] ?? '';
    });
    final parts = (times['fajr'] ?? '').split(':');
    if (parts.length >= 2) {
      _startCountdown(
          int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
    }
  }

  void _showPrayerTimesCard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PrayerTimesBottomSheet(times: _todayPrayers),
    );
  }

  void _startCountdown(int targetH, int targetM) {
    _countdownTimer?.cancel();
    void tick() {
      if (!mounted) return;
      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, targetH, targetM);
      if (target.isBefore(now)) target = target.add(const Duration(days: 1));
      final diff = target.difference(now);
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      final s = diff.inSeconds.remainder(60);
      setState(() {
        _countdown =
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      });
    }
    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _updateWidget(Map<String, String> times) async {
    // Widget update removed — home_widget plugin removed
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = theme.isDark;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0A1628), const Color(0xFF2A1F00)]
                    : [const Color(0xFF1B3D6F), const Color(0xFF2A5BA8)],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
          ),
          // Bottom white/surface area with Islamic pattern
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                width: double.infinity,
                child: const IslamicPatternBackground(child: SizedBox.expand()),
              ),
            ),
          ),
          // Islamic pattern overlay on top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.48,
            child: CustomPaint(
              painter: IslamicPatternPainter(Colors.white.withOpacity(0.05)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: theme.toggle,
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'مسجد أهل البيت ع',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ScheherazadeNew',
                        ),
                      ),
                      Image.asset(
                        'assets/images/logo.png',
                        height: 32,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.mosque, color: _gold, size: 26),
                      ),
                    ],
                  ),
                ),

                // Hijri date
                const _HijriDateChip(),
                const SizedBox(height: 12),

                // Day-of-week duaa / ziyarat shortcuts (like the photo)
                const _DayWorshipTabs(),
                const SizedBox(height: 12),

                // Countdown card — tap to see full day's prayer times
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _loading
                      ? const SizedBox(
                          height: 100,
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white)))
                      : GestureDetector(
                          onTap: _showPrayerTimesCard,
                          child: _buildCountdownCard(),
                        ),
                ),

                const SizedBox(height: 20),

                // Scrollable content
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    child: RefreshIndicator(
                      onRefresh: _loadPrayerTimes,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                        children: [
                          // Quick actions
                          _buildQuickActions(context, cs),
                          const SizedBox(height: 20),

                          // Announcements
                          const _HomeAnnouncementsSection(),
                          const SizedBox(height: 20),

                          // Image slider
                          const _HomeImageSlider(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'وقت صلاة $_nextPrayer في بغداد',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              fontFamily: 'ScheherazadeNew',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _countdown.isEmpty ? '--:--:--' : _countdown,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 13, color: _gold),
              const SizedBox(width: 5),
              Text(
                _nextPrayerTime,
                style: const TextStyle(color: _gold, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2D4A) : Colors.white;

    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.menu_book_rounded,
            label: 'القرآن الكريم',
            sublabel: 'The Holy Quran',
            color: const Color(0xFF1B3D6F),
            bg: cardBg,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const Directionality(
                  textDirection: TextDirection.rtl,
                  child: QuranPage(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.access_time_filled,
            label: 'أوقات الصلاة',
            sublabel: 'Prayer Times',
            color: const Color(0xFF4CAF50),
            bg: cardBg,
            onTap: () {
              final shell = context.findAncestorStateOfType<_MainShellState>();
              shell?.setState(() => shell._currentIndex = 1);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Prayer Times Bottom Sheet ───────────────────────────────────────────────

class _PrayerTimesBottomSheet extends StatelessWidget {
  final Map<String, String> times;
  const _PrayerTimesBottomSheet({required this.times});

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

  static const _navy = Color(0xFF1B3D6F);
  static const _gold = Color(0xFFC9A843);

  static String _toArabicTime(String t) {
    const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    final p = t.split(':');
    if (p.length < 2) return t;
    int h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    final s = h < 12 ? 'ص' : 'م';
    if (h == 0) h = 12; else if (h > 12) h -= 12;
    conv(int n) => n.toString().split('').map((c) => d[int.parse(c)]).join();
    return '${conv(h)}:${conv(m).toString().padLeft(2, '٠')} $s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    const order = ['fajr', 'sunrise', 'dhuhr', 'sunset', 'maghrib', 'midnight'];
    final now = TimeOfDay.now();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: _gold.withOpacity(0.35), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time_filled, size: 18, color: _gold),
              const SizedBox(width: 8),
              Text(
                'أوقات الصلاة - اليوم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : _navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: _gold.withOpacity(0.25)),
          ...order.map((key) {
            final time = times[key] ?? '--:--';
            final name = _prayerNames[key] ?? key;
            final icon = _prayerIcons[key] ?? Icons.access_time;

            // Highlight the next upcoming prayer
            bool isNext = false;
            final p = time.split(':');
            if (p.length >= 2) {
              final h = int.tryParse(p[0]) ?? 0;
              final m = int.tryParse(p[1]) ?? 0;
              isNext = (h > now.hour || (h == now.hour && m > now.minute)) &&
                  (key == 'fajr' || key == 'dhuhr' || key == 'maghrib');
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isNext
                    ? (isDark
                        ? const Color(0xFF1A2F1A)
                        : const Color(0xFFE8F5E9))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isNext
                    ? Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.4))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNext
                          ? const Color(0xFF4CAF50).withOpacity(0.15)
                          : (isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.06)),
                    ),
                    child: Icon(icon,
                        size: 18,
                        color: isNext
                            ? const Color(0xFF4CAF50)
                            : (isDark ? _gold : _navy).withOpacity(0.7)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isNext ? FontWeight.bold : FontWeight.normal,
                      color: isNext
                          ? const Color(0xFF4CAF50)
                          : cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _toArabicTime(time),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isNext
                          ? const Color(0xFF4CAF50)
                          : (isDark ? _gold : _navy),
                      fontFamily: 'ScheherazadeNew',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 0.8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'ScheherazadeNew',
              ),
            ),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.6),
                fontFamily: 'sans-serif',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hijri Date Chip ─────────────────────────────────────────────────────────

class _HijriDateChip extends StatelessWidget {
  const _HijriDateChip();

  static const _hijriMonths = [
    'محرم','صفر','ربيع الأول','ربيع الثاني',
    'جمادى الأولى','جمادى الثانية','رجب','شعبان',
    'رمضان','شوال','ذو القعدة','ذو الحجة',
  ];

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.now();
    final hijriStr =
        '${hijri.hDay} ${_hijriMonths[hijri.hMonth - 1]} ${hijri.hYear} هـ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9A843).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nightlight_round, size: 14, color: Color(0xFFC9A843)),
          const SizedBox(width: 6),
          Text(
            hijriStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'ScheherazadeNew',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home Image Slider ───────────────────────────────────────────────────────
// Reads from Firestore collection "home_slider" — each doc: { imageUrl, title, order }

class _HomeImageSlider extends StatefulWidget {
  const _HomeImageSlider();

  @override
  State<_HomeImageSlider> createState() => _HomeImageSliderState();
}

class _HomeImageSliderState extends State<_HomeImageSlider> {
  late final PageController _ctrl;
  int _current = 0;
  Timer? _autoTimer;
  List<Map<String, dynamic>> _slides = [];

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startAuto(int count) {
    _autoTimer?.cancel();
    if (count < 2) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      final next = (_current + 1) % count;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('home_slider')
          .orderBy('order')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            height: 190,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        _slides = docs
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();

        // Start / restart auto-scroll whenever slide count changes
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAuto(_slides.length));

        return Column(
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A843),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'معرض الصور',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1B3D6F),
                    ),
                  ),
                ],
              ),
            ),

            // Slider
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) {
                  final slide = _slides[i];
                  final url   = slide['imageUrl'] as String? ?? '';
                  final title = slide['title']    as String? ?? '';
                  return _SlideCard(
                    imageUrl: url,
                    title: title,
                    isActive: i == _current,
                  );
                },
              ),
            ),

            // Dot indicators
            if (_slides.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFC9A843)
                          : cs.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SlideCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final bool isActive;

  const _SlideCard({
    required this.imageUrl,
    required this.title,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: isActive ? 4 : 10,
        vertical: isActive ? 0 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFF1B3D6F).withOpacity(0.12),
                      child: const Center(
                          child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF1B3D6F).withOpacity(0.08),
                      child: const Icon(Icons.image_not_supported_outlined,
                          size: 40, color: Colors.white38),
                    ),
                  )
                : Container(
                    color: const Color(0xFF1B3D6F).withOpacity(0.08),
                    child: const Icon(Icons.image_outlined,
                        size: 40, color: Colors.white38),
                  ),

            // Gradient overlay + title
            if (title.isNotEmpty)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ScheherazadeNew',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── More Page ────────────────────────────────────────────────────────────────

// ─── Day-of-Week Worship Shortcuts (Home header) ─────────────────────────────
// Shows the day's duaa + ziyarat as small white pills, like the reference photo.
// Tapping a pill opens that chapter inside Mafatih al-Jinan.

class _DayWorshipTabs extends StatelessWidget {
  const _DayWorshipTabs();

  static const _navy = Color(0xFF1B3D6F);
  static const _gold = Color(0xFFC9A843);

  // weekday (Mon=1 … Sun=7) → list of [label, titleContains]
  static const Map<int, List<List<String>>> _byWeekday = {
    1: [ // الاثنين
      ['دعاء يوم الاثنين', 'دعاء يوم الاثنين'],
      ['زيارة الحسن (ع)', 'زيارة الحسن (ع)'],
    ],
    2: [ // الثلاثاء
      ['دعاء يوم الثلاثاء', 'دعاء يوم الثلاثاء'],
    ],
    3: [ // الأربعاء
      ['دعاء يوم الأربعاء', 'دعاء يوم الأربعاء'],
    ],
    4: [ // الخميس
      ['دعاء يوم الخميس', 'دعاء يوم الخميس'],
      ['دعاء كميل', 'كميل'],
    ],
    5: [ // الجمعة
      ['دعاء يوم الجمعة', 'دعاء يوم الجمعة'],
      ['دعاء الندبة', 'الندبة'],
      ['زيارة آل ياسين', 'آل ياسين'],
      ['دعاء السمات', 'السمات'],
    ],
    6: [ // السبت
      ['دعاء يوم السبت', 'دعاء يوم السبت'],
    ],
    7: [ // الأحد
      ['دعاء يوم الأحد', 'دعاء يوم الأحد'],
      ['زيارة أمين الله', 'أمين الله'],
    ],
  };

  @override
  Widget build(BuildContext context) {
    final items = _byWeekday[DateTime.now().weekday] ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final label = items[i][0];
          final match = items[i][1];
          return GestureDetector(
            onTap: () => openMafatihChapter(context, match),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_stories, size: 15, color: _gold),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ScheherazadeNew',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Home Announcements Section ──────────────────────────────────────────────

class _HomeAnnouncementsSection extends StatelessWidget {
  const _HomeAnnouncementsSection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'آخر الإعلانات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Directionality(
                    textDirection: TextDirection.rtl,
                    child: AnnouncementsPage(),
                  ),
                ),
              ),
              child: Text('عرض الكل',
                  style: TextStyle(color: cs.secondary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'لا توجد إعلانات حالياً',
                  style:
                      TextStyle(color: cs.onSurface.withOpacity(0.5)),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final title = d['title'] as String? ?? '';
                final body = d['body'] as String? ?? '';
                final imageUrl = d['imageUrl'] as String? ?? '';
                final ts = d['createdAt'] as Timestamp?;
                final dateStr = ts != null
                    ? _formatDate(ts.toDate())
                    : '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 160,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 160,
                            color: cs.primary.withOpacity(0.08),
                          ),
                          errorWidget: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title.isNotEmpty)
                              Text(title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  )),
                            if (title.isNotEmpty && body.isNotEmpty)
                              const SizedBox(height: 6),
                            if (body.isNotEmpty)
                              Text(body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.5)),
                            if (dateStr.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(dateStr,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface
                                          .withOpacity(0.45))),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'يناير','فبراير','مارس','أبريل','مايو','يونيو',
      'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── More Page ────────────────────────────────────────────────────────────────

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = context.watch<ThemeProvider>();

    final items = [
      _MoreItem(
        icon: Icons.menu_book_rounded,
        label: 'القرآن الكريم',
        color: const Color(0xFF1B7A4B),
        page: const QuranPage(),
      ),
      _MoreItem(
        icon: Icons.event_rounded,
        label: 'الفعاليات',
        color: const Color(0xFF9C27B0),
        page: const EventsPage(),
      ),
      _MoreItem(
        icon: Icons.share_rounded,
        label: 'تواصل معنا',
        color: const Color(0xFF1877F2),
        page: const SocialMediaPage(),
      ),
      _MoreItem(
        icon: Icons.calendar_month,
        label: 'التقويم الهجري',
        color: const Color(0xFF4CAF50),
        page: const HijriCalendarPage(),
      ),
      _MoreItem(
        icon: Icons.swap_vert_circle,
        label: 'محوّل التاريخ',
        color: const Color(0xFF009688),
        page: const DateConverterPage(),
      ),
      _MoreItem(
        icon: Icons.auto_stories,
        label: 'المفاتيح',
        color: const Color(0xFF2196F3),
        page: const MafatihPage(),
      ),
      _MoreItem(
        icon: Icons.explore,
        label: 'اتجاه القبلة',
        color: const Color(0xFF00BCD4),
        page: const QiblaPage(),
      ),
      _MoreItem(
        icon: Icons.campaign,
        label: 'الإعلانات',
        color: const Color(0xFFF44336),
        page: const AnnouncementsPage(),
      ),
      _MoreItem(
        icon: Icons.volunteer_activism,
        label: 'الزيارات',
        color: const Color(0xFF795548),
        page: const ZiyaratPage(),
      ),
    ];

    return IslamicPatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('المزيد'),
          actions: [
            IconButton(
              onPressed: theme.toggle,
              icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
            ),
          ],
        ),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: items
              .map(
                (item) => _MoreCard(item: item),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget page;
  const _MoreItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.page});
}

class _MoreCard extends StatelessWidget {
  final _MoreItem item;
  const _MoreCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: TextDirection.rtl,
              child: item.page,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 36, color: item.color),
            ),
            const SizedBox(height: 12),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: item.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
