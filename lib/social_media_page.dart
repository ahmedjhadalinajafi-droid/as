import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'islamic_background.dart';

class SocialMediaPage extends StatelessWidget {
  const SocialMediaPage({super.key});

  static const _navy = Color(0xFF1B3D6F);
  static const _gold = Color(0xFFC9A843);

  static const _platforms = [
    _PlatformData(
      name: 'فيسبوك',
      nameEn: 'Facebook',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
      handle: '@masjidahlalbait.baghdad',
      url: 'https://facebook.com/masjidahlalbait.baghdad',
      description: 'تابعونا للإعلانات اليومية وأوقات الفعاليات',
      buttonLabel: 'تابع',
    ),
    _PlatformData(
      name: 'يوتيوب',
      nameEn: 'YouTube',
      icon: Icons.smart_display_rounded,
      color: Color(0xFFFF0000),
      handle: '@MasjidAhlAlBaitBaghdad',
      url: 'https://youtube.com/@MasjidAhlAlBaitBaghdad',
      description: 'خطب الجمعة والمحاضرات الدينية والمناسبات',
      buttonLabel: 'اشترك',
    ),
    _PlatformData(
      name: 'تيليغرام',
      nameEn: 'Telegram',
      icon: Icons.send_rounded,
      color: Color(0xFF0088CC),
      handle: 't.me/masjidahlalbait',
      url: 'https://t.me/masjidahlalbait',
      description: 'أوقات الصلاة والأدعية اليومية والإشعارات',
      buttonLabel: 'انضم',
    ),
    _PlatformData(
      name: 'واتساب',
      nameEn: 'WhatsApp',
      icon: Icons.chat_bubble_rounded,
      color: Color(0xFF25D366),
      handle: '+964 770 000 0000',
      url: 'https://wa.me/9647700000000',
      description: 'للتواصل المباشر مع الإدارة والاستفسارات',
      buttonLabel: 'راسل',
    ),
    _PlatformData(
      name: 'انستغرام',
      nameEn: 'Instagram',
      icon: Icons.photo_camera_rounded,
      color: Color(0xFFE1306C),
      handle: '@masjid_ahlalbait_bg',
      url: 'https://instagram.com/masjid_ahlalbait_bg',
      description: 'صور الفعاليات والمناسبات الدينية',
      buttonLabel: 'تابع',
    ),
    _PlatformData(
      name: 'تويتر / X',
      nameEn: 'X (Twitter)',
      icon: Icons.alternate_email_rounded,
      color: Color(0xFF14171A),
      handle: '@MasjidAhlAlBait_BG',
      url: 'https://x.com/MasjidAhlAlBait_BG',
      description: 'آخر الأخبار والتحديثات السريعة',
      buttonLabel: 'تابع',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return IslamicPatternBackground(
      child: Scaffold( backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Collapsible header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            title: const Text('تواصل معنا'),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_navy, Color(0xFF2A5BA8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -30, right: -30,
                    child: Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20, left: -20,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gold.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                                color: _gold.withOpacity(0.5), width: 1.5),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 44,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.mosque, size: 36, color: _gold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'مسجد وحسينية أهل البيت ع',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ScheherazadeNew',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: _gold.withOpacity(0.5)),
                          ),
                          child: const Text(
                            'بغداد — المنصور',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 13,
                              fontFamily: 'ScheherazadeNew',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'منصات التواصل الاجتماعي',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _navy,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Platform cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) =>
                    _PlatformCard(platform: _platforms[i], isDark: isDark),
                childCount: _platforms.length,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ─── Platform Data ────────────────────────────────────────────────────────────

class _PlatformData {
  final String name;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String handle;
  final String url;
  final String description;
  final String buttonLabel;

  const _PlatformData({
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.handle,
    required this.url,
    required this.description,
    required this.buttonLabel,
  });
}

// ─── Platform Card ────────────────────────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  final _PlatformData platform;
  final bool isDark;

  const _PlatformCard({required this.platform, required this.isDark});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(platform.url);
    if (uri != null) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }
    // Fallback — copy handle to clipboard
    if (!context.mounted) return;
    Clipboard.setData(ClipboardData(text: platform.handle));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ ${platform.handle}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E2D4A) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: platform.color.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: platform.color.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Platform icon
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: platform.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(platform.icon,
                      color: platform.color, size: 28),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            platform.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1B3D6F),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            platform.nameEn,
                            style: TextStyle(
                              fontSize: 11,
                              color: platform.color.withOpacity(0.7),
                              fontFamily: 'sans-serif',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        platform.handle,
                        style: TextStyle(
                          fontSize: 12,
                          color: platform.color,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        platform.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Follow button
                GestureDetector(
                  onTap: () => _open(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: platform.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      platform.buttonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
