import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/prayer_service.dart';
import '../../theme/app_theme.dart';

class PrayerTimeEditor extends StatefulWidget {
  const PrayerTimeEditor({super.key});

  @override
  State<PrayerTimeEditor> createState() => _PrayerTimeEditorState();
}

class _PrayerTimeEditorState extends State<PrayerTimeEditor> {
  late List<TimeOfDay> _times;
  final _cityController = TextEditingController();
  bool _saving = false;

  static const List<IconData> _icons = [
    Icons.brightness_3_rounded,
    Icons.wb_twilight_rounded,
    Icons.wb_sunny_rounded,
    Icons.wb_cloudy_rounded,
    Icons.nights_stay_rounded,
    Icons.bedtime_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final service = context.read<PrayerService>();
    final rawTimes = service.currentRawTimes;
    _times = rawTimes
        .map((dt) => TimeOfDay(hour: dt.hour, minute: dt.minute))
        .toList();
    _cityController.text = service.cityName;
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.gold,
            onPrimary: Colors.black,
            surface: AppTheme.surfaceDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    final dateTimes = _times.map((t) {
      return DateTime(now.year, now.month, now.day, t.hour, t.minute);
    }).toList();

    await context.read<PrayerService>().saveManualTimes(
          dateTimes,
          _cityController.text.trim().isEmpty
              ? 'Manual'
              : _cityController.text.trim(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prayer times saved successfully'),
          backgroundColor: AppTheme.navyBlue,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Prayer Times'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.gold),
                  )
                : const Text('Save',
                    style: TextStyle(
                        color: AppTheme.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.navyBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.gold, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap any prayer time to change it. '
                    'These will override GPS-calculated times.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City / Mosque name',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              prefixIcon: Icon(Icons.location_city_rounded, color: AppTheme.gold),
            ),
            style: const TextStyle(color: Colors.white),
          ).animate().fadeIn(delay: 50.ms),

          const SizedBox(height: 20),
          ...List.generate(6, (i) {
            return _TimeRow(
              name: PrayerService.prayerNames[i],
              arabic: PrayerService.prayerArabic[i],
              icon: _icons[i],
              time: _times[i],
              onTap: () => _pickTime(i),
              index: i,
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Prayer Times',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String name;
  final String arabic;
  final IconData icon;
  final TimeOfDay time;
  final VoidCallback onTap;
  final int index;

  const _TimeRow({
    required this.name,
    required this.arabic,
    required this.icon,
    required this.time,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = time.format(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.navyBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.gold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(arabic,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.navyBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.gold.withOpacity(0.35)),
              ),
              child: Text(
                formatted,
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
