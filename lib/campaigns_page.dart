import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _navy = Color(0xFF1B3D6F);
const _gold = Color(0xFFC9A843);

// ─── Campaigns Page (حملات أهل البيت) ────────────────────────────────────────

class CampaignsPage extends StatelessWidget {
  const CampaignsPage({super.key});

  Stream<QuerySnapshot>? _buildStream() {
    try {
      return FirebaseFirestore.instance
          .collection('campaigns')
          .orderBy('date', descending: true)
          .snapshots();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final stream = _buildStream();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A1628) : const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text('حملات أهل البيت (ع)'),
      ),
      body: stream == null
          ? _ErrorView(cs: cs)
          : StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (ctx, snap) {
                if (snap.hasError) return _ErrorView(cs: cs);
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _EmptyView(cs: cs);

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _CampaignCard(data: data, isDark: isDark);
                  },
                );
              },
            ),
    );
  }
}

// ─── Campaign Card ────────────────────────────────────────────────────────────

class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const _CampaignCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final goal = data['goal'] as String? ?? '';
    final ts = data['date'] as Timestamp?;
    final date = ts?.toDate();

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
        border: Border.all(color: _gold.withOpacity(0.25), width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            if (imageUrl.isNotEmpty)
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

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volunteer_activism,
                            size: 12, color: _gold),
                        SizedBox(width: 4),
                        Text(
                          'حملة',
                          style: TextStyle(
                            fontSize: 11,
                            color: _gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ScheherazadeNew',
                      color: isDark ? Colors.white : _navy,
                    ),
                  ),

                  // Description
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],

                  // Goal
                  if (goal.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _navy.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flag, size: 16, color: _navy),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              goal,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Date
                  if (date != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 13, color: cs.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('d MMMM yyyy', 'ar').format(date),
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
    );
  }
}

// ─── Empty & Error Views ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyView({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_outlined,
              size: 64, color: cs.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'لا توجد حملات حالياً',
            style: TextStyle(
                fontSize: 16, color: cs.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ColorScheme cs;
  const _ErrorView({required this.cs});

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
                  fontSize: 14, color: cs.onSurface.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
