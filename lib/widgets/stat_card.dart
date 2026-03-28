import 'package:flutter/material.dart';
import 'package:storybird_flutter/core/theme/app_colors.dart';
import 'package:storybird_flutter/core/theme/app_theme.dart';

/// Stat card widget for displaying user statistics
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color? shadowColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: shadowColor == AppColors.tertiaryContainer
            ? AppColors.gummyShadowPurple
            : AppColors.gummyShadowCoral,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}