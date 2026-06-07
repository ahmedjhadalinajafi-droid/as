import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'islamic_background.dart';
import 'brand.dart';

const _navy = Color(0xFF1B3D6F);
const _gold = Color(0xFFC9A843);

// ─── Ziyara Trips Page (حملات الزيارة) ───────────────────────────────────────
// Reads Firestore collection "trips". Each document:
//   title         string    اسم الحملة            (required)
//   destination   string    الوجهة (النجف/كربلاء)
//   departureFrom string    مكان الانطلاق
//   imageUrl      string    رابط الصورة
//   departureDate timestamp تاريخ ووقت الذهاب     (used for قادمة/منتهية)
//   returnDate    timestamp تاريخ العودة
//   price         string    السعر بالدينار
//   seats         string    المقاعد المتبقية
//   phone         string    رقم الاتصال/واتساب (e.g. 9647701234567)
//   description   string    تفاصيل إضافية

class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage>
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('حملات الزيارة'),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: _gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'القادمة'),
              Tab(text: 'المنتهية'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: const [
            _TripList(upcoming: true),
            _TripList(upcoming: false),
          ],
        ),
      ),
    );
  }
}

// ─── Trip List ────────────────────────────────────────────────────────────────

class _TripList extends StatelessWidget {
  final bool upcoming;
  const _TripList({required this.upcoming});

  Stream<QuerySnapshot>? _buildStream() {
    try {
      return FirebaseFirestore.instance
          .collection('trips')
          .orderBy('departureDate', descending: true)
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

    if (stream == null) return _ErrorView(cs: cs);

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.hasError) return _ErrorView(cs: cs);
        final docs = snap.data?.docs ?? [];

        final now = DateTime.now();
        // Split by departure date. A trip with no date is treated as upcoming.
        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final dep = (data['departureDate'] as Timestamp?)?.toDate();
          final isUpcoming = dep == null || !dep.isBefore(now);
          return upcoming ? isUpcoming : !isUpcoming;
        }).toList();

        // Upcoming: soonest first. Ended: most recent first.
        filtered.sort((a, b) {
          final ad = ((a.data() as Map)['departureDate'] as Timestamp?)?.toDate();
          final bd = ((b.data() as Map)['departureDate'] as Timestamp?)?.toDate();
          if (ad == null) return -1;
          if (bd == null) return 1;
          return upcoming ? ad.compareTo(bd) : bd.compareTo(ad);
        });

        if (filtered.isEmpty) return _EmptyView(cs: cs, upcoming: upcoming);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final data = filtered[i].data() as Map<String, dynamic>;
            return _TripCard(data: data, isDark: isDark, isPast: !upcoming);
          },
        );
      },
    );
  }
}

// ─── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final bool isPast;
  const _TripCard({required this.data, required this.isDark, required this.isPast});

  static String _ar(DateTime d) => DateFormat('EEEE d MMMM yyyy', 'ar').format(d);
  static String _arTime(DateTime d) => DateFormat('hh:mm a', 'ar').format(d);

  Future<void> _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final title         = data['title']         as String? ?? '';
    final destination   = data['destination']   as String? ?? '';
    final departureFrom = data['departureFrom'] as String? ?? '';
    final imageUrl      = data['imageUrl']       as String? ?? '';
    final price         = (data['price']         ?? '').toString();
    final seats         = (data['seats']         ?? '').toString();
    final description   = data['description']    as String? ?? '';
    final depDate = (data['departureDate'] as Timestamp?)?.toDate();
    final retDate = (data['returnDate']    as Timestamp?)?.toDate();

    // Contacts: new array format takes priority, falls back to single phone.
    // Array format: [ {name: "أبو علي", label: "رجال ١", phone: "964..."}, ... ]
    final rawContacts = data['contacts'];
    final List<Map<String, String>> contacts;
    if (rawContacts is List && rawContacts.isNotEmpty) {
      contacts = rawContacts
          .whereType<Map>()
          .map((c) => {
                'name':  (c['name']  ?? '').toString(),
                'label': (c['label'] ?? '').toString(),
                'phone': (c['phone'] ?? '').toString(),
              })
          .where((c) => c['phone']!.isNotEmpty)
          .toList();
    } else {
      // Legacy single-phone field
      final p = data['phone'] as String? ?? '';
      contacts = p.isNotEmpty ? [{'name': '', 'label': '', 'phone': p}] : [];
    }

    final card = Container(
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
          color: isPast ? cs.outline.withOpacity(0.12) : _gold.withOpacity(0.3),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with route badge
            if (imageUrl.isNotEmpty)
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 170,
                      color: _navy.withOpacity(0.08),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  if (isPast)
                    Container(
                      height: 170,
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: Text('انتهت',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route chip: من بغداد ← الوجهة
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_bus_filled,
                            size: 14, color: _gold),
                        const SizedBox(width: 6),
                        Text(
                          destination.isNotEmpty
                              ? 'بغداد  ←  $destination'
                              : 'حملة زيارة',
                          style: const TextStyle(
                            fontSize: 12,
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

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Departure point
                  if (departureFrom.isNotEmpty)
                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'الانطلاق',
                      value: departureFrom,
                      cs: cs,
                    ),

                  // Departure date
                  if (depDate != null)
                    _InfoRow(
                      icon: Icons.flight_takeoff,
                      label: 'الذهاب',
                      value: '${_ar(depDate)} - ${_arTime(depDate)}',
                      cs: cs,
                    ),

                  // Return date
                  if (retDate != null)
                    _InfoRow(
                      icon: Icons.flight_land,
                      label: 'العودة',
                      value: _ar(retDate),
                      cs: cs,
                    ),

                  const SizedBox(height: 10),

                  // Price + seats
                  Row(
                    children: [
                      if (price.isNotEmpty)
                        Expanded(
                          child: _StatBox(
                            icon: Icons.payments,
                            label: 'السعر',
                            value: '$price د.ع',
                            color: const Color(0xFF1B7A4B),
                          ),
                        ),
                      if (price.isNotEmpty && seats.isNotEmpty)
                        const SizedBox(width: 10),
                      if (seats.isNotEmpty)
                        Expanded(
                          child: _StatBox(
                            icon: Icons.event_seat,
                            label: 'المقاعد المتبقية',
                            value: seats,
                            color: brandColor(context),
                          ),
                        ),
                    ],
                  ),

                  // Contact buttons (hidden for ended trips)
                  if (contacts.isNotEmpty && !isPast) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    const Text(
                      'للتواصل والحجز',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...contacts.map((c) => _ContactRow(
                          contact: c,
                          onWhatsApp: () => _openWhatsApp(c['phone']!),
                          onCall: () => _call(c['phone']!),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return isPast ? Opacity(opacity: 0.7, child: card) : card;
  }
}

// ─── Small Widgets ──────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final Map<String, String> contact;
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  const _ContactRow({
    required this.contact,
    required this.onWhatsApp,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final name  = contact['name']  ?? '';
    final label = contact['label'] ?? '';
    final phone = contact['phone'] ?? '';

    // Display: "أبو علي — رجال ١" or just whichever is available
    final displayTitle = [name, label]
        .where((s) => s.isNotEmpty)
        .join('  —  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Name + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayTitle.isNotEmpty)
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _navy,
                      fontFamily: 'ScheherazadeNew',
                    ),
                  ),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.55),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // WhatsApp button
          _ContactBtn(
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            onTap: onWhatsApp,
          ),
          const SizedBox(width: 8),
          // Call button
          _ContactBtn(
            icon: Icons.phone_rounded,
            color: brandColor(context),
            onTap: onCall,
          ),
        ],
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ContactBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _gold),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cs.onSurface.withOpacity(0.85),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty & Error Views ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final ColorScheme cs;
  final bool upcoming;
  const _EmptyView({required this.cs, required this.upcoming});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined,
              size: 64, color: cs.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            upcoming ? 'لا توجد حملات قادمة حالياً' : 'لا توجد حملات سابقة',
            style: TextStyle(fontSize: 16, color: cs.onSurface.withOpacity(0.5)),
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
