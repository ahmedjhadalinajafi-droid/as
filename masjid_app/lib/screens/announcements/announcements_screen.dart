import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../data/sample_data.dart';
import '../../models/announcement.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sampleAnnouncements.length,
        itemBuilder: (context, i) {
          return _AnnouncementCard(
            announcement: sampleAnnouncements[i],
            index: i,
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final int index;

  const _AnnouncementCard({required this.announcement, required this.index});

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Event': return const Color(0xFFFF9800);
      case 'Reminder': return const Color(0xFF2196F3);
      case 'Education': return const Color(0xFF4CAF50);
      default: return AppTheme.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(announcement.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    announcement.category,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy').format(announcement.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              announcement.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              announcement.body,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0, duration: 350.ms);
  }
}
