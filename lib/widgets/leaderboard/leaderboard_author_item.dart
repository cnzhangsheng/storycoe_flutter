import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/models/leaderboard.dart';
import 'package:storycoe_flutter/widgets/common/app_image.dart';

/// 排行榜作者卡片
class LeaderboardAuthorItem extends StatelessWidget {
  final LeaderboardAuthor author;
  final VoidCallback? onTap;
  final bool showRankBadge;

  const LeaderboardAuthorItem({
    super.key,
    required this.author,
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
          boxShadow: AppColors.gummyShadowCoral,
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
                  color: _getRankColor(author.rank),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getRankEmoji(author.rank),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // 头像
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2),
                color: AppColors.surfaceContainerHigh,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AppImage(
                  image: author.avatar ?? '',
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
                    child: Icon(
                      LucideIcons.user,
                      size: 24,
                      color: AppColors.onTertiaryContainer,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 名称和信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        author.name,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onPrimaryFixed,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Lv.${author.level}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.bookOpen,
                        size: 12,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${author.booksCreated}本',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        LucideIcons.heart,
                        size: 12,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        author.formattedShelfCount,
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