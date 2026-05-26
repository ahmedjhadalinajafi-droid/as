import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/hijri_utils.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/islamic_pattern_painter.dart';
import '../../services/prayer_service.dart';
import '../../providers/theme_provider.dart';
import '../prayer_times/prayer_times_screen.dart';
import '../quran/quran_screen.dart';
import '../qibla/qibla_screen.dart';
import '../mafatih/mafatih_screen.dart';
import '../hijri_calendar/hijri_calendar_screen.dart';
import '../donations/donations_screen.dart';
import '../announcements/announcements_screen.dart';
import '../events/events_screen.dart';
import '../ziyara/ziyara_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _countdownTimer;
  Duration _timeToNextPrayer = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final service = context.read<PrayerService>();
      if (service.nextPrayerTime != null) {
        final diff = service.nextPrayerTime!.difference(DateTime.now());
        if (mounted) setState(() => _timeToNextPrayer = diff.isNegative ? Duration.zero : diff);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hijri = HijriDate.now();
    final prayerService = context.watch<PrayerService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(hijri, prayerService)),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate(_buildFeatureCards()),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHeader(HijriDate hijri, PrayerService prayerService) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navyDark, Color(0xFF0A1F38)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: IslamicPatternPainter(
                color: AppTheme.gold,
                opacity: 0.05,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Masjid name header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.mosque_rounded,
                          color: AppTheme.gold, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'مسجد أهل البيت والحسينية',
                              style: TextStyle(
                                color: AppTheme.gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textDirection: TextDirection.rtl,
                            ).animate().fadeIn(delay: 100.ms),
                            const Text(
                              'Ahlul Bayt Mosque · Baghdad',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ).animate().fadeIn(delay: 150.ms),
                          ],
                        ),
                      ),
                      // Gold divider line like in the logo
                      Container(
                        width: 3,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppTheme.gold, Colors.transparent],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.gold.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${hijri.day} ${hijri.longMonthName}',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${hijri.year} AH',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Salutation
                  const Text(
                    'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'serif',
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 16),
                  // Next prayer countdown
                  if (!prayerService.loading)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppTheme.gold.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: AppTheme.gold, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next: ${prayerService.nextPrayerName}',
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 11),
                                ),
                                Text(
                                  _formatCountdown(_timeToNextPrayer),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PrayerTimesScreen())),
                            child: const Text('All Times',
                                style: TextStyle(
                                    color: AppTheme.gold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  // Gold accent line like the logo
                  const SizedBox(height: 12),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.gold,
                          AppTheme.gold,
                          Colors.transparent
                        ],
                        stops: const [0, 0.2, 0.8, 1],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureCards() {
    final features = [
      (
        'Prayer Times', 'الصلاة', Icons.access_time_rounded, AppTheme.gold,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PrayerTimesScreen()))
      ),
      (
        'Quran', 'القرآن الكريم', Icons.menu_book_rounded,
        const Color(0xFF4CAF50),
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const QuranScreen()))
      ),
      (
        'Qibla', 'القبلة', Icons.explore_rounded, const Color(0xFF42A5F5),
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const QiblaScreen()))
      ),
      (
        'Mafatih', 'مفاتيح الجنان', Icons.auto_stories_rounded,
        const Color(0xFFEC407A),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MafatihScreen()))
      ),
      (
        'Hijri Calendar', 'التقويم', Icons.calendar_month_rounded,
        const Color(0xFFAB47BC),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HijriCalendarScreen()))
      ),
      (
        'Donations', 'التبرعات', Icons.volunteer_activism_rounded,
        const Color(0xFFEF5350),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DonationsScreen()))
      ),
      (
        'Announcements', 'إعلانات', Icons.campaign_rounded,
        const Color(0xFF26C6DA),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AnnouncementsScreen()))
      ),
      (
        'Events', 'فعاليات', Icons.event_rounded, const Color(0xFFFF7043),
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const EventsScreen()))
      ),
      (
        'Imam Ali Ziyara', 'الزيارة', Icons.brightness_5_rounded, AppTheme.gold,
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ZiyaraScreen()))
      ),
    ];

    return features.asMap().entries.map((e) {
      final i = e.key;
      final f = e.value;
      return AnimatedFeatureCard(
        title: f.$1,
        subtitle: f.$2,
        icon: f.$3,
        iconColor: f.$4,
        onTap: f.$5,
        animationDelay: 80 + i * 55,
      );
    }).toList();
  }
}
