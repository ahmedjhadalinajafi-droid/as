import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../data/sample_data.dart';
import '../../models/event.dart';
import '../../services/notification_service.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sorted = [...sampleEvents]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded,
                color: AppTheme.gold),
            tooltip: 'Test notification',
            onPressed: () => _sendTestNotification(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (context, i) =>
            _EventCard(event: sorted[i], index: i),
      ),
    );
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    await NotificationService.instance.show(
      id: 1,
      title: '🕌 New Masjid Event',
      body: 'Eid Al-Adha Celebration — 17 Jun at 7:30 AM',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }
}

class _EventCard extends StatelessWidget {
  final MasjidEvent event;
  final int index;

  const _EventCard({required this.event, required this.index});

  Color _color(String cat) {
    switch (cat) {
      case 'Celebration': return const Color(0xFFFFD700);
      case 'Community': return const Color(0xFF4CAF50);
      case 'Education': return const Color(0xFF2196F3);
      default: return AppTheme.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(event.category);
    final isPast = event.dateTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPast ? Colors.white12 : color.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 120,
            decoration: BoxDecoration(
              color: isPast ? Colors.white24 : color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                              color: color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isPast) ...[
                        const SizedBox(width: 6),
                        const Text('PAST',
                            style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM').format(event.dateTime),
                        style: TextStyle(
                          color: isPast ? Colors.white38 : color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: TextStyle(
                      color: isPast ? Colors.white54 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          color: Colors.white38, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('hh:mm a').format(event.dateTime),
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white38, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        event.location,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.1, end: 0, duration: 350.ms);
  }
}
