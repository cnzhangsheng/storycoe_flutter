import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storycoe_flutter/models/leaderboard.dart';
import 'package:storycoe_flutter/services/api_service.dart';

/// 排行榜状态
class LeaderboardState {
  final LeaderboardBookListResponse hotBooks;
  final LeaderboardBookListResponse newBooks;
  final LeaderboardAuthorListResponse authors;
  final LeaderboardSummary summary;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.hotBooks = const LeaderboardBookListResponse(),
    this.newBooks = const LeaderboardBookListResponse(),
    this.authors = const LeaderboardAuthorListResponse(),
    this.summary = const LeaderboardSummary(),
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    LeaderboardBookListResponse? hotBooks,
    LeaderboardBookListResponse? newBooks,
    LeaderboardAuthorListResponse? authors,
    LeaderboardSummary? summary,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LeaderboardState(
      hotBooks: hotBooks ?? this.hotBooks,
      newBooks: newBooks ?? this.newBooks,
      authors: authors ?? this.authors,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 排行榜 Notifier
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier() : super(const LeaderboardState());

  /// 加载热门绘本榜
  Future<void> loadHotBooks({int limit = 10}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await apiClient.getToken();
      final response = await leaderboardApi.getHotBooks(limit: limit, token: token);
      final hotBooks = LeaderboardBookListResponse.fromJson(response);

      state = state.copyWith(
        hotBooks: hotBooks,
        isLoading: false,
      );

      debugPrint('[LeaderboardProvider] 加载热门绘本榜成功: ${hotBooks.books.length}本');
    } catch (e) {
      debugPrint('[LeaderboardProvider] 加载热门绘本榜失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 加载新星绘本榜
  Future<void> loadNewBooks({int days = 7, int limit = 10}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await apiClient.getToken();
      final response = await leaderboardApi.getNewBooks(days: days, limit: limit, token: token);
      final newBooks = LeaderboardBookListResponse.fromJson(response);

      state = state.copyWith(
        newBooks: newBooks,
        isLoading: false,
      );

      debugPrint('[LeaderboardProvider] 加载新星绘本榜成功: ${newBooks.books.length}本');
    } catch (e) {
      debugPrint('[LeaderboardProvider] 加载新星绘本榜失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 加载活跃作者榜
  Future<void> loadAuthors({int limit = 10}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await apiClient.getToken();
      final response = await leaderboardApi.getAuthors(limit: limit, token: token);
      final authors = LeaderboardAuthorListResponse.fromJson(response);

      state = state.copyWith(
        authors: authors,
        isLoading: false,
      );

      debugPrint('[LeaderboardProvider] 加载活跃作者榜成功: ${authors.authors.length}位');
    } catch (e) {
      debugPrint('[LeaderboardProvider] 加载活跃作者榜失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 加载排行榜摘要
  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await apiClient.getToken();
      final response = await leaderboardApi.getSummary(token: token);
      final summary = LeaderboardSummary.fromJson(response);

      state = state.copyWith(
        summary: summary,
        isLoading: false,
      );

      debugPrint('[LeaderboardProvider] 加载排行榜摘要成功');
    } catch (e) {
      debugPrint('[LeaderboardProvider] 加载排行榜摘要失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 刷新所有排行榜数据
  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await apiClient.getToken();

      // 并行加载所有榜单
      final results = await Future.wait([
        leaderboardApi.getHotBooks(limit: 10, token: token),
        leaderboardApi.getNewBooks(days: 7, limit: 10, token: token),
        leaderboardApi.getAuthors(limit: 10, token: token),
      ]);

      final hotBooks = LeaderboardBookListResponse.fromJson(results[0]);
      final newBooks = LeaderboardBookListResponse.fromJson(results[1]);
      final authors = LeaderboardAuthorListResponse.fromJson(results[2]);

      state = state.copyWith(
        hotBooks: hotBooks,
        newBooks: newBooks,
        authors: authors,
        isLoading: false,
      );

      debugPrint('[LeaderboardProvider] 刷新所有排行榜成功');
    } catch (e) {
      debugPrint('[LeaderboardProvider] 刷新排行榜失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// 排行榜 Provider
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier();
});

/// 便捷 Providers
final hotBooksProvider = Provider<List<LeaderboardBook>>((ref) {
  return ref.watch(leaderboardProvider).hotBooks.books;
});

final newBooksProvider = Provider<List<LeaderboardBook>>((ref) {
  return ref.watch(leaderboardProvider).newBooks.books;
});

final leaderboardAuthorsProvider = Provider<List<LeaderboardAuthor>>((ref) {
  return ref.watch(leaderboardProvider).authors.authors;
});

final leaderboardSummaryProvider = Provider<LeaderboardSummary>((ref) {
  return ref.watch(leaderboardProvider).summary;
});

final leaderboardLoadingProvider = Provider<bool>((ref) {
  return ref.watch(leaderboardProvider).isLoading;
});