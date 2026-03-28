import 'package:flutter/material.dart';
import 'package:storybird_flutter/core/theme/app_colors.dart';
import 'package:storybird_flutter/core/theme/app_theme.dart';

/// Gummy-style card with shadow
class GummyCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? shadowColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GummyCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.shadowColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppTheme.paddingMD),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: _getShadow(),
        ),
        child: child,
      ),
    );
  }

  List<BoxShadow> _getShadow() {
    if (shadowColor == AppColors.primaryContainer) {
      return AppColors.gummyShadowBlue;
    } else if (shadowColor == AppColors.secondaryContainer) {
      return AppColors.gummyShadowCoral;
    } else if (shadowColor == AppColors.tertiaryContainer) {
      return AppColors.gummyShadowPurple;
    }
    return AppColors.gummyShadowBlue;
  }
}