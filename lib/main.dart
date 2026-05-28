import 'dart:convert';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'announcements_page.dart';
import 'hijri_calendar_page.dart';
import 'mafatih_page.dart';
import 'notification_service.dart';
import 'prayer_times_page.dart';
import 'qibla_page.dart';
import 'quran_page.dart';
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

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        brightness: brightness,
        primary: navy,
        secondary: gold,
        tertiary: gold,
      ),
      fontFamily: 'ScheherazadeNew',
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: navy.withOpacity(0.4),
        titleTextStyle: const TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: isDark ? const Color(0xFF1E2D4A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? const Color(0xFF3A5070) : const Color(0xFFE8D8A0),
            width: 0.8,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
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
        indicatorColor: navy.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? navy : Colors.grey,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? navy : Colors.grey,
            fontFamily: 'ScheherazadeNew',
            fontSize: 13,
          ),
        ),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF5F5F0),
      dividerColor: navy.withOpacity(0.12),
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

  static const _pageBuilders = [
    HomePage.new,
    QuranPage.new,
    PrayerTimesPage.new,
    MorePage.new,
  ];

  Widget _page(int i) => _pageCache.putIfAbsent(
      i, () => _pageBuilders[i]());

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

// ─── Islamic Geometric Pattern Painter ───────────────────────────────────────

class _IslamicPatternPainter extends CustomPainter {
  final Color color;
  _IslamicPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    const cell = 64.0;
    const half = cell / 2;

    // Staggered grid of 8-pointed stars
    int row = 0;
    for (double y = -cell; y < size.height + cell; y += half) {
      final xOffset = (row % 2 == 0) ? 0.0 : half;
      for (double x = -cell + xOffset; x < size.width + cell; x += cell) {
        _drawStar(canvas, paint, Offset(x, y), cell * 0.42);
        _drawInnerSquare(canvas, paint, Offset(x, y), cell * 0.18);
      }
      row++;
    }

    // Connecting lines between stars
    row = 0;
    for (double y = -cell; y < size.height + cell; y += half) {
      final xOffset = (row % 2 == 0) ? 0.0 : half;
      for (double x = -cell + xOffset; x < size.width + cell; x += cell) {
        _drawConnectors(canvas, paint, Offset(x, y), cell * 0.42, half);
      }
      row++;
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path();
    final innerR = r * 0.42;
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 - math.pi / 2;
      final radius = i % 2 == 0 ? r : innerR;
      final pt = Offset(
        c.dx + radius * math.cos(angle),
        c.dy + radius * math.sin(angle),
      );
      if (i == 0) path.moveTo(pt.dx, pt.dy);
      else path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawInnerSquare(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 4;
      final pt = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
      if (i == 0) path.moveTo(pt.dx, pt.dy);
      else path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawConnectors(Canvas canvas, Paint p, Offset c, double r, double half) {
    final tipDist = r;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 8;
      final tip = Offset(
        c.dx + tipDist * math.cos(angle),
        c.dy + tipDist * math.sin(angle),
      );
      final nextAngle = angle + math.pi / 8 * 2;
      final nextTip = Offset(
        c.dx + tipDist * math.cos(nextAngle),
        c.dy + tipDist * math.sin(nextAngle),
      );
      canvas.drawLine(tip, nextTip, p);
    }
  }

  @override
  bool shouldRepaint(_IslamicPatternPainter old) => old.color != color;
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
    _NavItem(icon: Icons.menu_book_outlined,  selectedIcon: Icons.menu_book_rounded,    label: 'القرآن'),
    _NavItem(icon: Icons.access_time_outlined,selectedIcon: Icons.access_time_filled,   label: 'الصلاة'),
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

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: navy.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  horizontal: selected ? 18 : 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [navy, Color(0xFF2A5BA8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: navy.withOpacity(0.35),
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
                        color: selected ? gold : Colors.grey.shade400,
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
                                  style: const TextStyle(
                                    color: Colors.white,
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

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    // Try Firebase first
    try {
      final today = _todayKey();
      final doc = await FirebaseFirestore.instance
          .collection('prayer_times')
          .doc(today)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists && doc.data() != null) {
        _setPrayerTimes(Map<String, String>.from(
            doc.data()!.map((k, v) => MapEntry(k, v.toString()))));
        return;
      }
    } catch (_) {}

    // Fallback to local JSON
    try {
      final raw = await rootBundle.loadString('assets/prayer_times_2026.json');
      final Map<String, dynamic> all = json.decode(raw);
      final today = _todayKey();
      if (all.containsKey(today)) {
        final data = all[today] as Map<String, dynamic>;
        _setPrayerTimes(data.map((k, v) => MapEntry(k, v.toString())));
        return;
      }
    } catch (e) {
      debugPrint('Prayer times load error: $e');
    }

    // Nothing loaded — stop spinner
    if (mounted) setState(() => _loading = false);
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
    const order = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    const names = {
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
    };

    for (final key in order) {
      final t = times[key];
      if (t == null) continue;
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
        return;
      }
    }
    // After isha — next is fajr
    if (!mounted) return;
    setState(() {
      _nextPrayer = 'الفجر';
      _nextPrayerTime = times['fajr'] ?? '';
    });
  }

  Future<void> _updateWidget(Map<String, String> times) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('fajr', times['fajr'] ?? '');
      await HomeWidget.saveWidgetData<String>('dhuhr', times['dhuhr'] ?? '');
      await HomeWidget.saveWidgetData<String>('asr', times['asr'] ?? '');
      await HomeWidget.saveWidgetData<String>(
          'maghrib', times['maghrib'] ?? '');
      await HomeWidget.saveWidgetData<String>('isha', times['isha'] ?? '');
      await HomeWidget.saveWidgetData<String>(
          'next_prayer', _nextPrayer);
      await HomeWidget.saveWidgetData<String>(
          'next_prayer_time', _nextPrayerTime);
      await HomeWidget.updateWidget(
        androidName: 'MasjidWidgetProvider',
      );
    } catch (e) {
      debugPrint('Widget update error: $e');
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مسجد وحسينية أهل البيت',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: theme.toggle,
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: theme.isDark ? 'وضع النهار' : 'الوضع الليلي',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPrayerTimes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Logo
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 120,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.mosque,
                  size: 100,
                  color: cs.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Masjid name
            Center(
              child: Text(
                'مسجد وحسينية أهل البيت عليهم السلام',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ),
            Center(
              child: Text(
                'بغداد - المنصور',
                style: TextStyle(fontSize: 15, color: cs.secondary),
              ),
            ),
            const SizedBox(height: 6),
            // Gold divider — matches logo
            Center(
              child: Container(
                width: 120,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, Color(0xFFC9A843), Colors.transparent],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dual date banner — Hijri + Gregorian
            const _DualDateBanner(),
            const SizedBox(height: 16),

            // Next prayer card
            if (_nextPrayer.isNotEmpty)
              Card(
                color: const Color(0xFF1B3D6F).withOpacity(0.55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFC9A843), width: 1)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'الصلاة القادمة',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _nextPrayer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _nextPrayerTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Today's prayer times
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أوقات الصلاة اليوم',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const Divider(),
                      ..._buildPrayerRows(),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Latest announcements
            const _HomeAnnouncementsSection(),

            // Bottom padding for floating nav
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrayerRows() {
    const prayers = [
      ('fajr', 'الفجر', Icons.brightness_3),
      ('dhuhr', 'الظهر', Icons.wb_sunny),
      ('asr', 'العصر', Icons.brightness_5),
      ('maghrib', 'المغرب', Icons.brightness_4),
      ('isha', 'العشاء', Icons.nights_stay),
    ];

    return prayers.map((p) {
      final time = _todayPrayers[p.$1] ?? '--:--';
      final isNext = p.$2 == _nextPrayer;
      return ListTile(
        dense: true,
        leading: Icon(
          p.$3,
          color: isNext
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
        title: Text(
          p.$2,
          style: TextStyle(
            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            color: isNext ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        trailing: Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            color: isNext ? Theme.of(context).colorScheme.primary : null,
            letterSpacing: 1.5,
          ),
        ),
      );
    }).toList();
  }
}

// ─── More Page ────────────────────────────────────────────────────────────────

// ─── Home Announcements Section ──────────────────────────────────────────────

// ─── Dual Date Banner ────────────────────────────────────────────────────────

class _DualDateBanner extends StatelessWidget {
  const _DualDateBanner();

  static const _hijriMonths = [
    'محرم','صفر','ربيع الأول','ربيع الثاني',
    'جمادى الأولى','جمادى الثانية','رجب','شعبان',
    'رمضان','شوال','ذو القعدة','ذو الحجة',
  ];

  static const _arDays = [
    'الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد',
  ];

  static const _arMonths = [
    'يناير','فبراير','مارس','أبريل','مايو','يونيو',
    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const navy = Color(0xFF1B3D6F);
    const gold = Color(0xFFC9A843);

    final now = DateTime.now();
    final hijri = HijriCalendar.now();

    final dayName = _arDays[now.weekday - 1];
    final gregStr = '$dayName  ${now.day} ${_arMonths[now.month - 1]} ${now.year}م';
    final hijriStr = '${hijri.hDay} ${_hijriMonths[hijri.hMonth - 1]} ${hijri.hYear}هـ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: navy.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        children: [
          // Hijri date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.nightlight_round, size: 14, color: gold),
                    const SizedBox(width: 5),
                    Text('هجري',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  hijriStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: navy,
                    fontFamily: 'ScheherazadeNew',
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 36,
            color: gold.withOpacity(0.3),
          ),
          const SizedBox(width: 12),
          // Gregorian date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('ميلادي',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.5))),
                    const SizedBox(width: 5),
                    Icon(Icons.wb_sunny_outlined, size: 14, color: gold),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  gregStr,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: navy,
                    fontFamily: 'ScheherazadeNew',
                  ),
                ),
              ],
            ),
          ),
        ],
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
        icon: Icons.calendar_month,
        label: 'التقويم الهجري',
        color: const Color(0xFF4CAF50),
        page: const HijriCalendarPage(),
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
        color: const Color(0xFF9C27B0),
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

    return Scaffold(
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
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: items
            .map(
              (item) => _MoreCard(item: item),
            )
            .toList(),
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
