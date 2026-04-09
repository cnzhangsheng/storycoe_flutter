import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storycoe_flutter/core/utils/logger.dart';
import 'package:storycoe_flutter/models/book.dart';
import 'package:storycoe_flutter/models/sentence.dart';
import 'package:storycoe_flutter/services/api_service.dart';
import 'package:storycoe_flutter/services/tts_service.dart';

/// Maximum number of pages to cache
const int _maxCachedPages = 10;

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

  /// 是否循环播放
  final bool loopEnabled;

  /// 是否正在播放
  final bool isPlaying;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  /// 整页朗读：是否正在播放整页
  final bool isPlayingAll;

  /// 整页朗读：当前句子索引（-1 表示未开始）
  final int playingAllIndex;

  /// 整页朗读：是否暂停
  final bool isPlayingAllPaused;

  /// 当前播放的单词起始位置（用于单词级高亮）
  final int currentWordStart;

  /// 当前播放的单词结束位置
  final int currentWordEnd;

  const ReadingState({
    this.bookDetail,
    this.currentBook,
    this.currentPage = 0,
    this.loadedPages = const {},
    this.activeSentenceId,
    this.showTranslation = true,
    this.speedLabel = '中',
    this.accent = '美式',
    this.loopEnabled = false,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
    this.isPlayingAll = false,
    this.playingAllIndex = -1,
    this.isPlayingAllPaused = false,
    this.currentWordStart = -1,
    this.currentWordEnd = -1,
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

  /// 获取语速对应的 speech rate
  /// Android TTS 范围: 0.5 - 2.0，但部分引擎支持更小值
  double get speechRate {
    switch (speedLabel) {
      case '慢':
        return 0.1;
      case '中':
        return 0.3;
      case '正常':
        return 0.5;
      default:
        return 0.3;
    }
  }

  /// 获取发音对应的语言代码
  String get languageCode {
    switch (accent) {
      case '英式':
        return 'en-GB';
      case '美式':
        return 'en-US';
      case '默认':
        return 'en';
      default:
        return 'en';
    }
  }

  /// 获取可用的发音选项列表
  List<String> get availableAccents => ttsService.getAvailableAccents();

  ReadingState copyWith({
    BookDetail? bookDetail,
    Book? currentBook,
    int? currentPage,
    Map<int, BookPage>? loadedPages,
    String? activeSentenceId,
    bool? showTranslation,
    String? speedLabel,
    String? accent,
    bool? loopEnabled,
    bool? isPlaying,
    bool? isLoading,
    String? error,
    bool? isPlayingAll,
    int? playingAllIndex,
    bool? isPlayingAllPaused,
    int? currentWordStart,
    int? currentWordEnd,
    bool clearBookDetail = false,
    bool clearActiveSentence = false,
    bool clearError = false,
    bool clearPlayingAll = false,
    bool clearWordProgress = false,
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
      loopEnabled: loopEnabled ?? this.loopEnabled,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isPlayingAll: clearPlayingAll ? false : (isPlayingAll ?? this.isPlayingAll),
      playingAllIndex: clearPlayingAll ? -1 : (playingAllIndex ?? this.playingAllIndex),
      isPlayingAllPaused: clearPlayingAll ? false : (isPlayingAllPaused ?? this.isPlayingAllPaused),
      currentWordStart: clearWordProgress ? -1 : (currentWordStart ?? this.currentWordStart),
      currentWordEnd: clearWordProgress ? -1 : (currentWordEnd ?? this.currentWordEnd),
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
        super(const ReadingState()) {
    // 使用新的回调机制，确保状态同步
    _ttsService.addStateCallback(_onTtsStateChanged);
    // 添加进度回调（用于单词级高亮）
    _ttsService.addProgressCallback(_onTtsProgress);
    // 加载用户设置
    _loadUserSettings();
  }

  /// Add a page to the cache with LRU eviction
  /// Keeps only the most recently used pages up to _maxCachedPages
  Map<int, BookPage> _addToPageCache(
    Map<int, BookPage> currentCache,
    int pageIndex,
    BookPage page,
  ) {
    final newCache = Map<int, BookPage>.from(currentCache);

    // If key already exists, remove it first (will be re-added as most recent)
    newCache.remove(pageIndex);

    // If cache is full, remove the oldest entry (first key)
    if (newCache.length >= _maxCachedPages) {
      final oldestKey = newCache.keys.first;
      newCache.remove(oldestKey);
      log('[ReadingProvider] [_addToPageCache] 移除最早缓存页面: $oldestKey');
    }

    // Add the new page
    newCache[pageIndex] = page;
    return newCache;
  }

  /// 从后端加载用户设置
  Future<void> _loadUserSettings() async {
    try {
      final settings = await usersApi.getSettings();
      final speedLabel = settings['speed_label'] as String? ?? '中';
      final accentRaw = settings['accent'] as String? ?? 'US';
      final loopEnabled = settings['loop_enabled'] as bool? ?? false;

      // 转换发音设置
      String accent;
      switch (accentRaw) {
        case 'US':
          accent = '美式';
          break;
        case 'GB':
          accent = '英式';
          break;
        default:
          accent = '默认';
      }

      state = state.copyWith(
        speedLabel: speedLabel,
        accent: accent,
        loopEnabled: loopEnabled,
      );

      // 更新 TTS 参数
      await _ttsService.setSpeechRate(state.speechRate);
      await _ttsService.setLanguage(state.languageCode);

      log('[ReadingProvider] [ReadingNotifier] 用户设置已加载: speed=$speedLabel, accent=$accent, loop=$loopEnabled');
    } catch (e) {
      log('[ReadingProvider] [ReadingNotifier] 加载用户设置失败: $e');
    }
  }

  /// TTS 状态变化回调
  void _onTtsStateChanged() {
    log('[ReadingProvider] [ReadingNotifier] TTS 状态变化: ${_ttsService.state}');
    // 当 TTS 变为 idle 状态时，更新 isPlaying 为 false
    if (_ttsService.state == TtsState.idle && state.isPlaying) {
      log('[ReadingProvider] [ReadingNotifier] TTS 播放完成');

      // 清除单词进度
      state = state.copyWith(clearWordProgress: true);

      // 整页朗读模式：自动播放下一个句子
      if (state.isPlayingAll && !state.isPlayingAllPaused) {
        final nextIndex = state.playingAllIndex + 1;
        final sentences = state.currentSentences;

        if (nextIndex < sentences.length) {
          // 还有下一个句子
          log('[ReadingProvider] [ReadingNotifier] 整页朗读下一个句子: $nextIndex');
          _playSentenceInSequence(nextIndex);
        } else {
          // 所有句子播放完成
          log('[ReadingProvider] [ReadingNotifier] 整页朗读完成');
          state = state.copyWith(
            isPlayingAll: false,
            playingAllIndex: -1,
            isPlaying: false,
          );
        }
        return;
      }

      // 普通播放完成
      state = state.copyWith(isPlaying: false);

      // 循环播放：自动播放下一个句子
      if (state.loopEnabled) {
        _playNextSentence();
      }
    }
  }

  /// TTS 进度回调（单词级高亮）
  void _onTtsProgress(TtsProgress progress) {
    // 只在播放状态时更新进度
    if (state.isPlaying && state.activeSentenceId != null) {
      state = state.copyWith(
        currentWordStart: progress.start,
        currentWordEnd: progress.end,
      );
    }
  }

  /// 循环播放下一个句子
  void _playNextSentence() {
    final sentences = state.currentSentences;
    if (sentences.isEmpty) return;

    // 找到当前活跃句子的索引
    final currentIndex = sentences.indexWhere((s) => s.id == state.activeSentenceId);

    // 如果是最后一个句子，回到第一个；否则播放下一个
    final nextIndex = (currentIndex + 1) % sentences.length;
    final nextSentence = sentences[nextIndex];

    log('[ReadingProvider] [ReadingNotifier] 循环播放下一个句子: ${nextSentence.en}');
    playSentence(nextSentence);
  }

  /// ========================================
  /// 开始阅读（从书架点击进入）
  /// ========================================
  Future<void> startReading(Book book) async {
    log('[ReadingProvider] [startReading] 开始阅读: bookId=${book.id}, title=${book.title}');
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
      log('[ReadingProvider] [startReading] 加载绘本详情...');
      final bookDetailData = await booksApi.getBook(book.id);
      log('[ReadingProvider] [startReading] 绘本详情响应: pages=${(bookDetailData['pages'] as List?)?.length ?? 0}');
      final bookDetail = BookDetail.fromJson(bookDetailData);
      log('[ReadingProvider] [startReading] 解析成功: totalPages=${bookDetail.totalPages}, pages数量=${bookDetail.pages.length}');

      // 打印每页的基本信息
      for (var i = 0; i < bookDetail.pages.length; i++) {
        final page = bookDetail.pages[i];
        log('[ReadingProvider] [startReading] 页面$i: pageNumber=${page.pageNumber}, imageUrl=${page.imageUrl}, sentences=${page.sentences.length}');
      }

      // 更新状态
      state = state.copyWith(
        bookDetail: bookDetail,
        isLoading: false,
      );
      log('[ReadingProvider] [startReading] 状态更新: totalPages=${state.totalPages}');

      // 尝试恢复本地保存的进度
      final savedPage = await _restoreProgressLocally(book.id);
      int startPage = 0;
      if (savedPage != null && savedPage >= 0 && savedPage < bookDetail.totalPages) {
        startPage = savedPage;
        log('[ReadingProvider] [startReading] 从本地恢复进度: 第${startPage + 1}页');
      }

      // 加载起始页内容
      log('[ReadingProvider] [startReading] 开始加载第${startPage + 1}页...');
      await _loadPage(startPage);
      log('[ReadingProvider] [startReading] 页面加载完成, loadedPages=${state.loadedPages.length}');

      // 设置当前页
      if (startPage > 0) {
        final sentences = state.loadedPages[startPage]?.sentences ?? [];
        state = state.copyWith(
          currentPage: startPage,
          activeSentenceId: sentences.isNotEmpty ? sentences.first.id : null,
        );
      }

      // 预加载相邻页面
      _preloadAdjacentPages(startPage);

      log('[ReadingProvider] [startReading] 开始阅读完成: ${book.title}, 当前页: ${state.currentPage + 1}, 总页数: ${state.totalPages}');
    } catch (e) {
      log('[ReadingProvider] [startReading] 加载绘本失败: $e');
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
    log('[ReadingProvider] [startReadingById] 开始阅读: bookId=$bookId');

    // 如果已经加载了相同的书，跳过
    if (state.currentBook?.id == bookId && state.bookDetail != null) {
      log('[ReadingProvider] [startReadingById] 书籍已加载，跳过');
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
      log('[ReadingProvider] [startReadingById] 加载绘本基本信息...');
      final bookData = await booksApi.getBook(bookId);
      final book = Book.fromJson(bookData);
      log('[ReadingProvider] [startReadingById] 绘本基本信息: title=${book.title}');

      // 设置 currentBook
      state = state.copyWith(currentBook: book);

      // 加载绘本详情（包含页面和句子）
      log('[ReadingProvider] [startReadingById] 加载绘本详情...');
      final bookDetail = BookDetail.fromJson(bookData);
      log('[ReadingProvider] [startReadingById] 解析成功: totalPages=${bookDetail.totalPages}, pages数量=${bookDetail.pages.length}');

      // 更新状态
      state = state.copyWith(
        bookDetail: bookDetail,
        isLoading: false,
      );

      // 尝试恢复本地保存的进度
      final savedPage = await _restoreProgressLocally(bookId);
      int startPage = 0;
      if (savedPage != null && savedPage >= 0 && savedPage < bookDetail.totalPages) {
        startPage = savedPage;
        log('[ReadingProvider] [startReadingById] 从本地恢复进度: 第${startPage + 1}页');
      }

      // 加载起始页内容
      await _loadPage(startPage);
      log('[ReadingProvider] [startReadingById] 页面加载完成');

      // 设置当前页
      if (startPage > 0) {
        final sentences = state.loadedPages[startPage]?.sentences ?? [];
        state = state.copyWith(
          currentPage: startPage,
          activeSentenceId: sentences.isNotEmpty ? sentences.first.id : null,
        );
      }

      // 预加载相邻页面
      _preloadAdjacentPages(startPage);

      log('[ReadingProvider] [startReadingById] 开始阅读完成: ${book.title}, 当前页: ${state.currentPage + 1}, 总页数: ${state.totalPages}');
    } catch (e) {
      log('[ReadingProvider] [startReadingById] 加载绘本失败: $e');
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
    log('[ReadingProvider] [_loadPage] 开始加载页面: pageIndex=$pageIndex');

    if (state.currentBook == null) {
      log('[ReadingProvider] [_loadPage] 错误: currentBook 为空');
      return;
    }

    // 检查是否已缓存
    if (state.loadedPages.containsKey(pageIndex)) {
      log('[ReadingProvider] [_loadPage] 页面已缓存: pageIndex=$pageIndex');
      return;
    }

    // 检查 bookDetail 中是否有该页
    if (state.bookDetail != null &&
        pageIndex >= 0 &&
        pageIndex < state.bookDetail!.pages.length) {
      final page = state.bookDetail!.pages[pageIndex];
      log('[ReadingProvider] [_loadPage] bookDetail 中找到页面: pageIndex=$pageIndex, sentences=${page.sentences.length}');
      if (page.sentences.isNotEmpty) {
        // 已有数据，加入缓存（使用 LRU 策略）
        state = state.copyWith(
          loadedPages: _addToPageCache(state.loadedPages, pageIndex, page),
        );
        log('[ReadingProvider] [_loadPage] 从 bookDetail 缓存页面: pageIndex=$pageIndex');
        return;
      }
    }

    try {
      // 从API加载页面（页码从1开始）
      log('[ReadingProvider] [_loadPage] 从API加载: bookId=${state.currentBook!.id}, pageNumber=${pageIndex + 1}');
      final pageData = await booksApi.getBookPage(
        state.currentBook!.id,
        pageIndex + 1,
      );
      log('[ReadingProvider] [_loadPage] API响应: pageNumber=${pageData['page_number']}, sentences=${(pageData['sentences'] as List?)?.length ?? 0}');
      final page = BookPage.fromJson(pageData);
      log('[ReadingProvider] [_loadPage] 解析成功: page.pageNumber=${page.pageNumber}, sentences=${page.sentences.length}');

      // 更新缓存（使用 LRU 策略）
      state = state.copyWith(
        loadedPages: _addToPageCache(state.loadedPages, pageIndex, page),
      );
      log('[ReadingProvider] [_loadPage] 缓存成功: pageIndex=$pageIndex, 总缓存数=${state.loadedPages.length}');
    } catch (e) {
      log('[ReadingProvider] [_loadPage] 加载页面失败: pageIndex=$pageIndex, error=$e');
    }
  }

  /// ========================================
  /// 切换到指定页
  /// ========================================
  Future<void> goToPage(int pageIndex) async {
    log('[ReadingProvider] [goToPage] 请求切换到页面: pageIndex=$pageIndex, totalPages=${state.totalPages}');

    if (pageIndex < 0 || pageIndex >= state.totalPages) {
      log('[ReadingProvider] [goToPage] 无效页码: pageIndex=$pageIndex, totalPages=${state.totalPages}');
      return;
    }

    // 停止当前播放（包括整页朗读）
    await stopAllSentences();

    // 加载目标页
    log('[ReadingProvider] [goToPage] 开始加载页面...');
    await _loadPage(pageIndex);

    // 更新当前页
    final sentences = state.loadedPages[pageIndex]?.sentences ?? [];
    log('[ReadingProvider] [goToPage] 页面加载完成, sentences数量=${sentences.length}');
    state = state.copyWith(
      currentPage: pageIndex,
      activeSentenceId: sentences.isNotEmpty ? sentences.first.id : null,
    );
    log('[ReadingProvider] [goToPage] 状态已更新: currentPage=${state.currentPage}');

    // 同步阅读进度到后端
    await _syncProgress(pageIndex);

    // 预加载相邻页面
    _preloadAdjacentPages(pageIndex);
  }

  /// 预加载相邻页面数据
  void _preloadAdjacentPages(int currentPage) {
    final totalPages = state.totalPages;

    // 前一页
    if (currentPage > 0 && !state.loadedPages.containsKey(currentPage - 1)) {
      log('[ReadingProvider] [_preloadAdjacentPages] 预加载前一页: ${currentPage - 1}');
      _loadPage(currentPage - 1);
    }

    // 后一页
    if (currentPage < totalPages - 1 && !state.loadedPages.containsKey(currentPage + 1)) {
      log('[ReadingProvider] [_preloadAdjacentPages] 预加载后一页: ${currentPage + 1}');
      _loadPage(currentPage + 1);
    }
  }

  /// 同步阅读进度（后端 + 本地）
  Future<void> _syncProgress(int currentPage) async {
    if (state.currentBook == null) return;

    try {
      final bookId = state.currentBook!.id;
      final totalPages = state.totalPages;

      // 保存到本地（优先，确保离线也能记录）
      await _saveProgressLocally(bookId, currentPage);
      log('[ReadingProvider] [_syncProgress] 本地进度已保存: ${currentPage + 1}/$totalPages');

      // 同步到后端
      await readingApi.updateProgress(bookId, currentPage: currentPage + 1);
      log('[ReadingProvider] [_syncProgress] 后端进度已同步: ${currentPage + 1}/$totalPages');

      // 如果是最后一页，标记完成
      if (currentPage >= totalPages - 1) {
        await readingApi.markCompleted(bookId);
        log('[ReadingProvider] [_syncProgress] 绘本已标记完成');
      }
    } catch (e) {
      log('[ReadingProvider] [_syncProgress] 同步进度失败: $e');
    }
  }

  /// 保存进度到本地
  Future<void> _saveProgressLocally(String bookId, int currentPage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reading_progress_$bookId', currentPage);
    } catch (e) {
      log('[ReadingProvider] [_saveProgressLocally] 保存失败: $e');
    }
  }

  /// 从本地恢复进度
  Future<int?> _restoreProgressLocally(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPage = prefs.getInt('reading_progress_$bookId');
      return savedPage;
    } catch (e) {
      log('[ReadingProvider] [_restoreProgressLocally] 恢复失败: $e');
      return null;
    }
  }

  /// ========================================
  /// 下一页
  /// ========================================
  Future<void> nextPage() async {
    log('[ReadingProvider] [nextPage] 当前页=${state.currentPage}, 总页数=${state.totalPages}');
    if (state.currentPage < state.totalPages - 1) {
      log('[ReadingProvider] [nextPage] 切换到下一页: ${state.currentPage + 1}');
      await goToPage(state.currentPage + 1);
    } else {
      log('[ReadingProvider] [nextPage] 已到最后一页，无法继续');
    }
  }

  /// ========================================
  /// 上一页
  /// ========================================
  Future<void> prevPage() async {
    log('[ReadingProvider] [prevPage] 当前页=${state.currentPage}, 总页数=${state.totalPages}');
    if (state.currentPage > 0) {
      log('[ReadingProvider] [prevPage] 切换到上一页: ${state.currentPage - 1}');
      await goToPage(state.currentPage - 1);
    } else {
      log('[ReadingProvider] [prevPage] 已到第一页，无法继续');
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
  Future<void> setSpeed(String speedLabel) async {
    state = state.copyWith(speedLabel: speedLabel);
    // 更新 TTS 语速
    _ttsService.setSpeechRate(state.speechRate);
    // 持久化到后端
    try {
      await usersApi.updateSettings(speedLabel: speedLabel);
      log('[ReadingProvider] [setSpeed] 语速已保存: $speedLabel');
    } catch (e) {
      log('[ReadingProvider] [setSpeed] 保存语速失败: $e');
    }
  }

  /// ========================================
  /// 设置发音偏好
  /// ========================================
  Future<void> setAccent(String accent) async {
    state = state.copyWith(accent: accent);
    // 更新 TTS 语言
    _ttsService.setLanguage(state.languageCode);
    // 持久化到后端
    try {
      await usersApi.updateSettings(accent: accent == '美式' ? 'US' : (accent == '英式' ? 'GB' : 'DEFAULT'));
      log('[ReadingProvider] [setAccent] 发音已保存: $accent');
    } catch (e) {
      log('[ReadingProvider] [setAccent] 保存发音失败: $e');
    }
  }

  /// ========================================
  /// 切换循环播放
  /// ========================================
  Future<void> toggleLoop() async {
    final newLoopEnabled = !state.loopEnabled;
    state = state.copyWith(loopEnabled: newLoopEnabled);
    log('[ReadingProvider] [toggleLoop] 循环播放: $newLoopEnabled');
    // 持久化到后端
    try {
      await usersApi.updateSettings(loopEnabled: newLoopEnabled);
      log('[ReadingProvider] [toggleLoop] 循环设置已保存: $newLoopEnabled');
    } catch (e) {
      log('[ReadingProvider] [toggleLoop] 保存循环设置失败: $e');
    }
  }

  /// ========================================
  /// 播放句子
  /// ========================================
  Future<bool> playSentence(Sentence sentence) async {
    log('[ReadingProvider] [playSentence] 开始播放: ${sentence.en}');
    log('[ReadingProvider] [playSentence] 语速: ${state.speechRate}, 语言: ${state.languageCode}');

    await _ttsService.init();
    _ttsService.clearError();

    // 停止当前播放
    if (_ttsService.isPlaying) {
      await _ttsService.stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 强制设置语速和语言（每次播放前）
    await _ttsService.setSpeechRate(state.speechRate);
    await _ttsService.setLanguage(state.languageCode);
    log('[ReadingProvider] [playSentence] TTS 参数已设置');

    // 设置活跃句子
    state = state.copyWith(
      activeSentenceId: sentence.id,
      isPlaying: true,
    );

    // 开始播放
    final success = await _ttsService.speak(sentence.en);
    if (!success) {
      final errorMsg = _ttsService.lastError ?? '播放失败';
      log('[ReadingProvider] [playSentence] 播放失败: $errorMsg');
      state = state.copyWith(
        isPlaying: false,
        error: errorMsg,
      );
      return false;
    }
    return true;
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
  Future<bool> togglePlayPause(Sentence sentence) async {
    if (state.isPlaying && state.activeSentenceId == sentence.id) {
      await pauseSentence();
      return true;
    } else {
      return await playSentence(sentence);
    }
  }

  /// ========================================
  /// 更新当前书籍标题（编辑绘本名称时调用）
  /// ========================================
  void updateCurrentBookTitle(String newTitle) {
    if (state.currentBook == null) return;

    final updatedBook = state.currentBook!.copyWith(title: newTitle);
    state = state.copyWith(currentBook: updatedBook);

    // 同时更新 bookDetail 的标题
    if (state.bookDetail != null) {
      final updatedBookDetail = state.bookDetail!.copyWith(title: newTitle);
      state = state.copyWith(bookDetail: updatedBookDetail);
    }

    log('[ReadingProvider] [updateCurrentBookTitle] 标题已更新: $newTitle');
  }

  /// ========================================
  /// 更新当前书籍分享类型（修改分享类型时调用）
  /// ========================================
  void updateCurrentBookShareType(String newShareType) {
    if (state.currentBook == null) return;

    final updatedBook = state.currentBook!.copyWith(shareType: newShareType);
    state = state.copyWith(currentBook: updatedBook);

    // 同时更新 bookDetail 的分享类型
    if (state.bookDetail != null) {
      final updatedBookDetail = state.bookDetail!.copyWith(shareType: newShareType);
      state = state.copyWith(bookDetail: updatedBookDetail);
    }

    log('[ReadingProvider] [updateCurrentBookShareType] 分享类型已更新: $newShareType');
  }

  /// ========================================
  /// 停止阅读
  /// ========================================
  Future<void> stopReading() async {
    await _ttsService.stop();
    state = const ReadingState();
  }

  /// ========================================
  /// 更新句子文本
  /// ========================================
  Future<bool> updateSentence(String sentenceId, String newText) async {
    if (state.currentBook == null) return false;

    try {
      log('[ReadingProvider] [updateSentence] 更新句子: $sentenceId -> $newText');

      // 调用 API 更新
      await booksApi.updateSentence(
        bookId: state.currentBook!.id,
        sentenceId: sentenceId,
        text: newText,
      );

      // 更新本地缓存
      final updatedPages = Map<int, BookPage>.from(state.loadedPages);
      for (final entry in updatedPages.entries) {
        final page = entry.value;
        final sentenceIndex = page.sentences.indexWhere((s) => s.id == sentenceId);
        if (sentenceIndex != -1) {
          final updatedSentences = List<Sentence>.from(page.sentences);
          updatedSentences[sentenceIndex] = updatedSentences[sentenceIndex].copyWith(en: newText);
          updatedPages[entry.key] = page.copyWith(sentences: updatedSentences);
          break;
        }
      }

      // 更新 bookDetail 中的句子
      if (state.bookDetail != null) {
        final updatedBookDetailPages = <BookPage>[];
        for (final page in state.bookDetail!.pages) {
          final sentenceIndex = page.sentences.indexWhere((s) => s.id == sentenceId);
          if (sentenceIndex != -1) {
            final updatedSentences = List<Sentence>.from(page.sentences);
            updatedSentences[sentenceIndex] = updatedSentences[sentenceIndex].copyWith(en: newText);
            updatedBookDetailPages.add(page.copyWith(sentences: updatedSentences));
          } else {
            updatedBookDetailPages.add(page);
          }
        }
        state = state.copyWith(
          loadedPages: updatedPages,
          bookDetail: state.bookDetail!.copyWith(pages: updatedBookDetailPages),
        );
      } else {
        state = state.copyWith(loadedPages: updatedPages);
      }

      log('[ReadingProvider] [updateSentence] 句子更新成功');
      return true;
    } catch (e) {
      log('[ReadingProvider] [updateSentence] 更新失败: $e');
      state = state.copyWith(error: '更新句子失败: $e');
      return false;
    }
  }

  /// ========================================
  /// 创建新句子
  /// ========================================
  Future<Sentence?> createSentence(String en, String zh) async {
    if (state.currentBook == null) return null;

    try {
      log('[ReadingProvider] [createSentence] 创建句子: en=$en, zh=$zh');

      // 调用 API 创建句子
      final response = await booksApi.createSentence(
        bookId: state.currentBook!.id,
        pageNumber: state.currentPage + 1, // API 使用 1-based 页码
        en: en,
        zh: zh,
      );

      // 创建新的 Sentence 对象
      final newSentence = Sentence.fromJson(response);

      // 更新本地缓存
      final updatedPages = Map<int, BookPage>.from(state.loadedPages);
      if (updatedPages.containsKey(state.currentPage)) {
        final page = updatedPages[state.currentPage]!;
        final updatedSentences = List<Sentence>.from(page.sentences);
        updatedSentences.add(newSentence);
        updatedPages[state.currentPage] = page.copyWith(sentences: updatedSentences);
      }

      // 更新 bookDetail 中的句子
      if (state.bookDetail != null) {
        final updatedBookDetailPages = <BookPage>[];
        for (final page in state.bookDetail!.pages) {
          if (page.pageNumber == state.currentPage + 1) {
            final updatedSentences = List<Sentence>.from(page.sentences);
            updatedSentences.add(newSentence);
            updatedBookDetailPages.add(page.copyWith(sentences: updatedSentences));
          } else {
            updatedBookDetailPages.add(page);
          }
        }
        state = state.copyWith(
          loadedPages: updatedPages,
          bookDetail: state.bookDetail!.copyWith(pages: updatedBookDetailPages),
        );
      } else {
        state = state.copyWith(loadedPages: updatedPages);
      }

      log('[ReadingProvider] [createSentence] 句子创建成功: ${newSentence.id}');
      return newSentence;
    } catch (e) {
      log('[ReadingProvider] [createSentence] 创建失败: $e');
      state = state.copyWith(error: '创建句子失败: $e');
      return null;
    }
  }

  /// ========================================
  /// 清除错误
  /// ========================================
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// ========================================
  /// 重新排序句子
  /// ========================================
  Future<bool> reorderSentences(List<String> sentenceIds) async {
    if (state.currentBook == null) return false;

    try {
      log('[ReadingProvider] [reorderSentences] 重新排序: $sentenceIds');

      // 调用 API 更新排序
      await booksApi.reorderSentences(
        bookId: state.currentBook!.id,
        pageNumber: state.currentPage + 1,
        sentenceIds: sentenceIds,
      );

      // 更新本地缓存中的句子顺序
      final updatedPages = Map<int, BookPage>.from(state.loadedPages);
      if (updatedPages.containsKey(state.currentPage)) {
        final page = updatedPages[state.currentPage]!;

        // 创建句子ID到句子的映射
        final sentenceMap = {for (var s in page.sentences) s.id: s};

        // 按新顺序重建句子列表
        final reorderedSentences = sentenceIds.map((id) {
          final sentence = sentenceMap[id];
          if (sentence != null) {
            // 更新序号
            final index = sentenceIds.indexOf(id);
            return sentence.copyWith(sentenceOrder: index + 1);
          }
          // 如果找不到句子，跳过
          return null;
        }).whereType<Sentence>().toList();

        updatedPages[state.currentPage] = page.copyWith(sentences: reorderedSentences);
      }

      // 更新 bookDetail 中的句子
      if (state.bookDetail != null) {
        final updatedBookDetailPages = <BookPage>[];
        for (final page in state.bookDetail!.pages) {
          if (page.pageNumber == state.currentPage + 1) {
            final sentenceMap = {for (var s in page.sentences) s.id: s};
            final reorderedSentences = sentenceIds.map((id) {
              final sentence = sentenceMap[id];
              if (sentence != null) {
                final index = sentenceIds.indexOf(id);
                return sentence.copyWith(sentenceOrder: index + 1);
              }
              return null;
            }).whereType<Sentence>().toList();
            updatedBookDetailPages.add(page.copyWith(sentences: reorderedSentences));
          } else {
            updatedBookDetailPages.add(page);
          }
        }
        state = state.copyWith(
          loadedPages: updatedPages,
          bookDetail: state.bookDetail!.copyWith(pages: updatedBookDetailPages),
        );
      } else {
        state = state.copyWith(loadedPages: updatedPages);
      }

      log('[ReadingProvider] [reorderSentences] 排序更新成功');
      return true;
    } catch (e) {
      log('[ReadingProvider] [reorderSentences] 排序更新失败: $e');
      state = state.copyWith(error: '排序更新失败: $e');
      return false;
    }
  }

  /// ========================================
  /// 删除句子
  /// ========================================
  Future<bool> deleteSentence(String sentenceId) async {
    if (state.currentBook == null) return false;

    try {
      log('[ReadingProvider] [deleteSentence] 删除句子: $sentenceId');

      // 调用 API 删除
      await booksApi.deleteSentence(
        bookId: state.currentBook!.id,
        sentenceId: sentenceId,
      );

      // 更新本地缓存
      final updatedPages = Map<int, BookPage>.from(state.loadedPages);
      if (updatedPages.containsKey(state.currentPage)) {
        final page = updatedPages[state.currentPage]!;
        final updatedSentences = page.sentences.where((s) => s.id != sentenceId).toList();
        updatedPages[state.currentPage] = page.copyWith(sentences: updatedSentences);
      }

      // 更新 bookDetail 中的句子
      if (state.bookDetail != null) {
        final updatedBookDetailPages = <BookPage>[];
        for (final page in state.bookDetail!.pages) {
          if (page.pageNumber == state.currentPage + 1) {
            final updatedSentences = page.sentences.where((s) => s.id != sentenceId).toList();
            updatedBookDetailPages.add(page.copyWith(sentences: updatedSentences));
          } else {
            updatedBookDetailPages.add(page);
          }
        }
        state = state.copyWith(
          loadedPages: updatedPages,
          bookDetail: state.bookDetail!.copyWith(pages: updatedBookDetailPages),
        );
      } else {
        state = state.copyWith(loadedPages: updatedPages);
      }

      log('[ReadingProvider] [deleteSentence] 句子删除成功');
      return true;
    } catch (e) {
      log('[ReadingProvider] [deleteSentence] 删除失败: $e');
      state = state.copyWith(error: '删除句子失败: $e');
      return false;
    }
  }

  /// ========================================
  /// 刷新绘本详情（添加/删除页面后调用）
  /// ========================================
  Future<void> refreshBookDetail() async {
    if (state.currentBook == null) return;

    try {
      log('[ReadingProvider] [refreshBookDetail] 刷新绘本详情');

      final bookDetailData = await booksApi.getBook(state.currentBook!.id);
      final bookDetail = BookDetail.fromJson(bookDetailData);

      // 清除页面缓存
      state = state.copyWith(
        bookDetail: bookDetail,
        loadedPages: {},
      );

      // 重新加载当前页
      if (state.currentPage >= bookDetail.totalPages) {
        // 如果当前页超出范围，跳转到最后一页
        final newPage = (bookDetail.totalPages - 1).clamp(0, bookDetail.totalPages - 1);
        state = state.copyWith(currentPage: newPage);
      }

      await _loadPage(state.currentPage);

      log('[ReadingProvider] [refreshBookDetail] 刷新完成: totalPages=${bookDetail.totalPages}');
    } catch (e) {
      log('[ReadingProvider] [refreshBookDetail] 刷新失败: $e');
      state = state.copyWith(error: '刷新绘本失败: $e');
    }
  }

  /// ========================================
  /// 创建新页面
  /// ========================================
  Future<bool> createPage(String filename, List<int> imageBytes, {int? pageNumber}) async {
    if (state.currentBook == null) return false;

    try {
      log('[ReadingProvider] [createPage] 创建页面');

      final response = await booksApi.createPage(
        bookId: state.currentBook!.id,
        filename: filename,
        imageBytes: imageBytes,
        pageNumber: pageNumber,
      );

      // 刷新绘本详情
      await refreshBookDetail();

      // 如果新页面状态是 processing，开始轮询
      final newPageStatus = response['status'] as String? ?? 'completed';
      if (newPageStatus == 'processing') {
        _startPollingPageStatus(response['id'] as String);
      }

      log('[ReadingProvider] [createPage] 页面创建成功');
      return true;
    } catch (e) {
      log('[ReadingProvider] [createPage] 创建失败: $e');
      state = state.copyWith(error: '创建页面失败: $e');
      return false;
    }
  }

  /// ========================================
  /// 轮询页面状态（OCR 识别中）
  /// ========================================
  void _startPollingPageStatus(String pageId) {
    log('[ReadingProvider] [_startPollingPageStatus] 开始轮询页面状态: $pageId');

    // 每 2 秒检查一次页面状态
    Future.delayed(const Duration(seconds: 2), () async {
      if (state.currentBook == null) return;

      try {
        // 刷新绘本详情
        final bookDetailData = await booksApi.getBook(state.currentBook!.id);
        final bookDetail = BookDetail.fromJson(bookDetailData);

        // 查找该页面的状态
        final page = bookDetail.pages.where((p) => p.id == pageId).firstOrNull;
        if (page == null) {
          log('[ReadingProvider] [_startPollingPageStatus] 页面不存在，停止轮询');
          return;
        }

        // 更新状态
        state = state.copyWith(bookDetail: bookDetail);

        // 如果仍在处理中，继续轮询
        if (page.status == 'processing') {
          _startPollingPageStatus(pageId);
        } else {
          log('[ReadingProvider] [_startPollingPageStatus] OCR 完成，状态: ${page.status}');
          // 重新加载当前页面
          await _loadPage(state.currentPage);
        }
      } catch (e) {
        log('[ReadingProvider] [_startPollingPageStatus] 轮询失败: $e');
        // 出错后继续轮询
        _startPollingPageStatus(pageId);
      }
    });
  }

  /// ========================================
  /// 删除当前页面
  /// ========================================
  Future<bool> deleteCurrentPage() async {
    if (state.currentBook == null) return false;

    try {
      final pageNumber = state.currentPage + 1; // API 使用 1-based 页码
      log('[ReadingProvider] [deleteCurrentPage] 删除页面: $pageNumber');

      await booksApi.deletePage(state.currentBook!.id, pageNumber);

      // 刷新绘本详情
      await refreshBookDetail();

      log('[ReadingProvider] [deleteCurrentPage] 页面删除成功');
      return true;
    } catch (e) {
      log('[ReadingProvider] [deleteCurrentPage] 删除失败: $e');
      state = state.copyWith(error: '删除页面失败: $e');
      return false;
    }
  }

  /// ========================================
  /// 整页朗读：播放当前页所有句子
  /// ========================================
  Future<void> playAllSentences() async {
    final sentences = state.currentSentences;
    if (sentences.isEmpty) return;

    // 停止当前播放
    await stopPlaying();

    // 设置整页朗读状态
    state = state.copyWith(
      isPlayingAll: true,
      playingAllIndex: 0,
      isPlayingAllPaused: false,
      activeSentenceId: sentences.first.id,
    );

    log('[ReadingProvider] [playAllSentences] 开始整页朗读，共 ${sentences.length} 个句子');

    // 开始播放第一个句子
    await _playSentenceInSequence(0);
  }

  /// 播放序列中的指定句子
  Future<void> _playSentenceInSequence(int index) async {
    final sentences = state.currentSentences;
    if (index >= sentences.length || !state.isPlayingAll) return;

    final sentence = sentences[index];

    // 更新当前播放索引和活跃句子
    state = state.copyWith(
      playingAllIndex: index,
      activeSentenceId: sentence.id,
      isPlaying: true,
    );

    log('[ReadingProvider] [_playSentenceInSequence] 播放第 ${index + 1} 个句子: ${sentence.en}');

    // 播放句子
    final success = await playSentence(sentence);

    if (!success && state.isPlayingAll) {
      // 播放失败，停止整页朗读
      log('[ReadingProvider] [_playSentenceInSequence] 播放失败，停止整页朗读');
      state = state.copyWith(
        isPlayingAll: false,
        playingAllIndex: -1,
        isPlaying: false,
        clearPlayingAll: true,
      );
    }
  }

  /// 整页朗读：暂停
  Future<void> pauseAllSentences() async {
    await _ttsService.pause();
    state = state.copyWith(
      isPlayingAllPaused: true,
      isPlaying: false,
    );
    log('[ReadingProvider] [pauseAllSentences] 整页朗读已暂停');
  }

  /// 整页朗读：继续
  Future<void> resumeAllSentences() async {
    if (!state.isPlayingAll || state.playingAllIndex < 0) return;

    state = state.copyWith(isPlayingAllPaused: false);

    // 继续播放当前句子
    final sentences = state.currentSentences;
    if (state.playingAllIndex < sentences.length) {
      await playSentence(sentences[state.playingAllIndex]);
    }
    log('[ReadingProvider] [resumeAllSentences] 整页朗读继续');
  }

  /// 整页朗读：停止
  Future<void> stopAllSentences() async {
    await _ttsService.stop();
    state = state.copyWith(
      isPlayingAll: false,
      playingAllIndex: -1,
      isPlayingAllPaused: false,
      isPlaying: false,
      clearActiveSentence: true,
    );
    log('[ReadingProvider] [stopAllSentences] 整页朗读已停止');
  }

  /// 整页朗读：切换播放/暂停
  Future<void> togglePlayAllSentences() async {
    if (state.isPlayingAll) {
      if (state.isPlayingAllPaused) {
        await resumeAllSentences();
      } else {
        await pauseAllSentences();
      }
    } else {
      await playAllSentences();
    }
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

/// 当前播放的单词进度（用于单词级高亮）
final wordProgressProvider = Provider<(int, int)>((ref) {
  final state = ref.watch(readingProvider);
  return (state.currentWordStart, state.currentWordEnd);
});