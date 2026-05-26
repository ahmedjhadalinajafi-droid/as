import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/islamic_pattern_painter.dart';
import '../../services/prayer_service.dart';
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
    final hijri = HijriCalendar.now();
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

  Widget _buildHeader(HijriCalendar hijri, PrayerService prayerService) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D3B1F), Color(0xFF0A1628)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: IslamicPatternPainter(opacity: 0.06),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: 16,
                              fontFamily: 'serif',
                            ),
                          ).animate().fadeIn(delay: 100.ms),
                          const SizedBox(height: 4),
                          const Text(
                            'Assalamu Alaikum',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${hijri.hDay} ${hijri.longMonthName}',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${hijri.hYear} AH',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                  const Spacer(),
                  if (!prayerService.loading)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: AppTheme.gold, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next: ${prayerService.nextPrayerName}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatCountdown(_timeToNextPrayer),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
                            child: const Text('View All',
                                style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),
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
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen()))
      ),
      (
        'Quran', 'القرآن', Icons.menu_book_rounded, const Color(0xFF4CAF50),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen()))
      ),
      (
        'Qibla', 'القبلة', Icons.explore_rounded, const Color(0xFF2196F3),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen()))
      ),
      (
        'Mafatih', 'مفاتيح', Icons.auto_stories_rounded, const Color(0xFFE91E63),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MafatihScreen()))
      ),
      (
        'Calendar', 'التقويم', Icons.calendar_month_rounded, const Color(0xFF9C27B0),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HijriCalendarScreen()))
      ),
      (
        'Donations', 'التبرعات', Icons.volunteer_activism_rounded, const Color(0xFFFF5722),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationsScreen()))
      ),
      (
        'Announcements', 'إعلانات', Icons.campaign_rounded, const Color(0xFF00BCD4),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()))
      ),
      (
        'Events', 'فعاليات', Icons.event_rounded, const Color(0xFFFF9800),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()))
      ),
      (
        'Imam Ali Ziyara', 'زيارة', Icons.brightness_5_rounded, AppTheme.gold,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZiyaraScreen()))
      ),
    ];

    return features.asMap().entries.map((entry) {
      final i = entry.key;
      final f = entry.value;
      return AnimatedFeatureCard(
        title: f.$1,
        subtitle: f.$2,
        icon: f.$3,
        iconColor: f.$4,
        onTap: f.$5,
        animationDelay: 100 + i * 60,
      );
    }).toList();
  }
}
