import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/providers/auth_provider.dart';
import 'package:storycoe_flutter/providers/books_provider.dart';
import 'package:storycoe_flutter/providers/reading_provider.dart';
import 'package:storycoe_flutter/widgets/bookshelf/book_cover_item.dart';
import 'package:storycoe_flutter/widgets/common/app_image.dart';
import 'package:storycoe_flutter/widgets/common/bottom_nav.dart';

/// Home screen
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 恢复默认屏幕方向（允许所有方向）
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 首次进入时刷新书籍列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(booksProvider.notifier).loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksListProvider);
    final isLoading = ref.watch(booksLoadingProvider);
    final user = ref.watch(userProfileProvider);
    final avatarTimestamp = ref.watch(avatarTimestampProvider);

    return Scaffold(
      bottomNavigationBar: const BottomNav(currentLocation: '/home'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(booksProvider.notifier).loadBooks(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '你好，${user?.name ?? '小读者'}！',
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
                          '开启今日奇妙旅程',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: AppColors.gummyShadowBlue,
                        ),
                        transform: Matrix4.rotationZ(0.05),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppImage(
                            image: user?.avatar ?? '',
                            fit: BoxFit.cover,
                            cacheBuster: avatarTimestamp,
                            errorWidget: Container(
                              color: AppColors.surfaceContainerHigh,
                              child: const Icon(LucideIcons.user),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Book shelf header
                Text(
                  '我的绘本架',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.onPrimaryFixed,
                  ),
                ),
                const SizedBox(height: 24),

                // Book grid
                if (books.isEmpty)
                  _buildEmptyBookShelf(context)
                else
                  BookshelfGrid(
                    books: books,
                    onBookTap: (book) {
                      ref.read(readingProvider.notifier).startReading(book);
                      context.go('/reading/${book.id}');
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBookShelf(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.gummyShadowBlue,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              LucideIcons.bookOpen,
              size: 40,
              color: AppColors.onPrimaryFixed,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '绘本架空空如也',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimaryFixed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '去创作你的第一本绘本吧！',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryContainer,
              foregroundColor: AppColors.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.plus, size: 20),
                SizedBox(width: 8),
                Text(
                  '创作绘本',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}