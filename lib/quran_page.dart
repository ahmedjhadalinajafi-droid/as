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
  final List<Verse> verses;

  const Surah({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.type,
    required this.versesCount,
    required this.verses,
  });

  factory Surah.fromJson(Map<String, dynamic> j) {
    return Surah(
      id: j['id'] as int? ?? 0,
      name: j['name'] as String? ?? '',
      nameEn: (j['transliteration'] ?? j['name_en'] ?? '') as String,
      type: j['type'] as String? ?? '',
      versesCount:
          j['total_verses'] as int? ?? j['verses_count'] as int? ?? 0,
      verses: (j['verses'] as List<dynamic>? ?? [])
          .map((v) => Verse.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Verse {
  final int id;
  final String text;

  const Verse({required this.id, required this.text});

  factory Verse.fromJson(Map<String, dynamic> j) {
    return Verse(
      id: j['id'] as int? ?? j['verse_number'] as int? ?? 0,
      text: j['text'] as String? ?? '',
    );
  }
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
      final raw = await rootBundle.loadString('assets/quran.json');
      final List<dynamic> data = json.decode(raw);
      final surahs = data
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
                              backgroundColor:
                                  cs.primary.withOpacity(0.1),
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
                                    initialIndex:
                                        _surahs.indexOf(s),
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

    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _playerState = state);
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

  // EveryAyah CDN for surah — full surah via Quran Audio CDN
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

  Future<void> _stopAudio() async {
    await _player.stop();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.surahs.length) return;
    _stopAudio();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
            icon: const Icon(Icons.format_size),
            onPressed: () {},
            tooltip: 'حجم الخط',
          ),
        ],
      ),
      body: Column(
        children: [
          // Audio Player Bar
          Container(
            color: cs.primary.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    // Prev Surah
                    IconButton(
                      onPressed: _currentIndex > 0
                          ? () => _goTo(_currentIndex - 1)
                          : null,
                      icon: const Icon(Icons.skip_next), // RTL: next = prev
                      tooltip: 'السورة السابقة',
                    ),
                    // Play/Pause/Stop
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
                    // Stop
                    IconButton(
                      onPressed: _stopAudio,
                      icon: const Icon(Icons.stop),
                    ),
                    // Next Surah
                    IconButton(
                      onPressed:
                          _currentIndex < widget.surahs.length - 1
                              ? () => _goTo(_currentIndex + 1)
                              : null,
                      icon: const Icon(Icons.skip_previous), // RTL
                      tooltip: 'السورة التالية',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المنشد: مشاري العفاسي',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '${_fmt(_position)} / ${_fmt(_duration)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Progress bar
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

          // Navigation arrows
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
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 13,
                ),
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

          // Verses — swipeable between surahs
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              reverse: true, // RTL: swipe right = next surah (lower number)
              itemCount: widget.surahs.length,
              onPageChanged: (i) {
                _stopAudio();
                setState(() => _currentIndex = i);
              },
              itemBuilder: (_, i) {
                final surah = widget.surahs[i];
                return _SurahContent(surah: surah);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahContent extends StatelessWidget {
  final Surah surah;
  const _SurahContent({required this.surah});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Build one flowing Mushaf-style text block with inline verse markers
    final flowingText = surah.verses
        .map((v) => '${v.text} ﴿${v.id}﴾')
        .join(' ');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bismillah / surah name header
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
                    border: Border.all(color: cs.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    surah.id != 9
                        ? 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'
                        : surah.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      fontSize: 22,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${surah.nameEn}  —  ${surah.versesCount} آية',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // All verses as one flowing justified block
          if (surah.verses.isNotEmpty)
            SelectableText(
              flowingText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'ScheherazadeNew',
                fontSize: 24,
                height: 2.2,
                color: cs.onSurface,
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'النص غير متوفر',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
                ),
              ),
            ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
