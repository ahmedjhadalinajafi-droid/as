import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  factory _Chapter.fromJson(Map<String, dynamic> j) {
    return _Chapter(
      id: j['id'] as int? ?? 0,
      title: j['title'] as String? ?? '',
      subtitle: j['subtitle'] as String? ?? '',
      content: j['content'] as String? ?? '',
    );
  }
}

class MafatihPage extends StatefulWidget {
  const MafatihPage({super.key});

  @override
  State<MafatihPage> createState() => _MafatihPageState();
}

class _MafatihPageState extends State<MafatihPage> {
  List<_Chapter> _chapters = [];
  List<_Chapter> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

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
    try {
      final raw = await rootBundle.loadString('assets/mafatih.json');
      final List<dynamic> data = json.decode(raw);
      final chapters = data
          .map((e) => _Chapter.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _filtered = chapters;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _search.text.trim();
    setState(() {
      _filtered = q.isEmpty
          ? _chapters
          : _chapters
              .where((c) =>
                  c.title.contains(q) || c.subtitle.contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('مفاتيح الجنان')),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث عن دعاء أو زيارة...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final ch = _filtered[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor:
                                  cs.primary.withOpacity(0.1),
                              child: Text(
                                '${ch.id}',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              ch.title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: ch.subtitle.isNotEmpty
                                ? Text(ch.subtitle,
                                    style:
                                        const TextStyle(fontSize: 13))
                                : null,
                            trailing:
                                const Icon(Icons.chevron_left),
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => _ChapterReaderPage(
                                  chapters: _filtered,
                                  initialIndex: i,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ChapterReaderPage extends StatefulWidget {
  final List<_Chapter> chapters;
  final int initialIndex;
  const _ChapterReaderPage(
      {required this.chapters, required this.initialIndex});

  @override
  State<_ChapterReaderPage> createState() =>
      _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<_ChapterReaderPage> {
  late int _index;
  late PageController _controller;
  double _fontSize = 20;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _Chapter get _current => widget.chapters[_index];

  void _go(int i) {
    if (i < 0 || i >= widget.chapters.length) return;
    setState(() => _index = i);
    _controller.animateToPage(i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_current.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () =>
                setState(() => _fontSize = (_fontSize - 2).clamp(14, 36)),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () =>
                setState(() => _fontSize = (_fontSize + 2).clamp(14, 36)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _index < widget.chapters.length - 1
                    ? () => _go(_index + 1)
                    : null,
                icon: const Icon(Icons.arrow_back_ios, size: 14),
                label: Text(
                  _index < widget.chapters.length - 1
                      ? widget.chapters[_index + 1].title
                      : '',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_index + 1} / ${widget.chapters.length}',
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5),
                    fontSize: 12),
              ),
              TextButton.icon(
                onPressed: _index > 0 ? () => _go(_index - 1) : null,
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: Text(
                  _index > 0 ? widget.chapters[_index - 1].title : '',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          // Swipeable content
          Expanded(
            child: PageView.builder(
              controller: _controller,
              reverse: true,
              itemCount: widget.chapters.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final ch = widget.chapters[i];
                // Build flowing paragraph text — split on blank lines into paragraphs
                final paragraphs = ch.content
                    .split(RegExp(r'\n\s*\n'))
                    .map((p) => p.trim())
                    .where((p) => p.isNotEmpty)
                    .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        ch.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ScheherazadeNew',
                          fontSize: _fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      if (ch.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ch.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _fontSize - 2,
                            color: cs.onSurface.withOpacity(0.55),
                            fontFamily: 'ScheherazadeNew',
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      // Flowing paragraphs — natural word-wrap like a book
                      ...paragraphs.map((para) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: SelectableText(
                              para.replaceAll('\n', ' '),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontFamily: 'ScheherazadeNew',
                                fontSize: _fontSize,
                                height: 2.1,
                              ),
                            ),
                          )),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
