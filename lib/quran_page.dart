import 'dart:convert';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'islamic_background.dart';

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

// ─── Audio Download Manager ───────────────────────────────────────────────────

/// Singleton that manages local caching of surah audio files.
/// - cached     → plays from device storage (offline)
/// - not cached → streams from Firebase Storage
class QuranAudioCache extends ChangeNotifier {
  QuranAudioCache._();
  static final QuranAudioCache instance = QuranAudioCache._();

  Directory? _dir;

  // download progress per surah id: null = not downloading, 0..1 = in progress
  final Map<int, double> _progress = {};

  // surah ids that are fully downloaded
  final Set<int> _cached = {};

  // active download futures to prevent double-downloads
  final Map<int, Future<void>> _active = {};

  Future<void> init() async {
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory('${base.path}/quran_audio');
    await _dir!.create(recursive: true);
    // scan what is already on disk
    await _dir!.list().forEach((e) {
      if (e is File && e.path.endsWith('.mp3')) {
        final name = e.uri.pathSegments.last;
        final id = int.tryParse(name.replaceAll('.mp3', ''));
        if (id != null) _cached.add(id);
      }
    });
    notifyListeners();
  }

  bool isCached(int id) => _cached.contains(id);
  double? progress(int id) => _progress[id];
  bool isDownloading(int id) => _progress.containsKey(id);

  File _file(int id) => File('${_dir!.path}/$id.mp3');

  /// Returns a local file path if cached, otherwise null.
  String? localPath(int id) => isCached(id) ? _file(id).path : null;

  Future<void> download(int id) async {
    if (isCached(id) || isDownloading(id)) return;
    _active[id] = _doDownload(id);
    await _active[id];
    _active.remove(id);
  }

  Future<void> _doDownload(int id) async {
    try {
      _progress[id] = 0;
      notifyListeners();

      // 1. Resolve Firebase Storage URL
      final ref = FirebaseStorage.instance.ref('quran_audio/$id.mp3');
      final url = await ref.getDownloadURL();

      // 2. Stream-download with progress
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();
      final total = response.contentLength ?? 0;
      int received = 0;

      final file = _file(id);
      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          _progress[id] = received / total;
          notifyListeners();
        }
      }
      await sink.flush();
      await sink.close();

      _cached.add(id);
      _progress.remove(id);
      notifyListeners();
    } catch (_) {
      _progress.remove(id);
      final f = _file(id);
      if (await f.exists()) await f.delete();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    final f = _file(id);
    if (await f.exists()) await f.delete();
    _cached.remove(id);
    notifyListeners();
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
  final _cache = QuranAudioCache.instance;

  @override
  void initState() {
    super.initState();
    _init();
    _search.addListener(_filter);
    _cache.addListener(_onCacheChange);
  }

  @override
  void dispose() {
    _search.dispose();
    _cache.removeListener(_onCacheChange);
    super.dispose();
  }

  void _onCacheChange() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    await _cache.init();
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
    } catch (_) {
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
    return IslamicPatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                            return _SurahTile(
                              surah: s,
                              cache: _cache,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SurahReaderPage(
                                    surahs: _surahs,
                                    initialIndex: _surahs.indexOf(s),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Surah Tile with download button ─────────────────────────────────────────

class _SurahTile extends StatelessWidget {
  final Surah surah;
  final QuranAudioCache cache;
  final VoidCallback onTap;
  const _SurahTile(
      {required this.surah, required this.cache, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cached = cache.isCached(surah.id);
    final downloading = cache.isDownloading(surah.id);
    final prog = cache.progress(surah.id) ?? 0.0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primary.withOpacity(0.1),
        child: Text(
          '${surah.id}',
          style: TextStyle(
              color: cs.primary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        surah.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${surah.nameEn}  •  ${surah.versesCount} آية  •  ${surah.type == 'meccan' ? 'مكية' : 'مدنية'}',
            style: const TextStyle(fontSize: 12),
          ),
          if (downloading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(
                value: prog,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
                color: cs.primary,
                backgroundColor: cs.primary.withOpacity(0.15),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Download / cached / progress button
          if (downloading)
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                      value: prog, strokeWidth: 2.5, color: cs.primary),
                  Icon(Icons.download, size: 14, color: cs.primary),
                ],
              ),
            )
          else if (cached)
            IconButton(
              tooltip: 'محفوظ — اضغط لحذف',
              icon: const Icon(Icons.download_done_rounded),
              color: Colors.green,
              onPressed: () => _confirmDelete(context),
            )
          else
            IconButton(
              tooltip: 'تحميل للاستماع بلا إنترنت',
              icon: Icon(Icons.download_outlined, color: cs.primary),
              onPressed: () => _startDownload(context),
            ),
          const Icon(Icons.chevron_left),
        ],
      ),
      onTap: onTap,
    );
  }

  void _startDownload(BuildContext context) async {
    try {
      await cache.download(surah.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل ${surah.name}')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('حذف ${surah.name}'),
        content: const Text('هل تريد حذف الملف المحفوظ؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cache.delete(surah.id);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
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

  // Ayah-by-ayah highlight sync
  List<Verse>? _verses; // verses of the current surah
  List<double>? _timings; // exact per-ayah start times (sec) if available
  int? _activeAyah; // id of the ayah currently being recited (highlighted)
  static final Map<int, List<double>?> _timingsCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _setupAudio();
    _loadSurahMeta();
  }

  Future<void> _setupAudio() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
      // When the surah finishes, remove the highlight.
      if (s.processingState == ProcessingState.completed) {
        _setActiveAyah(null);
      }
    });
    _player.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
      _updateActiveAyah(p);
    });
    _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });
  }

  // Load the current surah's verses + (optional) exact ayah timings.
  Future<void> _loadSurahMeta() async {
    final id = _current.id;
    final verses = await loadVerses(id);
    final timings = await _loadTimings(id);
    if (!mounted || id != _current.id) return;
    setState(() {
      _verses = verses;
      _timings = (timings != null && timings.length == verses.length)
          ? timings
          : null;
      _activeAyah = null;
    });
  }

  // Per-ayah start times (seconds) stored in  quran_audio/<surah>.json
  // as a JSON array, e.g. [0, 4.8, 11.2, ...]. Returns null if absent.
  Future<List<double>?> _loadTimings(int id) async {
    if (_timingsCache.containsKey(id)) return _timingsCache[id];
    try {
      final ref = FirebaseStorage.instance.ref('quran_audio/$id.json');
      final bytes = await ref.getData(2 * 1024 * 1024);
      if (bytes == null) {
        _timingsCache[id] = null;
        return null;
      }
      final decoded = json.decode(utf8.decode(bytes));
      List<double>? starts;
      if (decoded is List) {
        starts = decoded.map((e) => (e as num).toDouble()).toList();
      } else if (decoded is Map && decoded['ayahs'] is List) {
        starts = (decoded['ayahs'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }
      _timingsCache[id] = starts;
      return starts;
    } catch (_) {
      _timingsCache[id] = null;
      return null;
    }
  }

  // Start time (seconds) for every ayah: exact timings if uploaded,
  // otherwise estimated from each ayah's share of the total duration
  // (weighted by letter count) so highlighting still works.
  List<double>? _ayahStarts() {
    final verses = _verses;
    if (verses == null || verses.isEmpty) return null;
    final timings = _timings;
    if (timings != null && timings.length == verses.length) return timings;
    final durMs = _duration.inMilliseconds;
    if (durMs <= 0) return null;
    final weights =
        verses.map((v) => v.text.replaceAll(' ', '').length).toList();
    final total = weights.fold<int>(0, (a, b) => a + b);
    if (total == 0) return null;
    final dur = durMs / 1000.0;
    final starts = <double>[];
    int acc = 0;
    for (final w in weights) {
      starts.add(acc / total * dur);
      acc += w;
    }
    return starts;
  }

  void _updateActiveAyah(Duration pos) {
    final verses = _verses;
    final starts = _ayahStarts();
    if (verses == null || starts == null) return;
    final t = pos.inMilliseconds / 1000.0;
    int idx = 0;
    for (int i = 0; i < starts.length; i++) {
      if (t + 0.001 >= starts[i]) {
        idx = i;
      } else {
        break;
      }
    }
    _setActiveAyah(verses[idx].id);
  }

  void _setActiveAyah(int? id) {
    if (_activeAyah == id) return;
    if (mounted) setState(() => _activeAyah = id);
  }

  @override
  void dispose() {
    _player.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Surah get _current => widget.surahs[_currentIndex];

  // In-memory cache of resolved Firebase Storage download URLs per surah id.
  static final Map<int, String> _urlCache = {};

  // Returns a local file:// URI if the surah is cached on device,
  // otherwise resolves the Firebase Storage download URL.
  Future<String> _resolveAudioUrl() async {
    final id = _current.id;
    final localPath = QuranAudioCache.instance.localPath(id);
    if (localPath != null) return localPath;
    final cached = _urlCache[id];
    if (cached != null) return cached;
    final ref = FirebaseStorage.instance.ref('quran_audio/$id.mp3');
    final url = await ref.getDownloadURL();
    _urlCache[id] = url;
    return url;
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
        final url = await _resolveAudioUrl();
        await _player.setUrl(url);
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
    _setActiveAyah(null);
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.surahs.length) return;
    _stopAudio();
    setState(() => _currentIndex = index);
    _loadSurahMeta();
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
                            'الشيخ أحمد الدباغ',
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

          // Navigation — next (←) on LEFT, previous (→) on RIGHT (Arabic book convention)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // RIGHT side in RTL → previous surah (Fatiha side)
              TextButton.icon(
                onPressed: _currentIndex > 0
                    ? () => _goTo(_currentIndex - 1)
                    : null,
                icon: const Icon(Icons.arrow_back_ios, size: 14),
                label: Text(
                  _currentIndex > 0
                      ? widget.surahs[_currentIndex - 1].name
                      : '',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Text(
                '${_currentIndex + 1} / ${widget.surahs.length}',
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5), fontSize: 13),
              ),
              // LEFT side in RTL → next surah (Al-Imran side)
              TextButton.icon(
                onPressed: _currentIndex < widget.surahs.length - 1
                    ? () => _goTo(_currentIndex + 1)
                    : null,
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: Text(
                  _currentIndex < widget.surahs.length - 1
                      ? widget.surahs[_currentIndex + 1].name
                      : '',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),

          const Divider(height: 1),

          // PageView: reverse:true = next surah (higher index) is to the LEFT
          // Swipe RIGHT → next surah enters from LEFT (like Arabic book)
          // Swipe LEFT  → previous surah enters from RIGHT
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: PageView.builder(
                controller: _pageController,
                reverse: true,
                itemCount: widget.surahs.length,
                onPageChanged: (i) {
                  _stopAudio();
                  setState(() => _currentIndex = i);
                  _loadSurahMeta();
                },
                itemBuilder: (_, i) => _SurahContent(
                  surah: widget.surahs[i],
                  fontSize: _fontSize,
                  activeAyah: i == _currentIndex ? _activeAyah : null,
                ),
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

  /// Id of the ayah currently being recited — highlighted and scrolled to.
  final int? activeAyah;

  const _SurahContent({
    required this.surah,
    required this.fontSize,
    this.activeAyah,
  });

  @override
  State<_SurahContent> createState() => _SurahContentState();
}

class _SurahContentState extends State<_SurahContent> {
  List<Verse>? _verses;
  final Map<int, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SurahContent old) {
    super.didUpdateWidget(old);
    if (old.surah.id != widget.surah.id) {
      _keys.clear();
      _load();
    }
    // Auto-scroll to keep the reciting ayah comfortably in view.
    if (widget.activeAyah != null && widget.activeAyah != old.activeAyah) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[widget.activeAyah]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.35,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _load() async {
    final verses = await loadVerses(widget.surah.id);
    if (mounted) setState(() => _verses = verses);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    if (_verses == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // One highlightable block per ayah
          for (final v in _verses!)
            _AyahBlock(
              key: _keys.putIfAbsent(v.id, () => GlobalKey()),
              verse: v,
              fontSize: widget.fontSize,
              active: widget.activeAyah == v.id,
              isDark: isDark,
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// A single ayah; turns gold/tinted while it is being recited.
class _AyahBlock extends StatelessWidget {
  final Verse verse;
  final double fontSize;
  final bool active;
  final bool isDark;
  const _AyahBlock({
    super.key,
    required this.verse,
    required this.fontSize,
    required this.active,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? cs.primary.withOpacity(isDark ? 0.30 : 0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: cs.primary.withOpacity(0.45))
            : null,
      ),
      child: Text(
        '${verse.text} ﴿${verse.id}﴾',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: fontSize,
          height: 2.1,
          color: active ? cs.primary : cs.onSurface,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
