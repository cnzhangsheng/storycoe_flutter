import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/models/leaderboard.dart';
import 'package:storycoe_flutter/providers/leaderboard_provider.dart';
import 'package:storycoe_flutter/providers/reading_provider.dart';
import 'package:storycoe_flutter/widgets/common/bottom_nav.dart';
import 'package:storycoe_flutter/widgets/leaderboard/leaderboard_book_item.dart';
import 'package:storycoe_flutter/widgets/leaderboard/leaderboard_author_item.dart';

/// 排行榜详情页面
class LeaderboardDetailScreen extends ConsumerStatefulWidget {
  final String type; // 'hot' | 'new' | 'authors'

  const LeaderboardDetailScreen({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<LeaderboardDetailScreen> createState() => _LeaderboardDetailScreenState();
}

class _LeaderboardDetailScreenState extends ConsumerState<LeaderboardDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final notifier = ref.read(leaderboardProvider.notifier);
    switch (widget.type) {
      case 'hot':
        notifier.loadHotBooks(limit: 50);
        break;
      case 'new':
        notifier.loadNewBooks(days: 7, limit: 50);
        break;
      case 'authors':
        notifier.loadAuthors(limit: 50);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(leaderboardLoadingProvider);
    final title = _getTitle();
    final icon = _getIcon();

    return Scaffold(
      bottomNavigationBar: const BottomNav(currentLocation: '/explore'),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/explore'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.gummyShadowBlue,
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        size: 20,
                        color: AppColors.onPrimaryFixed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onPrimaryFixed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 24,
                    color: AppColors.onPrimaryFixed,
                  ),
                ],
              ),
            ),

            // 排行榜列表
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryContainer,
                      ),
                    )
                  : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.type) {
      case 'hot':
        return '热门绘本榜';
      case 'new':
        return '新星绘本榜';
      case 'authors':
        return '活跃作者榜';
      default:
        return '排行榜';
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case 'hot':
        return LucideIcons.flame;
      case 'new':
        return LucideIcons.star;
      case 'authors':
        return LucideIcons.crown;
      default:
        return LucideIcons.trophy;
    }
  }

  Widget _buildList() {
    switch (widget.type) {
      case 'hot':
        final books = ref.watch(hotBooksProvider);
        return _buildBooksList(books);
      case 'new':
        final books = ref.watch(newBooksProvider);
        return _buildBooksList(books);
      case 'authors':
        final authors = ref.watch(leaderboardAuthorsProvider);
        return _buildAuthorsList(authors);
      default:
        return const Center(child: Text('未知排行榜类型'));
    }
  }

  Widget _buildBooksList(List<LeaderboardBook> books) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: 64,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无绘本数据',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LeaderboardBookItem(
            book: book,
            onTap: () {
              // 使用 startReadingById 直接根据 ID 加载绘本
              ref.read(readingProvider.notifier).startReadingById(book.id);
              context.go('/reading/${book.id}');
            },
          ),
        );
      },
    );
  }

  Widget _buildAuthorsList(List<LeaderboardAuthor> authors) {
    if (authors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.users,
              size: 64,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无作者数据',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: authors.length,
      itemBuilder: (context, index) {
        final author = authors[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LeaderboardAuthorItem(author: author),
        );
      },
    );
  }
}