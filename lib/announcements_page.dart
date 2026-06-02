import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'islamic_background.dart';

// Admin email — only this account can add/delete announcements
const _adminEmail = 'ahmedjhadalinajafi@gmail.com';

bool get _isAdmin =>
    FirebaseAuth.instance.currentUser?.email == _adminEmail;

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IslamicPatternBackground(
      child: Scaffold( backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('الإعلانات'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(child: Text('خطأ: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 64, color: cs.primary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('لا توجد إعلانات حالياً',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _AnnouncementCard(
                  data: data, docId: docs[i].id, showDelete: false);
            },
          );
        },
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
          SnackBar(content: Text('خطأ في تسجيل الدخول: $e')),
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
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
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
      icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white70),
      tooltip: 'دخول المشرف',
      onPressed: _signIn,
    );
  }
}

// ─── Announcement Card ────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool showDelete;
  const _AnnouncementCard(
      {required this.data, required this.docId, required this.showDelete});

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل تريد حذف هذا الإعلان نهائياً؟'),
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
        .collection('announcements')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = data['title'] as String? ?? '';
    final body = data['body'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('d MMMM yyyy', 'ar').format(ts.toDate())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: cs.primary.withOpacity(0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 60,
                color: cs.primary.withOpacity(0.05),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                if (title.isNotEmpty && body.isNotEmpty)
                  const SizedBox(height: 8),
                if (body.isNotEmpty)
                  Text(body,
                      style: const TextStyle(fontSize: 15, height: 1.6)),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 13,
                          color: cs.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      if (showDelete)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => _delete(context),
                          tooltip: 'حذف',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Announcement ─────────────────────────────────────────────────────────

class _AddAnnouncementPage extends StatefulWidget {
  const _AddAnnouncementPage();

  @override
  State<_AddAnnouncementPage> createState() => _AddAnnouncementPageState();
}

class _AddAnnouncementPageState extends State<_AddAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  bool _uploading = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _image = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _uploading = true);

    try {
      String imageUrl = '';
      if (_image != null && _imageBytes != null) {
        final ref = FirebaseStorage.instance
            .ref('announcements/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(_imageBytes!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IslamicPatternBackground(
      child: Scaffold( backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('إعلان جديد'),
        actions: [
          TextButton(
            onPressed: _uploading ? null : _submit,
            child: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('نشر',
                    style: TextStyle(
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
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cs.primary.withOpacity(0.3),
                        style: BorderStyle.solid),
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
                            Text('اضغط لإضافة صورة',
                                style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.5))),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'يرجى إدخال العنوان'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'نص الإعلان',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'يرجى إدخال نص الإعلان'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _submit,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_uploading ? 'جارٍ النشر...' : 'نشر الإعلان'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
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
