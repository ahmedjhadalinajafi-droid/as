import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../data/quran_surahs.dart';
import 'surah_detail_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String _search = '';

  List<SurahInfo> get _filtered => surahList
      .where((s) =>
          s.englishName.toLowerCase().contains(_search.toLowerCase()) ||
          s.arabicName.contains(_search) ||
          s.number.toString() == _search)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quran')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search surah...',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final s = _filtered[i];
                return _SurahTile(surah: s, index: i)
                    .animate(delay: Duration(milliseconds: i < 10 ? i * 30 : 0))
                    .fadeIn(duration: 250.ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final SurahInfo surah;
  final int index;

  const _SurahTile({required this.surah, required this.index});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SurahDetailScreen(surah: surah)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          '${surah.number}',
          style: const TextStyle(
            color: AppTheme.gold,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(
        surah.englishName,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        surah.englishNameTranslation,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            surah.arabicName,
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 16,
              fontFamily: 'serif',
            ),
          ),
          Text(
            '${surah.numberOfAyahs} ayahs · ${surah.revelationType}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
