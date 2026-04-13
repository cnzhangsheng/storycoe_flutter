import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/models/leaderboard.dart';
import 'package:storycoe_flutter/widgets/leaderboard/leaderboard_book_item.dart';
import 'package:storycoe_flutter/widgets/leaderboard/leaderboard_author_item.dart';

/// 排行榜展示区域（首页/探索页用）
class LeaderboardSection extends StatelessWidget {
  final List<LeaderboardBook> hotBooks;
  final List<LeaderboardBook> newBooks;
  final List<LeaderboardAuthor> authors;
  final VoidCallback? onViewAllHotBooks;
  final VoidCallback? onViewAllNewBooks;
  final VoidCallback? onViewAllAuthors;
  final void Function(LeaderboardBook)? onBookTap;

  const LeaderboardSection({
    super.key,
    this.hotBooks = const [],
    this.newBooks = const [],
    this.authors = const [],
    this.onViewAllHotBooks,
    this.onViewAllNewBooks,
    this.onViewAllAuthors,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hotBooks.isEmpty && newBooks.isEmpty && authors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 热门绘本榜
        if (hotBooks.isNotEmpty)
          _LeaderboardCard(
            title: '🔥 热门绘本榜',
            onViewAll: onViewAllHotBooks,
            children: hotBooks.take(3).map((book) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LeaderboardBookItem(
                book: book,
                onTap: onBookTap != null ? () => onBookTap!(book) : null,
              ),
            )).toList(),
          ),

        const SizedBox(height: 16),

        // 新星绘本榜
        if (newBooks.isNotEmpty)
          _LeaderboardCard(
            title: '⭐ 新星绘本榜',
            onViewAll: onViewAllNewBooks,
            children: newBooks.take(3).map((book) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LeaderboardBookItem(
                book: book,
                onTap: onBookTap != null ? () => onBookTap!(book) : null,
              ),
            )).toList(),
          ),

        const SizedBox(height: 16),

        // 活跃作者榜
        if (authors.isNotEmpty)
          _LeaderboardCard(
            title: '👑 活跃作者榜',
            onViewAll: onViewAllAuthors,
            children: authors.take(3).map((author) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LeaderboardAuthorItem(author: author),
            )).toList(),
          ),
      ],
    );
  }
}

/// 排行榜卡片容器
class _LeaderboardCard extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final List<Widget> children;

  const _LeaderboardCard({
    required this.title,
    this.onViewAll,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppColors.gummyShadowBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimaryFixed,
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Row(
                    children: [
                      Text(
                        '查看全部',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 内容列表
          ...children,
        ],
      ),
    );
  }
}