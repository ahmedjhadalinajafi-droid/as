import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _navy = Color(0xFF1B3D6F);
const _gold = Color(0xFFC9A843);

// Opens the Mafatih reader at the first chapter whose title contains [titleContains].
// Used by the home page day-of-week worship shortcuts.
Future<void> openMafatihChapter(
    BuildContext context, String titleContains) async {
  try {
    final raw = await rootBundle.loadString('assets/mafatih.json');
    final list = (json.decode(raw) as List<dynamic>)
        .map((e) => _Chapter.fromJson(e as Map<String, dynamic>))
        .where((c) => c.title.isNotEmpty && c.content.isNotEmpty)
        .toList();
    final idx = list.indexWhere((c) => c.title.contains(titleContains));
    if (idx < 0 || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: _ReaderPage(chapters: list, initialIndex: idx),
        ),
      ),
    );
  } catch (_) {}
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _Chapter {
  final int id;
  final String title;
  final String subtitle;
  final String content;

  const _Chapter({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  factory _Chapter.fromJson(Map<String, dynamic> j) => _Chapter(
        id: j['id'] as int? ?? 0,
        title: (j['title'] as String? ?? '').trim(),
        subtitle: (j['subtitle'] as String? ?? '').trim(),
        content: (j['content'] as String? ?? '').trim(),
      );

  String get category {
    if (title.startsWith('سورة') || title.contains('القرآن')) return 'قرآن';
    if (title.contains('زيارة') || title.contains('زيار')) return 'زيارات';
    if (title.contains('دعاء') || title.contains('الدعاء')) return 'أدعية';
    if (title.contains('صلاة') || title.contains('الصلاة')) return 'صلوات';
    return 'أخرى';
  }
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class MafatihPage extends StatefulWidget {
  const MafatihPage({super.key});

  @override
  State<MafatihPage> createState() => _MafatihPageState();
}

class _MafatihPageState extends State<MafatihPage>
    with SingleTickerProviderStateMixin {
  List<_Chapter> _all = [];
  List<_Chapter> _filtered = [];
  String _selectedCat = 'الكل';
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();

  static const _cats = ['الكل', 'أدعية', 'زيارات', 'صلوات', 'قرآن', 'أخرى'];

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await rootBundle.loadString('assets/mafatih.json');
      final list = json.decode(raw) as List<dynamic>;
      final chapters = list
          .map((e) => _Chapter.fromJson(e as Map<String, dynamic>))
          .where((c) => c.title.isNotEmpty && c.content.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _all = chapters;
          _filtered = chapters;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _filter() {
    final q = _search.text.trim();
    setState(() {
      var list = _selectedCat == 'الكل'
          ? _all
          : _all.where((c) => c.category == _selectedCat).toList();
      if (q.isNotEmpty) {
        list = list
            .where((c) => c.title.contains(q) || c.content.contains(q))
            .toList();
      }
      _filtered = list;
    });
  }

  void _selectCat(String cat) {
    setState(() => _selectedCat = cat);
    _filter();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF5F5F0),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_navy, Color(0xFF2A5298)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20, right: -20,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30, left: -30,
                    child: Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gold.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _gold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _gold.withOpacity(0.4)),
                              ),
                              child: const Icon(Icons.auto_stories,
                                  color: _gold, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مفاتيح الجنان',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'ScheherazadeNew',
                                  ),
                                ),
                                Text(
                                  'الشيخ عباس القمّي',
                                  style: TextStyle(
                                    color: _gold,
                                    fontSize: 13,
                                    fontFamily: 'ScheherazadeNew',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _search,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'ScheherazadeNew'),
                decoration: InputDecoration(
                  hintText: 'ابحث في مفاتيح الجنان...',
                  hintStyle: const TextStyle(fontFamily: 'ScheherazadeNew'),
                  prefixIcon: const Icon(Icons.search, color: _navy),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E2D4A)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: _navy.withOpacity(0.15), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _gold, width: 1.5),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),

          // ── Category chips ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _cats[i];
                  final selected = _selectedCat == cat;
                  return GestureDetector(
                    onTap: () => _selectCat(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? _navy
                            : (isDark
                                ? const Color(0xFF1E2D4A)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected
                              ? _gold
                              : (isDark
                                  ? Colors.white12
                                  : _navy.withOpacity(0.15)),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'ScheherazadeNew',
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white60
                                  : _navy),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Stats bar ────────────────────────────────────────────────
          if (!_loading && _error == null)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  '${_filtered.length} عنصر',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.45),
                    fontFamily: 'ScheherazadeNew',
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),

          // ── Body ─────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _gold),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل مفاتيح الجنان...',
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        color: _navy,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'تعذّر تحميل المحتوى',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ScheherazadeNew',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        size: 64, color: cs.onSurface.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد نتائج',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'ScheherazadeNew',
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _ChapterCard(
                    chapter: _filtered[i],
                    index: i,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => _ReaderPage(
                          chapters: _filtered,
                          initialIndex: i,
                        ),
                      ),
                    ),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Chapter Card ─────────────────────────────────────────────────────────────

class _ChapterCard extends StatelessWidget {
  final _Chapter chapter;
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  const _ChapterCard({
    required this.chapter,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  Color get _catColor {
    switch (chapter.category) {
      case 'أدعية':   return const Color(0xFF2196F3);
      case 'زيارات':  return const Color(0xFF9C27B0);
      case 'صلوات':   return const Color(0xFF4CAF50);
      case 'قرآن':    return const Color(0xFFC9A843);
      default:        return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E2D4A) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: _navy.withOpacity(0.08),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: _catColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title + category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: TextStyle(
                          fontFamily: 'ScheherazadeNew',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          chapter.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: _catColor,
                            fontFamily: 'ScheherazadeNew',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_left,
                  color: isDark ? Colors.white30 : _navy.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reader Page ──────────────────────────────────────────────────────────────

class _ReaderPage extends StatefulWidget {
  final List<_Chapter> chapters;
  final int initialIndex;
  const _ReaderPage({required this.chapters, required this.initialIndex});

  @override
  State<_ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<_ReaderPage> {
  late int _index;
  late PageController _ctrl;
  double _fontSize = 22;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _Chapter get _cur => widget.chapters[_index];

  void _go(int i) {
    if (i < 0 || i >= widget.chapters.length) return;
    setState(() => _index = i);
    _ctrl.animateToPage(i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A1628) : const Color(0xFFFAF8F0),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(
          _cur.title,
          style: const TextStyle(
            fontFamily: 'ScheherazadeNew',
            fontSize: 17,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease, size: 20),
            onPressed: () =>
                setState(() => _fontSize = (_fontSize - 2).clamp(14, 40)),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, size: 20),
            onPressed: () =>
                setState(() => _fontSize = (_fontSize + 2).clamp(14, 40)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Navigation bar (Arabic book convention, matches Quran) ──
          // RIGHT side → previous chapter, LEFT side → next chapter
          Container(
            color: isDark ? const Color(0xFF1E2D4A) : Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // RIGHT in RTL → previous chapter
                Flexible(
                  child: TextButton.icon(
                    onPressed: _index > 0 ? () => _go(_index - 1) : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 14, color: _gold),
                    label: Text(
                      _index > 0 ? widget.chapters[_index - 1].title : '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'ScheherazadeNew'),
                    ),
                  ),
                ),
                Text(
                  '${_index + 1} / ${widget.chapters.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                // LEFT in RTL → next chapter
                Flexible(
                  child: TextButton.icon(
                    onPressed: _index < widget.chapters.length - 1
                        ? () => _go(_index + 1)
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: _gold),
                    label: Text(
                      _index < widget.chapters.length - 1
                          ? widget.chapters[_index + 1].title
                          : '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'ScheherazadeNew'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Content ────────────────────────────────────────────────
          // LTR + reverse:true → swipe like an Arabic book (matches Quran)
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: PageView.builder(
                controller: _ctrl,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.chapters.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final ch = widget.chapters[i];
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Decorative top line
                        Center(
                          child: Container(
                            width: 60,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          ch.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'ScheherazadeNew',
                            fontSize: _fontSize + 6,
                            fontWeight: FontWeight.bold,
                            color: isDark ? _gold : _navy,
                          ),
                        ),

                        if (ch.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            ch.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'ScheherazadeNew',
                              fontSize: _fontSize - 2,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        Container(
                          height: 1,
                          color: _gold.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),

                        // Content
                        SelectableText(
                          ch.content,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontFamily: 'ScheherazadeNew',
                            fontSize: _fontSize,
                            height: 2.2,
                            color: isDark
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
