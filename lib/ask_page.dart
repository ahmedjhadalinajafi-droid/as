import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_config.dart';
import 'islamic_background.dart';
import 'notification_service.dart';

const _deviceAdminKey = 'ask_device_admin';
const _adminSecret = 'MasjidAhlAlBait-Admin-Baghdad-Mansour-2026';

const _navy = Color(0xFF1B3D6F);
const _gold = Color(0xFFC9A843);

// ─── Ask Page ─────────────────────────────────────────────────────────────────

class AskPage extends StatefulWidget {
  const AskPage({super.key});

  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  Set<String> _myIds = {};
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final isAdmin = prefs.getBool(_deviceAdminKey) ?? false;
    setState(() {
      _myIds = (prefs.getStringList('my_questions') ?? []).toSet();
      _isAdmin = isAdmin;
    });
    if (isAdmin) _saveAdminToken();
  }

  Future<void> _saveAdminToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('config')
            .doc('admin_device')
            .set({'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
                SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Save admin token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _isAdmin ? 3 : 1,
      child: IslamicPatternBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('الأسئلة والأجوبة'),
            bottom: TabBar(
              isScrollable: false,
              indicatorColor: _gold,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                const Tab(text: 'أسئلتي'),
                if (_isAdmin) const Tab(text: 'الأسئلة والأجوبة'),
                if (_isAdmin) _PendingBadgeTab(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_comment_rounded),
            label: const Text('اطرح سؤالاً'),
            onPressed: _askQuestion,
          ),
          body: TabBarView(
            children: [
              _MyQuestionsTab(myIds: _myIds),
              if (_isAdmin) const _PublicQATab(),
              if (_isAdmin) const _PendingTab(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _askQuestion() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AskSheet(),
    );
    if (result == null) return;

    final questionText = (result['question'] as String? ?? '').trim();

    // Secret admin toggle
    if (questionText == _adminSecret) {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getBool(_deviceAdminKey) ?? false;
      await prefs.setBool(_deviceAdminKey, !current);
      await _load();
      // Restart listeners so this device starts getting new-question alerts.
      NotificationService().startQuestionListeners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!current
              ? 'تم تفعيل صلاحيات المشرف ✅'
              : 'تم إلغاء صلاحيات المشرف'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('جارٍ إرسال السؤال...'),
      duration: Duration(seconds: 60),
      behavior: SnackBarBehavior.floating,
    ));

    try {
      String clientToken = '';
      try {
        clientToken = await FirebaseMessaging.instance.getToken() ?? '';
      } catch (_) {}

      // Prefer hosted image (Hostinger); fall back to base64-in-Firestore.
      String imageUrl = '';
      String imageBase64 = '';
      final imageFile = result['image'] as XFile?;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        imageUrl = await Backend.uploadImage(bytes) ?? '';
        if (imageUrl.isEmpty) {
          imageBase64 = await _encodeImage(imageFile);
          if (imageBase64.isEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('الصورة كبيرة جداً، سيتم إرسال السؤال بدون صورة'),
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      }

      final docRef = FirebaseFirestore.instance.collection('questions').doc();
      await docRef.set({
        'question': questionText,
        'name': result['name'] as String? ?? '',
        'answer': '',
        'imageUrl': imageUrl,
        'imageBase64': imageBase64,
        'answerImageBase64': '',
        'status': 'pending',
        'askedAt': FieldValue.serverTimestamp(),
        'clientFcmToken': clientToken,
      });

      // Push "new question" to admin devices via the Hostinger server (works
      // even when the admin app is closed).
      final preview = questionText.length > 80
          ? '${questionText.substring(0, 80)}...'
          : questionText;
      await Backend.notifyNewQuestion(preview);

      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('my_questions') ?? [];
      ids.add(docRef.id);
      await prefs.setStringList('my_questions', ids);
      await _load();
      // Restart the answer listener so a notification fires when THIS
      // question gets answered.
      NotificationService().startQuestionListeners();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم إرسال سؤالك ✅ سيظهر الجواب في "أسئلتي"'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل إرسال السؤال: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  // Compresses and encodes to base64. Returns empty string if over 700 KB
  // (Firestore document limit is 1 MB; other fields take some space too).
  Future<String> _encodeImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final encoded = base64Encode(bytes);
      if (encoded.length > 700000) return ''; // too large
      return encoded;
    } catch (e) {
      debugPrint('Image encode error: $e');
      return '';
    }
  }
}

// ─── Pending Badge Tab ────────────────────────────────────────────────────────

class _PendingBadgeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (ctx, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('بانتظار الرد'),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('$count',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── My Questions Tab ─────────────────────────────────────────────────────────

class _MyQuestionsTab extends StatelessWidget {
  final Set<String> myIds;
  const _MyQuestionsTab({required this.myIds});

  @override
  Widget build(BuildContext context) {
    if (myIds.isEmpty) {
      return const _EmptyState(
        icon: Icons.help_outline_rounded,
        text: 'لم ترسل أي سؤال بعد.\nاضغط "اطرح سؤالاً" للبدء.',
      );
    }
    final ids = myIds.toList().reversed.take(30).toList();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .where(FieldPath.documentId, whereIn: ids)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.help_outline_rounded,
            text: 'لم ترسل أي سؤال بعد.',
          );
        }
        docs.sort((a, b) {
          final ta = (a.data() as Map)['askedAt'] as Timestamp?;
          final tb = (b.data() as Map)['askedAt'] as Timestamp?;
          return (tb?.compareTo(ta ?? Timestamp(0, 0))) ?? 0;
        });
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: docs.length,
          itemBuilder: (ctx, i) => _QACard(
            data: docs[i].data() as Map<String, dynamic>,
            docId: docs[i].id,
            showAdminActions: false,
          ),
        );
      },
    );
  }
}

// ─── Public Q&A Tab ───────────────────────────────────────────────────────────

class _PublicQATab extends StatelessWidget {
  const _PublicQATab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .where('status', isEqualTo: 'answered')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.forum_outlined,
            text: 'لا توجد أسئلة مُجابة بعد.',
          );
        }
        docs.sort((a, b) {
          final ta = (a.data() as Map)['answeredAt'] as Timestamp?;
          final tb = (b.data() as Map)['answeredAt'] as Timestamp?;
          return (tb?.compareTo(ta ?? Timestamp(0, 0))) ?? 0;
        });
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: docs.length,
          itemBuilder: (ctx, i) => _QACard(
            data: docs[i].data() as Map<String, dynamic>,
            docId: docs[i].id,
            showAdminActions: false,
          ),
        );
      },
    );
  }
}

// ─── Pending Tab ──────────────────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.inbox_outlined,
            text: 'لا توجد أسئلة بانتظار الرد.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: docs.length,
          itemBuilder: (ctx, i) => _QACard(
            data: docs[i].data() as Map<String, dynamic>,
            docId: docs[i].id,
            showAdminActions: true,
          ),
        );
      },
    );
  }
}

// ─── Q&A Card ─────────────────────────────────────────────────────────────────

class _QACard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool showAdminActions;
  const _QACard(
      {required this.data,
      required this.docId,
      required this.showAdminActions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final question = data['question'] as String? ?? '';
    final answer = data['answer'] as String? ?? '';
    final name = data['name'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final answered = status == 'answered' && answer.isNotEmpty;
    final imageBase64 = data['imageBase64'] as String? ?? '';
    final answerImageBase64 = data['answerImageBase64'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final answerImageUrl = data['answerImageUrl'] as String? ?? '';
    final ts = data['askedAt'] as Timestamp?;
    final dateStr =
        ts != null ? DateFormat('d MMMM yyyy', 'ar').format(ts.toDate()) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.help_outline_rounded, color: _navy, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(question,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _navy,
                          height: 1.5)),
                ),
              ],
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 28),
                child: Text('— $name',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.5))),
              ),
            ],
            if (imageUrl.isNotEmpty || imageBase64.isNotEmpty) ...[
              const SizedBox(height: 10),
              _QAImage(url: imageUrl, base64: imageBase64),
            ],
            const SizedBox(height: 10),
            if (answered) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B7A4B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF1B7A4B).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.verified_rounded,
                          color: Color(0xFF1B7A4B), size: 18),
                      SizedBox(width: 6),
                      Text('الجواب',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B7A4B))),
                    ]),
                    const SizedBox(height: 6),
                    Text(answer,
                        style: const TextStyle(fontSize: 14, height: 1.6)),
                    if (answerImageUrl.isNotEmpty ||
                        answerImageBase64.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _QAImage(
                          url: answerImageUrl, base64: answerImageBase64),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 14, color: _gold),
                    const SizedBox(width: 5),
                    const Text('بانتظار الرد',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9A7B23))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (dateStr.isNotEmpty)
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.45))),
                const Spacer(),
                if (showAdminActions) ...[
                  TextButton.icon(
                    onPressed: () => _openAnswerDialog(context, answered),
                    icon: Icon(answered ? Icons.edit : Icons.reply,
                        size: 18, color: _navy),
                    label: Text(answered ? 'تعديل' : 'رد',
                        style: const TextStyle(color: _navy)),
                  ),
                  IconButton(
                    onPressed: () => _delete(context),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAnswerDialog(BuildContext context, bool editing) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AnswerDialog(
          existing: editing ? (data['answer'] as String? ?? '') : ''),
    );
    if (result == null) return;

    final answerText = (result['answer'] as String? ?? '').trim();
    if (answerText.isEmpty) return;

    try {
      String answerImageUrl = data['answerImageUrl'] as String? ?? '';
      String answerImageBase64 = data['answerImageBase64'] as String? ?? '';
      final imageFile = result['image'] as XFile?;
      if (imageFile != null) {
        try {
          final bytes = await imageFile.readAsBytes();
          final url = await Backend.uploadImage(bytes);
          if (url != null) {
            answerImageUrl = url;
          } else {
            final encoded = base64Encode(bytes);
            if (encoded.length <= 700000) answerImageBase64 = encoded;
          }
        } catch (_) {}
      }

      await FirebaseFirestore.instance
          .collection('questions')
          .doc(docId)
          .update({
        'answer': answerText,
        'answerImageUrl': answerImageUrl,
        'answerImageBase64': answerImageBase64,
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      });

      // Push "answered" to the client who asked (works when app is closed).
      final clientToken = data['clientFcmToken'] as String? ?? '';
      final preview = answerText.length > 80
          ? '${answerText.substring(0, 80)}...'
          : answerText;
      await Backend.notifyAnswer(clientToken, preview);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل نشر الجواب: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السؤال'),
        content: const Text('هل تريد حذف هذا السؤال نهائياً؟'),
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
        .collection('questions')
        .doc(docId)
        .delete();
  }
}

// ─── Answer Dialog ────────────────────────────────────────────────────────────

class _AnswerDialog extends StatefulWidget {
  final String existing;
  const _AnswerDialog({required this.existing});

  @override
  State<_AnswerDialog> createState() => _AnswerDialogState();
}

class _AnswerDialogState extends State<_AnswerDialog> {
  late final TextEditingController _ctrl;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existing);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 60, maxWidth: 800);
    if (file != null) setState(() => _image = file);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing.isEmpty ? 'كتابة الجواب' : 'تعديل الجواب'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              maxLines: 6,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'اكتب الجواب هنا...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_image!.path),
                    height: 140, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                  _image == null ? 'إضافة صورة (اختياري)' : 'تغيير الصورة'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        ElevatedButton(
            onPressed: () {
              final t = _ctrl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(context, {'answer': t, 'image': _image});
            },
            child: const Text('نشر الجواب')),
      ],
    );
  }
}

// ─── Ask Sheet ────────────────────────────────────────────────────────────────

class _AskSheet extends StatefulWidget {
  const _AskSheet();

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  final _question = TextEditingController();
  final _name = TextEditingController();
  XFile? _image;
  String? _nameError;
  String? _questionError;

  @override
  void dispose() {
    _question.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 60, maxWidth: 800);
    if (file != null) setState(() => _image = file);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('اطرح سؤالك',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'الاسم *',
                hintText: 'اكتب اسمك',
                prefixIcon: const Icon(Icons.person_outline),
                errorText: _nameError,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _question,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'سؤالك *',
                hintText: 'اكتب سؤالك هنا...',
                errorText: _questionError,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                alignLabelWithHint: true,
              ),
              onChanged: (_) {
                if (_questionError != null) {
                  setState(() => _questionError = null);
                }
              },
            ),
            const SizedBox(height: 10),
            if (_image != null) ...[
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(_image!.path),
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _image = null),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                  _image == null ? 'إضافة صورة (اختياري)' : 'تغيير الصورة'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final q = _question.text.trim();
                final n = _name.text.trim();
                setState(() {
                  _nameError = n.isEmpty ? 'يرجى كتابة الاسم' : null;
                  _questionError = q.isEmpty ? 'يرجى كتابة السؤال' : null;
                });
                if (q.isEmpty || n.isEmpty) return;
                Navigator.pop(context,
                    {'question': q, 'name': n, 'image': _image});
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('إرسال السؤال'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Q&A Image Display ────────────────────────────────────────────────────────
// Shows a hosted image (Hostinger URL) when available, otherwise decodes a
// base64 image stored in Firestore.

class _QAImage extends StatelessWidget {
  final String url;
  final String base64;
  const _QAImage({required this.url, required this.base64});

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 180,
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }
    try {
      final bytes = base64Decode(base64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(bytes,
            width: double.infinity, height: 180, fit: BoxFit.cover),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: cs.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: cs.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}
