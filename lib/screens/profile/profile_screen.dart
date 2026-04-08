import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/providers/auth_provider.dart';
import 'package:storycoe_flutter/providers/user_settings_provider.dart';
import 'package:storycoe_flutter/services/api_service.dart';
import 'package:storycoe_flutter/widgets/common/app_image.dart';
import 'package:storycoe_flutter/widgets/common/bottom_nav.dart';

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
                // 用户卡片 - 童趣设计
                _buildUserCard(user),

                const SizedBox(height: 32),

                // 成就展示
                _buildAchievementsSection(user),

                const SizedBox(height: 32),

                // 功能菜单 - 卡片式设计
                _buildMenuSection(),
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
  /// 用户卡片 - 童趣风格（水平布局）
  /// ========================================
  Widget _buildUserCard(dynamic user) {
    // 获取头像时间戳用于强制刷新缓存
    final avatarTimestamp = ref.watch(avatarTimestampProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.surfaceContainerLow,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
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
      child: Row(
        children: [
          // 头像区域 - 左侧
          GestureDetector(
            onTap: () => _showAvatarOptions(user),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AppImage(
                        image: user?.avatar ?? '',
                        fit: BoxFit.cover,
                        cacheBuster: avatarTimestamp,
                        errorWidget: Container(
                          color: AppColors.surfaceContainerHigh,
                          child: Center(
                            child: Icon(
                              LucideIcons.smile,
                              size: 32,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 编辑图标覆盖层
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.camera,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3),
                            Text(
                              '更换',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 右侧信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名称 - 点击可编辑
                GestureDetector(
                  onTap: () => _showEditNameDialog(user),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          user?.name ?? 'Lily 小象',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onPrimaryFixed,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        LucideIcons.pencil,
                        size: 14,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 等级徽章 + 身份标签
                Row(
                  children: [
                    // 等级徽章
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondaryContainer,
                            AppColors.secondaryContainer.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
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

                    const SizedBox(width: 8),

                    // 身份标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryContainer.withValues(alpha: 0.1),
                            AppColors.secondaryContainer.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryContainer.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.trees,
                            size: 12,
                            color: AppColors.primaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '森林探索者',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryContainer,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
          onTap: () => context.push('/profile/parental'),
        ),

        const SizedBox(height: 16),

        _buildMenuTile(
          icon: LucideIcons.messageCircle,
          label: '帮助与反馈',
          description: '遇到问题？联系我们',
          color: AppColors.primaryContainer,
          bgColor: AppColors.primaryContainer.withValues(alpha: 0.08),
          onTap: () => context.push('/profile/help'),
        ),

        const SizedBox(height: 16),

        _buildMenuTile(
          icon: LucideIcons.logOut,
          label: '退出登录',
          description: '切换其他账户',
          color: AppColors.onSurfaceVariant,
          bgColor: AppColors.surfaceContainerLow,
          isLogout: true,
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            // GoRouter redirect 会自动导航到 /login
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
  /// 显示头像操作选项
  /// ========================================
  void _showAvatarOptions(dynamic user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '更换头像',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAvatarOption(
                      icon: LucideIcons.camera,
                      label: '拍照',
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUploadAvatar(ImageSource.camera);
                      },
                    ),
                    _buildAvatarOption(
                      icon: LucideIcons.image,
                      label: '相册',
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUploadAvatar(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 28,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// ========================================
  /// 选择并上传头像
  /// ========================================
  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile == null) return;

    try {
      // 显示加载提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在上传头像...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 读取图片数据
      final bytes = await pickedFile.readAsBytes();
      final filename = pickedFile.name;

      // 上传头像
      final response = await usersApi.uploadAvatar(
        filename: filename,
        bytes: bytes,
      );

      // 更新本地状态
      ref.read(authProvider.notifier).refreshProfile();
      // 更新头像时间戳，强制刷新缓存
      ref.read(avatarTimestampProvider.notifier).state =
          DateTime.now().millisecondsSinceEpoch.toString();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('头像更新成功'),
            backgroundColor: AppColors.primaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('上传头像失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// ========================================
  /// 显示编辑名字对话框
  /// ========================================
  void _showEditNameDialog(dynamic user) {
    final controller = TextEditingController(text: user?.name ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: AppColors.primaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('修改名字'),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: '请输入新名字',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryContainer,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                Navigator.pop(context);
                await _updateName(newName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  /// ========================================
  /// 更新用户名字
  /// ========================================
  Future<void> _updateName(String newName) async {
    try {
      await usersApi.updateProfile(name: newName);
      ref.read(authProvider.notifier).refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('名字更新成功'),
            backgroundColor: AppColors.primaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('更新名字失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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