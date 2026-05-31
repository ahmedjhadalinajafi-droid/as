import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'islamic_background.dart';

// ─── Islamic Occasions ────────────────────────────────────────────────────────

class _Occasion {
  final int month; // Hijri month
  final int day;
  final String name;
  final Color color;
  const _Occasion({required this.month, required this.day, required this.name, required this.color});
}

const _islamicOccasions = [
  _Occasion(month: 1,  day: 1,  name: 'رأس السنة الهجرية',                         color: Color(0xFF1B3D6F)),
  _Occasion(month: 1,  day: 7,  name: 'مولد الإمام علي بن الحسين ع',               color: Color(0xFF2E7D32)),
  _Occasion(month: 1,  day: 10, name: 'يوم عاشوراء - شهادة الإمام الحسين ع',       color: Color(0xFFC62828)),
  _Occasion(month: 1,  day: 25, name: 'شهادة الإمام علي بن الحسين ع',              color: Color(0xFFC62828)),
  _Occasion(month: 2,  day: 7,  name: 'مولد الإمام محمد الباقر ع',                 color: Color(0xFF2E7D32)),
  _Occasion(month: 2,  day: 20, name: 'الأربعين - زيارة الأربعين',                  color: Color(0xFF1B3D6F)),
  _Occasion(month: 2,  day: 28, name: 'وفاة النبي ﷺ وشهادة الإمام الحسن ع',        color: Color(0xFFC62828)),
  _Occasion(month: 2,  day: 30, name: 'شهادة الإمام علي الهادي ع',                 color: Color(0xFFC62828)),
  _Occasion(month: 3,  day: 8,  name: 'شهادة السيدة فاطمة الزهراء ع',              color: Color(0xFFC62828)),
  _Occasion(month: 3,  day: 17, name: 'مولد النبي محمد ﷺ ومولد الإمام الصادق ع',   color: Color(0xFF2E7D32)),
  _Occasion(month: 4,  day: 10, name: 'شهادة السيدة فاطمة الزهراء ع (رواية)',       color: Color(0xFFC62828)),
  _Occasion(month: 5,  day: 13, name: 'مولد السيدة فاطمة الزهراء ع',               color: Color(0xFF2E7D32)),
  _Occasion(month: 5,  day: 15, name: 'مولد الإمام الحسن المجتبى ع',               color: Color(0xFF2E7D32)),
  _Occasion(month: 6,  day: 3,  name: 'شهادة السيدة فاطمة الزهراء ع (رواية ثالثة)', color: Color(0xFFC62828)),
  _Occasion(month: 6,  day: 20, name: 'شهادة السيدة فاطمة الزهراء ع (رواية رابعة)', color: Color(0xFFC62828)),
  _Occasion(month: 7,  day: 1,  name: 'أول رجب المرجب',                             color: Color(0xFF1B3D6F)),
  _Occasion(month: 7,  day: 10, name: 'مولد الإمام محمد الجواد ع',                  color: Color(0xFF2E7D32)),
  _Occasion(month: 7,  day: 13, name: 'مولد الإمام علي بن أبي طالب ع',              color: Color(0xFF2E7D32)),
  _Occasion(month: 7,  day: 24, name: 'دحو الأرض',                                  color: Color(0xFF1B3D6F)),
  _Occasion(month: 7,  day: 25, name: 'شهادة الإمام موسى الكاظم ع',                color: Color(0xFFC62828)),
  _Occasion(month: 7,  day: 27, name: 'المبعث النبوي الشريف',                       color: Color(0xFFC9A843)),
  _Occasion(month: 8,  day: 3,  name: 'شهادة الإمام الحسن المجتبى ع',              color: Color(0xFFC62828)),
  _Occasion(month: 8,  day: 5,  name: 'مولد الإمام الحسين ع',                      color: Color(0xFF2E7D32)),
  _Occasion(month: 8,  day: 7,  name: 'مولد أبي الفضل العباس ع',                   color: Color(0xFF2E7D32)),
  _Occasion(month: 8,  day: 11, name: 'مولد الإمام علي الهادي ع',                  color: Color(0xFF2E7D32)),
  _Occasion(month: 8,  day: 15, name: 'مولد الإمام المهدي عجل الله فرجه',           color: Color(0xFFC9A843)),
  _Occasion(month: 9,  day: 1,  name: 'بداية شهر رمضان المبارك',                   color: Color(0xFFC9A843)),
  _Occasion(month: 9,  day: 10, name: 'وفاة السيدة خديجة الكبرى ع',                color: Color(0xFFC62828)),
  _Occasion(month: 9,  day: 17, name: 'ذكرى غزوة بدر الكبرى',                      color: Color(0xFF1B3D6F)),
  _Occasion(month: 9,  day: 19, name: 'ليلة ضربة الإمام علي ع',                    color: Color(0xFFC62828)),
  _Occasion(month: 9,  day: 21, name: 'شهادة الإمام علي بن أبي طالب ع',            color: Color(0xFFC62828)),
  _Occasion(month: 9,  day: 23, name: 'ليلة القدر المرجّحة',                         color: Color(0xFFC9A843)),
  _Occasion(month: 10, day: 1,  name: 'عيد الفطر المبارك',                          color: Color(0xFFC9A843)),
  _Occasion(month: 10, day: 8,  name: 'شهادة الإمام الحسن العسكري ع',              color: Color(0xFFC62828)),
  _Occasion(month: 10, day: 25, name: 'شهادة الإمام الصادق ع',                     color: Color(0xFFC62828)),
  _Occasion(month: 11, day: 11, name: 'مولد الإمام علي الرضا ع',                   color: Color(0xFF2E7D32)),
  _Occasion(month: 11, day: 29, name: 'شهادة الإمام محمد الجواد ع',                color: Color(0xFFC62828)),
  _Occasion(month: 12, day: 7,  name: 'شهادة الإمام الباقر ع',                     color: Color(0xFFC62828)),
  _Occasion(month: 12, day: 10, name: 'عيد الأضحى المبارك',                        color: Color(0xFFC9A843)),
  _Occasion(month: 12, day: 15, name: 'مولد الإمام علي الهادي ع (رواية)',           color: Color(0xFF2E7D32)),
  _Occasion(month: 12, day: 18, name: 'عيد الغدير الأغر',                          color: Color(0xFFC9A843)),
  _Occasion(month: 12, day: 24, name: 'يوم المباهلة',                               color: Color(0xFF1B3D6F)),
];

const _hijriMonthNames = [
  'محرم','صفر','ربيع الأول','ربيع الثاني',
  'جمادى الأولى','جمادى الثانية','رجب','شعبان',
  'رمضان','شوال','ذو القعدة','ذو الحجة',
];

const _gregMonthNames = [
  'يناير','فبراير','مارس','أبريل','مايو','يونيو',
  'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر',
];

const _weekDays = ['أح', 'اث', 'ثل', 'أر', 'خم', 'جم', 'سب'];

// ─── Page ─────────────────────────────────────────────────────────────────────

class HijriCalendarPage extends StatefulWidget {
  const HijriCalendarPage({super.key});

  @override
  State<HijriCalendarPage> createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  late int _viewYear;
  late int _viewMonth;
  int? _selectedGregDay;
  late HijriCalendar _todayH;
  late DateTime _todayG;

  @override
  void initState() {
    super.initState();
    _todayG = DateTime.now();
    _todayH = HijriCalendar.now();
    _viewYear = _todayG.year;
    _viewMonth = _todayG.month;
    _selectedGregDay = _todayG.day;
  }

  void _prev() => setState(() {
        _selectedGregDay = null;
        if (_viewMonth == 1) { _viewMonth = 12; _viewYear--; }
        else _viewMonth--;
      });

  void _next() => setState(() {
        _selectedGregDay = null;
        if (_viewMonth == 12) { _viewMonth = 1; _viewYear++; }
        else _viewMonth++;
      });

  void _goToday() => setState(() {
        _viewYear = _todayG.year;
        _viewMonth = _todayG.month;
        _selectedGregDay = _todayG.day;
      });

  int get _daysInMonth => DateTime(_viewYear, _viewMonth + 1, 0).day;

  // 0 = Sunday
  int get _firstWeekday => DateTime(_viewYear, _viewMonth, 1).weekday % 7;

  HijriCalendar _hijriFor(int gregDay) =>
      HijriCalendar.fromDate(DateTime(_viewYear, _viewMonth, gregDay));

  List<_Occasion> _occasionsFor(HijriCalendar h) => _islamicOccasions
      .where((o) => o.month == h.hMonth && o.day == h.hDay)
      .toList();

  List<int> get _visibleHijriMonths {
    final seen = <int>{};
    for (int d = 1; d <= _daysInMonth; d++) {
      seen.add(_hijriFor(d).hMonth);
    }
    return seen.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const navy = Color(0xFF1B3D6F);
    const gold = Color(0xFFC9A843);

    final daysInMonth = _daysInMonth;
    final firstWd = _firstWeekday;
    final hijriMonths = _visibleHijriMonths
        .map((m) => _hijriMonthNames[m - 1])
        .join(' / ');

    HijriCalendar? selectedH;
    List<_Occasion> selectedOccasions = [];
    if (_selectedGregDay != null) {
      selectedH = _hijriFor(_selectedGregDay!);
      selectedOccasions = _occasionsFor(selectedH);
    }

    return IslamicPatternBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('التقويم'),
        actions: [
          TextButton(
            onPressed: _goToday,
            child: const Text('اليوم', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Month header ─────────────────────────────────────────
            Container(
              color: navy,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _next,
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _viewMonth.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                color: gold,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _gregMonthNames[_viewMonth - 1],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ScheherazadeNew',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_viewYear',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hijriMonths,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                            fontFamily: 'ScheherazadeNew',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _prev,
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            // ── Selected day info — shown at TOP ─────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _selectedGregDay != null && selectedH != null
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: navy.withOpacity(0.07),
                        border: Border(
                          bottom: BorderSide(color: gold.withOpacity(0.4), width: 1.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Dual date row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Hijri date
                              Column(
                                children: [
                                  Text(
                                    '${selectedH.hDay}',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: navy,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    '${_hijriMonthNames[selectedH.hMonth - 1]} ${selectedH.hYear} هـ',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: navy,
                                      fontFamily: 'ScheherazadeNew',
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 48,
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                color: gold.withOpacity(0.5),
                              ),
                              // Gregorian date
                              Column(
                                children: [
                                  Text(
                                    '$_selectedGregDay',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    '${_gregMonthNames[_viewMonth - 1]} $_viewYear م',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Occasions for selected day
                          if (selectedOccasions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ...selectedOccasions.map((o) => Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: o.color.withOpacity(0.09),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: o.color.withOpacity(0.35)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10, height: 10,
                                        decoration: BoxDecoration(
                                            color: o.color, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          o.name,
                                          style: TextStyle(
                                            fontSize: 14,
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
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Weekday headers ──────────────────────────────────────
            Container(
              color: navy.withOpacity(0.85),
              padding: const EdgeInsets.symmetric(vertical: 6),
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

            // ── Day grid — circle cells ───────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.1,
                mainAxisSpacing: 2,
              ),
              itemCount: firstWd + daysInMonth,
              itemBuilder: (_, i) {
                if (i < firstWd) return const SizedBox.shrink();
                final gregDay = i - firstWd + 1;
                final hDate = _hijriFor(gregDay);
                final isToday = _viewYear == _todayG.year &&
                    _viewMonth == _todayG.month &&
                    gregDay == _todayG.day;
                final isSelected = gregDay == _selectedGregDay;
                final occasions = _occasionsFor(hDate);
                final hasOccasion = occasions.isNotEmpty;

                return GestureDetector(
                  onTap: () => setState(() =>
                      _selectedGregDay = isSelected ? null : gregDay),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? navy
                          : isToday
                              ? gold.withOpacity(0.18)
                              : null,
                      border: isToday && !isSelected
                          ? Border.all(color: gold, width: 1.8)
                          : isSelected
                              ? null
                              : hasOccasion
                                  ? Border.all(
                                      color: occasions.first.color.withOpacity(0.35),
                                      width: 1,
                                    )
                                  : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hijri date
                        Text(
                          '${hDate.hDay}',
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.1,
                            color: isSelected
                                ? Colors.white60
                                : hasOccasion
                                    ? occasions.first.color.withOpacity(0.9)
                                    : cs.onSurface.withOpacity(0.45),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Gregorian date
                        Text(
                          '$gregDay',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.1,
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
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white70
                                  : occasions.first.color,
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

            // ── Month occasions list ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._visibleHijriMonths.map((hm) {
                    final monthOccasions = _islamicOccasions
                        .where((o) => o.month == hm)
                        .toList()
                      ..sort((a, b) => a.day.compareTo(b.day));
                    if (monthOccasions.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                height: 18,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.mosque, size: 16, color: Color(0xFF1B3D6F)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'مناسبات شهر ${_hijriMonthNames[hm - 1]}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1B3D6F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...monthOccasions.map((o) => Container(
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
                                  '${o.day} ${_hijriMonthNames[o.month - 1]}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: o.color.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
    );
  }
}
