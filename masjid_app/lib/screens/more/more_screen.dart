import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_card.dart';
import '../announcements/announcements_screen.dart';
import '../events/events_screen.dart';
import '../donations/donations_screen.dart';
import '../mafatih/mafatih_screen.dart';
import '../hijri_calendar/hijri_calendar_screen.dart';
import '../ziyara/ziyara_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Announcements', 'إعلانات', Icons.campaign_rounded,
        const Color(0xFF00BCD4),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AnnouncementsScreen()))
      ),
      (
        'Events', 'فعاليات', Icons.event_rounded, const Color(0xFFFF9800),
        () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const EventsScreen()))
      ),
      (
        'Donations', 'التبرعات', Icons.volunteer_activism_rounded,
        const Color(0xFFFF5722),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DonationsScreen()))
      ),
      (
        'Mafatih', 'مفاتيح الجنان', Icons.auto_stories_rounded,
        const Color(0xFFE91E63),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MafatihScreen()))
      ),
      (
        'Hijri Calendar', 'التقويم الهجري', Icons.calendar_month_rounded,
        const Color(0xFF9C27B0),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HijriCalendarScreen()))
      ),
      (
        'Imam Ali Ziyara', 'زيارة الإمام علي', Icons.brightness_5_rounded,
        AppTheme.gold,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ZiyaraScreen()))
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return AnimatedFeatureCard(
            title: item.$1,
            subtitle: item.$2,
            icon: item.$3,
            iconColor: item.$4,
            onTap: item.$5,
            animationDelay: i * 80,
          );
        },
      ),
    );
  }
}
