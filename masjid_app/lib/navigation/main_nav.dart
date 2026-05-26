import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/prayer_times/prayer_times_screen.dart';
import '../screens/quran/quran_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/settings/settings_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PrayerTimesScreen(),
    QuranScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppTheme.surfaceDark : AppTheme.navyBlue;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppTheme.gold.withOpacity(0.15)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                backgroundColor: Colors.transparent,
                selectedItemColor: AppTheme.gold,
                unselectedItemColor:
                    isDark ? Colors.white38 : Colors.white60,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 11,
                unselectedFontSize: 10,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.access_time_rounded),
                    label: 'Prayer',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book_rounded),
                    label: 'Quran',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'More',
                  ),
                ],
              ),
            ),
            // Settings icon on the right
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              color: AppTheme.gold,
              tooltip: 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}
