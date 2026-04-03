import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/providers/create_provider.dart';

/// Bottom navigation bar widget
class BottomNav extends ConsumerWidget {
  final String currentLocation;

  const BottomNav({
    super.key,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGenerating = ref.watch(isGeneratingProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryContainer.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: LucideIcons.home,
                label: '首页',
                isSelected: currentLocation == '/home' || currentLocation.startsWith('/reading'),
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: LucideIcons.compass,
                label: '探索',
                isSelected: currentLocation == '/explore',
                onTap: () => context.go('/explore'),
              ),
              _NavItem(
                icon: LucideIcons.edit3,
                label: '创作',
                isSelected: currentLocation == '/create' || currentLocation == '/create/progress',
                onTap: () {
                  // 如果正在生成，跳转到进度页面；否则跳转到创作页面
                  if (isGenerating) {
                    context.go('/create/progress');
                  } else {
                    context.go('/create');
                  }
                },
              ),
              _NavItem(
                icon: LucideIcons.user,
                label: '我的',
                isSelected: currentLocation == '/profile',
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.onPrimaryFixed
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.onPrimaryFixed
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}