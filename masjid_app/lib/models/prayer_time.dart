class PrayerTimeModel {
  final String name;
  final String arabicName;
  final DateTime time;
  final bool isNext;
  final bool isCurrent;

  const PrayerTimeModel({
    required this.name,
    required this.arabicName,
    required this.time,
    this.isNext = false,
    this.isCurrent = false,
  });
}
