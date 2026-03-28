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
  /// 空闲
  idle,
  /// 播放中
  playing,
  /// 暂停中
  paused,
}

/// ========================================
/// 句子朗读项组件
///
/// 功能：
/// - 显示英文句子和序号
/// - 显示中文翻译（可切换显示/隐藏）
/// - 独立播放/暂停/继续按钮
/// - 支持长按编辑修正 OCR 错误
/// - 播放状态样式反馈
/// ========================================
class SentenceReadItem extends ConsumerStatefulWidget {
  /// 句子数据
  final Sentence sentence;

  /// 句子序号（从1开始）
  final int index;

  /// 是否为当前活跃句子
  final bool isActive;

  /// 是否显示翻译
  final bool showTranslation;

  /// 编辑回调
  final ValueChanged<String>? onEdit;

  const SentenceReadItem({
    super.key,
    required this.sentence,
    required this.index,
    this.isActive = false,
    this.showTranslation = true,
    this.onEdit,
  });

  @override
  ConsumerState<SentenceReadItem> createState() => _SentenceReadItemState();
}

class _SentenceReadItemState extends ConsumerState<SentenceReadItem> {
  /// 当前播放状态
  SentencePlayState _playState = SentencePlayState.idle;

  /// 是否处于编辑模式
  bool _isEditing = false;

  /// 编辑控制器
  late TextEditingController _editController;

  /// 焦点节点
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.sentence.en);
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playState == SentencePlayState.playing;
    final isPaused = _playState == SentencePlayState.paused;

    return GestureDetector(
      onTap: _onTap,
      onLongPress: _startEditing,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppColors.primaryContainer.withValues(alpha: 0.15)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isActive
                ? AppColors.primaryContainer
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: widget.isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 序号
            _buildIndexBadge(),
            const SizedBox(width: 12),

            // 句子内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 英文句子（可编辑）
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
    );
  }

  /// ========================================
  /// 序号徽章
  /// ========================================
  Widget _buildIndexBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: widget.isActive
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
            color: widget.isActive
                ? AppColors.onSecondaryContainer
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// ========================================
  /// 句子文本（支持编辑，支持显示翻译）
  /// ========================================
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
              // 取消按钮
              GestureDetector(
                onTap: _cancelEditing,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
              ),
              // 确认按钮
              GestureDetector(
                onTap: _confirmEditing,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    LucideIcons.check,
                    size: 18,
                    color: AppColors.primaryContainer,
                  ),
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
        // 英文句子
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

        // 中文翻译（根据 showTranslation 决定是否显示）
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

  /// ========================================
  /// 播放按钮
  /// ========================================
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
        child: Icon(
          icon,
          size: 22,
          color: iconColor,
        ),
      ),
    );
  }

  /// ========================================
  /// 点击事件
  /// ========================================
  void _onTap() {
    if (_isEditing) return;

    // 设置为活跃句子
    ref.read(readingProvider.notifier).setActiveSentence(widget.sentence.id);
  }

  /// ========================================
  /// 播放按钮点击
  /// ========================================
  Future<void> _onPlayTap() async {
    if (_isEditing) return;

    // 设置为活跃句子
    ref.read(readingProvider.notifier).setActiveSentence(widget.sentence.id);

    // 切换播放状态
    await ttsService.togglePlayPause(widget.sentence.en);

    // 更新本地状态
    setState(() {
      if (ttsService.isPlaying) {
        _playState = SentencePlayState.playing;
      } else if (ttsService.isPaused) {
        _playState = SentencePlayState.paused;
      } else {
        _playState = SentencePlayState.idle;
      }
    });

    // 监听 TTS 状态变化
    ttsService.onStateChanged = () {
      if (mounted) {
        setState(() {
          if (ttsService.isPlaying) {
            _playState = SentencePlayState.playing;
          } else if (ttsService.isPaused) {
            _playState = SentencePlayState.paused;
          } else {
            _playState = SentencePlayState.idle;
          }
        });
      }
    };
  }

  /// ========================================
  /// 开始编辑
  /// ========================================
  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    // 延迟聚焦，确保键盘弹出
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  /// ========================================
  /// 取消编辑
  /// ========================================
  void _cancelEditing() {
    _editController.text = widget.sentence.en;
    setState(() {
      _isEditing = false;
    });
  }

  /// ========================================
  /// 确认编辑
  /// ========================================
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