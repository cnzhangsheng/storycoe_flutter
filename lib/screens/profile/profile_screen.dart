import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storybird_flutter/core/theme/app_colors.dart';
import 'package:storybird_flutter/core/theme/app_theme.dart';
import 'package:storybird_flutter/providers/auth_provider.dart';
import 'package:storybird_flutter/providers/user_settings_provider.dart';
import 'package:storybird_flutter/widgets/common/app_image.dart';
import 'package:storybird_flutter/widgets/common/bottom_nav.dart';

/// Profile screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final settings = ref.watch(userSettingsProvider);

    return Scaffold(
      bottomNavigationBar: const BottomNav(currentLocation: '/profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: 32,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: Column(
          children: [
            // Profile header card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: AppColors.gummyShadowBlue,
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        transform: Matrix4.rotationZ(0.05),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL - 6,
                          ),
                          child: AppImage(
                            image: user?.avatar ?? '',
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: AppColors.surfaceContainerHigh,
                              child: const Icon(LucideIcons.user),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryContainer,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.edit2,
                            size: 16,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    user?.name ?? 'Lily 小象',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onPrimaryFixed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lv.${user?.level ?? 3} 森林探索者',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryFixed.withValues(alpha: 0.7),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${user?.booksRead ?? 12}',
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.onPrimaryFixed,
                                ),
                              ),
                              Text(
                                '已读绘本',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimaryFixed
                                      .withValues(alpha: 0.6),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${user?.stars ?? 156}',
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.onPrimaryFixed,
                                ),
                              ),
                              Text(
                                '累计星星',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimaryFixed
                                      .withValues(alpha: 0.6),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Reading speed setting
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: AppColors.gummyShadowPurple,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.settings,
                          size: 20,
                          color: AppColors.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '阅读语速',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '当前：${settings.speedLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: ['慢', '中', '快'].map((speed) {
                        final isSelected = settings.speedLabel == speed;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(userSettingsProvider.notifier)
                                  .setSpeed(speed);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.tertiaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow:
                                    isSelected ? AppColors.gummyShadowPurple : null,
                              ),
                              child: Text(
                                speed,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.onTertiaryContainer
                                      : AppColors.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pronunciation setting
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: AppColors.gummyShadowCoral,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.volume2,
                          size: 20,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '发音习惯',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(userSettingsProvider.notifier)
                                .setAccent('US');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: settings.accent == 'US'
                                  ? AppColors.secondaryContainer
                                      .withValues(alpha: 0.05)
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: settings.accent == 'US'
                                    ? AppColors.secondaryContainer
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: settings.accent == 'US'
                                  ? AppColors.gummyShadowCoral
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '美式发音',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: settings.accent == 'US'
                                        ? AppColors.onSecondaryContainer
                                        : AppColors.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  'US Accent',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: settings.accent == 'US'
                                        ? AppColors.onSecondaryContainer
                                            .withValues(alpha: 0.6)
                                        : AppColors.onSurfaceVariant
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(userSettingsProvider.notifier)
                                .setAccent('UK');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: settings.accent == 'UK'
                                  ? AppColors.secondaryContainer
                                      .withValues(alpha: 0.05)
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: settings.accent == 'UK'
                                    ? AppColors.secondaryContainer
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '英式发音',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: settings.accent == 'UK'
                                        ? AppColors.onSecondaryContainer
                                        : AppColors.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  'UK Accent',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: settings.accent == 'UK'
                                        ? AppColors.onSecondaryContainer
                                            .withValues(alpha: 0.6)
                                        : AppColors.onSurfaceVariant
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Loop toggle
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: AppColors.gummyShadowBlue,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          AppColors.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.star,
                      size: 24,
                      color: AppColors.onPrimaryFixed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '单句循环',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '开启后绘本单句将重复播放',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.loopEnabled,
                    onChanged: (value) {
                      ref
                          .read(userSettingsProvider.notifier)
                          .toggleLoop();
                    },
                    activeTrackColor: AppColors.primaryContainer,
                    activeThumbColor: AppColors.onPrimaryContainer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            ...[
              _buildActionTile(
                icon: LucideIcons.users,
                label: '家长中心',
                color: AppColors.onTertiaryContainer,
                bgColor: AppColors.tertiaryContainer.withValues(alpha: 0.1),
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: LucideIcons.helpCircle,
                label: '帮助与反馈',
                color: AppColors.onSurfaceVariant,
                bgColor: AppColors.surfaceContainerLow,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: LucideIcons.logOut,
                label: '退出登录',
                color: AppColors.error,
                bgColor: AppColors.errorContainer.withValues(alpha: 0.05),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ],
            const SizedBox(height: 24),

            // Version info
            Center(
              child: Text(
                'StoryBird v1.0.0',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: color.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}