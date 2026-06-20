import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../data/mafatih_data.dart';
import '../../models/dua.dart';

class MafatihScreen extends StatefulWidget {
  const MafatihScreen({super.key});

  @override
  State<MafatihScreen> createState() => _MafatihScreenState();
}

class _MafatihScreenState extends State<MafatihScreen> {
  String _search = '';

  List<Dua> get _filtered => mafatihDuas
      .where((d) =>
          d.title.toLowerCase().contains(_search.toLowerCase()) ||
          d.translation.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mafatih al-Jinan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search duas...',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                return _DuaCard(dua: _filtered[i], index: i);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaCard extends StatefulWidget {
  final Dua dua;
  final int index;

  const _DuaCard({required this.dua, required this.index});

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  bool _expanded = false;
  bool _showTranslit = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            widget.dua.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            widget.dua.source,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: AppTheme.gold,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  Text(
                    widget.dua.arabicText,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 18,
                      fontFamily: 'serif',
                      height: 2.0,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  if (_showTranslit) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.dua.transliteration,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    widget.dua.translation,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _showTranslit = !_showTranslit),
                    child: Text(
                      _showTranslit ? 'Hide transliteration' : 'Show transliteration',
                      style: const TextStyle(color: AppTheme.gold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }
}
