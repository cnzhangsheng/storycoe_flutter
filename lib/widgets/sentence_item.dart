import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/models/sentence.dart';
import 'package:storycoe_flutter/providers/reading_provider.dart';

/// 句子项组件
/// 显示英文句子和中文翻译，支持播放/暂停
class SentenceItem extends ConsumerWidget {
  final Sentence sentence;
  final bool isActive;
  final bool showTranslation;
  final VoidCallback? onTap;

  const SentenceItem({
    super.key,
    required this.sentence,
    required this.isActive,
    required this.showTranslation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final isThisPlaying = isActive && isPlaying;

    return GestureDetector(
      onTap: onTap ??
          () {
            // 默认行为：切换播放/暂停
            ref.read(readingProvider.notifier).togglePlayPause(sentence);
          },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(isActive ? 32 : 24),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          boxShadow: isActive ? AppColors.gummyShadowBlue : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 播放/暂停按钮
            _buildPlayButton(isThisPlaying),
            const SizedBox(width: 16),
            // 文本内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 英文句子
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: isActive ? 24 : 20,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      color: isActive
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    child: Text(sentence.en),
                  ),
                  // 中文翻译
                  if (showTranslation && sentence.zh.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTranslation(isActive),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(bool isPlaying) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 56 : 48,
      height: isActive ? 56 : 48,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.secondaryContainer
            : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(isActive ? 28 : 24),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        isPlaying ? LucideIcons.pause : LucideIcons.play,
        size: 24,
        color: isActive
            ? AppColors.onSecondaryContainer
            : AppColors.onPrimaryContainer,
      ),
    );
  }

  Widget _buildTranslation(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: isActive
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.lightbulb,
            size: 16,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              sentence.zh,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}