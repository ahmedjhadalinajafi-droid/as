import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AnimatedFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final int animationDelay;

  const AnimatedFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor = AppTheme.gold,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.surfaceDark, AppTheme.surfaceVariant]
                : [AppTheme.surfaceLight, AppTheme.surfaceVariantLight],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.gold.withOpacity(isDark ? 0.15 : 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0D1F33),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.95, 0.95), duration: 400.ms);
  }
}
