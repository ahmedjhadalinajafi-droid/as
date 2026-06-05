import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'islamic_background.dart';

// ─── Admin PIN (change this to whatever you want) ─────────────────────────────
const _adminPin = '786786';
const _deviceAdminKey = 'ask_device_admin';

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
  int _titleTaps = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _myIds = (prefs.getStringList('my_questions') ?? []).toSet();
        _isAdmin = prefs.getBool(_deviceAdminKey) ?? false;
      });
    }
  }

  // Tap the title 5 times to trigger admin PIN dialog
  void _onTitleTap() {
    _titleTaps++;
    if (_titleTaps >= 5) {
      _titleTaps = 0;
      _showPinDialog();
    }
  }

  Future<void> _showPinDialog() async {
    final controller = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دخول المشرف'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'رمز الدخول',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('دخول')),
        ],
      ),
    );

    if (entered == null) return;

    if (entered == _adminPin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_deviceAdminKey, true);
      if (mounted) {
        setState(() => _isAdmin = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل صلاحيات المشرف على هذا الجهاز ✅'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رمز غير صحيح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeAdmin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء صلاحيات المشرف'),
        content: const Text('هل تريد إلغاء صلاحيات المشرف من هذا الجهاز؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceAdminKey, false);
    if (mounted) setState(() => _isAdmin = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _isAdmin ? 3 : 1,
      child: IslamicPatternBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: GestureDetector(
              onTap: _onTitleTap,
              child: const Text('الأسئلة والأجوبة'),
            ),
            actions: [
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: _gold),
                  tooltip: 'إلغاء صلاحيات المشرف',
                  onPressed: _removeAdmin,
                ),
            ],
            bottom: TabBar(
              isScrollable: false,
              indicatorColor: _gold,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                const Tab(text: 'أسئلتي'),
                if (_isAdmin) const Tab(text: 'الأسئلة والأجوبة'),
                if (_isAdmin) const Tab(text: 'بانتظار الرد'),
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
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AskSheet(),
    );
    if (result == null) return;

    final doc = await FirebaseFirestore.instance.collection('questions').add({
      'question': result['question'],
      'name': result['name'] ?? '',
      'answer': '',
      'status': 'pending',
      'askedAt': FieldValue.serverTimestamp(),
    });

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('my_questions') ?? [];
    ids.add(doc.id);
    await prefs.setStringList('my_questions', ids);
    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال سؤالك ✅ سيظهر الجواب في "أسئلتي"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

// ─── Pending Tab (admin only) ─────────────────────────────────────────────────

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
  const _QACard({
    required this.data,
    required this.docId,
    required this.showAdminActions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final question = data['question'] as String? ?? '';
    final answer = data['answer'] as String? ?? '';
    final name = data['name'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final answered = status == 'answered' && answer.isNotEmpty;
    final ts = data['askedAt'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('d MMMM yyyy', 'ar').format(ts.toDate())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.help_outline_rounded, color: _navy, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _navy,
                      height: 1.5,
                    ),
                  ),
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
            const SizedBox(height: 10),

            // Answer or pending badge
            if (answered)
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
                    Row(
                      children: const [
                        Icon(Icons.verified_rounded,
                            color: Color(0xFF1B7A4B), size: 18),
                        SizedBox(width: 6),
                        Text('الجواب',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B7A4B))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(answer,
                        style:
                            const TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                    onPressed: () => _answer(context, answered),
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

  Future<void> _answer(BuildContext context, bool editing) async {
    final controller =
        TextEditingController(text: data['answer'] as String? ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editing ? 'تعديل الجواب' : 'كتابة الجواب'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'اكتب الجواب هنا...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('نشر الجواب')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('questions')
        .doc(docId)
        .update({
      'answer': result,
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
    });
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

// ─── Ask Sheet ────────────────────────────────────────────────────────────────

class _AskSheet extends StatefulWidget {
  const _AskSheet();

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  final _question = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    _name.dispose();
    super.dispose();
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('اطرح سؤالك',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _question,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'سؤالك',
                hintText: 'اكتب سؤالك هنا...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'الاسم (اختياري)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                final q = _question.text.trim();
                if (q.isEmpty) return;
                Navigator.pop(context, {
                  'question': q,
                  'name': _name.text.trim(),
                });
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
                  fontSize: 15,
                  color: cs.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}
