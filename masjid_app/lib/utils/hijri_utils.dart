import 'dart:math';

class HijriDate {
  final int year;
  final int month;
  final int day;

  const HijriDate({required this.year, required this.month, required this.day});

  static HijriDate fromGregorian(DateTime date) {
    final jdn = _toJdn(date.year, date.month, date.day);
    return _fromJdn(jdn);
  }

  static HijriDate now() => fromGregorian(DateTime.now());

  static int _toJdn(int y, int m, int d) {
    return (1461 * (y + 4800 + (m - 14) ~/ 12)) ~/ 4 +
        (367 * (m - 2 - 12 * ((m - 14) ~/ 12))) ~/ 12 -
        (3 * ((y + 4900 + (m - 14) ~/ 12) ~/ 100)) ~/ 4 +
        d - 32075;
  }

  static HijriDate _fromJdn(int jdn) {
    final l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    final l2 = l - 10631 * n + 354;
    final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
        (l2 ~/ 5670) * ((43 * l2) ~/ 15238);
    final l3 = l2 - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    final m = (24 * l3) ~/ 709;
    final d = l3 - (709 * m) ~/ 24;
    final y = 30 * n + j - 30;
    return HijriDate(year: y, month: m, day: d);
  }

  // Convert this Hijri date back to Gregorian
  DateTime toGregorian() {
    final jdn = (11 * year + 3) ~/ 30 +
        354 * year +
        30 * month -
        (month - 1) ~/ 2 +
        day +
        1948440 -
        385;
    return _jdnToGregorian(jdn);
  }

  static DateTime _jdnToGregorian(int jdn) {
    final l = jdn + 68569;
    final n = (4 * l) ~/ 146097;
    final l2 = l - (146097 * n + 3) ~/ 4;
    final i = (4000 * (l2 + 1)) ~/ 1461001;
    final l3 = l2 - (1461 * i) ~/ 4 + 31;
    final j = (80 * l3) ~/ 2447;
    final d = l3 - (2447 * j) ~/ 80;
    final l4 = j ~/ 11;
    final m = j + 2 - 12 * l4;
    final y = 100 * (n - 49) + i + l4;
    return DateTime(y, m, d);
  }

  /// Returns 0=Sunday … 6=Saturday for the first day of (year, month)
  int firstWeekdayOfMonth() {
    final d = HijriDate(year: year, month: month, day: 1).toGregorian();
    return d.weekday % 7;
  }

  int daysInMonth() {
    if (month % 2 == 1) return 30;
    if (month == 12 && _isLeapYear(year)) return 30;
    return 29;
  }

  static bool _isLeapYear(int y) => (y * 11 + 14) % 30 < 11;

  String get longMonthName => _monthNames[month - 1];
  String get monthNameAr => _monthNamesAr[month - 1];

  static const List<String> _monthNames = [
    'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani",
    'Jumada al-Ula', 'Jumada al-Thani', 'Rajab', "Sha'ban",
    'Ramadan', 'Shawwal', "Dhul Qi'dah", 'Dhul Hijjah',
  ];

  static const List<String> _monthNamesAr = [
    'المحرم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
    'جمادى الأولى', 'جمادى الثانية', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];
}
