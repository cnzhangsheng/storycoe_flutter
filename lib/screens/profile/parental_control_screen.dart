import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';

/// ========================================
/// 家长中心页面
/// ========================================
class ParentalControlScreen extends ConsumerStatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  ConsumerState<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends ConsumerState<ParentalControlScreen> {
  // 设置项
  bool _readingTimeLimit = false;
  int _maxReadingMinutes = 30;
  bool _contentFilter = true;
  bool _pinEnabled = false;
  String _pin = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text(
          '家长中心',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.tertiaryContainer,
        foregroundColor: AppColors.onTertiaryContainer,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 提示信息
            _buildInfoCard(),

            const SizedBox(height: 24),

            // 阅读时长限制
            _buildSectionTitle('阅读时长管理', LucideIcons.clock),
            const SizedBox(height: 12),
            _buildReadingTimeCard(),

            const SizedBox(height: 24),

            // 内容过滤
            _buildSectionTitle('内容安全', LucideIcons.shield),
            const SizedBox(height: 12),
            _buildContentFilterCard(),

            const SizedBox(height: 24),

            // 家长控制 PIN
            _buildSectionTitle('家长控制', LucideIcons.lock),
            const SizedBox(height: 12),
            _buildPinCard(),

            const SizedBox(height: 24),

            // 账户管理
            _buildSectionTitle('账户管理', LucideIcons.user),
            const SizedBox(height: 12),
            _buildAccountCard(),
          ],
        ),
      ),
    );
  }

  /// 信息提示卡片
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.info,
            color: AppColors.primaryContainer,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '家长中心可以帮助您管理孩子的阅读体验，保护孩子的健康阅读。',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 分类标题
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.onTertiaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onPrimaryFixed,
          ),
        ),
      ],
    );
  }

  /// 阅读时长卡片
  Widget _buildReadingTimeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 阅读时长限制开关
          _buildSwitchTile(
            icon: LucideIcons.timer,
            title: '阅读时长限制',
            subtitle: '限制每日阅读时间',
            value: _readingTimeLimit,
            onChanged: (value) {
              setState(() {
                _readingTimeLimit = value;
              });
            },
          ),

          // 时长选择
          if (_readingTimeLimit) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '每日最大阅读时长：',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _maxReadingMinutes,
                      underline: const SizedBox(),
                      items: [15, 30, 45, 60, 90, 120].map((minutes) {
                        return DropdownMenuItem(
                          value: minutes,
                          child: Text('$minutes 分钟'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _maxReadingMinutes = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 内容过滤卡片
  Widget _buildContentFilterCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildSwitchTile(
        icon: LucideIcons.filter,
        title: '内容过滤',
        subtitle: '自动过滤不适合儿童的内容',
        value: _contentFilter,
        onChanged: (value) {
          setState(() {
            _contentFilter = value;
          });
        },
      ),
    );
  }

  /// PIN 码卡片
  Widget _buildPinCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: LucideIcons.key,
            title: '家长 PIN 码',
            subtitle: '设置 PIN 码保护家长设置',
            value: _pinEnabled,
            onChanged: (value) async {
              if (value) {
                // 显示设置 PIN 码对话框
                final pin = await _showPinDialog();
                if (pin != null && pin.length == 4) {
                  setState(() {
                    _pinEnabled = true;
                    _pin = pin;
                  });
                }
              } else {
                setState(() {
                  _pinEnabled = false;
                  _pin = '';
                });
              }
            },
          ),
          if (_pinEnabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    color: AppColors.tertiaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PIN 码已设置',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final pin = await _showPinDialog();
                      if (pin != null && pin.length == 4) {
                        setState(() {
                          _pin = pin;
                        });
                      }
                    },
                    child: const Text('修改'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 账户管理卡片
  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: LucideIcons.userCircle,
            title: '孩子信息',
            subtitle: '管理孩子的个人信息',
            onTap: () {
              _showComingSoonDialog('孩子信息管理');
            },
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: LucideIcons.history,
            title: '阅读历史',
            subtitle: '查看孩子的阅读记录',
            onTap: () {
              _showComingSoonDialog('阅读历史');
            },
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: LucideIcons.barChart3,
            title: '阅读统计',
            subtitle: '查看阅读数据和报告',
            onTap: () {
              _showComingSoonDialog('阅读统计');
            },
          ),
        ],
      ),
    );
  }

  /// 开关项
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.tertiaryContainer,
          ),
        ],
      ),
    );
  }

  /// 菜单项
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: AppColors.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// 显示 PIN 码设置对话框
  Future<String?> _showPinDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('设置 PIN 码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请输入 4 位数字 PIN 码'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 16,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '••••',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 显示即将推出对话框
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$feature功能'),
          content: const Text('该功能即将推出，敬请期待！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }
}