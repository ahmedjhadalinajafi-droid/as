import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../../theme/app_theme.dart';
import '../../data/quran_surahs.dart';

class SurahDetailScreen extends StatefulWidget {
  final SurahInfo surah;

  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  double _fontSize = 22;
  bool _showTranslation = true;

  @override
  Widget build(BuildContext context) {
    final ayahCount = widget.surah.numberOfAyahs;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.englishName),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            tooltip: 'Toggle translation',
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
            color: _showTranslation ? AppTheme.gold : Colors.white38,
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.text_fields_rounded),
            onSelected: (v) => setState(() => _fontSize = v),
            itemBuilder: (_) => [18, 20, 22, 26, 30]
                .map((s) => PopupMenuItem(
                      value: s.toDouble(),
                      child: Text('$s px'),
                    ))
                .toList(),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ayahCount + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _buildBismillah();
          final ayah = i;
          final arabic = quran.getVerse(widget.surah.number, ayah);
          final translation =
              quran.getVerseTranslation(widget.surah.number, ayah);

          return _AyahCard(
            ayahNumber: ayah,
            arabicText: arabic,
            translation: _showTranslation ? translation : null,
            fontSize: _fontSize,
          );
        },
      ),
    );
  }

  Widget _buildBismillah() {
    if (widget.surah.number == 1 || widget.surah.number == 9) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        style: TextStyle(
          color: AppTheme.gold,
          fontSize: 22,
          fontFamily: 'serif',
          height: 2,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final int ayahNumber;
  final String arabicText;
  final String? translation;
  final double fontSize;

  const _AyahCard({
    required this.ayahNumber,
    required this.arabicText,
    required this.translation,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$ayahNumber',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            arabicText,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontFamily: 'serif',
              height: 1.8,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          if (translation != null) ...[
            const Divider(color: Colors.white12, height: 24),
            Text(
              translation!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
