import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storycoe_flutter/models/sentence.dart';
import 'package:storycoe_flutter/services/api_service.dart';
import 'package:storycoe_flutter/providers/books_provider.dart';

/// 日志工具
void _log(String message, [dynamic data]) {
  final timestamp = DateTime.now().toString().substring(11, 23);
  final logMsg = '[CreateProvider][$timestamp] $message';
  if (data != null) {
    debugPrint('$logMsg: $data');
  } else {
    debugPrint(logMsg);
  }
}

/// 选中图片数据
class SelectedImage {
  final String path;
  final Uint8List? bytes;
  final String name;

  const SelectedImage({
    required this.path,
    this.bytes,
    required this.name,
  });
}

/// 生成进度状态
class GenerateProgress {
  final int step;
  final int total;
  final int progress;
  final String message;
  final Map<String, dynamic>? data;

  const GenerateProgress({
    this.step = 0,
    this.total = 0,
    this.progress = 0,
    this.message = '',
    this.data,
  });
}

/// 创作页面状态
class CreateState {
  /// 封面图片
  final SelectedImage? coverImage;

  /// 选中的图片列表（内页）
  final List<SelectedImage> images;

  /// 当前编辑的图片索引
  final int currentImageIndex;

  /// 绘本标题
  final String title;

  /// 是否正在生成
  final bool isGenerating;

  /// 生成进度
  final GenerateProgress generateProgress;

  /// 错误信息
  final String? error;

  /// 生成的书籍 ID
  final String? generatedBookId;

  const CreateState({
    this.coverImage,
    this.images = const [],
    this.currentImageIndex = 0,
    this.title = '我的绘本',
    this.isGenerating = false,
    this.generateProgress = const GenerateProgress(),
    this.error,
    this.generatedBookId,
  });

  /// 是否有图片
  bool get hasImages => images.isNotEmpty;

  /// 是否有封面
  bool get hasCover => coverImage != null;

  /// 当前图片
  SelectedImage? get currentImage =>
      images.isNotEmpty && currentImageIndex < images.length
          ? images[currentImageIndex]
          : null;

  CreateState copyWith({
    SelectedImage? coverImage,
    bool clearCover = false,
    List<SelectedImage>? images,
    int? currentImageIndex,
    String? title,
    bool? isGenerating,
    GenerateProgress? generateProgress,
    String? error,
    String? generatedBookId,
  }) {
    return CreateState(
      coverImage: clearCover ? null : (coverImage ?? this.coverImage),
      images: images ?? this.images,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      title: title ?? this.title,
      isGenerating: isGenerating ?? this.isGenerating,
      generateProgress: generateProgress ?? this.generateProgress,
      error: error,
      generatedBookId: generatedBookId ?? this.generatedBookId,
    );
  }
}

/// 创作页面状态管理
class CreateNotifier extends StateNotifier<CreateState> {
  final Ref ref;

  CreateNotifier(this.ref) : super(const CreateState());

  /// 设置封面图片
  void setCoverImage(SelectedImage image) {
    _log('设置封面图片');
    state = state.copyWith(coverImage: image);
  }

  /// 移除封面图片
  void removeCoverImage() {
    _log('移除封面图片');
    state = state.copyWith(clearCover: true);
  }

  /// 添加图片
  void addImage(SelectedImage image) {
    state = state.copyWith(
      images: [...state.images, image],
      currentImageIndex: state.images.length,
    );
  }

  /// 添加多张图片
  void addImages(List<SelectedImage> images) {
    state = state.copyWith(
      images: [...state.images, ...images],
    );
  }

  /// 移除图片
  void removeImage(int index) {
    final newImages = List<SelectedImage>.from(state.images);
    newImages.removeAt(index);

    int newIndex = state.currentImageIndex;
    if (newIndex >= newImages.length) {
      newIndex = newImages.isEmpty ? 0 : newImages.length - 1;
    }

    state = state.copyWith(
      images: newImages,
      currentImageIndex: newIndex,
    );
  }

  /// 移动图片（用于拖动排序）
  void moveImage(int oldIndex, int newIndex) {
    final newImages = List<SelectedImage>.from(state.images);
    final item = newImages.removeAt(oldIndex);
    newImages.insert(newIndex, item);
    state = state.copyWith(images: newImages);
  }

  /// 设置当前图片索引
  void setCurrentImageIndex(int index) {
    if (index >= 0 && index < state.images.length) {
      state = state.copyWith(currentImageIndex: index);
    }
  }

  /// 清空所有图片（包括封面）
  void clearImages() {
    state = const CreateState();
  }

  /// 设置绘本标题
  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// 开始生成（同步设置状态）
  void startGenerating() {
    state = state.copyWith(isGenerating: true, error: null);
  }

  /// 生成绘本
  Future<String?> generateBook(String title) async {
    _log('开始生成绘本', {
      'title': title,
      'imageCount': state.images.length,
      'hasCover': state.hasCover,
    });

    if (state.images.isEmpty) {
      _log('错误: 没有图片');
      state = state.copyWith(isGenerating: false, error: '请先上传照片');
      return null;
    }

    // 状态已由 startGenerating() 设置，这里不需要再设置

    try {
      // 获取 token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      _log('获取 token', {'hasToken': token != null, 'tokenLength': token?.length ?? 0});

      if (token == null || token.isEmpty) {
        _log('错误: token 为空，用户未登录');
        state = state.copyWith(
          isGenerating: false,
          error: '请先登录',
        );
        return null;
      }

      // 准备封面数据
      (String, List<int>)? coverData;
      if (state.coverImage != null && state.coverImage!.bytes != null) {
        coverData = ('cover.jpg', state.coverImage!.bytes!);
        _log('准备封面', {'size': state.coverImage!.bytes!.length});
      }

      // 准备图片数据
      final imageData = <(String, List<int>)>[];
      for (var i = 0; i < state.images.length; i++) {
        final image = state.images[i];
        if (image.bytes != null) {
          imageData.add(('page_${i + 1}.jpg', image.bytes!));
          _log('准备图片', {'index': i, 'name': 'page_${i + 1}.jpg', 'size': image.bytes!.length});
        }
      }

      _log('调用 API', {'imageCount': imageData.length, 'hasCover': coverData != null});

      // 调用生成 API
      final stream = generateApi.generateBook(
        title: title,
        cover: coverData,
        images: imageData,
        token: token,
      );

      String? bookId;
      int chunkCount = 0;

      await for (final chunk in stream) {
        chunkCount++;
        _log('收到数据块 #$chunkCount', {'length': chunk.length});

        // 解析 SSE 事件
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            _log('解析 SSE 数据', jsonStr.length > 100 ? jsonStr.substring(0, 100) + '...' : jsonStr);
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;

              if (data.containsKey('error')) {
                _log('收到错误响应', data['error']);
                state = state.copyWith(
                  isGenerating: false,
                  error: data['error'].toString(),
                );
                return null;
              }

              final progress = GenerateProgress(
                step: data['step'] as int? ?? 0,
                total: data['total'] as int? ?? 0,
                progress: data['progress'] as int? ?? 0,
                message: data['message'] as String? ?? '',
                data: data['data'] as Map<String, dynamic>?,
              );

              _log('更新进度', {'progress': progress.progress, 'message': progress.message});
              state = state.copyWith(generateProgress: progress);

              if (progress.data != null && progress.data!['book_id'] != null) {
                bookId = progress.data!['book_id'] as String;
                _log('获取到 bookId', bookId);
              }
            } catch (e) {
              _log('JSON 解析失败', e.toString());
            }
          }
        }
      }

      _log('生成完成', {'bookId': bookId, 'totalChunks': chunkCount});
      state = state.copyWith(
        isGenerating: false,
        generatedBookId: bookId,
        // 清空图片数据和标题，准备下次创作
        clearCover: true,
        images: [],
        title: '我的绘本',
      );

      // 刷新书籍列表
      if (bookId != null) {
        _log('刷新书籍列表');
        ref.read(booksProvider.notifier).loadBooks();
      }

      return bookId;
    } catch (e, stackTrace) {
      _log('生成异常', e.toString());
      _log('堆栈', stackTrace.toString());

      // 检测是否是连接关闭错误（切换应用导致）
      String errorMessage = '生成失败: $e';
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('connection closed') ||
          errorStr.contains('connection reset') ||
          errorStr.contains('broken pipe') ||
          errorStr.contains('socketexception') ||
          errorStr.contains('clientexception')) {
        errorMessage = '网络连接已断开，可能是因为切换了应用。\n请检查绘本架，如果未生成成功请重试。';
      }

      state = state.copyWith(
        isGenerating: false,
        error: errorMessage,
      );
      return null;
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 重置生成状态（保留图片和标题，用于重试）
  void reset() {
    state = state.copyWith(
      isGenerating: false,
      generateProgress: const GenerateProgress(),
      error: null,
      generatedBookId: null,
    );
  }

  /// 完全重置所有状态（用于生成成功后）
  void resetAll() {
    state = const CreateState();
  }
}

/// 创作页面 Provider
final createProvider =
    StateNotifierProvider<CreateNotifier, CreateState>((ref) {
  return CreateNotifier(ref);
});

/// 便捷 Providers
final selectedImagesProvider = Provider<List<SelectedImage>>((ref) {
  return ref.watch(createProvider).images;
});

final coverImageProvider = Provider<SelectedImage?>((ref) {
  return ref.watch(createProvider).coverImage;
});

final currentImageProvider = Provider<SelectedImage?>((ref) {
  return ref.watch(createProvider).currentImage;
});

final isGeneratingProvider = Provider<bool>((ref) {
  return ref.watch(createProvider).isGenerating;
});

final generateProgressProvider = Provider<GenerateProgress>((ref) {
  return ref.watch(createProvider).generateProgress;
});

final titleProvider = Provider<String>((ref) {
  return ref.watch(createProvider).title;
});