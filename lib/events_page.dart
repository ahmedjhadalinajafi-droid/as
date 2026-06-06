import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'backend_config.dart';
import 'islamic_background.dart';
import 'photo_viewer.dart';

const _navy = Color(0xFF1B3D6F);
const _gold = Color(0xFFC9A843);

// Same secret-key admin flag used by the Q&A page. A device becomes admin by
// typing the secret string as a question; that toggles this SharedPreferences
// flag, which also unlocks adding/deleting events here.
const _deviceAdminKey = 'ask_device_admin';

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

  Future<void> _addEvent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _AddEventPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IslamicPatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
        floatingActionButton: _isAdmin
            ? FloatingActionButton.extended(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('فعالية جديدة'),
                onPressed: _addEvent,
              )
            : null,
        body: TabBarView(
          controller: _tabs,
          children: [
            _EventList(upcoming: true, isAdmin: _isAdmin),
            _EventList(upcoming: false, isAdmin: _isAdmin),
          ],
        ),
      ),
    );
  }
}

// ─── Events List ──────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final bool upcoming;
  final bool isAdmin;
  const _EventList({required this.upcoming, required this.isAdmin});

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

        // Boosted (مميز) events pinned to the top of the list.
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
            return _EventCard(
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

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isPast;
  final bool isAdmin;

  const _EventCard({
    required this.data,
    required this.docId,
    required this.isPast,
    required this.isAdmin,
  });

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفعالية'),
        content: const Text('هل تريد حذف هذه الفعالية نهائياً؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance.collection('events').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final title       = data['title']       as String? ?? '';
    final description = data['description'] as String? ?? '';
    final location    = data['location']    as String? ?? '';
    final imageBase64 = data['imageBase64'] as String? ?? '';
    final imageUrl    = data['imageUrl']    as String? ?? ''; // legacy
    final category    = data['category']    as String? ?? 'فعالية';
    final ts          = data['date']        as Timestamp?;
    final date        = ts?.toDate();
    final boosted     = (data['boosted']    as bool?) ?? false;

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
            // Image — base64 (stored in Firestore) preferred, legacy URL fallback
            if (imageBase64.isNotEmpty)
              _EventImage(
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
              _EventImage(
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
                        // Category chip + boosted badge + admin delete
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
                                      color: catData.$3.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(catData.$2,
                                            size: 12, color: catData.$3),
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
                                  if (boosted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [_gold, Color(0xFFE0C66A)],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8),
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
                                    builder: (_) => _AddEventPage(
                                        docId: docId, initial: data),
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

// Wraps an event image and overlays an "انتهت" (ended) badge for past events.
// Tapping the image opens it full-screen.
class _EventImage extends StatelessWidget {
  final Widget child;
  final bool isPast;
  final ImageProvider? fullImage;
  const _EventImage(
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

// ─── Add Event (admin) ────────────────────────────────────────────────────────

class _AddEventPage extends StatefulWidget {
  // When [docId] is set the page edits that existing event instead of creating
  // a new one; [initial] holds its current field values to prefill the form.
  final String? docId;
  final Map<String, dynamic>? initial;
  const _AddEventPage({this.docId, this.initial});

  @override
  State<_AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<_AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  String _category = _categories.first.$1;
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
      _location.text = d['location'] as String? ?? '';
      final cat = d['category'] as String? ?? '';
      if (_categories.any((c) => c.$1 == cat)) _category = cat;
      _boosted = (d['boosted'] as bool?) ?? false;
      final ts = d['date'];
      if (ts is Timestamp) _date = ts.toDate();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1000);
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
        content: Text('يرجى اختيار تاريخ ووقت الفعالية'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _uploading = true);

    try {
      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'location': _location.text.trim(),
        'category': _category,
        'boosted': _boosted,
        'date': Timestamp.fromDate(_date!),
      };

      // Only touch the image fields when a new image was chosen — otherwise an
      // edit keeps the existing image. Prefer hosted (Hostinger), fall back to
      // base64-in-Firestore.
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

      final events = FirebaseFirestore.instance.collection('events');
      if (_isEdit) {
        await events.doc(widget.docId).update(data);
      } else {
        data['imageUrl'] ??= '';
        data['imageBase64'] ??= '';
        data['createdAt'] = FieldValue.serverTimestamp();
        await events.add(data);
        // Push a notification to all app users about the new event.
        await Backend.notifyBroadcast(
          title: 'فعالية جديدة 🗓️',
          body: _title.text.trim(),
          page: 'events',
        );
        Analytics.eventPosted();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'تم تعديل الفعالية ✅' : 'تم نشر الفعالية ✅'),
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
          title: Text(_isEdit ? 'تعديل الفعالية' : 'فعالية جديدة'),
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
                      border:
                          Border.all(color: cs.primary.withOpacity(0.3)),
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
                    labelText: 'عنوان الفعالية',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'يرجى إدخال العنوان'
                      : null,
                ),
                const SizedBox(height: 12),

                // Category
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: 'النوع',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c.$1,
                            child: Row(
                              children: [
                                Icon(c.$2, size: 18, color: c.$3),
                                const SizedBox(width: 8),
                                Text(c.$1),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _category = v ?? _categories.first.$1),
                ),
                const SizedBox(height: 12),

                // Date & time
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'التاريخ والوقت',
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

                // Location
                TextFormField(
                  controller: _location,
                  decoration: InputDecoration(
                    labelText: 'المكان (اختياري)',
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: _gold),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _description,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'الوصف (اختياري)',
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
                  title: const Text('تمييز الفعالية (تظهر في الأعلى)'),
                  secondary: const Icon(Icons.star, color: _gold),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _uploading ? null : _submit,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_uploading
                      ? 'جارٍ الحفظ...'
                      : (_isEdit ? 'حفظ التعديل' : 'نشر الفعالية')),
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
