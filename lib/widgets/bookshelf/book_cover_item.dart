import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:storybird_flutter/core/theme/app_colors.dart';
import 'package:storybird_flutter/core/utils/bookshelf_sizer.dart';
import 'package:storybird_flutter/models/book.dart';

/// ========================================
/// 绘本封面组件
///
/// 特性：
/// - 封面固定宽高比 3:4
/// - CachedNetworkImage 本地缓存
/// - 圆角 12px + 阴影
/// - 骨架屏加载动画
/// - 加载失败显示默认绘本图标
/// - 点击跳转详情页
/// ========================================
class BookCoverItem extends StatelessWidget {
  /// 绘本数据
  final Book book;

  /// 点击回调
  final VoidCallback onTap;

  /// 封面宽度（可选，默认自动计算）
  final double? width;

  /// 封面高度（可选，默认按 3:4 比例自动计算）
  final double? height;

  /// 圆角大小
  final double borderRadius;

  const BookCoverItem({
    super.key,
    required this.book,
    required this.onTap,
    this.width,
    this.height,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图片区域
          Expanded(
            child: _BookCoverImage(
              imageUrl: book.image,
              borderRadius: borderRadius,
              isNew: book.isNew,
              level: book.level,
            ),
          ),
          const SizedBox(height: 8),
          // 标题区域
          _BookTitle(title: book.title),
        ],
      ),
    );
  }
}

/// ========================================
/// 绘本封面图片组件
/// ========================================
class _BookCoverImage extends StatelessWidget {
  final String? imageUrl;
  final double borderRadius;
  final bool isNew;
  final int level;

  const _BookCoverImage({
    required this.imageUrl,
    required this.borderRadius,
    this.isNew = false,
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 封面图片容器
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: _buildImage(),
          ),
        ),

        // NEW 标签
        if (isNew)
          Positioned(
            top: 8,
            right: 8,
            child: _buildNewBadge(),
          ),

        // 等级标签
        Positioned(
          bottom: 8,
          left: 8,
          child: _buildLevelBadge(),
        ),
      ],
    );
  }

  /// 构建图片组件
  Widget _buildImage() {
    final hasValidUrl = imageUrl != null && imageUrl!.isNotEmpty;

    if (!hasValidUrl) {
      return _buildPlaceholder(isError: true);
    }

    // 判断是否为本地资源
    final isLocalAsset = imageUrl!.startsWith('assets/');

    if (isLocalAsset) {
      return Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildPlaceholder(isError: true),
      );
    }

    // 网络图片：使用 CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: _getFullUrl(imageUrl!),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // 加载中：骨架屏
      placeholder: (_, __) => _buildSkeletonPlaceholder(),
      // 加载失败：默认绘本图标
      errorWidget: (_, __, ___) => _buildPlaceholder(isError: true),
    );
  }

  /// 处理相对路径 URL
  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    // 拼接后端静态资源地址
    return 'http://localhost:8000$url';
  }

  /// 骨架屏占位
  Widget _buildSkeletonPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
        child: Center(
          child: Icon(
            LucideIcons.bookOpen,
            size: 48,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  /// 占位图（加载中/加载失败）
  Widget _buildPlaceholder({bool isError = false}) {
    return Container(
      color: isError
          ? AppColors.surfaceContainerHigh
          : Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? LucideIcons.bookOpen : LucideIcons.loader2,
              size: 40,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            if (isError) ...[
              const SizedBox(height: 8),
              Text(
                '绘本封面',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// NEW 标签
  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  /// 等级标签
  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'LV.$level',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// ========================================
/// 绘本标题组件
/// ========================================
class _BookTitle extends StatelessWidget {
  final String title;

  const _BookTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.onPrimaryFixed,
        height: 1.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// ========================================
/// 绘本骨架屏组件（列表加载时使用）
/// ========================================
class BookCoverSkeleton extends StatelessWidget {
  final double borderRadius;

  const BookCoverSkeleton({
    super.key,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 封面骨架
        Expanded(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 标题骨架
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

/// ========================================
/// 绘本书架网格组件
///
/// 完整的书架 GridView，支持：
/// - 一行严格3列
/// - 动态尺寸计算
/// - 横竖屏自动刷新
/// - 刘海屏/折叠屏适配
/// ========================================
class BookshelfGrid extends StatefulWidget {
  /// 绘本列表
  final List<Book> books;

  /// 点击绘本回调
  final ValueChanged<Book> onBookTap;

  /// 是否显示骨架屏
  final bool isLoading;

  /// 骨架屏数量
  final int skeletonCount;

  const BookshelfGrid({
    super.key,
    required this.books,
    required this.onBookTap,
    this.isLoading = false,
    this.skeletonCount = 6,
  });

  @override
  State<BookshelfGrid> createState() => _BookshelfGridState();
}

class _BookshelfGridState extends State<BookshelfGrid> {
  @override
  Widget build(BuildContext context) {
    // 使用 LayoutBuilder 监听尺寸变化，支持横竖屏刷新
    return LayoutBuilder(
      builder: (context, constraints) {
        // 获取动态 GridDelegate
        final gridDelegate = BookshelfSizer.getGridDelegate(context);

        // 显示骨架屏
        if (widget.isLoading) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: gridDelegate.crossAxisCount,
            mainAxisSpacing: gridDelegate.mainAxisSpacing,
            crossAxisSpacing: gridDelegate.crossAxisSpacing,
            childAspectRatio: gridDelegate.childAspectRatio,
            children: List.generate(
              widget.skeletonCount,
              (_) => const BookCoverSkeleton(),
            ),
          );
        }

        // 显示绘本列表
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: gridDelegate,
          itemCount: widget.books.length,
          itemBuilder: (context, index) {
            final book = widget.books[index];
            return BookCoverItem(
              book: book,
              onTap: () => widget.onBookTap(book),
            );
          },
        );
      },
    );
  }
}