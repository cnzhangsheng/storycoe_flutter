import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/models/book.dart';
import 'package:storycoe_flutter/providers/explore_provider.dart';
import 'package:storycoe_flutter/providers/leaderboard_provider.dart';
import 'package:storycoe_flutter/providers/reading_provider.dart';
import 'package:storycoe_flutter/widgets/common/app_image.dart';
import 'package:storycoe_flutter/widgets/common/bottom_nav.dart';
import 'package:storycoe_flutter/widgets/leaderboard/leaderboard_section.dart';

/// 探索页面
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(exploreProvider.notifier).setSearchTerm(_searchController.text);
    });
    // 加载排行榜摘要数据
    ref.read(leaderboardProvider.notifier).loadSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedBooks = ref.watch(displayedBooksProvider);
    final hasMore = ref.watch(hasMoreBooksProvider);
    final isEmpty = ref.watch(filteredBooksEmptyProvider);
    final selectedLevel = ref.watch(exploreProvider).selectedLevel;

    return Scaffold(
      bottomNavigationBar: const BottomNav(currentLocation: '/explore'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // 页面标题
              const Text(
                '探索绘本世界',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.onPrimaryFixed,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '发现更多奇妙故事',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),

              // 排行榜区域
              Consumer(
                builder: (context, ref, child) {
                  final summary = ref.watch(leaderboardSummaryProvider);
                  return LeaderboardSection(
                    hotBooks: summary.hotBooks,
                    newBooks: summary.newBooks,
                    authors: summary.authors,
                    onViewAllHotBooks: () => context.go('/explore/leaderboard/hot'),
                    onViewAllNewBooks: () => context.go('/explore/leaderboard/new'),
                    onViewAllAuthors: () => context.go('/explore/leaderboard/authors'),
                    onBookTap: (lbBook) {
                      // 使用排行榜绘本数据跳转到阅读页
                      ref.read(readingProvider.notifier).startReadingById(lbBook.id);
                      context.go('/reading/${lbBook.id}');
                    },
                  );
                },
              ),
              const SizedBox(height: 32),

              // 搜索框
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  boxShadow: AppColors.gummyShadowBlue,
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '搜索绘本名称...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Icon(
                        LucideIcons.search,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 级别筛选按钮
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _LevelChip(
                      label: '全部级别',
                      isSelected: selectedLevel == null,
                      onTap: () => ref.read(exploreProvider.notifier).setLevel(null),
                    ),
                    const SizedBox(width: 12),
                    ...[1, 2, 3].map((level) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _LevelChip(
                            label: '级别 $level',
                            isSelected: selectedLevel == level,
                            onTap: () => ref.read(exploreProvider.notifier).setLevel(level),
                            isLevelButton: true,
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 绘本网格
              if (!isEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.75, // 3:4 比例
                  ),
                  itemCount: displayedBooks.length,
                  itemBuilder: (context, index) {
                    final book = displayedBooks[index];
                    return _ExploreBookCard(
                      book: book,
                      onTap: () {
                        ref.read(readingProvider.notifier).startReading(book);
                        context.go('/reading/${book.id}');
                      },
                    );
                  },
                ),

              // 加载更多按钮
              if (hasMore && !isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () =>
                          ref.read(exploreProvider.notifier).loadMore(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerLowest,
                        foregroundColor: AppColors.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '加载更多',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(LucideIcons.arrowRight, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

              // 空状态
              if (isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            LucideIcons.search,
                            size: 40,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '没有找到相关的绘本哦',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// 级别筛选按钮
class _LevelChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLevelButton;

  const _LevelChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isLevelButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLevelButton
                  ? AppColors.secondaryContainer
                  : AppColors.primaryContainer)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? (isLevelButton
                  ? AppColors.gummyShadowCoral
                  : AppColors.gummyShadowBlue)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (isLevelButton
                    ? AppColors.onSecondaryContainer
                    : AppColors.onPrimaryFixed)
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 探索绘本卡片
class _ExploreBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _ExploreBookCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                // 封面图片
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: AppColors.gummyShadowBlue,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG - 4),
                    child: AppImage(
                      image: book.image ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorWidget: Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(
                          LucideIcons.bookOpen,
                          size: 48,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),

                // NEW 标签
                if (book.isNew)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ),

                // 底部级别和播放按钮
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'LV.${book.level}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.play,
                          size: 16,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
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
          ),
        ],
      ),
    );
  }
}