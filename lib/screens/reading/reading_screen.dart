import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/models/book.dart';
import 'package:storycoe_flutter/models/sentence.dart';
import 'package:storycoe_flutter/providers/auth_provider.dart';
import 'package:storycoe_flutter/providers/books_provider.dart';
import 'package:storycoe_flutter/providers/create_provider.dart';
import 'package:storycoe_flutter/providers/reading_provider.dart';
import 'package:storycoe_flutter/services/api_service.dart';
import 'package:storycoe_flutter/services/tts_service.dart';
import 'package:storycoe_flutter/widgets/reading/sentence_read_item.dart';

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

  /// 添加句子状态
  bool _isAddingSentence = false;
  final _newSentenceController = TextEditingController();
  bool _isSavingSentence = false;

  /// 屏幕方向偏好：'portrait' | 'landscape' | 'auto'
  String _orientationMode = 'auto';

  /// 图片实际尺寸（用于自适应布局）
  Size? _imageSize;

  /// 是否显示滑动翻页提示
  bool _showSwipeHint = true;

  /// 是否是绘本作者
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();

    // 3秒后自动隐藏滑动提示
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSwipeHint = false);
    });

    // 预初始化 TTS，确保用户点击播放按钮时引擎已就绪（解决 Android 小米手机 TTS 不工作问题）
    _initTts();
    // 检查是否需要加载书籍
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookIfNeeded();
    });
  }

  /// 预初始化 TTS 服务
  Future<void> _initTts() async {
    await ttsService.init();
    // 设置初始语言和语速
    final readingState = ref.read(readingProvider);
    await ttsService.setLanguage(readingState.languageCode);
    await ttsService.setSpeechRate(readingState.speechRate);
    debugPrint('[ReadingScreen] TTS 预初始化完成');
  }

  /// 检查并加载书籍（如果当前没有加载或 bookId 不同）
  void _loadBookIfNeeded() {
    final readingState = ref.read(readingProvider);
    final currentBookId = readingState.currentBook?.id;

    // 如果 currentBook 为空或 ID 不匹配，通过 bookId 加载
    if (currentBookId == null || currentBookId != widget.bookId) {
      debugPrint('[ReadingScreen] 需要加载书籍: bookId=${widget.bookId}');
      ref.read(readingProvider.notifier).startReadingById(widget.bookId);
    } else {
      debugPrint('[ReadingScreen] 书籍已加载: bookId=${widget.bookId}');
    }
  }

  /// 获取图片实际尺寸
  void _loadImageSize(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      _imageSize = null;
      return;
    }

    final imageProvider = _getImageProvider(imageUrl);
    imageProvider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          if (mounted) {
            setState(() {
              _imageSize = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );
            });
          }
        },
        onError: (exception, stackTrace) {
          debugPrint('[ReadingScreen] 获取图片尺寸失败: $exception');
          _imageSize = null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _imageController.dispose();
    // 离开页面时停止阅读
    ref.read(readingProvider.notifier).stopReading();
    // 恢复默认屏幕方向（允许所有方向）
    // 使用 Future.microtask 确保在当前帧完成后执行
    Future.microtask(() {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
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

    // 更新作者状态
    final bookDetail = readingState.bookDetail;
    final currentUser = ref.watch(userProfileProvider);
    final isOwner = currentUser?.id == bookDetail?.userId;
    if (_isOwner != isOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isOwner = isOwner);
      });
    }

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
              book,
            ),

            // 主内容区域
            Expanded(
              child: isLandscape
                  ? _buildLandscapeLayout()
                  : _buildPortraitLayout(),
            ),
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
    Book? book,
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

          // 绘本名称（作者可长按编辑）
          Expanded(
            child: GestureDetector(
              onLongPress: _isOwner && book != null
                  ? () => _showEditTitleDialog(context, book)
                  : null,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
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
                  ),
                  // 作者显示编辑图标提示
                  if (_isOwner) ...[
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.pencil,
                      size: 14,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
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

          const SizedBox(width: 8),

          // 更多按钮
          GestureDetector(
            onTap: () => _showReadingMenu(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.moreVertical,
                size: 20,
                color: AppColors.onPrimaryFixed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示 TTS 调试弹窗
  void _showTtsDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.bug, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('TTS 调试日志'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 480,
          child: Column(
            children: [
              // 引擎信息（新增）
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ttsService.getEnginesDebugInfo(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 状态信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('状态: ${ttsService.state}'),
                    Text('正在播放: ${ttsService.isPlaying}'),
                    Text('当前文本: ${ttsService.currentText ?? "无"}'),
                    if (ttsService.lastError != null)
                      Text(
                        '错误: ${ttsService.lastError}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 打开设置按钮
              ElevatedButton.icon(
                onPressed: () async {
                  await ttsService.openTtsSettings();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已打开 TTS 设置，配置后返回应用重试'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.settings),
                label: const Text('打开系统 TTS 设置'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // 设置指南
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ttsService.getTtsSetupGuide(),
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // 日志区域
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      ttsService.debugLogsText.isEmpty
                          ? '暂无日志'
                          : ttsService.debugLogsText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ttsService.clearDebugLogs();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已清除')),
              );
            },
            child: const Text('清除日志'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ttsService.debugLogsText));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已复制到剪贴板')),
              );
            },
            child: const Text('复制日志'),
          ),
        ],
      ),
    );
  }

  /// 显示屏幕方向选择弹窗
  void _showOrientationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.smartphone, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            const Text('屏幕方向'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOrientationOption(
              icon: LucideIcons.smartphone,
              label: '竖屏',
              description: '锁定为竖屏显示',
              value: 'portrait',
            ),
            const SizedBox(height: 8),
            _buildOrientationOption(
              icon: LucideIcons.tablet,
              label: '横屏',
              description: '锁定为横屏显示',
              value: 'landscape',
            ),
            const SizedBox(height: 8),
            _buildOrientationOption(
              icon: LucideIcons.smartphoneNfc,
              label: '自动',
              description: '跟随设备方向自动切换',
              value: 'auto',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 构建屏幕方向选项
  Widget _buildOrientationOption({
    required IconData icon,
    required String label,
    required String description,
    required String value,
  }) {
    final isSelected = _orientationMode == value;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _setOrientation(value);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.15)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.surfaceContainerHigh,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withValues(alpha: 0.2)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 20,
                color: AppColors.primaryContainer,
              ),
          ],
        ),
      ),
    );
  }

  /// 设置屏幕方向
  void _setOrientation(String mode) {
    setState(() {
      _orientationMode = mode;
    });

    switch (mode) {
      case 'portrait':
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
      case 'landscape':
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case 'auto':
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == 'portrait'
              ? '已锁定为竖屏显示'
              : mode == 'landscape'
                  ? '已锁定为横屏显示'
                  : '已切换为自动方向',
        ),
        backgroundColor: AppColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示阅读页菜单
  void _showReadingMenu(BuildContext context) async {
    final book = ref.read(readingProvider).currentBook;
    final bookDetail = ref.read(readingProvider).bookDetail;
    final currentUser = ref.read(userProfileProvider);
    final totalPages = ref.read(readingProvider).totalPages;
    if (book == null || bookDetail == null) return;

    // 判断是否是作者
    final isOwner = currentUser?.id == bookDetail.userId;

    // 检查是否在书架中（非作者需要检查）
    bool isInShelf = false;
    if (!isOwner) {
      try {
        isInShelf = await booksApi.checkShelfStatus(book.id);
      } catch (e) {
        debugPrint('[ReadingScreen] 检查书架状态失败: $e');
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖拽指示条
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // 横竖屏设置按钮（所有人可见）
            _buildMenuButton(
              icon: _orientationMode == 'portrait'
                  ? LucideIcons.smartphone
                  : _orientationMode == 'landscape'
                      ? LucideIcons.tablet
                      : LucideIcons.smartphoneNfc,
              label: _orientationMode == 'portrait'
                  ? '竖屏模式'
                  : _orientationMode == 'landscape'
                      ? '横屏模式'
                      : '自动方向',
              color: AppColors.tertiaryContainer,
              onTap: () {
                Navigator.pop(sheetContext);
                _showOrientationDialog(context);
              },
            ),

            const SizedBox(height: 12),

            // 调试按钮（所有人可见）
            _buildMenuButton(
              icon: LucideIcons.bug,
              label: 'TTS 调试',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(sheetContext);
                _showTtsDebugDialog(context);
              },
            ),

            // 作者菜单：分享类型、添加页面、删除页面、删除绘本
            if (isOwner) ...[
              const SizedBox(height: 12),

              // 添加页面按钮
              _buildMenuButton(
                icon: LucideIcons.plusCircle,
                label: '添加页面',
                color: AppColors.primaryContainer,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAddPageDialog(context);
                },
              ),

              const SizedBox(height: 12),

              // 删除当前页按钮（只有多页时才显示）
              if (totalPages > 1)
                _buildMenuButton(
                  icon: LucideIcons.fileMinus,
                  label: '删除当前页',
                  color: AppColors.error,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _confirmDeleteCurrentPage(context);
                  },
                ),

              if (totalPages > 1)
                const SizedBox(height: 12),

              // 分享类型按钮
              _buildMenuButton(
                icon: book.shareType == 'public' ? LucideIcons.globe : LucideIcons.lock,
                label: book.shareType == 'public' ? '公开绘本' : '私有绘本',
                color: book.shareType == 'public' ? AppColors.secondaryContainer : AppColors.onSurfaceVariant,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showShareTypeDialog(context, book);
                },
              ),

              const SizedBox(height: 12),

              // 删除按钮
              _buildMenuButton(
                icon: LucideIcons.trash2,
                label: '删除绘本',
                color: AppColors.error,
                onTap: () async {
                  Navigator.pop(sheetContext);

                  // 显示删除确认
                  final confirmed = await showDeleteConfirm(book);
                  if (confirmed && context.mounted) {
                    context.go('/home');
                  }
                },
              ),
            ],

            // 非作者菜单：加入书架/已在书架
            if (!isOwner) ...[
              const SizedBox(height: 12),

              _buildMenuButton(
                icon: isInShelf ? LucideIcons.bookmark : LucideIcons.bookmarkPlus,
                label: isInShelf ? '已在书架' : '加入书架',
                color: isInShelf ? AppColors.secondaryContainer : AppColors.primaryContainer,
                onTap: () async {
                  Navigator.pop(sheetContext);

                  if (isInShelf) {
                    // 已在书架，点击移除
                    try {
                      await booksApi.removeFromShelf(book.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已从书架移除')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('移除失败: $e')),
                        );
                      }
                    }
                  } else {
                    // 加入书架
                    try {
                      await booksApi.addToShelf(book.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已加入书架')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('加入失败: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ],

            const SizedBox(height: 24),

            // 取消按钮
            GestureDetector(
              onTap: () => Navigator.pop(sheetContext),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '取消',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 菜单按钮
  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// ========================================
  /// 添加页面对话框
  /// ========================================
  Future<void> _showAddPageDialog(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    // 显示加载提示
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 读取图片数据
      final bytes = await pickedFile.readAsBytes();
      final filename = pickedFile.name;

      // 调用 API 创建页面
      final success = await ref.read(readingProvider.notifier).createPage(
            filename,
            bytes,
          );

      // 关闭加载提示
      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('页面添加成功'),
            backgroundColor: AppColors.primaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // 关闭加载提示
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加页面失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// ========================================
  /// 确认删除当前页
  /// ========================================
  Future<void> _confirmDeleteCurrentPage(BuildContext context) async {
    final readingState = ref.read(readingProvider);
    final currentPage = readingState.currentPage + 1;
    final totalPages = readingState.totalPages;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '删除页面',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          '确定要删除第 $currentPage 页吗？\n共 $totalPages 页，删除后无法恢复。',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 显示加载提示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final success = await ref.read(readingProvider.notifier).deleteCurrentPage();

        // 关闭加载提示
        if (mounted) Navigator.pop(context);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('页面已删除'),
              backgroundColor: AppColors.onSurfaceVariant,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        // 关闭加载提示
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// 显示编辑标题对话框
  void _showEditTitleDialog(BuildContext context, dynamic book) {
    final controller = TextEditingController(text: book.title);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '编辑绘本名称',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '请输入绘本名称',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;

              Navigator.pop(dialogContext);

              // 更新绘本
              final updatedBook = book.copyWith(title: newTitle);
              await ref.read(booksProvider.notifier).updateBook(updatedBook);

              // 同步更新阅读页的标题
              ref.read(readingProvider.notifier).updateCurrentBookTitle(newTitle);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('绘本名称已更新'),
                    backgroundColor: AppColors.primaryContainer,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 跳转到编辑绘本页面
  void _navigateToEditBook(BuildContext context, dynamic book) {
    final readingState = ref.read(readingProvider);
    final bookDetail = readingState.bookDetail;

    // 获取绘本信息
    final bookId = book.id;
    final title = book.title;
    final shareType = book.shareType ?? 'private';
    final coverUrl = book.image ?? bookDetail?.coverImage;

    // 获取内页图片 URL 列表
    final pageUrls = <String>[];
    if (bookDetail != null) {
      for (final page in bookDetail.pages) {
        if (page.imageUrl != null && page.imageUrl!.isNotEmpty) {
          pageUrls.add(page.imageUrl!);
        }
      }
    }

    // 设置编辑模式数据
    ref.read(createProvider.notifier).setEditingBook(
      bookId: bookId,
      title: title,
      shareType: shareType,
      coverUrl: coverUrl,
      pageUrls: pageUrls,
    );

    // 跳转到创作页面
    context.go('/create?edit=$bookId');
  }

  /// 显示分享类型选择对话框
  void _showShareTypeDialog(BuildContext context, dynamic book) {
    String selectedType = book.shareType ?? 'private';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '分享类型',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 私有选项
              _buildShareTypeOption(
                context: context,
                value: 'private',
                label: '私有',
                description: '仅自己可见',
                icon: LucideIcons.lock,
                isSelected: selectedType == 'private',
                onTap: () => setState(() => selectedType = 'private'),
              ),
              const SizedBox(height: 12),
              // 公开选项
              _buildShareTypeOption(
                context: context,
                value: 'public',
                label: '公开',
                description: '所有用户可见',
                icon: LucideIcons.globe,
                isSelected: selectedType == 'public',
                onTap: () => setState(() => selectedType = 'public'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                '取消',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // 更新分享类型
                final updatedBook = book.copyWith(shareType: selectedType);
                await ref.read(booksProvider.notifier).updateBook(updatedBook);

                // 同步更新阅读页的书本信息
                ref.read(readingProvider.notifier).updateCurrentBookShareType(selectedType);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(selectedType == 'public' ? '已设为公开绘本' : '已设为私有绘本'),
                      backgroundColor: AppColors.primaryContainer,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分享类型选项
  Widget _buildShareTypeOption({
    required BuildContext context,
    required String value,
    required String label,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.1)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.onSurfaceVariant.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.onPrimaryFixed
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 20,
                color: AppColors.primaryContainer,
              ),
          ],
        ),
      ),
    );
  }

  /// 显示删除确认并执行删除
  Future<bool> showDeleteConfirm(dynamic book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  LucideIcons.trash2,
                  size: 36,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '确定要删除绘本吗？',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onPrimaryFixed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '《${book.title}》',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '删除后绘本将永远消失，无法恢复',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          '取消',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '删除',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(booksProvider.notifier).removeBook(book.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('《${book.title}》已删除'),
            backgroundColor: AppColors.onSurfaceVariant,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    return confirmed == true;
  }

  /// ========================================
  /// 竖屏布局
  /// ========================================
  Widget _buildPortraitLayout() {
    // 根据图片宽高比计算高度
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double imageHeight = 200; // 默认高度

    if (_imageSize != null && _imageSize!.width > 0 && _imageSize!.height > 0) {
      final imageAspect = _imageSize!.width / _imageSize!.height;
      // 根据屏幕宽度计算图片高度
      final calculatedHeight = (screenWidth - 104) / imageAspect; // 减去边距和按钮
      // 限制最小150px，最大为屏幕高度的40%
      imageHeight = calculatedHeight.clamp(150.0, screenHeight * 0.4);
    }

    return Column(
      children: [
        // 绘本图片区域（带翻页按钮，自适应高度）
        SizedBox(
          height: imageHeight,
          child: _buildImageSectionWithControls(),
        ),

        // 句子列表区域（主要区域）
        Expanded(
          child: _buildSentencesList(),
        ),
      ],
    );
  }

  /// ========================================
  /// 横屏布局
  /// ========================================
  Widget _buildLandscapeLayout() {
    // 根据图片宽高比计算宽度
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double imageWidth = 260; // 默认宽度

    if (_imageSize != null && _imageSize!.width > 0 && _imageSize!.height > 0) {
      final imageAspect = _imageSize!.width / _imageSize!.height;
      // 根据屏幕高度计算图片宽度
      final calculatedWidth = (screenHeight - 80) * imageAspect; // 减去边距
      // 限制最小200px，最大为屏幕宽度的45%
      imageWidth = calculatedWidth.clamp(200.0, screenWidth * 0.45);
    }

    return Row(
      children: [
        // 左侧：绘本图片（带翻页按钮，自适应宽度）
        SizedBox(
          width: imageWidth,
          child: _buildImageSectionWithControls(),
        ),

        const SizedBox(width: 12),

        // 右侧：句子列表
        Expanded(
          child: _buildSentencesList(),
        ),
      ],
    );
  }

  /// ========================================
  /// 绘本图片区域
  /// ========================================
  Widget _buildImageSectionWithControls() {
    return _buildImageSection();
  }

  /// ========================================
  /// 绘本图片区域（支持缩放、拖动、淡入淡出翻页）
  /// ========================================
  Widget _buildImageSection() {
    final currentPageData = ref.watch(readingProvider).currentPageData;
    final currentPage = ref.watch(readingProvider).currentPage;
    final imageUrl = currentPageData?.imageUrl;

    // 加载图片尺寸（用于自适应布局）
    if (imageUrl != null && imageUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadImageSize(imageUrl);
      });
    }

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
            // 如果没有图片，显示空状态占位符
            if (imageUrl == null || imageUrl.isEmpty)
              _buildEmptyImagePlaceholder()
            else
              // 淡入淡出翻页动画
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  key: ValueKey('page_$currentPage'),
                  onHorizontalDragEnd: (details) {
                    _handleSwipePage(details, currentPage);
                  },
                  child: PhotoView(
                    key: ValueKey('photoview_$currentPage'),
                    imageProvider: _getImageProvider(imageUrl),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    initialScale: PhotoViewComputedScale.contained,
                    backgroundDecoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                    ),
                    loadingBuilder: (context, event) => _buildImageSkeleton(),
                    errorBuilder: (context, error, stackTrace) => _buildImageError(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 空图片占位符
  Widget _buildEmptyImagePlaceholder() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                LucideIcons.imageOff,
                size: 40,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无图片',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '该页面尚未上传图片',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 图片加载错误占位符
  Widget _buildImageError() {
    return Center(
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
    );
  }

  /// 处理滑动翻页
  void _handleSwipePage(DragEndDetails details, int currentPage) {
    const double sensitivity = 100; // 滑动阈值
    if (details.primaryVelocity == null) return;

    final totalPages = ref.read(readingProvider).totalPages;

    if (details.primaryVelocity! < -sensitivity) {
      // 向左滑 → 下一页
      if (currentPage < totalPages - 1) {
        _imageController.value = Matrix4.identity();
        ref.read(readingProvider.notifier).nextPage();
        if (_showSwipeHint) setState(() => _showSwipeHint = false);
      }
    } else if (details.primaryVelocity! > sensitivity) {
      // 向右滑 → 上一页
      if (currentPage > 0) {
        _imageController.value = Matrix4.identity();
        ref.read(readingProvider.notifier).prevPage();
        if (_showSwipeHint) setState(() => _showSwipeHint = false);
      }
    }
  }

  /// 获取图片提供者
  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    }

    // 网络图片：使用 CachedNetworkImageProvider 实现持久缓存
    final fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '${ApiConfig.baseUrl}$imageUrl';

    return CachedNetworkImageProvider(fullUrl);
  }

  /// 图片骨架屏（加载占位）
  Widget _buildImageSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerHighest,
      child: Container(
        color: AppColors.surfaceContainerHigh,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 绘本图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  size: 40,
                  color: AppColors.surfaceContainerHigh,
                ),
              ),
              const SizedBox(height: 16),
              // 加载文字
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 预缓存图片到内存
  void _preloadImages(List<String?> imageUrls) {
    for (final url in imageUrls) {
      if (url == null || url.isEmpty) continue;
      final imageProvider = _getImageProvider(url);
      precacheImage(imageProvider, context);
    }
  }

  /// ========================================
  /// 句子列表区域
  /// ========================================
  Widget _buildSentencesList() {
    final readingState = ref.watch(readingProvider);
    final sentences = readingState.currentSentences;
    final currentPage = readingState.currentPage;
    final activeSentenceId = readingState.activeSentenceId;
    final showTranslation = readingState.showTranslation;
    final totalPages = readingState.totalPages;

    // 获取当前页面状态
    final currentPageData = readingState.currentPageData;
    final isProcessing = currentPageData?.isProcessing ?? false;

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
          // 识别中提示
          if (isProcessing)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.tertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '正在识别文字，请稍候...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.tertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 滑动翻页提示
          if (_showSwipeHint && totalPages > 1 && !isProcessing)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.hand,
                    size: 14,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '左右滑动图片可翻页',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // 标题栏
          _buildSentencesHeader(),

          // 句子列表
          Expanded(
            child: sentences.isEmpty
                ? _buildEmptySentences()
                : sentences.length == 1
                    ? _buildSingleSentenceList(sentences, activeSentenceId, showTranslation, currentPage)
                    : _buildReorderableSentenceList(sentences, activeSentenceId, showTranslation, currentPage),
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

  /// 单个句子的列表（不需要拖拽排序）
  Widget _buildSingleSentenceList(
    List<Sentence> sentences,
    String? activeSentenceId,
    bool showTranslation,
    int currentPage,
  ) {
    final sentence = sentences.first;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SentenceReadItem(
            key: ValueKey('sentence_${sentence.id}_$currentPage'),
            sentence: sentence,
            index: 1,
            isActive: activeSentenceId == sentence.id,
            showTranslation: showTranslation,
            onEdit: (newText) {
              _onSentenceEdit(sentence, newText);
            },
            onDelete: () => _onDeleteSentence(sentence.id),
          ),
        ),
        _buildAddSentenceButton(),
      ],
    );
  }

  /// 可拖拽排序的句子列表
  Widget _buildReorderableSentenceList(
    List<Sentence> sentences,
    String? activeSentenceId,
    bool showTranslation,
    int currentPage,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _isOwner ? sentences.length + 1 : sentences.length, // 非作者不显示添加按钮
      onReorder: _isOwner
          ? (oldIndex, newIndex) async {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }

              if (oldIndex >= sentences.length || newIndex >= sentences.length) {
                return;
              }

              final newSentences = List<Sentence>.from(sentences);
              final item = newSentences.removeAt(oldIndex);
              newSentences.insert(newIndex, item);

              final sentenceIds = newSentences.map((s) => s.id).toList();
              await ref.read(readingProvider.notifier).reorderSentences(sentenceIds);
            }
          : (oldIndex, newIndex) {}, // 非作者禁用拖拽
      proxyDecorator: (child, index, animation) {
        // 拖拽时的样式
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final animValue = Curves.easeInOut.transform(animation.value);
            final elevation = 1 + animValue * 8;
            final scale = 1 + animValue * 0.02;
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tertiaryContainer.withValues(alpha: 0.4),
                      blurRadius: elevation * 2,
                      offset: Offset(0, elevation),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        // 添加句子按钮（仅作者可见）
        if (index == sentences.length) {
          return Container(
            key: const ValueKey('add_sentence_button'),
            child: _buildAddSentenceButton(),
          );
        }

        final sentence = sentences[index];
        final isActive = activeSentenceId == sentence.id;

        return Container(
          key: ValueKey('sentence_${sentence.id}_$currentPage'),
          padding: const EdgeInsets.only(bottom: 12),
          child: SentenceReadItem(
            sentence: sentence,
            index: index + 1,
            isActive: isActive,
            showTranslation: showTranslation,
            isOwner: _isOwner, // 传递作者状态
            onEdit: _isOwner
                ? (newText) {
                    _onSentenceEdit(sentence, newText);
                  }
                : null,
            onDelete: _isOwner ? () => _onDeleteSentence(sentence.id) : null,
          ),
        );
      },
    );
  }

  /// 删除句子
  Future<void> _onDeleteSentence(String sentenceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.onErrorContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('删除句子'),
            ],
          ),
          content: const Text('确定要删除这个句子吗？删除后将无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
              ),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorContainer,
                foregroundColor: AppColors.onErrorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.trash2, size: 16),
                  SizedBox(width: 6),
                  Text('删除'),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(readingProvider.notifier).deleteSentence(sentenceId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('句子已删除')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败，请重试')),
        );
      }
    }
  }

  /// 添加句子按钮或输入框
  Widget _buildAddSentenceButton() {
    // 如果正在添加句子，显示输入框
    if (_isAddingSentence) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 输入框
              TextField(
                controller: _newSentenceController,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: '输入英文句子...',
                  hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),
              // 按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 取消按钮
                  TextButton(
                    onPressed: _isSavingSentence
                        ? null
                        : () {
                            setState(() {
                              _isAddingSentence = false;
                              _newSentenceController.clear();
                            });
                          },
                    child: Text(
                      '取消',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 保存按钮
                  ElevatedButton(
                    onPressed: _isSavingSentence ? null : _saveNewSentence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSavingSentence
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimaryContainer,
                            ),
                          )
                        : const Text(
                            '保存',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 默认显示添加按钮
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _isAddingSentence = true;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.plus,
                    size: 20,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '添加新句子',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 左滑操作提示
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.hand,
                size: 12,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '左滑句子可编辑或删除',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 保存新句子
  Future<void> _saveNewSentence() async {
    final en = _newSentenceController.text.trim();

    if (en.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入英文句子')),
      );
      return;
    }

    setState(() {
      _isSavingSentence = true;
    });

    // 调用 Provider 创建句子（后端会自动翻译）
    final newSentence = await ref.read(readingProvider.notifier).createSentence(en, '');

    setState(() {
      _isSavingSentence = false;
    });

    if (newSentence != null && mounted) {
      setState(() {
        _isAddingSentence = false;
        _newSentenceController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('句子添加成功')),
      );
    } else if (mounted) {
      final error = ref.read(readingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? '添加失败，请重试')),
      );
    }
  }

  /// 句子列表标题栏（紧凑设计）
  Widget _buildSentencesHeader() {
    final showTranslation = ref.watch(readingProvider).showTranslation;
    final speedLabel = ref.watch(readingProvider).speedLabel;
    final accent = ref.watch(readingProvider).accent;
    final isPlayingAll = ref.watch(readingProvider).isPlayingAll;
    final isPlayingAllPaused = ref.watch(readingProvider).isPlayingAllPaused;
    final sentences = ref.watch(readingProvider).currentSentences;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          // 整页朗读按钮
          if (sentences.isNotEmpty)
            GestureDetector(
              onTap: () {
                ref.read(readingProvider.notifier).togglePlayAllSentences();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isPlayingAll
                      ? AppColors.secondaryContainer
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isPlayingAll
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primaryContainer.withAlpha(50),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  isPlayingAll
                      ? (isPlayingAllPaused ? LucideIcons.play : LucideIcons.pause)
                      : LucideIcons.playCircle,
                  size: 16,
                  color: isPlayingAll
                      ? AppColors.onSecondaryContainer
                      : AppColors.onPrimaryContainer,
                ),
              ),
            ),

          if (sentences.isNotEmpty) const SizedBox(width: 8),

          // 标题
          const Text(
            '朗读练习',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimaryFixed,
            ),
          ),
          const SizedBox(width: 8),
          // 翻译按钮
          GestureDetector(
            onTap: () {
              ref.read(readingProvider.notifier).toggleTranslation();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: showTranslation
                    ? AppColors.secondaryContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showTranslation ? LucideIcons.languages : LucideIcons.eyeOff,
                    size: 12,
                    color: showTranslation
                        ? AppColors.onSecondaryContainer
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    showTranslation ? '译' : '显示',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: showTranslation
                          ? AppColors.onSecondaryContainer
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 发音选择器（紧凑）
          _buildCompactAccentSelector(accent),

          const SizedBox(width: 6),

          // 语速选择器（紧凑）
          _buildCompactSpeedSelector(speedLabel),
        ],
      ),
    );
  }

  /// 紧凑发音选择器
  Widget _buildCompactAccentSelector(String currentAccent) {
    // 获取可用的发音选项
    final availableAccents = ref.read(readingProvider).availableAccents;

    // 如果没有可用选项，显示提示
    if (availableAccents.isEmpty) {
      return Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '英语',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availableAccents.map((accent) {
          final isSelected = currentAccent == accent;
          return GestureDetector(
            onTap: () {
              ref.read(readingProvider.notifier).setAccent(accent);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                accent,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 紧凑语速选择器
  Widget _buildCompactSpeedSelector(String currentSpeed) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['慢', '中', '正常'].map((speed) {
          final isSelected = currentSpeed == speed;
          return GestureDetector(
            onTap: () {
              ref.read(readingProvider.notifier).setSpeed(speed);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                speed,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 编辑句子回调
  Future<void> _onSentenceEdit(Sentence original, String newText) async {
    debugPrint('编辑句子: ${original.id} -> $newText');

    // 调用 API 更新句子
    final success = await ref.read(readingProvider.notifier).updateSentence(original.id, newText);

    if (!success && mounted) {
      // 显示错误提示
      final readingState = ref.read(readingProvider);
      if (readingState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(readingState.error!),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(readingProvider.notifier).clearError();
      }
    } else if (mounted && success) {
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('句子已更新'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
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