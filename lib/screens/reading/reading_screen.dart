import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:storybird_flutter/core/theme/app_colors.dart';
import 'package:storybird_flutter/models/sentence.dart';
import 'package:storybird_flutter/providers/reading_provider.dart';
import 'package:storybird_flutter/widgets/reading/sentence_read_item.dart';

/// ========================================
/// 绘本朗读详情页
///
/// 功能：
/// 1. 自动加载展示绘本第一页内容
/// 2. 英文句子按原文从上到下垂直排列
/// 3. 每个句子独立朗读按钮（播放/暂停/继续）
/// 4. 顶部显示绘本名称、页码标识
/// 5. 中间区域展示绘本大图，支持缩放、拖动
/// 6. 下方有序排列英文句子+朗读控件，可编辑修正
/// 7. 适配手机横竖屏、不同设备尺寸
/// 8. 上一页/下一页翻页按钮
/// 9. 离线英文TTS标准美式发音、慢速儿童适配朗读
/// ========================================
class ReadingScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ReadingScreen({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  /// 图片缩放控制器
  final TransformationController _imageController = TransformationController();

  @override
  void dispose() {
    _imageController.dispose();
    // 离开页面时停止阅读
    ref.read(readingProvider.notifier).stopReading();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readingState = ref.watch(readingProvider);
    final book = readingState.currentBook;
    final currentPage = readingState.currentPage;
    final totalPages = readingState.totalPages;
    final isLoading = readingState.isLoading;
    final error = readingState.error;

    // 错误处理
    if (error != null) {
      return _buildErrorScreen(error);
    }

    // 加载中
    if (isLoading && book == null) {
      return _buildLoadingScreen();
    }

    // 横竖屏检测
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopBar(
              context,
              book?.title ?? '绘本朗读',
              currentPage,
              totalPages,
            ),

            // 主内容区域
            Expanded(
              child: isLandscape
                  ? _buildLandscapeLayout()
                  : _buildPortraitLayout(),
            ),

            // 底部翻页控制
            _buildBottomControls(currentPage, totalPages),
          ],
        ),
      ),
    );
  }

  /// ========================================
  /// 加载中页面
  /// ========================================
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryContainer,
            ),
            const SizedBox(height: 24),
            Text(
              '正在加载绘本...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ========================================
  /// 错误页面
  /// ========================================
  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  LucideIcons.alertCircle,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '加载失败',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimaryFixed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ========================================
  /// 顶部导航栏
  /// ========================================
  Widget _buildTopBar(
    BuildContext context,
    String title,
    int currentPage,
    int totalPages,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.chevronLeft,
                size: 24,
                color: AppColors.onPrimaryFixed,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 绘本名称
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimaryFixed,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '第 ${currentPage + 1} / $totalPages 页',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 页码指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.bookOpen,
                  size: 14,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  '${currentPage + 1}/$totalPages',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ========================================
  /// 竖屏布局
  /// ========================================
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // 绘本图片区域
        Expanded(
          flex: 5,
          child: _buildImageSection(),
        ),

        const SizedBox(height: 12),

        // 句子列表区域
        Expanded(
          flex: 5,
          child: _buildSentencesList(),
        ),
      ],
    );
  }

  /// ========================================
  /// 横屏布局
  /// ========================================
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // 左侧：绘本图片
        Expanded(
          flex: 5,
          child: _buildImageSection(),
        ),

        const SizedBox(width: 16),

        // 右侧：句子列表
        Expanded(
          flex: 5,
          child: _buildSentencesList(),
        ),
      ],
    );
  }

  /// ========================================
  /// 绘本图片区域（支持缩放、拖动）
  /// ========================================
  Widget _buildImageSection() {
    final currentPageData = ref.watch(readingProvider).currentPageData;
    final currentPage = ref.watch(readingProvider).currentPage;
    final imageUrl = currentPageData?.imageUrl;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // 可缩放图片
            PhotoView(
              key: ValueKey('page_$currentPage'),
              imageProvider: _getImageProvider(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              initialScale: PhotoViewComputedScale.contained,
              backgroundDecoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
              ),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event?.expectedTotalBytes != null
                      ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                      : null,
                  color: AppColors.primaryContainer,
                ),
              ),
              errorBuilder: (context, error, stackTrace) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.imageOff,
                      size: 48,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '图片加载失败',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 缩放提示
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.zoomIn,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '双指缩放',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取图片提供者
  ImageProvider _getImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const AssetImage('assets/images/book_blue_bird.png');
    }

    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    }

    // 网络图片
    final fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : 'http://localhost:8000$imageUrl';

    return NetworkImage(fullUrl) as ImageProvider;
  }

  /// ========================================
  /// 句子列表区域
  /// ========================================
  Widget _buildSentencesList() {
    final sentences = ref.watch(readingProvider).currentSentences;
    final currentPage = ref.watch(readingProvider).currentPage;
    final activeSentenceId = ref.watch(readingProvider).activeSentenceId;
    final showTranslation = ref.watch(readingProvider).showTranslation;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏
          _buildSentencesHeader(),

          // 句子列表
          Expanded(
            child: sentences.isEmpty
                ? _buildEmptySentences()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: sentences.length,
                    itemBuilder: (context, index) {
                      final sentence = sentences[index];
                      final isActive = activeSentenceId == sentence.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SentenceReadItem(
                          key: ValueKey('sentence_${sentence.id}_$currentPage'),
                          sentence: sentence,
                          index: index + 1,
                          isActive: isActive,
                          showTranslation: showTranslation,
                          onEdit: (newText) {
                            _onSentenceEdit(sentence, newText);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 空句子提示
  Widget _buildEmptySentences() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: 48,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '当前页面暂无句子',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 句子列表标题栏
  Widget _buildSentencesHeader() {
    final showTranslation = ref.watch(readingProvider).showTranslation;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.messageCircle,
              size: 20,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '朗读练习',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimaryFixed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  showTranslation ? '点击句子逐句朗读，长按可编辑修正' : '翻译已隐藏，点击右侧按钮显示',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 显示/隐藏翻译按钮
          GestureDetector(
            onTap: () {
              ref.read(readingProvider.notifier).toggleTranslation();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: showTranslation
                    ? AppColors.secondaryContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                showTranslation ? LucideIcons.languages : LucideIcons.eyeOff,
                size: 22,
                color: showTranslation
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 编辑句子回调
  void _onSentenceEdit(Sentence original, String newText) {
    // TODO: 调用API更新句子
    debugPrint('编辑句子: ${original.id} -> $newText');
  }

  /// ========================================
  /// 底部翻页控制
  /// ========================================
  Widget _buildBottomControls(int currentPage, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页按钮
          _buildPageButton(
            icon: LucideIcons.chevronLeft,
            label: '上一页',
            enabled: currentPage > 0,
            onTap: currentPage > 0
                ? () {
                    ref.read(readingProvider.notifier).prevPage();
                    _imageController.value = Matrix4.identity();
                  }
                : null,
          ),

          const SizedBox(width: 32),

          // 页码指示点
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              totalPages.clamp(1, 5),
              (index) {
                final displayIndex = totalPages <= 5
                    ? index
                    : (currentPage <= 2 ? index : currentPage - 2 + index)
                        .clamp(0, totalPages - 1);

                final isCurrentPage = displayIndex == currentPage;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCurrentPage
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 32),

          // 下一页按钮
          _buildPageButton(
            icon: LucideIcons.chevronRight,
            label: '下一页',
            enabled: currentPage < totalPages - 1,
            onTap: currentPage < totalPages - 1
                ? () {
                    ref.read(readingProvider.notifier).nextPage();
                    _imageController.value = Matrix4.identity();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  /// 翻页按钮
  Widget _buildPageButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled
                  ? AppColors.onSecondaryContainer
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: enabled
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}