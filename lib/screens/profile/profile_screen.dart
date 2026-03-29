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

/// ========================================
/// 我的页面 - 儿童化设计
/// ========================================
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      bottomNavigationBar: const BottomNav(currentLocation: '/profile'),
      body: Stack(
        children: [
          // 背景装饰
          _buildBackgroundDecoration(),

          // 内容
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 48,
              left: 24,
              right: 24,
              bottom: 100,
            ),
            child: Column(
              children: [
                // 标题
                _buildTitle(),

                const SizedBox(height: 32),

                // 用户卡片 - 童趣设计
                _buildUserCard(user),

                const SizedBox(height: 32),

                // 成就展示
                _buildAchievementsSection(user),

                const SizedBox(height: 32),

                // 功能菜单 - 卡片式设计
                _buildMenuSection(),

                const SizedBox(height: 24),

                // 版本信息
                _buildVersionInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ========================================
  /// 背景装饰 - 云朵图案
  /// ========================================
  Widget _buildBackgroundDecoration() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CloudBackgroundPainter(),
      ),
    );
  }

  /// ========================================
  /// 页面标题
  /// ========================================
  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryContainer,
                AppColors.primaryContainer.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.sparkles,
                size: 20,
                color: AppColors.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              const Text(
                '我的小世界',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ========================================
  /// 用户卡片 - 童趣风格
  /// ========================================
  Widget _buildUserCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.surfaceContainerLow,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 8,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头像区域 - 可爱的圆角设计
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 头像外框 - 彩虹边框效果
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryContainer,
                      AppColors.secondaryContainer,
                      AppColors.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AppImage(
                      image: user?.avatar ?? '',
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: AppColors.surfaceContainerHigh,
                        child: Center(
                          child: Icon(
                            LucideIcons.smile,
                            size: 48,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 等级徽章 - 星星装饰
              Positioned(
                bottom: -8,
                right: -8,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondaryContainer,
                        AppColors.secondaryContainer.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Lv.${user?.level ?? 3}',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 用户名称 - 大字体儿童风格
          Text(
            user?.name ?? 'Lily 小象',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.onPrimaryFixed,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 6),

          // 身份标签 - 有趣的称号
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryContainer.withValues(alpha: 0.1),
                  AppColors.secondaryContainer.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.trees,
                  size: 16,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  '森林探索者',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ========================================
  /// 成就展示 - 可爱的统计卡片
  /// ========================================
  Widget _buildAchievementsSection(dynamic user) {
    return Column(
      children: [
        // 标题
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                LucideIcons.trophy,
                size: 20,
                color: AppColors.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '我的成就',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 成就卡片网格
        Row(
          children: [
            Expanded(
              child: _buildAchievementCard(
                icon: LucideIcons.bookOpen,
                value: '${user?.booksRead ?? 12}',
                label: '已读绘本',
                color: AppColors.primaryContainer,
                bgColor: AppColors.primaryContainer.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAchievementCard(
                icon: LucideIcons.star,
                value: '${user?.stars ?? 156}',
                label: '累计星星',
                color: AppColors.secondaryContainer,
                bgColor: AppColors.secondaryContainer.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAchievementCard(
                icon: LucideIcons.flame,
                value: '${user?.streak ?? 30}',
                label: '连续天数',
                color: AppColors.tertiaryContainer,
                bgColor: AppColors.tertiaryContainer.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 成就卡片
  Widget _buildAchievementCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 图标
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),

          const SizedBox(height: 12),

          // 数值
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          // 标签
          Text(
            label,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// ========================================
  /// 功能菜单 - 童趣卡片设计
  /// ========================================
  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuTile(
          icon: LucideIcons.shield,
          label: '家长中心',
          description: '管理孩子账户与设置',
          color: AppColors.tertiaryContainer,
          bgColor: AppColors.tertiaryContainer.withValues(alpha: 0.08),
          onTap: () {},
        ),

        const SizedBox(height: 16),

        _buildMenuTile(
          icon: LucideIcons.messageCircle,
          label: '帮助与反馈',
          description: '遇到问题？联系我们',
          color: AppColors.primaryContainer,
          bgColor: AppColors.primaryContainer.withValues(alpha: 0.08),
          onTap: () {},
        ),

        const SizedBox(height: 16),

        _buildMenuTile(
          icon: LucideIcons.logOut,
          label: '退出登录',
          description: '切换其他账户',
          color: AppColors.onSurfaceVariant,
          bgColor: AppColors.surfaceContainerLow,
          isLogout: true,
          onTap: () {
            ref.read(authProvider.notifier).logout();
            context.go('/login');
          },
        ),
      ],
    );
  }

  /// 菜单卡片
  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required Color bgColor,
    bool isLogout = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLogout
                ? AppColors.errorContainer.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 28,
                color: isLogout ? AppColors.error : color,
              ),
            ),

            const SizedBox(width: 16),

            // 标签和描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isLogout ? AppColors.error : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // 箭头
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: isLogout ? AppColors.error.withValues(alpha: 0.5) : color.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ========================================
  /// 版本信息
  /// ========================================
  Widget _buildVersionInfo() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.bird,
              size: 16,
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              'StoryBird v1.0.0',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ========================================
/// 云朵背景绘制器
/// ========================================
class _CloudBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // 绘制几个简单的云朵形状
    _drawCloud(canvas, size, paint, size.width * 0.15, size.height * 0.08, 40);
    _drawCloud(canvas, size, paint, size.width * 0.85, size.height * 0.12, 35);
    _drawCloud(canvas, size, paint, size.width * 0.5, size.height * 0.05, 30);
    _drawCloud(canvas, size, paint, size.width * 0.3, size.height * 0.15, 25);
    _drawCloud(canvas, size, paint, size.width * 0.7, size.height * 0.18, 28);
  }

  void _drawCloud(Canvas canvas, Size size, Paint paint, double x, double y, double radius) {
    // 简单的云朵形状（多个圆组合）
    canvas.drawCircle(Offset(x, y), radius, paint);
    canvas.drawCircle(Offset(x + radius * 0.8, y), radius * 0.7, paint);
    canvas.drawCircle(Offset(x - radius * 0.6, y + radius * 0.2), radius * 0.6, paint);
    canvas.drawCircle(Offset(x + radius * 0.3, y - radius * 0.3), radius * 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}