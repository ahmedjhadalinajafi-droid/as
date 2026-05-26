import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/prayer_service.dart';
import '../../theme/app_theme.dart';
import 'prayer_time_editor.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final prayerService = context.watch<PrayerService>();
    final isDark = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Appearance'),
          _SettingCard(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: isDark ? AppTheme.gold : const Color(0xFFFFB300),
            title: isDark ? 'Dark Mode' : 'Light Mode',
            subtitle: 'Tap to switch to ${isDark ? 'light' : 'dark'} theme',
            trailing: Switch(
              value: isDark,
              onChanged: (_) => themeProvider.toggle(),
              activeColor: AppTheme.gold,
              activeTrackColor: AppTheme.navyBlue,
            ),
          ).animate().fadeIn(delay: 50.ms),

          const SizedBox(height: 20),
          _SectionHeader(title: 'Prayer Times'),
          _SettingCard(
            icon: prayerService.isManual
                ? Icons.edit_calendar_rounded
                : Icons.gps_fixed_rounded,
            iconColor: prayerService.isManual
                ? AppTheme.gold
                : const Color(0xFF4CAF50),
            title: prayerService.isManual ? 'Manual Prayer Times' : 'Auto (GPS)',
            subtitle: prayerService.isManual
                ? 'Times set manually — tap to edit'
                : 'Times calculated from your location',
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerTimeEditor()),
            ),
          ).animate().fadeIn(delay: 100.ms),

          if (prayerService.isManual)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () async {
                  await context.read<PrayerService>().switchToGps();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched to GPS-based prayer times'),
                        backgroundColor: AppTheme.navyBlue,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                label: const Text('Switch back to GPS'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.gold),
              ),
            ),

          const SizedBox(height: 20),
          _SectionHeader(title: 'About'),
          _SettingCard(
            icon: Icons.mosque_rounded,
            iconColor: AppTheme.navyBlue,
            title: 'Ahlul Bayt Mosque',
            subtitle: 'مسجد أهل البيت والحسينية\nBaghdad – Al-Mansour',
          ).animate().fadeIn(delay: 150.ms),

          _SettingCard(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.white38,
            title: 'App Version',
            subtitle: '1.0.0',
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.gold,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0D1F33),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
