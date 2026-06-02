import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'islamic_background.dart';

const _navy = Color(0xFF1B3D6F);
const _gold = Color(0xFFC9A843);

const _categories = [
  ('فعالية', Icons.event, Color(0xFF9C27B0)),
  ('محاضرة', Icons.record_voice_over, Color(0xFF2196F3)),
  ('خطبة الجمعة', Icons.menu_book, Color(0xFF1B3D6F)),
  ('مناسبة دينية', Icons.star, Color(0xFFC9A843)),
  ('إعلان عام', Icons.campaign, Color(0xFFF44336)),
];

// ─── Events Page ──────────────────────────────────────────────────────────────

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IslamicPatternBackground(
      child: Scaffold( backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('الفعاليات والأحداث'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'القادمة'),
            Tab(text: 'السابقة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _EventList(upcoming: true),
          _EventList(upcoming: false),
        ],
      ),
    ),
    );
  }
}

// ─── Events List ──────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final bool upcoming;
  const _EventList({required this.upcoming});

  Stream<QuerySnapshot>? _buildStream() {
    try {
      final now = Timestamp.now();
      Query query = FirebaseFirestore.instance
          .collection('events')
          .orderBy('date', descending: !upcoming);
      if (upcoming) {
        query = query.where('date', isGreaterThanOrEqualTo: now);
      } else {
        query = query.where('date', isLessThan: now);
      }
      return query.snapshots();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stream = _buildStream();

    if (stream == null) {
      return _FirebaseErrorView(cs: cs);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.hasError) {
          return _FirebaseErrorView(cs: cs);
        }
        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 64, color: cs.primary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  upcoming ? 'لا توجد فعاليات قادمة' : 'لا توجد فعاليات سابقة',
                  style: TextStyle(
                      fontSize: 16, color: cs.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _EventCard(data: data, isPast: !upcoming);
          },
        );
      },
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isPast;

  const _EventCard({required this.data, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final title       = data['title']       as String? ?? '';
    final description = data['description'] as String? ?? '';
    final location    = data['location']    as String? ?? '';
    final imageUrl    = data['imageUrl']    as String? ?? '';
    final category    = data['category']    as String? ?? 'فعالية';
    final ts          = data['date']        as Timestamp?;
    final date        = ts?.toDate();

    final catData = _categories.firstWhere(
      (c) => c.$1 == category,
      orElse: () => _categories.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D4A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isPast ? cs.outline.withOpacity(0.1) : _gold.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            if (imageUrl.isNotEmpty)
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 180,
                      color: _navy.withOpacity(0.08),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  if (isPast)
                    Container(
                      height: 180,
                      color: Colors.black.withOpacity(0.35),
                      child: const Center(
                        child: Text('انتهت',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date badge
                  if (date != null)
                    Container(
                      width: 54,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isPast
                            ? cs.outline.withOpacity(0.1)
                            : _navy,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('dd').format(date),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isPast
                                  ? cs.onSurface.withOpacity(0.4)
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('MMM', 'ar').format(date),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPast
                                  ? cs.onSurface.withOpacity(0.35)
                                  : _gold,
                            ),
                          ),
                          Text(
                            DateFormat('yyyy').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: isPast
                                  ? cs.onSurface.withOpacity(0.3)
                                  : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: catData.$3.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(catData.$2, size: 12, color: catData.$3),
                              const SizedBox(width: 4),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: catData.$3,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : _navy,
                          ),
                        ),

                        // Description
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: cs.onSurface.withOpacity(0.65),
                            ),
                          ),
                        ],

                        // Location
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: _gold),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Time
                        if (date != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 13,
                                  color: cs.onSurface.withOpacity(0.4)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('hh:mm a', 'ar').format(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Firebase Error View ──────────────────────────────────────────────────────

class _FirebaseErrorView extends StatelessWidget {
  final ColorScheme cs;
  const _FirebaseErrorView({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64, color: cs.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'تعذّر الاتصال بالخادم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
