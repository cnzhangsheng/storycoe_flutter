import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/models/leaderboard.dart';
import 'package:storycoe_flutter/widgets/common/app_image.dart';

/// 排行榜绘本卡片
class LeaderboardBookItem extends StatelessWidget {
  final LeaderboardBook book;
  final VoidCallback? onTap;
  final bool showRankBadge;

  const LeaderboardBookItem({
    super.key,
    required this.book,
    this.onTap,
    this.showRankBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: AppColors.gummyShadowBlue,
        ),
        child: Row(
          children: [
            // 排名徽章
            if (showRankBadge)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _getRankColor(book.rank),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getRankEmoji(book.rank),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // 封面图片
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSM - 2),
                child: AppImage(
                  image: book.coverImage ?? '',
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(
                      LucideIcons.bookOpen,
                      size: 24,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 标题和信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onPrimaryFixed,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LV.${book.level}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.eye,
                        size: 12,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        book.formattedReadCount,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 播放按钮
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                LucideIcons.play,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // 金色
      case 2:
        return const Color(0xFFC0C0C0); // 银色
      case 3:
        return const Color(0xFFCD7F32); // 铜色
      default:
        return AppColors.surfaceContainerHigh;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return rank.toString();
    }
  }
}