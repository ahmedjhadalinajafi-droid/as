import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../theme/app_theme.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late HijriCalendar _current;
  final HijriCalendar _today = HijriCalendar.now();

  @override
  void initState() {
    super.initState();
    _current = HijriCalendar.now();
  }

  void _prevMonth() {
    setState(() {
      if (_current.hMonth == 1) {
        _current = HijriCalendar()
          ..hYear = _current.hYear - 1
          ..hMonth = 12
          ..hDay = 1;
      } else {
        _current = HijriCalendar()
          ..hYear = _current.hYear
          ..hMonth = _current.hMonth - 1
          ..hDay = 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_current.hMonth == 12) {
        _current = HijriCalendar()
          ..hYear = _current.hYear + 1
          ..hMonth = 1
          ..hDay = 1;
      } else {
        _current = HijriCalendar()
          ..hYear = _current.hYear
          ..hMonth = _current.hMonth + 1
          ..hDay = 1;
      }
    });
  }

  int _daysInMonth(int year, int month) {
    // Hijri months alternate between 29 and 30 days
    return (month % 2 == 1 || (month == 12 && _isLeapYear(year))) ? 30 : 29;
  }

  bool _isLeapYear(int year) => (year * 11 + 14) % 30 < 11;

  bool _isSpecialDay(int day, int month) {
    // Mark special Islamic days
    final special = {
      1: [1, 10], // Muharram: New Year (1), Ashura (10)
      3: [12], // Rabi al-Awwal: Mawlid (12)
      7: [27], // Rajab: Isra & Mi'raj (27)
      8: [15], // Sha'ban: Mid-Sha'ban (15)
      9: [1, 21, 23, 27], // Ramadan: Start, Laylat al-Qadr candidates
      10: [1], // Shawwal: Eid al-Fitr (1)
      12: [10], // Dhul Hijjah: Eid al-Adha (10)
    };
    return special[month]?.contains(day) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(_current.hYear, _current.hMonth);
    // Get the first day's weekday offset (simplified: start from 0)
    final firstDayOffset = HijriCalendar()
      ..hYear = _current.hYear
      ..hMonth = _current.hMonth
      ..hDay = 1;
    final startWeekday = firstDayOffset.getDayOfWeek();

    return Scaffold(
      appBar: AppBar(title: const Text('Hijri Calendar')),
      body: Column(
        children: [
          _buildHeader(),
          _buildWeekRow(),
          Expanded(
            child: _buildGrid(daysInMonth, startWeekday)
                .animate()
                .fadeIn(duration: 300.ms),
          ),
          _buildSpecialDaysKey(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.gold),
            onPressed: _prevMonth,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _current.longMonthName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${_current.hYear} AH',
                  style: const TextStyle(color: AppTheme.gold, fontSize: 13),
                ),
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
        children: days
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        color: d == 'Fri' ? AppTheme.gold : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildGrid(int daysInMonth, int startWeekday) {
    final cells = startWeekday + daysInMonth;
    final rows = (cells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, i) {
        final day = i - startWeekday + 1;
        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final isToday = _today.hYear == _current.hYear &&
            _today.hMonth == _current.hMonth &&
            _today.hDay == day;
        final isSpecial = _isSpecialDay(day, _current.hMonth);
        final isFriday = (i % 7) == 5;

        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isToday
                ? AppTheme.primaryGreen
                : isSpecial
                    ? AppTheme.gold.withOpacity(0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: AppTheme.gold, width: 1.5)
                : isSpecial
                    ? Border.all(color: AppTheme.gold.withOpacity(0.3))
                    : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: isToday
                      ? Colors.white
                      : isFriday
                          ? AppTheme.gold
                          : isSpecial
                              ? AppTheme.gold
                              : Colors.white70,
                  fontWeight:
                      isToday || isSpecial ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              if (isSpecial)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.gold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecialDaysKey() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(width: 6),
          const Text('Islamic occasion',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(width: 20),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen,
              border: Border.all(color: AppTheme.gold, width: 1.5),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Today',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}
