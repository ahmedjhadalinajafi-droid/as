import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'islamic_background.dart';

const _navy = Color(0xFF1B3D6F);
const _gold = Color(0xFFC9A843);

class DateConverterPage extends StatefulWidget {
  const DateConverterPage({super.key});

  @override
  State<DateConverterPage> createState() => _DateConverterPageState();
}

class _DateConverterPageState extends State<DateConverterPage> {
  // false = Gregorian → Hijri ; true = Hijri → Gregorian
  bool _hijriToGreg = false;

  // Gregorian input
  DateTime _greg = DateTime.now();

  // Hijri input
  late int _hYear;
  late int _hMonth;
  late int _hDay;

  static const _hijriMonths = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني', 'جمادى الأولى',
    'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال',
    'ذو القعدة', 'ذو الحجة',
  ];

  @override
  void initState() {
    super.initState();
    final h = HijriCalendar.now();
    _hYear = h.hYear;
    _hMonth = h.hMonth;
    _hDay = h.hDay;
  }

  // ── Conversions ──────────────────────────────────────────────────
  HijriCalendar get _gregAsHijri => HijriCalendar.fromDate(_greg);

  DateTime get _hijriAsGreg =>
      HijriCalendar.now().hijriToGregorian(_hYear, _hMonth, _hDay);

  // ── Pickers ──────────────────────────────────────────────────────
  Future<void> _pickGreg() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _greg,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _greg = picked);
  }

  void _pickHijri() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HijriPicker(
        year: _hYear,
        month: _hMonth,
        day: _hDay,
        months: _hijriMonths,
        onChanged: (y, m, d) => setState(() {
          _hYear = y;
          _hMonth = m;
          _hDay = d;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return IslamicPatternBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('محوّل التاريخ')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Direction toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2D4A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  _toggleBtn('ميلادي ← هجري', !_hijriToGreg,
                      () => setState(() => _hijriToGreg = false)),
                  _toggleBtn('هجري ← ميلادي', _hijriToGreg,
                      () => setState(() => _hijriToGreg = true)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input card
            _hijriToGreg ? _buildHijriInput(cs, isDark) : _buildGregInput(cs, isDark),

            // Swap arrow
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: _gold,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.swap_vert, color: Colors.white),
                  onPressed: () =>
                      setState(() => _hijriToGreg = !_hijriToGreg),
                ),
              ),
            ),

            // Result card
            _hijriToGreg ? _buildGregResult(cs, isDark) : _buildHijriResult(cs, isDark),
          ],
        ),
      ),
    ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? _navy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : _navy,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'ScheherazadeNew',
            ),
          ),
        ),
      ),
    );
  }

  // ── Gregorian input (tap to pick) ────────────────────────────────
  Widget _buildGregInput(ColorScheme cs, bool isDark) {
    return _inputCard(
      isDark: isDark,
      label: 'التاريخ الميلادي',
      icon: Icons.wb_sunny_outlined,
      value: DateFormat('EEEE، d MMMM yyyy', 'ar').format(_greg),
      onTap: _pickGreg,
    );
  }

  Widget _buildHijriResult(ColorScheme cs, bool isDark) {
    final h = _gregAsHijri;
    return _resultCard(
      isDark: isDark,
      label: 'التاريخ الهجري',
      icon: Icons.nightlight_round,
      value:
          '${h.hDay} ${_hijriMonths[h.hMonth - 1]} ${h.hYear} هـ',
      // Same calendar day as the chosen Gregorian date
      weekday: DateFormat('EEEE', 'ar').format(_greg),
    );
  }

  // ── Hijri input (tap to pick) ────────────────────────────────────
  Widget _buildHijriInput(ColorScheme cs, bool isDark) {
    return _inputCard(
      isDark: isDark,
      label: 'التاريخ الهجري',
      icon: Icons.nightlight_round,
      value: '$_hDay ${_hijriMonths[_hMonth - 1]} $_hYear هـ',
      onTap: _pickHijri,
    );
  }

  Widget _buildGregResult(ColorScheme cs, bool isDark) {
    final g = _hijriAsGreg;
    return _resultCard(
      isDark: isDark,
      label: 'التاريخ الميلادي',
      icon: Icons.wb_sunny_outlined,
      value: DateFormat('d MMMM yyyy', 'ar').format(g),
      weekday: DateFormat('EEEE', 'ar').format(g),
    );
  }

  Widget _inputCard({
    required bool isDark,
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2D4A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _navy.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: _gold),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54)),
                const Spacer(),
                const Icon(Icons.edit_calendar, size: 18, color: _navy),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'ScheherazadeNew',
                color: isDark ? Colors.white : _navy,
              ),
            ),
            const SizedBox(height: 4),
            Text('اضغط للتغيير',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
      ),
    );
  }

  Widget _resultCard({
    required bool isDark,
    required String label,
    required IconData icon,
    required String value,
    required String weekday,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: _gold),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'ScheherazadeNew',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(weekday,
              style: const TextStyle(fontSize: 14, color: _gold)),
        ],
      ),
    );
  }
}

// ─── Hijri Picker Bottom Sheet ───────────────────────────────────────────────

class _HijriPicker extends StatefulWidget {
  final int year;
  final int month;
  final int day;
  final List<String> months;
  final void Function(int year, int month, int day) onChanged;

  const _HijriPicker({
    required this.year,
    required this.month,
    required this.day,
    required this.months,
    required this.onChanged,
  });

  @override
  State<_HijriPicker> createState() => _HijriPickerState();
}

class _HijriPickerState extends State<_HijriPicker> {
  late int _y = widget.year;
  late int _m = widget.month;
  late int _d = widget.day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('اختر التاريخ الهجري',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ScheherazadeNew')),
          const SizedBox(height: 16),
          Row(
            children: [
              _stepper('اليوم', _d.toString(),
                  () => setState(() => _d = _d < 30 ? _d + 1 : 1),
                  () => setState(() => _d = _d > 1 ? _d - 1 : 30)),
              const SizedBox(width: 8),
              _stepper('الشهر', widget.months[_m - 1],
                  () => setState(() => _m = _m < 12 ? _m + 1 : 1),
                  () => setState(() => _m = _m > 1 ? _m - 1 : 12)),
              const SizedBox(width: 8),
              _stepper('السنة', _y.toString(),
                  () => setState(() => _y++),
                  () => setState(() => _y--)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                widget.onChanged(_y, _m, _d);
                Navigator.pop(context);
              },
              child: const Text('تأكيد'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepper(
      String label, String value, VoidCallback up, VoidCallback down) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          IconButton(
              onPressed: up,
              icon: const Icon(Icons.keyboard_arrow_up, color: _gold)),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ScheherazadeNew')),
          IconButton(
              onPressed: down,
              icon: const Icon(Icons.keyboard_arrow_down, color: _gold)),
        ],
      ),
    );
  }
}
