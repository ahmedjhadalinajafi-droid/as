import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

const _adminEmail = 'ahmedjhadalinajafi@gmail.com';
bool get _isAdmin =>
    FirebaseAuth.instance.currentUser?.email == _adminEmail;

const _navy = Color(0xFF1B3D6F);
const _gold = Color(0xFFC9A843);

// ─── Event Categories ─────────────────────────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفعاليات والأحداث'),
        actions: [_AdminLoginButton()],
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Directionality(
                    textDirection: TextDirection.rtl,
                    child: _CreateEventPage(),
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('إضافة حدث'),
              backgroundColor: _navy,
              foregroundColor: Colors.white,
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: [
          _EventList(upcoming: true),
          _EventList(upcoming: false),
        ],
      ),
    );
  }
}

// ─── Events List ──────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final bool upcoming;
  const _EventList({required this.upcoming});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = Timestamp.now();

    Query query = FirebaseFirestore.instance
        .collection('events')
        .orderBy('date', descending: !upcoming);

    if (upcoming) {
      query = query.where('date', isGreaterThanOrEqualTo: now);
    } else {
      query = query.where('date', isLessThan: now);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(child: Text('خطأ: ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
            return _EventCard(
              data: data,
              docId: docs[i].id,
              isPast: !upcoming,
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

  const _EventCard(
      {required this.data, required this.docId, required this.isPast});

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحدث'),
        content: const Text('هل تريد حذف هذا الحدث نهائياً؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('events')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final category = data['category'] as String? ?? 'فعالية';
    final ts = data['date'] as Timestamp?;
    final date = ts?.toDate();

    // Find category data
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
          color: isPast
              ? cs.outline.withOpacity(0.1)
              : _gold.withOpacity(0.25),
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
                      child: const Center(
                          child: CircularProgressIndicator()),
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
                              color: isPast ? cs.onSurface.withOpacity(0.4) : Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('MMM', 'ar').format(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: isPast
                                  ? cs.onSurface.withOpacity(0.35)
                                  : _gold,
                              fontWeight: FontWeight.bold,
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
                        Row(
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
                            const Spacer(),
                            if (_isAdmin)
                              GestureDetector(
                                onTap: () => _delete(context),
                                child: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                              ),
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
                              Icon(Icons.location_on_outlined,
                                  size: 14,
                                  color: _gold),
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

// ─── Create Event Page ────────────────────────────────────────────────────────

class _CreateEventPage extends StatefulWidget {
  const _CreateEventPage();

  @override
  State<_CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<_CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String _category = 'فعالية';
  XFile? _image;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _image = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String imageUrl = '';
      if (_image != null && _imageBytes != null) {
        final ref = FirebaseStorage.instance.ref(
            'events/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(_imageBytes!);
        imageUrl = await ref.getDownloadURL();
      }

      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'category': _category,
        'date': Timestamp.fromDate(eventDateTime),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _adminEmail,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final dateStr =
        DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate);
    final timeStr = _selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة حدث جديد'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('حفظ',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold,
                        fontSize: 16)),
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
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2D4A)
                        : _navy.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _gold.withOpacity(0.3),
                        style: BorderStyle.solid),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_imageBytes!, fit: BoxFit.cover),
                            Positioned(
                              bottom: 8, left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('تغيير الصورة',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 52, color: _gold.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text('اضغط لإضافة صورة الحدث',
                                style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.4),
                                    fontSize: 14)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Category selector
              Text('نوع الحدث',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface.withOpacity(0.7))),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = cat.$1 == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? cat.$3
                              : cat.$3.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: cat.$3.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(cat.$2,
                                size: 14,
                                color: selected ? Colors.white : cat.$3),
                            const SizedBox(width: 5),
                            Text(
                              cat.$1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    selected ? Colors.white : cat.$3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Title
              _StyledField(
                controller: _titleCtrl,
                label: 'عنوان الحدث',
                icon: Icons.title,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'يرجى إدخال عنوان الحدث'
                    : null,
              ),
              const SizedBox(height: 14),

              // Description
              _StyledField(
                controller: _descCtrl,
                label: 'تفاصيل الحدث',
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 14),

              // Location
              _StyledField(
                controller: _locationCtrl,
                label: 'الموقع / المكان',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 20),

              // Date & Time row
              Row(
                children: [
                  Expanded(
                    child: _DateTimeButton(
                      icon: Icons.calendar_today,
                      label: 'التاريخ',
                      value: dateStr,
                      onTap: _pickDate,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTimeButton(
                      icon: Icons.access_time,
                      label: 'الوقت',
                      value: timeStr,
                      onTap: _pickTime,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Save button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _saving ? 'جارٍ الحفظ...' : 'حفظ الحدث',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Styled Text Field ────────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _gold.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _gold.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _navy, width: 1.5),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E2D4A)
            : Colors.white,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

// ─── Date/Time Button ─────────────────────────────────────────────────────────

class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color color;

  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2D4A) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.7))),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, size: 16, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Login Button ───────────────────────────────────────────────────────

class _AdminLoginButton extends StatefulWidget {
  @override
  State<_AdminLoginButton> createState() => _AdminLoginButtonState();
}

class _AdminLoginButtonState extends State<_AdminLoginButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) await GoogleSignIn().signOut();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)),
      );
    }
    if (_isAdmin) {
      return IconButton(
        icon: const Icon(Icons.logout, color: Colors.white70),
        tooltip: 'تسجيل خروج المشرف',
        onPressed: _signOut,
      );
    }
    return IconButton(
      icon:
          const Icon(Icons.admin_panel_settings_outlined, color: Colors.white70),
      tooltip: 'دخول المشرف',
      onPressed: _signIn,
    );
  }
}
