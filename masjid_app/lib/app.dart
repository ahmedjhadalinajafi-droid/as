import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'navigation/main_nav.dart';
import 'providers/theme_provider.dart';
import 'services/proximity_service.dart';
import 'screens/ziyara/ziyara_screen.dart';

class MasjidApp extends StatelessWidget {
  const MasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'مسجد أهل البيت والحسينية',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProximityService>().startMonitoring(_onNearShrine);
    });
  }

  void _onNearShrine() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'أنت قريب من مرقد الإمام علي (ع)',
          style: TextStyle(color: AppTheme.gold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'You are near the Shrine of Imam Ali (AS)\nWould you like to read the Ziyara?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ZiyaraScreen()),
              );
            },
            child: const Text('Read Ziyara'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const MainNav();
}
