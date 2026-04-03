import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/providers/create_provider.dart';
import 'package:storycoe_flutter/providers/books_provider.dart';

/// 生成朗读绘本进度页面
/// 显示上传结果，OCR 在后台异步处理
class GenerateProgressScreen extends ConsumerStatefulWidget {
  const GenerateProgressScreen({super.key});

  @override
  ConsumerState<GenerateProgressScreen> createState() =>
      _GenerateProgressScreenState();
}

class _GenerateProgressScreenState
    extends ConsumerState<GenerateProgressScreen> {
  @override
  void initState() {
    super.initState();
    // 刷新书籍列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(booksProvider.notifier).loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createProvider);
    final error = createState.error;
    final bookId = createState.generatedBookId;

    // 上传成功
    final isSuccess = bookId != null && error == null;

    // 上传失败
    final isFailed = error != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // 状态图标
              _buildStatusIcon(isSuccess, isFailed),

              const SizedBox(height: 32),

              // 状态消息
              _buildStatusMessage(isSuccess, isFailed, error),

              const Spacer(),

              // 提示卡片
              _buildTipCard(isSuccess),

              const SizedBox(height: 24),

              // 按钮区域
              _buildButtons(isSuccess, isFailed, bookId),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isSuccess, bool isFailed) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    if (isSuccess) {
      icon = LucideIcons.check;
      iconColor = Colors.white;
      bgColor = AppColors.tertiaryContainer;
    } else if (isFailed) {
      icon = LucideIcons.x;
      iconColor = Colors.white;
      bgColor = AppColors.error;
    } else {
      icon = LucideIcons.loader2;
      iconColor = AppColors.onPrimaryFixed;
      bgColor = AppColors.surfaceContainerLow;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 48,
        color: iconColor,
      ),
    );
  }

  Widget _buildStatusMessage(bool isSuccess, bool isFailed, String? error) {
    String title;
    String subtitle;

    if (isSuccess) {
      title = '上传成功！';
      subtitle = '图片正在后台处理中，请稍后在绘本架查看';
    } else if (isFailed) {
      title = '上传失败';
      subtitle = error ?? '请稍后重试';
    } else {
      title = '正在上传...';
      subtitle = '请稍候';
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.onPrimaryFixed,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isFailed ? AppColors.error : AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTipCard(bool isSuccess) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.lightbulb,
              size: 24,
              color: AppColors.onPrimaryFixed,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              '文字识别需要一些时间，您可以先去探索其他内容，稍后回来查看',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onPrimaryFixed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(bool isSuccess, bool isFailed, String? bookId) {
    // 主按钮
    final primaryButton = ElevatedButton(
      onPressed: () {
        if (isSuccess || isFailed) {
          ref.read(createProvider.notifier).resetAll();
        }
        context.go('/home');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSuccess
            ? AppColors.secondaryContainer
            : AppColors.surfaceContainerLow,
        foregroundColor: isSuccess
            ? AppColors.onSecondaryContainer
            : AppColors.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSuccess ? LucideIcons.home : LucideIcons.arrowLeft, size: 20),
          const SizedBox(width: 8),
          Text(
            isSuccess ? '返回首页' : '返回',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    // 失败时显示重试按钮
    if (isFailed) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(createProvider.notifier).clearError();
                context.go('/create');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: AppColors.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.refreshCw, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '重新尝试',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: primaryButton,
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: primaryButton,
    );
  }
}