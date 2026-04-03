import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/providers/create_provider.dart';
import 'package:storycoe_flutter/widgets/common/bottom_nav.dart';

/// 创作页面
/// 支持绘本照片上传、拖动排序、生成朗读绘本
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  late final TextEditingController _titleController;
  final _picker = ImagePicker();

  static const int _maxImagesPerPick = 20;
  static const int _maxTotalImages = 50;

  @override
  void initState() {
    super.initState();
    // 初始化 TextEditingController（初始值在 didChangeDependencies 中设置）
    _titleController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从 state 中恢复标题
    final title = ref.read(createProvider).title;
    _titleController.text = title;
  }

  /// 检查是否有正在生成的任务，如果有则跳转到进度页面
  void _checkGeneratingStatus() {
    final isGenerating = ref.read(isGeneratingProvider);
    if (isGenerating) {
      context.go('/create/progress');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// 保存标题到 state
  void _saveTitle() {
    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      ref.read(createProvider.notifier).setTitle(title);
    }
  }

  Future<void> _pickImages() async {
    final notifier = ref.read(createProvider.notifier);
    final currentImages = ref.read(selectedImagesProvider);
    final remainingSlots = _maxTotalImages - currentImages.length;

    if (remainingSlots <= 0) {
      _showSnackBar('已达到最大照片数量 $_maxTotalImages 张');
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isEmpty) return;

      final imagesToAdd = images.take(remainingSlots).toList();

      if (images.length > imagesToAdd.length) {
        _showSnackBar('已达到最大数量，仅添加了 ${imagesToAdd.length} 张');
      }

      for (final xfile in imagesToAdd) {
        final Uint8List? bytes = await xfile.readAsBytes();
        if (bytes != null) {
          notifier.addImage(SelectedImage(
            path: xfile.path,
            bytes: bytes,
            name: xfile.name,
          ));
        }
      }
    } catch (e) {
      _showErrorSnackBar('选择照片失败: $e');
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      final Uint8List? bytes = await image.readAsBytes();
      if (bytes != null) {
        ref.read(createProvider.notifier).setCoverImage(SelectedImage(
          path: image.path,
          bytes: bytes,
          name: image.name,
        ));
        _showSnackBar('封面已设置');
      }
    } catch (e) {
      _showErrorSnackBar('选择封面失败: $e');
    }
  }

  /// 启动生成并跳转到进度页面
  void _startGenerateAndNavigate() {
    final title = _titleController.text.trim();

    // 先检查图片
    final images = ref.read(selectedImagesProvider);
    if (images.isEmpty) {
      _showErrorSnackBar('请先上传照片');
      return;
    }

    // 检查标题
    if (title.isEmpty) {
      _showErrorSnackBar('请输入绘本名称');
      return;
    }

    // 保存标题到 state（重试时可恢复）
    ref.read(createProvider.notifier).setTitle(title);

    // 1. 先设置生成状态（同步）
    ref.read(createProvider.notifier).startGenerating();

    // 2. 跳转到进度页面
    context.go('/create/progress');

    // 3. 启动生成任务（异步执行）
    ref.read(createProvider.notifier).generateBook(title);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.tertiaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(selectedImagesProvider);
    final coverImage = ref.watch(coverImageProvider);
    final error = ref.watch(createProvider).error;

    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(error);
        ref.read(createProvider.notifier).clearError();
      });
    }

    return Scaffold(
      bottomNavigationBar: const BottomNav(currentLocation: '/create'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: 48,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildTitleInput(),
            const SizedBox(height: 24),
            _buildCoverUpload(coverImage),
            const SizedBox(height: 24),
            if (images.isEmpty) _buildUploadButtons(),
            SizedBox(height: images.isEmpty ? 0 : 16),
            if (images.isNotEmpty) _buildImageGrid(images),
            const SizedBox(height: 24),
            if (images.isNotEmpty) _buildTipsCard(),
            const SizedBox(height: 24),
            if (images.isNotEmpty) _buildGenerateButton(images),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '创作新绘本',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.onPrimaryFixed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '上传绘本照片，生成朗读绘本',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            '绘本名称',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '给你的书起个好听的名字...',
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverUpload(SelectedImage? coverImage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '绘本封面',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '可选',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (coverImage == null)
            GestureDetector(
              onTap: _pickCoverImage,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.imagePlus,
                        size: 40,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '点击上传封面',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb
                          ? Image.memory(coverImage.bytes!, fit: BoxFit.cover)
                          : Image.file(File(coverImage.path), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(createProvider.notifier).removeCoverImage();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(LucideIcons.x, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.bookOpen, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('封面', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadButtons() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(LucideIcons.imagePlus, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              '从相册上传',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择绘本照片，最多 $_maxImagesPerPick 张',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 图片网格（支持拖拽排序）
  Widget _buildImageGrid(List<SelectedImage> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '已上传 ${images.length} 张',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('添加', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ref.read(createProvider.notifier).clearImages(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                        SizedBox(width: 4),
                        Text('清空', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 使用 GridView 布局，包装在可拖拽的 Widget 中
        _DraggableImageGrid(
          images: images,
          onReorder: (oldIndex, newIndex) {
            ref.read(createProvider.notifier).moveImage(oldIndex, newIndex);
          },
          onDelete: (index) {
            ref.read(createProvider.notifier).removeImage(index);
          },
        ),
      ],
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.lightbulb, size: 20, color: AppColors.onPrimaryFixed),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '长按照片可以拖动调整顺序',
              style: TextStyle(fontSize: 14, color: AppColors.onPrimaryFixed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(List<SelectedImage> images) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: images.isEmpty ? null : _startGenerateAndNavigate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryContainer,
          foregroundColor: AppColors.onSecondaryContainer,
          disabledBackgroundColor: AppColors.surfaceContainerHigh,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.sparkles, size: 20),
            const SizedBox(width: 8),
            Text(
              images.isEmpty ? '请先上传照片' : '生成朗读绘本',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  }

/// ========================================
/// 可拖拽排序的图片网格组件
/// 使用 Flutter 原生的 LongPressDraggable 实现
/// 支持拖动时放大、阴影加深、其他照片避让
/// ========================================
class _DraggableImageGrid extends StatefulWidget {
  final List<SelectedImage> images;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onDelete;

  const _DraggableImageGrid({
    required this.images,
    required this.onReorder,
    required this.onDelete,
  });

  @override
  State<_DraggableImageGrid> createState() => _DraggableImageGridState();
}

class _DraggableImageGridState extends State<_DraggableImageGrid>
    with TickerProviderStateMixin {
  int? _draggingIndex;
  int? _hoveringIndex;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.images.asMap().entries.map((entry) {
        final index = entry.key;
        final image = entry.value;
        final isDragging = _draggingIndex == index;
        final isHovering = _hoveringIndex == index;
        final isOther = _draggingIndex != null && _draggingIndex != index;

        return LongPressDraggable<int>(
          data: index,
          onDragStarted: () {
            setState(() {
              _draggingIndex = index;
            });
            _animationController.forward();
          },
          onDragEnd: (_) {
            setState(() {
              _draggingIndex = null;
              _hoveringIndex = null;
            });
            _animationController.reverse();
          },
          feedback: _buildDraggingFeedback(image, index),
          childWhenDragging: _buildPlaceholder(index),
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) {
              setState(() {
                _hoveringIndex = index;
              });
              return details.data != index;
            },
            onLeave: (_) {
              setState(() {
                _hoveringIndex = null;
              });
            },
            onAcceptWithDetails: (details) {
              final fromIndex = details.data;
              if (fromIndex != index) {
                widget.onReorder(fromIndex, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                transform: _calculateTransform(isDragging, isHovering, isOther),
                transformAlignment: Alignment.center,
                child: _buildImageItem(image, index, isDragging: isDragging),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  /// 计算变换矩阵
  Matrix4 _calculateTransform(bool isDragging, bool isHovering, bool isOther) {
    if (isDragging) {
      return Matrix4.diagonal3Values(0.9, 0.9, 1.0);
    }
    if (isHovering) {
      return Matrix4.diagonal3Values(1.08, 1.08, 1.0);
    }
    if (isOther) {
      return Matrix4.diagonal3Values(0.95, 0.95, 1.0);
    }
    return Matrix4.identity();
  }

  /// 拖动时的浮动反馈（放大 + 阴影加深）
  Widget _buildDraggingFeedback(SelectedImage image, int index) {
    final itemSize = (MediaQuery.of(context).size.width - 48 - 24) / 3;
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.15,
        child: Container(
          width: itemSize,
          height: itemSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.tertiaryContainer,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                kIsWeb
                    ? Image.memory(image.bytes!, fit: BoxFit.cover)
                    : Image.file(File(image.path), fit: BoxFit.cover),
                // 页码标签
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '第${index + 1}页',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 原位置的占位符（缩小 + 半透明）
  Widget _buildPlaceholder(int index) {
    final itemSize = (MediaQuery.of(context).size.width - 48 - 24) / 3;
    return Container(
      width: itemSize,
      height: itemSize,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.tertiaryContainer.withValues(alpha: 0.5),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          '第${index + 1}页',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(SelectedImage image, int index, {bool isDragging = false}) {
    final itemSize = (MediaQuery.of(context).size.width - 48 - 24) / 3;
    return Container(
      width: itemSize,
      height: itemSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDragging ? 0.2 : 0.1),
            blurRadius: isDragging ? 16 : 8,
            offset: Offset(0, isDragging ? 6 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            kIsWeb
                ? Image.memory(image.bytes!, fit: BoxFit.cover)
                : Image.file(File(image.path), fit: BoxFit.cover),

            // 页码标签
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '第${index + 1}页',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),

            // 删除按钮
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                onTap: () => widget.onDelete(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                ),
              ),
            ),

            // 拖动指示器
            Positioned(
              right: 4,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(LucideIcons.move, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}