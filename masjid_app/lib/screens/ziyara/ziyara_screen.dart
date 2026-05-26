import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../data/ziyara_data.dart';
import '../../widgets/islamic_pattern_painter.dart';

class ZiyaraScreen extends StatefulWidget {
  const ZiyaraScreen({super.key});

  @override
  State<ZiyaraScreen> createState() => _ZiyaraScreenState();
}

class _ZiyaraScreenState extends State<ZiyaraScreen> {
  bool _showTranslation = true;
  double _fontSize = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ziyarat Imam Ali (AS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            tooltip: 'Toggle translation',
            color: _showTranslation ? AppTheme.gold : Colors.white38,
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.text_fields_rounded),
            onSelected: (v) => setState(() => _fontSize = v),
            itemBuilder: (_) => [16.0, 18.0, 20.0, 24.0, 28.0]
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Text('$s px'),
                    ))
                .toList(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _SectionCard(
                  section: ZiyaraData.sections[i],
                  showTranslation: _showTranslation,
                  fontSize: _fontSize,
                  index: i,
                ),
                childCount: ZiyaraData.sections.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 160,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D3B1F), Color(0xFF1A1A3A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withOpacity(0.25)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(painter: IslamicPatternPainter(opacity: 0.08)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🕌',
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  ZiyaraData.title,
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 20,
                    fontFamily: 'serif',
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 4),
                const Text(
                  'Shrine of Imam Ali (AS) · Najaf, Iraq',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ZiyaraSection section;
  final bool showTranslation;
  final double fontSize;
  final int index;

  const _SectionCard({
    required this.section,
    required this.showTranslation,
    required this.fontSize,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            section.arabicText,
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: fontSize,
              fontFamily: 'serif',
              height: 2.0,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          if (showTranslation) ...[
            const Divider(color: Colors.white12, height: 24),
            Text(
              section.translation,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.7,
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
