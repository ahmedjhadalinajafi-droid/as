import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

class HijriCalendarPage extends StatefulWidget {
  const HijriCalendarPage({super.key});

  @override
  State<HijriCalendarPage> createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  late HijriCalendar _hijri;
  late DateTime _gregorian;

  @override
  void initState() {
    super.initState();
    _gregorian = DateTime.now();
    _hijri = HijriCalendar.now();
  }

  static const _hijriMonths = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
    'جمادى الأولى', 'جمادى الثانية', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];

  // Notable Islamic occasions: month => [(day, name, isShia)]
  static const Map<int, List<(int, String)>> _occasions = {
    1: [
      (1, 'رأس السنة الهجرية'),
      (10, 'يوم عاشوراء'),
      (25, 'شهادة الإمام علي بن الحسين (السجاد) ع'),
    ],
    2: [
      (7, 'مولد الإمام محمد الباقر ع'),
      (20, 'الأربعين - زيارة الأربعين'),
      (28, 'وفاة النبي محمد ﷺ وشهادة الإمام الحسن ع'),
      (30, 'شهادة الإمام علي الهادي ع'),
    ],
    3: [
      (8, 'شهادة السيدة فاطمة الزهراء ع'),
      (17, 'مولد النبي محمد ﷺ - مولد الإمام الصادق ع'),
    ],
    4: [
      (10, 'شهادة السيدة فاطمة الزهراء ع (رواية ثانية)'),
    ],
    5: [
      (13, 'مولد الإمام علي بن أبي طالب ع'),
      (15, 'مولد الإمام الحسن المجتبى ع'),
    ],
    6: [
      (3, 'شهادة الإمام علي النقي (الهادي) ع'),
    ],
    7: [
      (13, 'مولد الإمام علي بن أبي طالب ع (رواية)'),
      (27, 'المبعث النبوي الشريف'),
    ],
    8: [
      (3, 'شهادة الإمام الحسن المجتبى ع'),
      (15, 'مولد الإمام المهدي (عج)'),
    ],
    9: [
      (1, 'بداية شهر رمضان المبارك'),
      (19, 'ليلة ضربة الإمام علي ع'),
      (21, 'شهادة الإمام علي بن أبي طالب ع'),
      (23, 'ليلة القدر'),
    ],
    10: [
      (1, 'عيد الفطر المبارك'),
      (25, 'شهادة الإمام الصادق ع'),
    ],
    11: [],
    12: [
      (10, 'عيد الأضحى المبارك'),
      (18, 'عيد الغدير الأغر'),
    ],
  };

  List<(int, String)> get _currentMonthOccasions =>
      _occasions[_hijri.hMonth] ?? [];

  List<(int, String)> get _upcomingOccasions {
    final result = <(int, String)>[];
    for (int m = _hijri.hMonth; m <= 12; m++) {
      for (final occ in (_occasions[m] ?? [])) {
        if (m > _hijri.hMonth || occ.$1 >= _hijri.hDay) {
          result.add(occ);
        }
      }
      if (result.length >= 5) break;
    }
    return result.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('التقويم الهجري')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Hijri Date Card
          Card(
            color: cs.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'التاريخ الهجري اليوم',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_hijri.hDay} ${_hijriMonths[_hijri.hMonth - 1]} ${_hijri.hYear}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE، d MMMM yyyy', 'ar').format(_gregorian),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Current month mini-calendar
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'شهر ${_hijriMonths[_hijri.hMonth - 1]} ${_hijri.hYear}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMonthGrid(cs),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Upcoming occasions
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المناسبات القادمة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const Divider(),
                  ..._buildUpcomingOccasions(cs),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // All occasions this month
          if (_currentMonthOccasions.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مناسبات ${_hijriMonths[_hijri.hMonth - 1]}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const Divider(),
                    ..._currentMonthOccasions.map((occ) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: cs.primary.withOpacity(0.1),
                            child: Text(
                              '${occ.$1}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(occ.$2,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            '${occ.$1} ${_hijriMonths[_hijri.hMonth - 1]}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(ColorScheme cs) {
    // Days of week header (Arabic, Sun-Sat)
    const dayLabels = ['أح', 'اث', 'ثل', 'أر', 'خم', 'جم', 'سب'];
    final daysInMonth = _hijri.getDaysInMonth(_hijri.hYear, _hijri.hMonth);

    // Find the weekday of day 1 of this Hijri month
    final firstGregorian = HijriCalendar()
      ..hYear = _hijri.hYear
      ..hMonth = _hijri.hMonth
      ..hDay = 1;
    final firstDate = firstGregorian.hijriToGregorian(
        _hijri.hYear, _hijri.hMonth, 1);
    final startWeekday = firstDate.weekday % 7; // Sunday=0

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayLabels
              .map((d) => SizedBox(
                    width: 32,
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.primary,
                            fontWeight: FontWeight.bold)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startWeekday) return const SizedBox.shrink();
            final day = i - startWeekday + 1;
            final isToday = day == _hijri.hDay;
            final hasOccasion = (_currentMonthOccasions
                .any((occ) => occ.$1 == day));

            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isToday ? cs.primary : null,
                shape: BoxShape.circle,
                border: hasOccasion && !isToday
                    ? Border.all(color: cs.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday ? Colors.white : null,
                    fontWeight:
                        isToday || hasOccasion ? FontWeight.bold : null,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildUpcomingOccasions(ColorScheme cs) {
    final upcoming = _upcomingOccasions;
    if (upcoming.isEmpty) {
      return [const Text('لا توجد مناسبات قادمة هذا الشهر')];
    }
    return upcoming
        .map((occ) => ListTile(
              dense: true,
              leading: Icon(Icons.event, color: cs.primary, size: 20),
              title: Text(occ.$2, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                '${occ.$1} ${_hijriMonths[_hijri.hMonth - 1]} ${_hijri.hYear}',
                style: const TextStyle(fontSize: 12),
              ),
            ))
        .toList();
  }
}
