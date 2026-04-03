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
import 'package:storycoe_flutter/widgets/common/progress_bar.dart';
import 'package:storycoe_flutter/widgets/stat_card.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksListProvider);
    final user = ref.watch(userProfileProvider);
    final avatarTimestamp = ref.watch(avatarTimestampProvider);
    final lastBook = books.isNotEmpty ? books.first : null;

    return Scaffold(
      bottomNavigationBar: const BottomNav(currentLocation: '/home'),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    SizedBox(height: 4),
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
            const SizedBox(height: 40),

            // Continue reading card
            if (lastBook != null)
              GestureDetector(
                onTap: () {
                  ref
                      .read(readingProvider.notifier)
                      .startReading(lastBook);
                  context.go('/reading/${lastBook.id}');
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    boxShadow: AppColors.gummyShadowBlue,
                  ),
                  child: Row(
                    children: [
                      // Book cover
                      Container(
                        width: 96,
                        height: 128,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.gummyShadowBlue,
                        ),
                        transform: Matrix4.rotationZ(-0.05),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppImage(
                            image: lastBook.image,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: AppColors.surfaceContainerHigh,
                              child: const Icon(LucideIcons.bookOpen),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '继续阅读',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.onPrimaryFixed.withValues(
                                  alpha: 0.6,
                                ),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastBook.title,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.onPrimaryFixed,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ProgressBar(
                                    progress: lastBook.progress / 100,
                                    backgroundColor: Colors.white
                                        .withValues(alpha: 0.2),
                                    progressColor: Colors.white,
                                    height: 8,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${lastBook.progress}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.onPrimaryFixed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          LucideIcons.play,
                          size: 24,
                          color: AppColors.onPrimaryFixed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: LucideIcons.star,
                    value: '${user?.stars ?? 24}',
                    label: '成就星星',
                    iconBackgroundColor:
                        AppColors.tertiaryContainer.withValues(alpha: 0.2),
                    iconColor: AppColors.onTertiaryContainer,
                    shadowColor: AppColors.tertiaryContainer,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    icon: LucideIcons.flame,
                    value: '${user?.streak ?? 5}',
                    label: '阅读坚持',
                    iconBackgroundColor:
                        AppColors.secondaryContainer.withValues(alpha: 0.2),
                    iconColor: AppColors.onSecondaryContainer,
                    shadowColor: AppColors.secondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Book shelf header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.gummyShadowBlue,
                      ),
                      child: const Icon(
                        LucideIcons.search,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.gummyShadowBlue,
                      ),
                      child: const Icon(
                        LucideIcons.filter,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Book grid - 使用新版书架组件（3列布局）
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
            const SizedBox(height: 40),

            // Challenge card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: AppColors.gummyShadowPurple,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.flame,
                                size: 16,
                                color: AppColors.onTertiaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '今日挑战',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.onTertiaryContainer,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '词汇大冲关',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: AppColors.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '完成3本绘本朗读，\n解锁神秘礼包！',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onTertiaryContainer,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                AppColors.onTertiaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '立即参加',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gift icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      LucideIcons.gift,
                      size: 48,
                      color: AppColors.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
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