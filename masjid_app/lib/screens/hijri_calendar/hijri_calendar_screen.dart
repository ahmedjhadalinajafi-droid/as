import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../utils/hijri_utils.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  final HijriDate _today = HijriDate.now();
  late int _year;
  late int _month;
  Map<String, String> _userEvents = {};

  @override
  void initState() {
    super.initState();
    _year = _today.year;
    _month = _today.month;
    _loadUserEvents();
  }

  Future<void> _loadUserEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('hijri_events') ?? '{}';
    setState(() => _userEvents = Map<String, String>.from(jsonDecode(raw)));
  }

  Future<void> _saveUserEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hijri_events', jsonEncode(_userEvents));
  }

  String _dayKey(int y, int m, int d) => '$y-$m-$d';

  void _prevMonth() => setState(() {
        if (_month == 1) { _year--; _month = 12; }
        else { _month--; }
      });

  void _nextMonth() => setState(() {
        if (_month == 12) { _year++; _month = 1; }
        else { _month++; }
      });

  HijriDate get _currentDate => HijriDate(year: _year, month: _month, day: 1);

  bool _isIslamicOccasion(int day, int month) {
    const special = {
      1: [1, 10], 3: [12], 7: [27], 8: [15],
      9: [1, 21, 23, 27], 10: [1], 12: [10],
    };
    return special[month]?.contains(day) ?? false;
  }

  String? _occasionName(int day, int month) {
    final occasions = {
      '1-1': 'Islamic New Year', '1-10': 'Ashura',
      '3-12': "Mawlid al-Nabi ﷺ", '7-27': "Isra' & Mi'raj",
      '8-15': "Mid-Sha'ban", '9-1': 'First of Ramadan',
      '9-27': 'Laylat al-Qadr', '10-1': 'Eid al-Fitr',
      '12-10': 'Eid al-Adha',
    };
    return occasions['$month-$day'];
  }

  void _onDayTap(int day) {
    final key = _dayKey(_year, _month, day);
    final existing = _userEvents[key];
    final controller = TextEditingController(text: existing ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventBottomSheet(
        day: day, month: _month, year: _year,
        monthName: _currentDate.longMonthName,
        controller: controller,
        occasionName: _occasionName(day, _month),
        existingNote: existing,
        onSave: (text) async {
          setState(() {
            if (text.isEmpty) _userEvents.remove(key);
            else _userEvents[key] = text;
          });
          await _saveUserEvents();
        },
        onDelete: () async {
          setState(() => _userEvents.remove(key));
          await _saveUserEvents();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentDate;
    final daysInMonth = current.daysInMonth();
    final startWeekday = current.firstWeekdayOfMonth();

    return Scaffold(
      appBar: AppBar(title: const Text('Hijri Calendar')),
      body: Column(
        children: [
          _buildHeader(current),
          _buildWeekRow(),
          Expanded(
            child: _buildGrid(daysInMonth, startWeekday)
                .animate().fadeIn(duration: 300.ms),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader(HijriDate current) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.gold),
            onPressed: _prevMonth,
          ),
          Expanded(
            child: Column(
              children: [
                Text(current.longMonthName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    textAlign: TextAlign.center),
                Text('${current.year} AH',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.gold),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: days.map((d) => Expanded(
          child: Center(
            child: Text(d,
                style: TextStyle(
                  color: d == 'Fri' ? AppTheme.gold : Colors.white38,
                  fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildGrid(int daysInMonth, int startWeekday) {
    final rows = ((startWeekday + daysInMonth) / 7).ceil();
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, childAspectRatio: 0.9),
      itemCount: rows * 7,
      itemBuilder: (context, i) {
        final day = i - startWeekday + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
        final isToday = _today.year == _year && _today.month == _month && _today.day == day;
        final isOccasion = _isIslamicOccasion(day, _month);
        final isFriday = (i % 7) == 5;
        final hasNote = _userEvents.containsKey(_dayKey(_year, _month, day));
        return GestureDetector(
          onTap: () => _onDayTap(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.navyBlue
                  : isOccasion ? AppTheme.gold.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday ? Border.all(color: AppTheme.gold, width: 1.5)
                  : isOccasion ? Border.all(color: AppTheme.gold.withOpacity(0.3))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day',
                    style: TextStyle(
                      color: isToday ? Colors.white
                          : isFriday || isOccasion ? AppTheme.gold
                          : Colors.white70,
                      fontWeight: isToday || isOccasion ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    )),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (isOccasion)
                    Container(width: 4, height: 4,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppTheme.gold)),
                  if (hasNote) ...[
                    if (isOccasion) const SizedBox(width: 2),
                    Container(width: 4, height: 4,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFF4CAF50))),
                  ],
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _LegendDot(color: AppTheme.navyBlue, label: 'Today'),
        const SizedBox(width: 16),
        _LegendDot(color: AppTheme.gold, label: 'Islamic occasion'),
        const SizedBox(width: 16),
        _LegendDot(color: const Color(0xFF4CAF50), label: 'Your note'),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
  ]);
}

class _EventBottomSheet extends StatefulWidget {
  final int day, month, year;
  final String monthName;
  final TextEditingController controller;
  final String? occasionName, existingNote;
  final Future<void> Function(String) onSave;
  final Future<void> Function() onDelete;
  const _EventBottomSheet({
    required this.day, required this.month, required this.year,
    required this.monthName, required this.controller,
    required this.onSave, required this.onDelete,
    this.occasionName, this.existingNote,
  });
  @override
  State<_EventBottomSheet> createState() => _EventBottomSheetState();
}

class _EventBottomSheetState extends State<_EventBottomSheet> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('${widget.day} ${widget.monthName} ${widget.year} AH',
              style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16)),
          if (widget.occasionName != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, color: AppTheme.gold, size: 14),
              const SizedBox(width: 4),
              Text(widget.occasionName!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ]),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller, maxLines: 3, autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Add a note or event for this day...',
              labelText: 'Note / Event',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(children: [
            if (widget.existingNote != null)
              TextButton.icon(
                onPressed: () async { await widget.onDelete(); if (context.mounted) Navigator.pop(context); },
                icon: const Icon(Icons.delete_rounded, size: 16, color: Colors.redAccent),
                label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saving ? null : () async {
                setState(() => _saving = true);
                await widget.onSave(widget.controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              },
              child: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ]),
        ]),
      ),
    );
  }
}
