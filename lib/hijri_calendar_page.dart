import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

// ─── Islamic Occasions Data ───────────────────────────────────────────────────

class _Occasion {
  final int month;
  final int day;
  final String name;
  final Color color;

  const _Occasion({
    required this.month,
    required this.day,
    required this.name,
    required this.color,
  });
}

const List<_Occasion> _islamicOccasions = [
  // محرم
  _Occasion(month: 1, day: 1,  name: 'رأس السنة الهجرية',               color: Color(0xFF1B3D6F)),
  _Occasion(month: 1, day: 7,  name: 'مولد الإمام علي بن الحسين ع',     color: Color(0xFF2E7D32)),
  _Occasion(month: 1, day: 10, name: 'يوم عاشوراء - شهادة الإمام الحسين ع', color: Color(0xFFC62828)),
  _Occasion(month: 1, day: 25, name: 'شهادة الإمام علي بن الحسين ع',    color: Color(0xFFC62828)),
  // صفر
  _Occasion(month: 2, day: 7,  name: 'مولد الإمام محمد الباقر ع',       color: Color(0xFF2E7D32)),
  _Occasion(month: 2, day: 20, name: 'الأربعين - زيارة الأربعين',        color: Color(0xFF1B3D6F)),
  _Occasion(month: 2, day: 28, name: 'وفاة النبي ﷺ وشهادة الإمام الحسن ع', color: Color(0xFFC62828)),
  _Occasion(month: 2, day: 30, name: 'شهادة الإمام علي الهادي ع',       color: Color(0xFFC62828)),
  // ربيع الأول
  _Occasion(month: 3, day: 8,  name: 'شهادة السيدة فاطمة الزهراء ع',    color: Color(0xFFC62828)),
  _Occasion(month: 3, day: 17, name: 'مولد النبي محمد ﷺ ومولد الإمام الصادق ع', color: Color(0xFF2E7D32)),
  // ربيع الثاني
  _Occasion(month: 4, day: 10, name: 'شهادة السيدة فاطمة الزهراء ع (رواية)', color: Color(0xFFC62828)),
  // جمادى الأولى
  _Occasion(month: 5, day: 13, name: 'مولد السيدة فاطمة الزهراء ع',     color: Color(0xFF2E7D32)),
  _Occasion(month: 5, day: 15, name: 'مولد الإمام الحسن المجتبى ع',     color: Color(0xFF2E7D32)),
  // جمادى الثانية
  _Occasion(month: 6, day: 3,  name: 'شهادة السيدة فاطمة الزهراء ع (رواية ثالثة)', color: Color(0xFFC62828)),
  _Occasion(month: 6, day: 20, name: 'شهادة السيدة فاطمة الزهراء ع (رواية رابعة)', color: Color(0xFFC62828)),
  // رجب
  _Occasion(month: 7, day: 1,  name: 'أول رجب المرجب',                  color: Color(0xFF1B3D6F)),
  _Occasion(month: 7, day: 10, name: 'مولد الإمام محمد الجواد ع',        color: Color(0xFF2E7D32)),
  _Occasion(month: 7, day: 13, name: 'مولد الإمام علي بن أبي طالب ع',   color: Color(0xFF2E7D32)),
  _Occasion(month: 7, day: 24, name: 'دحو الأرض',                        color: Color(0xFF1B3D6F)),
  _Occasion(month: 7, day: 25, name: 'شهادة الإمام موسى الكاظم ع',      color: Color(0xFFC62828)),
  _Occasion(month: 7, day: 27, name: 'المبعث النبوي الشريف',             color: Color(0xFFC9A843)),
  // شعبان
  _Occasion(month: 8, day: 3,  name: 'شهادة الإمام الحسن المجتبى ع',    color: Color(0xFFC62828)),
  _Occasion(month: 8, day: 5,  name: 'مولد الإمام الحسين ع',             color: Color(0xFF2E7D32)),
  _Occasion(month: 8, day: 7,  name: 'مولد أبي الفضل العباس ع',          color: Color(0xFF2E7D32)),
  _Occasion(month: 8, day: 11, name: 'مولد الإمام علي الهادي ع',         color: Color(0xFF2E7D32)),
  _Occasion(month: 8, day: 15, name: 'مولد الإمام المهدي (عج)',           color: Color(0xFFC9A843)),
  // رمضان
  _Occasion(month: 9, day: 1,  name: 'بداية شهر رمضان المبارك',          color: Color(0xFFC9A843)),
  _Occasion(month: 9, day: 10, name: 'وفاة السيدة خديجة الكبرى ع',       color: Color(0xFFC62828)),
  _Occasion(month: 9, day: 15, name: 'مولد الإمام الحسن المجتبى ع',      color: Color(0xFF2E7D32)),
  _Occasion(month: 9, day: 17, name: 'ذكرى غزوة بدر الكبرى',             color: Color(0xFF1B3D6F)),
  _Occasion(month: 9, day: 19, name: 'ليلة ضربة الإمام علي ع',           color: Color(0xFFC62828)),
  _Occasion(month: 9, day: 21, name: 'شهادة الإمام علي بن أبي طالب ع',  color: Color(0xFFC62828)),
  _Occasion(month: 9, day: 23, name: 'ليلة القدر المرجّحة',               color: Color(0xFFC9A843)),
  // شوال
  _Occasion(month: 10, day: 1,  name: 'عيد الفطر المبارك',               color: Color(0xFFC9A843)),
  _Occasion(month: 10, day: 8,  name: 'شهادة الإمام الحسن العسكري ع',    color: Color(0xFFC62828)),
  _Occasion(month: 10, day: 25, name: 'شهادة الإمام الصادق ع',           color: Color(0xFFC62828)),
  // ذو القعدة
  _Occasion(month: 11, day: 11, name: 'مولد الإمام علي الرضا ع',         color: Color(0xFF2E7D32)),
  _Occasion(month: 11, day: 29, name: 'شهادة الإمام محمد الجواد ع',      color: Color(0xFFC62828)),
  // ذو الحجة
  _Occasion(month: 12, day: 7,  name: 'شهادة الإمام الباقر ع',           color: Color(0xFFC62828)),
  _Occasion(month: 12, day: 10, name: 'عيد الأضحى المبارك',              color: Color(0xFFC9A843)),
  _Occasion(month: 12, day: 15, name: 'مولد الإمام علي الهادي ع (رواية)', color: Color(0xFF2E7D32)),
  _Occasion(month: 12, day: 18, name: 'عيد الغدير الأغر',                color: Color(0xFFC9A843)),
  _Occasion(month: 12, day: 24, name: 'يوم المباهلة',                    color: Color(0xFF1B3D6F)),
];

const _hijriMonthNames = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
  'جمادى الأولى', 'جمادى الثانية', 'رجب', 'شعبان',
  'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];

const _weekDays = ['أح', 'اث', 'ثل', 'أر', 'خم', 'جم', 'سب'];

// ─── Page ─────────────────────────────────────────────────────────────────────

class HijriCalendarPage extends StatefulWidget {
  const HijriCalendarPage({super.key});

  @override
  State<HijriCalendarPage> createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  late HijriCalendar _today;
  late int _viewYear;
  late int _viewMonth;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _today = HijriCalendar.now();
    _viewYear = _today.hYear;
    _viewMonth = _today.hMonth;
  }

  bool get _isCurrentMonth =>
      _viewYear == _today.hYear && _viewMonth == _today.hMonth;

  void _prevMonth() {
    setState(() {
      _selectedDay = null;
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear--;
      } else {
        _viewMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDay = null;
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear++;
      } else {
        _viewMonth++;
      }
    });
  }

  void _goToToday() {
    setState(() {
      _viewYear = _today.hYear;
      _viewMonth = _today.hMonth;
      _selectedDay = _today.hDay;
    });
  }

  int _daysInMonth(int year, int month) {
    final cal = HijriCalendar()
      ..hYear = year
      ..hMonth = month
      ..hDay = 1;
    return cal.getDaysInMonth(year, month);
  }

  int _firstWeekday(int year, int month) {
    final greg = HijriCalendar().hijriToGregorian(year, month, 1);
    return greg.weekday % 7; // Sunday = 0
  }

  List<_Occasion> _occasionsForDay(int day) {
    return _islamicOccasions
        .where((o) => o.month == _viewMonth && o.day == day)
        .toList();
  }

  List<_Occasion> get _monthOccasions => _islamicOccasions
      .where((o) => o.month == _viewMonth)
      .toList()
    ..sort((a, b) => a.day.compareTo(b.day));

  String _gregDateForDay(int day) {
    try {
      final greg = HijriCalendar().hijriToGregorian(_viewYear, _viewMonth, day);
      return DateFormat('d/M/yyyy').format(greg);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const navy = Color(0xFF1B3D6F);
    const gold = Color(0xFFC9A843);

    final daysInMonth = _daysInMonth(_viewYear, _viewMonth);
    final firstWeekday = _firstWeekday(_viewYear, _viewMonth);
    final selectedOccasions =
        _selectedDay != null ? _occasionsForDay(_selectedDay!) : <_Occasion>[];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('التقويم الهجري'),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text('اليوم',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Today's date strip ──────────────────────────────────────
          Container(
            width: double.infinity,
            color: navy.withOpacity(0.06),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.today, size: 16, color: navy),
                    const SizedBox(width: 6),
                    Text(
                      'اليوم: ${_today.hDay} ${_hijriMonthNames[_today.hMonth - 1]} ${_today.hYear}هـ',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: navy),
                    ),
                  ],
                ),
                Text(
                  DateFormat('d/M/yyyy').format(DateTime.now()),
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),

          // ── Month navigator ─────────────────────────────────────────
          Container(
            color: navy,
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _nextMonth, // RTL: right arrow = next
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 28),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _hijriMonthNames[_viewMonth - 1],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ScheherazadeNew',
                        ),
                      ),
                      Text(
                        '$_viewYear هـ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          // ── Weekday headers ─────────────────────────────────────────
          Container(
            color: navy.withOpacity(0.85),
            padding:
                const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: _weekDays
                  .map((d) => Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // ── Day grid ────────────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < firstWeekday) return const SizedBox.shrink();
              final day = i - firstWeekday + 1;
              final isToday = _isCurrentMonth && day == _today.hDay;
              final isSelected = day == _selectedDay;
              final occasions = _occasionsForDay(day);
              final hasOccasion = occasions.isNotEmpty;
              final occasionColor =
                  hasOccasion ? occasions.first.color : null;

              return GestureDetector(
                onTap: () => setState(() =>
                    _selectedDay = isSelected ? null : day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? navy
                        : isToday
                            ? gold.withOpacity(0.2)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: gold, width: 1.5)
                        : isSelected
                            ? null
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? gold
                                  : cs.onSurface,
                        ),
                      ),
                      if (hasOccasion)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white70
                                : occasionColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1),

          // ── Selected day info or month occasions ─────────────────────
          Expanded(
            child: _selectedDay != null && selectedOccasions.isNotEmpty
                ? _SelectedDayPanel(
                    day: _selectedDay!,
                    month: _viewMonth,
                    year: _viewYear,
                    gregDate: _gregDateForDay(_selectedDay!),
                    occasions: selectedOccasions,
                  )
                : _MonthOccasionsList(
                    occasions: _monthOccasions,
                    monthName: _hijriMonthNames[_viewMonth - 1],
                    year: _viewYear,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Selected Day Panel ───────────────────────────────────────────────────────

class _SelectedDayPanel extends StatelessWidget {
  final int day;
  final int month;
  final int year;
  final String gregDate;
  final List<_Occasion> occasions;

  const _SelectedDayPanel({
    required this.day,
    required this.month,
    required this.year,
    required this.gregDate,
    required this.occasions,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.event, color: Color(0xFF1B3D6F), size: 20),
            const SizedBox(width: 8),
            Text(
              '$day ${_hijriMonthNames[month - 1]} $year هـ  •  $gregDate',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1B3D6F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...occasions.map((o) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: o.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: o.color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: o.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      o.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: o.color,
                        fontFamily: 'ScheherazadeNew',
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ─── Month Occasions List ─────────────────────────────────────────────────────

class _MonthOccasionsList extends StatelessWidget {
  final List<_Occasion> occasions;
  final String monthName;
  final int year;

  const _MonthOccasionsList({
    required this.occasions,
    required this.monthName,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    if (occasions.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد مناسبات هذا الشهر',
          style: TextStyle(fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: occasions.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 4),
            child: Text(
              'مناسبات شهر $monthName $year هـ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1B3D6F),
              ),
            ),
          );
        }
        final o = occasions[i - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: o.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              right: BorderSide(color: o.color, width: 3),
            ),
          ),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: o.color.withOpacity(0.15),
              child: Text(
                '${o.day}',
                style: TextStyle(
                  fontSize: 12,
                  color: o.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              o.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: o.color,
                fontFamily: 'ScheherazadeNew',
              ),
            ),
            subtitle: Text(
              '${o.day} $monthName',
              style: TextStyle(
                  fontSize: 11,
                  color: o.color.withOpacity(0.7)),
            ),
          ),
        );
      },
    );
  }
}
