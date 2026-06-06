import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'analytics_service.dart';
import 'backend_config.dart';
import 'islamic_background.dart';
import 'photo_viewer.dart';

const _navy = Color(0xFF1B3D6F);
const _gold = Color(0xFFC9A843);

// Same secret-key admin flag used by the events and Q&A pages.
const _deviceAdminKey = 'ask_device_admin';

// Splits a stored contact string (numbers separated by , ، ; or newlines)
// into a clean list of individual numbers.
List<String> _parseContacts(String raw) => raw
    .split(RegExp(r'[,\n;،]'))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

// ─── Trips Page ────────────────────────────────────────────────────────────────

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isAdmin = prefs.getBool(_deviceAdminKey) ?? false);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _addTrip() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _AddTripPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IslamicPatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('الرحلات والزيارات'),
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
        floatingActionButton: _isAdmin
            ? FloatingActionButton.extended(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('رحلة جديدة'),
                onPressed: _addTrip,
              )
            : null,
        body: TabBarView(
          controller: _tabs,
          children: [
            _TripList(upcoming: true, isAdmin: _isAdmin),
            _TripList(upcoming: false, isAdmin: _isAdmin),
          ],
        ),
      ),
    );
  }
}

// ─── Trips List ────────────────────────────────────────────────────────────────

class _TripList extends StatelessWidget {
  final bool upcoming;
  final bool isAdmin;
  const _TripList({required this.upcoming, required this.isAdmin});

  Stream<QuerySnapshot>? _buildStream() {
    try {
      final now = Timestamp.now();
      Query query = FirebaseFirestore.instance
          .collection('trips')
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
                Icon(Icons.directions_bus_filled_outlined,
                    size: 64, color: cs.primary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  upcoming ? 'لا توجد رحلات قادمة' : 'لا توجد رحلات سابقة',
                  style: TextStyle(
                      fontSize: 16, color: cs.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          );
        }

        // Boosted (مميز) trips pinned to the top of the list.
        final sorted = [...docs];
        sorted.sort((a, b) {
          final aB = ((a.data() as Map)['boosted'] as bool?) ?? false;
          final bB = ((b.data() as Map)['boosted'] as bool?) ?? false;
          if (aB == bB) return 0;
          return aB ? -1 : 1;
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: sorted.length,
          itemBuilder: (ctx, i) {
            final data = sorted[i].data() as Map<String, dynamic>;
            return _TripCard(
              data: data,
              docId: sorted[i].id,
              isPast: !upcoming,
              isAdmin: isAdmin,
            );
          },
        );
      },
    );
  }
}

// ─── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isPast;
  final bool isAdmin;

  const _TripCard({
    required this.data,
    required this.docId,
    required this.isPast,
    required this.isAdmin,
  });

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الرحلة'),
        content: const Text('هل تريد حذف هذه الرحلة نهائياً؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance.collection('trips').doc(docId).delete();
  }

  Future<void> _book(String contact) async {
    final digits = contact.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    Analytics.tripBooked(data['destination'] as String? ?? '');
    // Prefer WhatsApp, fall back to a normal phone dial.
    final wa = Uri.parse('https://wa.me/${digits.replaceAll('+', '')}');
    if (await canLaunchUrl(wa)) {
      await launchUrl(wa, mode: LaunchMode.externalApplication);
      return;
    }
    final tel = Uri.parse('tel:$digits');
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final title       = data['title']       as String? ?? '';
    final description = data['description'] as String? ?? '';
    final destination = data['destination'] as String? ?? '';
    final cost        = data['cost']        as String? ?? '';
    final contacts    = _parseContacts(data['contact'] as String? ?? '');
    final imageBase64 = data['imageBase64'] as String? ?? '';
    final imageUrl    = data['imageUrl']    as String? ?? '';
    final ts          = data['date']        as Timestamp?;
    final date        = ts?.toDate();
    final boosted     = (data['boosted']    as bool?) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D4A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (boosted)
            BoxShadow(
              color: _gold.withOpacity(0.45),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: _navy.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: boosted
              ? _gold
              : (isPast ? cs.outline.withOpacity(0.1) : _gold.withOpacity(0.25)),
          width: boosted ? 1.6 : 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image — base64 (Firestore) preferred, hosted URL fallback
            if (imageBase64.isNotEmpty)
              _TripImage(
                fullImage: MemoryImage(base64Decode(imageBase64)),
                isPast: isPast,
                child: Image.memory(
                  base64Decode(imageBase64),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              )
            else if (imageUrl.isNotEmpty)
              _TripImage(
                fullImage: CachedNetworkImageProvider(imageUrl),
                isPast: isPast,
                child: CachedNetworkImage(
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
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: badges + admin delete
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.directions_bus_filled,
                                      size: 12, color: Color(0xFF00897B)),
                                  SizedBox(width: 4),
                                  Text(
                                    'رحلة',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF00897B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (boosted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_gold, Color(0xFFE0C66A)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'مميز',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isAdmin) ...[
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _AddTripPage(docId: docId, initial: data),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 4, left: 4),
                            child: Icon(Icons.edit_outlined,
                                color: _navy, size: 19),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _delete(context),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 4, left: 4),
                            child: Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _navy,
                    ),
                  ),

                  // Destination
                  if (destination.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 15, color: _gold),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            destination,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Description
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Info chips: date, cost
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (date != null)
                        _InfoChip(
                          icon: Icons.event,
                          text: DateFormat('EEEE d MMM yyyy', 'ar').format(date),
                          cs: cs,
                        ),
                      if (date != null)
                        _InfoChip(
                          icon: Icons.access_time,
                          text: DateFormat('hh:mm a', 'ar').format(date),
                          cs: cs,
                        ),
                      if (cost.isNotEmpty)
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          text: cost,
                          cs: cs,
                          highlight: true,
                        ),
                    ],
                  ),

                  // Booking buttons — one per contact number
                  if (!isPast && contacts.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    for (int i = 0; i < contacts.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _book(contacts[i]),
                          icon: const Icon(Icons.chat, size: 18),
                          label: Text(contacts.length == 1
                              ? 'احجز الآن'
                              : 'احجز: ${contacts[i]}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B7A4B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final bool highlight;
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.cs,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? _gold : _navy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// Wraps a trip image and overlays an "انتهت" (ended) badge for past trips.
// Tapping the image opens it full-screen.
class _TripImage extends StatelessWidget {
  final Widget child;
  final bool isPast;
  final ImageProvider? fullImage;
  const _TripImage(
      {required this.child, required this.isPast, this.fullImage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: fullImage == null
          ? null
          : () => openPhotoView(context, fullImage!),
      child: Stack(
        children: [
          child,
          if (isPast)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: Text('انتهت',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Add Trip (admin) ──────────────────────────────────────────────────────────

class _AddTripPage extends StatefulWidget {
  // When [docId] is set the page edits that existing trip instead of creating
  // a new one; [initial] holds its current field values to prefill the form.
  final String? docId;
  final Map<String, dynamic>? initial;
  const _AddTripPage({this.docId, this.initial});

  @override
  State<_AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<_AddTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _destination = TextEditingController();
  final _cost = TextEditingController();
  // One controller per booking number; starts with a single empty field.
  final List<TextEditingController> _contacts = [TextEditingController()];
  DateTime? _date;
  bool _boosted = false;
  Uint8List? _imageBytes;
  bool _uploading = false;

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (d != null) {
      _title.text = d['title'] as String? ?? '';
      _description.text = d['description'] as String? ?? '';
      _destination.text = d['destination'] as String? ?? '';
      _cost.text = d['cost'] as String? ?? '';
      final existing = _parseContacts(d['contact'] as String? ?? '');
      if (existing.isNotEmpty) {
        _contacts
          ..clear()
          ..addAll(existing.map((c) => TextEditingController(text: c)));
      }
      _boosted = (d['boosted'] as bool?) ?? false;
      final ts = d['date'];
      if (ts is Timestamp) _date = ts.toDate();
    }
  }

  void _addContactField() {
    setState(() => _contacts.add(TextEditingController()));
  }

  void _removeContactField(int i) {
    setState(() {
      _contacts[i].dispose();
      _contacts.removeAt(i);
      if (_contacts.isEmpty) _contacts.add(TextEditingController());
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _destination.dispose();
    _cost.dispose();
    for (final c in _contacts) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1000);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date ?? now),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يرجى اختيار تاريخ ووقت الرحلة'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _uploading = true);

    try {
      // Join all non-empty numbers with a comma; the card splits them back.
      final contactsJoined = _contacts
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .join(', ');

      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'destination': _destination.text.trim(),
        'cost': _cost.text.trim(),
        'contact': contactsJoined,
        'boosted': _boosted,
        'date': Timestamp.fromDate(_date!),
      };

      // Only touch image fields when a new image was chosen — an edit keeps the
      // existing image otherwise. Prefer hosted (Hostinger), fall back to base64.
      if (_imageBytes != null) {
        String imageUrl = await Backend.uploadImage(_imageBytes!) ?? '';
        String imageBase64 = '';
        if (imageUrl.isEmpty) {
          final encoded = base64Encode(_imageBytes!);
          if (encoded.length <= 700000) {
            imageBase64 = encoded;
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('الصورة كبيرة جداً، سيتم النشر بدون صورة'),
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
        data['imageUrl'] = imageUrl;
        data['imageBase64'] = imageBase64;
      }

      final trips = FirebaseFirestore.instance.collection('trips');
      if (_isEdit) {
        await trips.doc(widget.docId).update(data);
      } else {
        data['imageUrl'] ??= '';
        data['imageBase64'] ??= '';
        data['createdAt'] = FieldValue.serverTimestamp();
        await trips.add(data);
        // Push a notification to all app users about the new trip.
        await Backend.notifyBroadcast(
          title: 'رحلة جديدة 🚌',
          body: _destination.text.trim().isNotEmpty
              ? '${_title.text.trim()} — ${_destination.text.trim()}'
              : _title.text.trim(),
          page: 'trips',
        );
        Analytics.tripPosted();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'تم تعديل الرحلة ✅' : 'تم نشر الرحلة ✅'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IslamicPatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(_isEdit ? 'تعديل الرحلة' : 'رحلة جديدة'),
          actions: [
            TextButton(
              onPressed: _uploading ? null : _submit,
              child: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(_isEdit ? 'حفظ' : 'نشر',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.primary.withOpacity(0.3)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: cs.primary.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text('اضغط لإضافة صورة (اختياري)',
                                  style: TextStyle(
                                      color: cs.onSurface.withOpacity(0.5))),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: 'عنوان الرحلة',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'يرجى إدخال العنوان'
                      : null,
                ),
                const SizedBox(height: 12),

                // Destination
                TextFormField(
                  controller: _destination,
                  decoration: InputDecoration(
                    labelText: 'الوجهة (مثال: كربلاء المقدسة)',
                    prefixIcon: const Icon(Icons.place, color: _gold),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Date & time
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'موعد الانطلاق',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.event, color: _navy),
                    ),
                    child: Text(
                      _date == null
                          ? 'اضغط لاختيار التاريخ والوقت'
                          : DateFormat('EEEE d MMMM yyyy — hh:mm a', 'ar')
                              .format(_date!),
                      style: TextStyle(
                        color: _date == null
                            ? cs.onSurface.withOpacity(0.5)
                            : cs.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cost
                TextFormField(
                  controller: _cost,
                  decoration: InputDecoration(
                    labelText: 'التكلفة (مثال: 25 ألف دينار)',
                    prefixIcon:
                        const Icon(Icons.payments_outlined, color: _gold),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Contact / booking numbers — supports more than one
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('أرقام الحجز / واتساب (اختياري)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7))),
                ),
                const SizedBox(height: 6),
                for (int i = 0; i < _contacts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contacts[i],
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.chat,
                                  color: Color(0xFF1B7A4B)),
                              hintText: '+9647xxxxxxxxx',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        if (_contacts.length > 1)
                          IconButton(
                            onPressed: () => _removeContactField(i),
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            tooltip: 'حذف الرقم',
                          ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _addContactField,
                    icon: const Icon(Icons.add_circle_outline,
                        color: Color(0xFF1B7A4B)),
                    label: const Text('إضافة رقم آخر',
                        style: TextStyle(color: Color(0xFF1B7A4B))),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _description,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'تفاصيل الرحلة (اختياري)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),

                // Boosted toggle
                SwitchListTile(
                  value: _boosted,
                  onChanged: (v) => setState(() => _boosted = v),
                  activeColor: _gold,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تمييز الرحلة (تظهر في الأعلى)'),
                  secondary: const Icon(Icons.star, color: _gold),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _uploading ? null : _submit,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_uploading
                      ? 'جارٍ الحفظ...'
                      : (_isEdit ? 'حفظ التعديل' : 'نشر الرحلة')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Firebase Error View ───────────────────────────────────────────────────────

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
