import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/prayer_service.dart';
import '../../models/prayer_time.dart';
import '../../widgets/islamic_pattern_painter.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PrayerService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<PrayerService>().load(),
          ),
        ],
      ),
      body: service.loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : service.error != null
              ? _buildError(service)
              : _buildContent(service),
    );
  }

  Widget _buildError(PrayerService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            Text(service.error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, height: 1.6)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<PrayerService>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PrayerService service) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(service)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _PrayerCard(
                prayer: service.prayers[i],
                formatTime: service.formatTime,
                now: _now,
                index: i,
              ),
              childCount: service.prayers.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader(PrayerService service) {
    Duration remaining = Duration.zero;
    if (service.nextPrayerTime != null) {
      final diff = service.nextPrayerTime!.difference(_now);
      remaining = diff.isNegative ? Duration.zero : diff;
    }
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D3B1F), Color(0xFF0A2040)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(painter: IslamicPatternPainter(opacity: 0.08)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next: ${service.nextPrayerName}',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '$h:$m:$s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(
                      duration: 3.seconds,
                      color: AppTheme.gold.withOpacity(0.4),
                    ),
                const SizedBox(height: 8),
                Text(
                  service.cityName,
                  style: const TextStyle(color: AppTheme.gold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final PrayerTimeModel prayer;
  final String Function(DateTime) formatTime;
  final DateTime now;
  final int index;

  const _PrayerCard({
    required this.prayer,
    required this.formatTime,
    required this.now,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: prayer.isNext
            ? const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              )
            : null,
        color: prayer.isNext ? null : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: prayer.isNext
              ? AppTheme.gold.withOpacity(0.4)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (prayer.isNext ? AppTheme.gold : Colors.white).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _icon(prayer.name),
            color: prayer.isNext ? AppTheme.gold : Colors.white54,
            size: 20,
          ),
        ),
        title: Text(
          prayer.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: prayer.isNext ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          prayer.arabicName,
          style: TextStyle(
            color: prayer.isNext ? AppTheme.gold.withOpacity(0.8) : Colors.white38,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          formatTime(prayer.time),
          style: TextStyle(
            color: prayer.isNext ? AppTheme.gold : Colors.white,
            fontSize: 16,
            fontWeight: prayer.isNext ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0, duration: 300.ms);
  }

  IconData _icon(String name) {
    switch (name) {
      case 'Fajr': return Icons.brightness_3_rounded;
      case 'Sunrise': return Icons.wb_twilight_rounded;
      case 'Dhuhr': return Icons.wb_sunny_rounded;
      case 'Asr': return Icons.wb_cloudy_rounded;
      case 'Maghrib': return Icons.nights_stay_rounded;
      case 'Isha': return Icons.bedtime_rounded;
      default: return Icons.access_time_rounded;
    }
  }
}
