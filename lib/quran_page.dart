import 'dart:convert';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class Surah {
  final int id;
  final String name;
  final String nameEn;
  final String type;
  final int versesCount;

  const Surah({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.type,
    required this.versesCount,
  });

  factory Surah.fromJson(Map<String, dynamic> j) {
    return Surah(
      id: j['id'] as int? ?? 0,
      name: j['name'] as String? ?? '',
      nameEn: (j['transliteration'] ?? j['name_en'] ?? '') as String,
      type: j['type'] as String? ?? '',
      versesCount:
          j['total_verses'] as int? ?? j['verses_count'] as int? ?? 0,
    );
  }
}

class Verse {
  final int id;
  final String text;
  const Verse({required this.id, required this.text});
}

// Global raw data — parsed once, verses extracted on demand
List<dynamic>? _rawQuranData;
final Map<int, List<Verse>> _versesCache = {};

Future<void> _ensureLoaded() async {
  if (_rawQuranData != null) return;
  final raw = await rootBundle.loadString('assets/quran.json');
  _rawQuranData = json.decode(raw) as List<dynamic>;
}

Future<List<Verse>> loadVerses(int surahId) async {
  if (_versesCache.containsKey(surahId)) return _versesCache[surahId]!;
  await _ensureLoaded();
  final surahData = _rawQuranData!.firstWhere(
    (s) => (s as Map<String, dynamic>)['id'] == surahId,
    orElse: () => <String, dynamic>{},
  ) as Map<String, dynamic>;
  final verses = (surahData['verses'] as List<dynamic>? ?? [])
      .map((v) {
        final m = v as Map<String, dynamic>;
        return Verse(
          id: m['id'] as int? ?? m['verse_number'] as int? ?? 0,
          text: m['text'] as String? ?? '',
        );
      })
      .toList();
  _versesCache[surahId] = verses;
  // Keep cache small — evict oldest beyond 5 surahs
  if (_versesCache.length > 5) {
    final oldest = _versesCache.keys.first;
    _versesCache.remove(oldest);
  }
  return verses;
}

// ─── Surah List Page ─────────────────────────────────────────────────────────

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  List<Surah> _surahs = [];
  List<Surah> _filtered = [];
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
      await _ensureLoaded();
      final surahs = _rawQuranData!
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _surahs = surahs;
          _filtered = surahs;
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
          ? _surahs
          : _surahs
              .where((s) =>
                  s.name.contains(q) ||
                  s.nameEn.toLowerCase().contains(q.toLowerCase()) ||
                  s.id.toString() == q)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final s = _filtered[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primary.withOpacity(0.1),
                              child: Text(
                                '${s.id}',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              s.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${s.nameEn}  •  ${s.versesCount} آية  •  ${s.type == 'meccan' ? 'مكية' : 'مدنية'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SurahReaderPage(
                                    surahs: _surahs,
                                    initialIndex: _surahs.indexOf(s),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Surah Reader Page ────────────────────────────────────────────────────────

class SurahReaderPage extends StatefulWidget {
  final List<Surah> surahs;
  final int initialIndex;

  const SurahReaderPage({
    super.key,
    required this.surahs,
    required this.initialIndex,
  });

  @override
  State<SurahReaderPage> createState() => _SurahReaderPageState();
}

class _SurahReaderPageState extends State<SurahReaderPage> {
  late int _currentIndex;
  late PageController _pageController;
  double _fontSize = 24;

  // Audio
  final AudioPlayer _player = AudioPlayer();
  PlayerState? _playerState;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _audioLoading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _setupAudio();
  }

  Future<void> _setupAudio() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _player.playerStateStream.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Surah get _current => widget.surahs[_currentIndex];

  String get _audioUrl {
    final num = _current.id.toString().padLeft(3, '0');
    return 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/$num.mp3';
  }

  Future<void> _playPause() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }
    if (_playerState?.processingState == ProcessingState.idle ||
        _playerState == null) {
      setState(() => _audioLoading = true);
      try {
        await _player.setUrl(_audioUrl);
        setState(() => _audioLoading = false);
      } catch (e) {
        setState(() => _audioLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تحميل الصوت')),
          );
        }
        return;
      }
    }
    await _player.play();
  }

  Future<void> _stopAudio() async => _player.stop();

  void _goTo(int index) {
    if (index < 0 || index >= widget.surahs.length) return;
    _stopAudio();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPlaying = _player.playing;
    final isDone =
        _playerState?.processingState == ProcessingState.completed;

    return Scaffold(
      appBar: AppBar(
        title: Text(_current.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () =>
                setState(() => _fontSize = (_fontSize - 2).clamp(16, 36)),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () =>
                setState(() => _fontSize = (_fontSize + 2).clamp(16, 36)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Audio bar
          Container(
            color: cs.primary.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentIndex > 0
                          ? () => _goTo(_currentIndex - 1)
                          : null,
                      icon: const Icon(Icons.skip_next),
                    ),
                    _audioLoading
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            iconSize: 36,
                            onPressed: isDone
                                ? () async {
                                    await _player.seek(Duration.zero);
                                    await _player.play();
                                  }
                                : _playPause,
                            icon: Icon(
                              isDone
                                  ? Icons.replay
                                  : isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                              color: cs.primary,
                            ),
                          ),
                    IconButton(
                        onPressed: _stopAudio,
                        icon: const Icon(Icons.stop)),
                    IconButton(
                      onPressed: _currentIndex < widget.surahs.length - 1
                          ? () => _goTo(_currentIndex + 1)
                          : null,
                      icon: const Icon(Icons.skip_previous),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مشاري العفاسي',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text('${_fmt(_position)} / ${_fmt(_duration)}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_duration.inSeconds > 0)
                  Slider(
                    value: _position.inSeconds
                        .clamp(0, _duration.inSeconds)
                        .toDouble(),
                    max: _duration.inSeconds.toDouble(),
                    onChanged: (v) =>
                        _player.seek(Duration(seconds: v.toInt())),
                    activeColor: cs.primary,
                  ),
              ],
            ),
          ),

          // Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _currentIndex < widget.surahs.length - 1
                    ? () => _goTo(_currentIndex + 1)
                    : null,
                icon: const Icon(Icons.arrow_back_ios, size: 14),
                label: Text(
                  _currentIndex < widget.surahs.length - 1
                      ? widget.surahs[_currentIndex + 1].name
                      : '',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Text(
                '${_currentIndex + 1} / ${widget.surahs.length}',
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5), fontSize: 13),
              ),
              TextButton.icon(
                onPressed: _currentIndex > 0
                    ? () => _goTo(_currentIndex - 1)
                    : null,
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: Text(
                  _currentIndex > 0
                      ? widget.surahs[_currentIndex - 1].name
                      : '',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),

          const Divider(height: 1),

          // Swipeable surah pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.surahs.length,
              onPageChanged: (i) {
                _stopAudio();
                setState(() => _currentIndex = i);
              },
              itemBuilder: (_, i) => _SurahContent(
                surah: widget.surahs[i],
                fontSize: _fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Surah Content — lazy-loads verses, virtualized list ─────────────────────

class _SurahContent extends StatefulWidget {
  final Surah surah;
  final double fontSize;
  const _SurahContent({required this.surah, required this.fontSize});

  @override
  State<_SurahContent> createState() => _SurahContentState();
}

class _SurahContentState extends State<_SurahContent> {
  List<Verse>? _verses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SurahContent old) {
    super.didUpdateWidget(old);
    if (old.surah.id != widget.surah.id) _load();
  }

  Future<void> _load() async {
    final verses = await loadVerses(widget.surah.id);
    if (mounted) setState(() => _verses = verses);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_verses == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // All verses joined as one continuous flowing text — true Mushaf style
    final allText = _verses!.map((v) => '${v.text} ﴿${v.id}﴾').join('  ');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basmalah / surah header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border:
                        Border.all(color: cs.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.surah.id != 9
                        ? 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'
                        : widget.surah.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      fontSize: widget.fontSize,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.surah.nameEn}  —  ${widget.surah.versesCount} آية',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          // One continuous flowing text block
          Text(
            allText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontFamily: 'ScheherazadeNew',
              fontSize: widget.fontSize,
              height: 2.2,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
