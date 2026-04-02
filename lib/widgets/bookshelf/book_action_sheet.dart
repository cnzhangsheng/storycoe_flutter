import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';

/// ========================================
/// 绘本操作面板 - 底部弹出
///
/// 功能：
/// - 编辑绘本
/// - 删除绘本
/// - 儿童化设计：柔和圆角、可爱图标
/// ========================================
class BookActionSheet {
  /// 显示操作面板
  static Future<String?> show({
    required BuildContext context,
    required String bookTitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BookActionSheetContent(
        bookTitle: bookTitle,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}

/// 操作面板内容
class _BookActionSheetContent extends StatelessWidget {
  final String bookTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookActionSheetContent({
    required this.bookTitle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽指示条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // 绘本名称
          Text(
            bookTitle,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.onPrimaryFixed,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 24),

          // 编辑按钮 - 蓝色卡片
          _ActionButton(
            icon: LucideIcons.pencil,
            label: '编辑绘本',
            description: '修改绘本名称',
            color: AppColors.primaryContainer,
            bgColor: AppColors.primaryContainer.withValues(alpha: 0.08),
            onTap: () {
              Navigator.pop(context, 'edit');
              onEdit();
            },
          ),

          const SizedBox(height: 16),

          // 删除按钮 - 红色卡片
          _ActionButton(
            icon: LucideIcons.trash2,
            label: '删除绘本',
            description: '绘本将永久消失',
            color: AppColors.error,
            bgColor: AppColors.errorContainer.withValues(alpha: 0.08),
            onTap: () {
              Navigator.pop(context, 'delete');
              onDelete();
            },
          ),

          const SizedBox(height: 24),

          // 取消按钮
          GestureDetector(
            onTap: () => Navigator.pop(context, 'cancel'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '取消',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 操作按钮卡片
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
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
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}