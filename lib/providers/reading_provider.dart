import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybird_flutter/models/book.dart';
import 'package:storybird_flutter/models/sentence.dart';
import 'package:storybird_flutter/services/api_service.dart';
import 'package:storybird_flutter/services/tts_service.dart';

/// ========================================
/// 阅读页面状态
/// ========================================
class ReadingState {
  /// 当前绘本详情（从API加载）
  final BookDetail? bookDetail;

  /// 当前书架上的绘本信息
  final Book? currentBook;

  /// 当前页码（从0开始）
  final int currentPage;

  /// 已加载的页面数据缓存
  final Map<int, BookPage> loadedPages;

  /// 当前活跃句子ID
  final String? activeSentenceId;

  /// 是否显示翻译
  final bool showTranslation;

  /// 朗读速度: '慢', '中', '正常'
  final String speedLabel;

  /// 发音偏好: '美式', '英式'
  final String accent;

  /// 是否正在播放
  final bool isPlaying;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  const ReadingState({
    this.bookDetail,
    this.currentBook,
    this.currentPage = 0,
    this.loadedPages = const {},
    this.activeSentenceId,
    this.showTranslation = true,
    this.speedLabel = '中',
    this.accent = '美式',
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
  });

  /// 总页数
  int get totalPages {
    if (bookDetail != null && bookDetail!.pages.isNotEmpty) {
      return bookDetail!.totalPages;
    }
    return loadedPages.isNotEmpty ? loadedPages.length : 1;
  }

  /// 当前页面数据
  BookPage? get currentPageData {
    // 优先从缓存获取
    if (loadedPages.containsKey(currentPage)) {
      return loadedPages[currentPage];
    }
    // 其次从 bookDetail 获取
    if (bookDetail != null &&
        currentPage >= 0 &&
        currentPage < bookDetail!.pages.length) {
      return bookDetail!.pages[currentPage];
    }
    return null;
  }

  /// 当前页面的句子列表
  List<Sentence> get currentSentences {
    final page = currentPageData;
    if (page != null && page.sentences.isNotEmpty) {
      return page.sentences;
    }
    return [];
  }

  /// 获取语速对应的 speech rate (0.0 - 1.0)
  double get speechRate {
    switch (speedLabel) {
      case '慢':
        return 0.3;
      case '中':
        return 0.45;
      case '正常':
        return 0.6;
      default:
        return 0.45;
    }
  }

  /// 获取发音对应的语言代码
  String get languageCode {
    switch (accent) {
      case '英式':
        return 'en-GB';
      case '美式':
        return 'en-US';
      default:
        return 'en-US';
    }
  }

  ReadingState copyWith({
    BookDetail? bookDetail,
    Book? currentBook,
    int? currentPage,
    Map<int, BookPage>? loadedPages,
    String? activeSentenceId,
    bool? showTranslation,
    String? speedLabel,
    String? accent,
    bool? isPlaying,
    bool? isLoading,
    String? error,
    bool clearBookDetail = false,
    bool clearActiveSentence = false,
    bool clearError = false,
  }) {
    return ReadingState(
      bookDetail: clearBookDetail ? null : (bookDetail ?? this.bookDetail),
      currentBook: currentBook ?? this.currentBook,
      currentPage: currentPage ?? this.currentPage,
      loadedPages: loadedPages ?? this.loadedPages,
      activeSentenceId: clearActiveSentence ? null : (activeSentenceId ?? this.activeSentenceId),
      showTranslation: showTranslation ?? this.showTranslation,
      speedLabel: speedLabel ?? this.speedLabel,
      accent: accent ?? this.accent,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ========================================
/// 阅读状态管理
/// ========================================
class ReadingNotifier extends StateNotifier<ReadingState> {
  final TtsService _ttsService;

  ReadingNotifier({TtsService? ttsService})
      : _ttsService = ttsService ?? TtsService(),
        super(const ReadingState());

  /// ========================================
  /// 开始阅读（从书架点击进入）
  /// ========================================
  Future<void> startReading(Book book) async {
    debugPrint('[startReading] 开始阅读: bookId=${book.id}, title=${book.title}');
    state = state.copyWith(
      currentBook: book,
      currentPage: 0,
      isLoading: true,
      clearBookDetail: true,
      clearActiveSentence: true,
      clearError: true,
    );

    try {
      // 加载绘本详情
      debugPrint('[startReading] 加载绘本详情...');
      final bookDetailData = await booksApi.getBook(book.id);
      debugPrint('[startReading] 绘本详情响应: pages=${(bookDetailData['pages'] as List?)?.length ?? 0}');
      final bookDetail = BookDetail.fromJson(bookDetailData);
      debugPrint('[startReading] 解析成功: totalPages=${bookDetail.totalPages}, pages数量=${bookDetail.pages.length}');

      // 打印每页的基本信息
      for (var i = 0; i < bookDetail.pages.length; i++) {
        final page = bookDetail.pages[i];
        debugPrint('[startReading] 页面$i: pageNumber=${page.pageNumber}, imageUrl=${page.imageUrl}, sentences=${page.sentences.length}');
      }

      // 更新状态
      state = state.copyWith(
        bookDetail: bookDetail,
        isLoading: false,
      );
      debugPrint('[startReading] 状态更新: totalPages=${state.totalPages}');

      // 加载第一页内容
      debugPrint('[startReading] 开始加载第一页...');
      await _loadPage(0);
      debugPrint('[startReading] 第一页加载完成, loadedPages=${state.loadedPages.length}');

      debugPrint('[startReading] 开始阅读完成: ${book.title}, 总页数: ${state.totalPages}');
    } catch (e) {
      debugPrint('[startReading] 加载绘本失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载绘本失败: $e',
      );
    }
  }

  /// ========================================
  /// 通过 bookId 开始阅读（从创作页或直接路由进入）
  /// ========================================
  Future<void> startReadingById(String bookId) async {
    debugPrint('[startReadingById] 开始阅读: bookId=$bookId');

    // 如果已经加载了相同的书，跳过
    if (state.currentBook?.id == bookId && state.bookDetail != null) {
      debugPrint('[startReadingById] 书籍已加载，跳过');
      return;
    }

    state = state.copyWith(
      currentPage: 0,
      isLoading: true,
      clearBookDetail: true,
      clearActiveSentence: true,
      clearError: true,
    );

    try {
      // 先加载绘本基本信息
      debugPrint('[startReadingById] 加载绘本基本信息...');
      final bookData = await booksApi.getBook(bookId);
      final book = Book.fromJson(bookData);
      debugPrint('[startReadingById] 绘本基本信息: title=${book.title}');

      // 设置 currentBook
      state = state.copyWith(currentBook: book);

      // 加载绘本详情（包含页面和句子）
      debugPrint('[startReadingById] 加载绘本详情...');
      final bookDetail = BookDetail.fromJson(bookData);
      debugPrint('[startReadingById] 解析成功: totalPages=${bookDetail.totalPages}, pages数量=${bookDetail.pages.length}');

      // 更新状态
      state = state.copyWith(
        bookDetail: bookDetail,
        isLoading: false,
      );

      // 加载第一页内容
      await _loadPage(0);
      debugPrint('[startReadingById] 开始阅读完成: ${book.title}, 总页数: ${state.totalPages}');
    } catch (e) {
      debugPrint('[startReadingById] 加载绘本失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载绘本失败: $e',
      );
    }
  }

  /// ========================================
  /// 加载指定页面
  /// ========================================
  Future<void> _loadPage(int pageIndex) async {
    debugPrint('[_loadPage] 开始加载页面: pageIndex=$pageIndex');

    if (state.currentBook == null) {
      debugPrint('[_loadPage] 错误: currentBook 为空');
      return;
    }

    // 检查是否已缓存
    if (state.loadedPages.containsKey(pageIndex)) {
      debugPrint('[_loadPage] 页面已缓存: pageIndex=$pageIndex');
      return;
    }

    // 检查 bookDetail 中是否有该页
    if (state.bookDetail != null &&
        pageIndex >= 0 &&
        pageIndex < state.bookDetail!.pages.length) {
      final page = state.bookDetail!.pages[pageIndex];
      debugPrint('[_loadPage] bookDetail 中找到页面: pageIndex=$pageIndex, sentences=${page.sentences.length}');
      if (page.sentences.isNotEmpty) {
        // 已有数据，加入缓存
        state = state.copyWith(
          loadedPages: {...state.loadedPages, pageIndex: page},
        );
        debugPrint('[_loadPage] 从 bookDetail 缓存页面: pageIndex=$pageIndex');
        return;
      }
    }

    try {
      // 从API加载页面（页码从1开始）
      debugPrint('[_loadPage] 从API加载: bookId=${state.currentBook!.id}, pageNumber=${pageIndex + 1}');
      final pageData = await booksApi.getBookPage(
        state.currentBook!.id,
        pageIndex + 1,
      );
      debugPrint('[_loadPage] API响应: pageNumber=${pageData['page_number']}, sentences=${(pageData['sentences'] as List?)?.length ?? 0}');
      final page = BookPage.fromJson(pageData);
      debugPrint('[_loadPage] 解析成功: page.pageNumber=${page.pageNumber}, sentences=${page.sentences.length}');

      // 更新缓存
      state = state.copyWith(
        loadedPages: {...state.loadedPages, pageIndex: page},
      );
      debugPrint('[_loadPage] 缓存成功: pageIndex=$pageIndex, 总缓存数=${state.loadedPages.length}');
    } catch (e) {
      debugPrint('[_loadPage] 加载页面失败: pageIndex=$pageIndex, error=$e');
    }
  }

  /// ========================================
  /// 切换到指定页
  /// ========================================
  Future<void> goToPage(int pageIndex) async {
    debugPrint('[goToPage] 请求切换到页面: pageIndex=$pageIndex, totalPages=${state.totalPages}');

    if (pageIndex < 0 || pageIndex >= state.totalPages) {
      debugPrint('[goToPage] 无效页码: pageIndex=$pageIndex, totalPages=${state.totalPages}');
      return;
    }

    // 停止当前播放
    await stopPlaying();

    // 加载目标页
    debugPrint('[goToPage] 开始加载页面...');
    await _loadPage(pageIndex);

    // 更新当前页
    final sentences = state.loadedPages[pageIndex]?.sentences ?? [];
    debugPrint('[goToPage] 页面加载完成, sentences数量=${sentences.length}');
    state = state.copyWith(
      currentPage: pageIndex,
      activeSentenceId: sentences.isNotEmpty ? sentences.first.id : null,
    );
    debugPrint('[goToPage] 状态已更新: currentPage=${state.currentPage}');
  }

  /// ========================================
  /// 下一页
  /// ========================================
  Future<void> nextPage() async {
    debugPrint('[nextPage] 当前页=${state.currentPage}, 总页数=${state.totalPages}');
    if (state.currentPage < state.totalPages - 1) {
      debugPrint('[nextPage] 切换到下一页: ${state.currentPage + 1}');
      await goToPage(state.currentPage + 1);
    } else {
      debugPrint('[nextPage] 已到最后一页，无法继续');
    }
  }

  /// ========================================
  /// 上一页
  /// ========================================
  Future<void> prevPage() async {
    debugPrint('[prevPage] 当前页=${state.currentPage}, 总页数=${state.totalPages}');
    if (state.currentPage > 0) {
      debugPrint('[prevPage] 切换到上一页: ${state.currentPage - 1}');
      await goToPage(state.currentPage - 1);
    } else {
      debugPrint('[prevPage] 已到第一页，无法继续');
    }
  }

  /// ========================================
  /// 设置当前活跃句子
  /// ========================================
  void setActiveSentence(String? sentenceId) {
    state = state.copyWith(activeSentenceId: sentenceId);
  }

  /// ========================================
  /// 切换翻译显示
  /// ========================================
  void toggleTranslation() {
    state = state.copyWith(showTranslation: !state.showTranslation);
  }

  /// ========================================
  /// 设置朗读速度
  /// ========================================
  void setSpeed(String speedLabel) {
    state = state.copyWith(speedLabel: speedLabel);
    // 更新 TTS 语速
    _ttsService.setSpeechRate(state.speechRate);
  }

  /// ========================================
  /// 设置发音偏好
  /// ========================================
  void setAccent(String accent) {
    state = state.copyWith(accent: accent);
    // 更新 TTS 语言
    _ttsService.setLanguage(state.languageCode);
  }

  /// ========================================
  /// 播放句子
  /// ========================================
  Future<void> playSentence(Sentence sentence) async {
    await _ttsService.init();

    // 停止当前播放
    if (_ttsService.isPlaying) {
      await _ttsService.stop();
    }

    // 设置当前语速和语言
    await _ttsService.setSpeechRate(state.speechRate);
    await _ttsService.setLanguage(state.languageCode);

    // 设置活跃句子
    state = state.copyWith(
      activeSentenceId: sentence.id,
      isPlaying: true,
    );

    // 开始播放
    final success = await _ttsService.speak(sentence.en);
    if (!success) {
      state = state.copyWith(isPlaying: false);
    }
  }

  /// ========================================
  /// 暂停播放
  /// ========================================
  Future<void> pauseSentence() async {
    await _ttsService.pause();
    state = state.copyWith(isPlaying: false);
  }

  /// ========================================
  /// 继续播放
  /// ========================================
  Future<void> resumeSentence() async {
    if (state.currentSentences.isEmpty) return;

    final sentence = state.currentSentences.firstWhere(
      (s) => s.id == state.activeSentenceId,
      orElse: () => state.currentSentences.first,
    );
    await playSentence(sentence);
  }

  /// ========================================
  /// 停止播放
  /// ========================================
  Future<void> stopPlaying() async {
    await _ttsService.stop();
    state = state.copyWith(isPlaying: false);
  }

  /// ========================================
  /// 切换播放/暂停
  /// ========================================
  Future<void> togglePlayPause(Sentence sentence) async {
    if (state.isPlaying && state.activeSentenceId == sentence.id) {
      await pauseSentence();
    } else {
      await playSentence(sentence);
    }
  }

  /// ========================================
  /// 停止阅读
  /// ========================================
  Future<void> stopReading() async {
    await _ttsService.stop();
    state = const ReadingState();
  }

  /// ========================================
  /// 清除错误
  /// ========================================
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// ========================================
/// 阅读页面 Provider
/// ========================================
final readingProvider =
    StateNotifierProvider<ReadingNotifier, ReadingState>((ref) {
  return ReadingNotifier();
});

/// ========================================
/// 便捷 Providers
/// ========================================
final currentBookProvider = Provider<Book?>((ref) {
  return ref.watch(readingProvider).currentBook;
});

final currentPageProvider = Provider<int>((ref) {
  return ref.watch(readingProvider).currentPage;
});

final totalPagesProvider = Provider<int>((ref) {
  return ref.watch(readingProvider).totalPages;
});

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(readingProvider).isPlaying;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(readingProvider).isLoading;
});

final currentSentencesProvider = Provider<List<Sentence>>((ref) {
  return ref.watch(readingProvider).currentSentences;
});