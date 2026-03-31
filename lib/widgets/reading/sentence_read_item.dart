import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storybird_flutter/core/theme/app_colors.dart';
import 'package:storybird_flutter/models/sentence.dart';
import 'package:storybird_flutter/providers/reading_provider.dart';
import 'package:storybird_flutter/services/tts_service.dart';

/// ========================================
/// 句子朗读状态枚举
/// ========================================
enum SentencePlayState {
  idle,
  playing,
  paused,
}

/// ========================================
/// 句子朗读项组件
///
/// 功能：
/// - 显示英文句子和序号
/// - 显示中文翻译（可切换显示/隐藏）
/// - 独立播放/暂停/继续按钮
/// - 左滑显示操作栏（修改/删除）
/// - 长按拖拽排序
/// ========================================
class SentenceReadItem extends ConsumerStatefulWidget {
  final Sentence sentence;
  final int index;
  final bool isActive;
  final bool showTranslation;
  final ValueChanged<String>? onEdit;
  final VoidCallback? onDelete;
  final bool isDragging;

  const SentenceReadItem({
    super.key,
    required this.sentence,
    required this.index,
    this.isActive = false,
    this.showTranslation = true,
    this.onEdit,
    this.onDelete,
    this.isDragging = false,
  });

  @override
  ConsumerState<SentenceReadItem> createState() => _SentenceReadItemState();
}

class _SentenceReadItemState extends ConsumerState<SentenceReadItem>
    with SingleTickerProviderStateMixin {
  SentencePlayState _playState = SentencePlayState.idle;
  bool _isEditing = false;
  late TextEditingController _editController;
  final FocusNode _focusNode = FocusNode();

  // 滑动控制
  double _swipeOffset = 0;
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.sentence.en);
    ttsService.addStateCallback(_onTtsStateChanged);
  }

  void _onTtsStateChanged() {
    if (!mounted) return;

    final readingState = ref.read(readingProvider);
    final ttsState = ttsService.state;

    if (widget.isActive) {
      setState(() {
        if (ttsState == TtsState.idle || !readingState.isPlaying) {
          _playState = SentencePlayState.idle;
        } else if (ttsState == TtsState.playing) {
          _playState = SentencePlayState.playing;
        } else if (ttsState == TtsState.paused) {
          _playState = SentencePlayState.paused;
        }
      });
    }
  }

  @override
  void dispose() {
    ttsService.removeStateCallback(_onTtsStateChanged);
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playState == SentencePlayState.playing;
    final isPaused = _playState == SentencePlayState.paused;

    // 操作栏宽度（半宽）
    final actionWidth = MediaQuery.of(context).size.width * 0.4;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 底层操作栏（仅在滑动时显示）
        if (_swipeOffset < 0)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  const Spacer(),
                  // 编辑按钮
                  GestureDetector(
                    onTap: () {
                      _resetSwipe();
                      _startEditing();
                    },
                    child: Container(
                      width: actionWidth / 2,
                      color: AppColors.primaryContainer,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.pencil, color: AppColors.onPrimaryContainer, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            '修改',
                            style: TextStyle(
                              color: AppColors.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 删除按钮
                  GestureDetector(
                    onTap: () {
                      _resetSwipe();
                      widget.onDelete?.call();
                    },
                    child: Container(
                      width: actionWidth / 2,
                      color: AppColors.errorContainer,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.trash2, color: AppColors.onErrorContainer, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            '删除',
                            style: TextStyle(
                              color: AppColors.onErrorContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 上层内容（可滑动）
        GestureDetector(
          onHorizontalDragStart: (_) {
            _isSwiping = true;
          },
          onHorizontalDragUpdate: (details) {
            if (!_isSwiping) return;
            setState(() {
              // 只允许左滑（负值），最大滑动一半宽度
              _swipeOffset = (_swipeOffset + details.delta.dx).clamp(-actionWidth, 0.0);
            });
          },
          onHorizontalDragEnd: (_) {
            _isSwiping = false;
            // 滑动超过一半时保持打开状态
            if (_swipeOffset < -actionWidth / 2) {
              setState(() {
                _swipeOffset = -actionWidth;
              });
            } else {
              _resetSwipe();
            }
          },
          onTap: _swipeOffset < 0 ? _resetSwipe : _onTap,
          child: AnimatedContainer(
            duration: _isSwiping ? Duration.zero : const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(_swipeOffset, 0, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDragging
                    ? AppColors.tertiaryContainer.withValues(alpha: 0.3)
                    : widget.isActive
                        ? AppColors.primaryContainer.withValues(alpha: 0.15)
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDragging
                      ? AppColors.tertiaryContainer
                      : widget.isActive
                          ? AppColors.primaryContainer
                          : Colors.transparent,
                  width: 2,
                ),
                boxShadow: widget.isDragging || widget.isActive
                    ? [
                        BoxShadow(
                          color: (widget.isDragging ? AppColors.tertiaryContainer : AppColors.primaryContainer)
                              .withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 拖拽手柄 + 序号
                  _buildIndexBadge(),
                  const SizedBox(width: 12),

                  // 句子内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSentenceText(),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 播放按钮
                  _buildPlayButton(isPlaying, isPaused),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _resetSwipe() {
    setState(() {
      _swipeOffset = 0;
    });
  }

  Widget _buildIndexBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: widget.isDragging
            ? AppColors.tertiaryContainer
            : widget.isActive
                ? AppColors.secondaryContainer
                : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${widget.index}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: widget.isDragging
                ? AppColors.onTertiaryContainer
                : widget.isActive
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSentenceText() {
    if (_isEditing) {
      return TextField(
        controller: _editController,
        focusNode: _focusNode,
        maxLines: null,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          height: 1.5,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _cancelEditing,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(LucideIcons.x, size: 18, color: AppColors.error),
                ),
              ),
              GestureDetector(
                onTap: _confirmEditing,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(LucideIcons.check, size: 18, color: AppColors.primaryContainer),
                ),
              ),
            ],
          ),
        ),
        onSubmitted: (_) => _confirmEditing(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.sentence.en,
          style: TextStyle(
            fontSize: widget.isActive ? 17 : 15,
            fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w600,
            color: widget.isActive
                ? AppColors.onPrimaryFixed
                : AppColors.onSurface.withValues(alpha: 0.85),
            height: 1.5,
          ),
        ),
        if (widget.showTranslation && widget.sentence.zh.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.sentence.zh,
              style: TextStyle(
                fontSize: widget.isActive ? 14 : 13,
                fontWeight: FontWeight.w500,
                color: widget.isActive
                    ? AppColors.primaryContainer.withValues(alpha: 0.9)
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayButton(bool isPlaying, bool isPaused) {
    IconData icon;
    Color bgColor;
    Color iconColor;

    if (isPlaying) {
      icon = LucideIcons.pause;
      bgColor = AppColors.secondaryContainer;
      iconColor = AppColors.onSecondaryContainer;
    } else if (isPaused) {
      icon = LucideIcons.play;
      bgColor = AppColors.tertiaryContainer;
      iconColor = AppColors.onTertiaryContainer;
    } else {
      icon = LucideIcons.volume2;
      bgColor = AppColors.primaryContainer;
      iconColor = AppColors.onPrimaryContainer;
    }

    return GestureDetector(
      onTap: _onPlayTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }

  void _onTap() {
    if (_isEditing) return;
    ref.read(readingProvider.notifier).setActiveSentence(widget.sentence.id);
  }

  Future<void> _onPlayTap() async {
    if (_isEditing) return;

    setState(() {
      _playState = SentencePlayState.playing;
    });

    ref.read(readingProvider.notifier).setActiveSentence(widget.sentence.id);

    final success = await ref.read(readingProvider.notifier).togglePlayPause(widget.sentence);

    if (mounted) {
      setState(() {
        final readingState = ref.read(readingProvider);
        if (success && readingState.isPlaying) {
          _playState = SentencePlayState.playing;
        } else {
          _playState = SentencePlayState.idle;
        }
      });

      if (!success) {
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
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    _editController.text = widget.sentence.en;
    setState(() {
      _isEditing = false;
    });
  }

  void _confirmEditing() {
    final newText = _editController.text.trim();
    if (newText.isNotEmpty && newText != widget.sentence.en) {
      widget.onEdit?.call(newText);
    }
    setState(() {
      _isEditing = false;
    });
  }
}