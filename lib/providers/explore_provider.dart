import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storycoe_flutter/models/book.dart';
import 'package:storycoe_flutter/services/api_service.dart';

/// 探索状态
class ExploreState {
  final List<Book> publicBooks;
  final String searchTerm;
  final int? selectedLevel;
  final int page;
  final bool isLoading;
  final String? error;

  const ExploreState({
    this.publicBooks = const [],
    this.searchTerm = '',
    this.selectedLevel,
    this.page = 1,
    this.isLoading = false,
    this.error,
  });

  /// 过滤后的绘本列表
  List<Book> get filteredBooks {
    return publicBooks.where((book) {
      final matchesSearch =
          book.title.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesLevel =
          selectedLevel == null || book.level == selectedLevel;
      return matchesSearch && matchesLevel;
    }).toList();
  }

  /// 当前显示的绘本（分页）
  List<Book> get displayedBooks {
    return filteredBooks.take(page * 4).toList();
  }

  /// 是否还有更多
  bool get hasMore => displayedBooks.length < filteredBooks.length;

  ExploreState copyWith({
    List<Book>? publicBooks,
    String? searchTerm,
    int? selectedLevel,
    int? page,
    bool? isLoading,
    String? error,
    bool clearLevel = false,
    bool clearError = false,
  }) {
    return ExploreState(
      publicBooks: publicBooks ?? this.publicBooks,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedLevel: clearLevel ? null : (selectedLevel ?? this.selectedLevel),
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 探索 Notifier
class ExploreNotifier extends StateNotifier<ExploreState> {
  ExploreNotifier() : super(const ExploreState()) {
    loadPublicBooks();
  }

  /// 从 API 加载公开绘本
  Future<void> loadPublicBooks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await booksApi.listPublicBooks();
      final booksList = response['books'] as List;

      final books = booksList
          .map((json) => Book.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        publicBooks: books,
        isLoading: false,
      );

      debugPrint('[ExploreProvider] 加载公开绘本成功: ${books.length} 本');
    } catch (e) {
      debugPrint('[ExploreProvider] 加载公开绘本失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 设置搜索词
  void setSearchTerm(String term) {
    state = state.copyWith(searchTerm: term, page: 1);
  }

  /// 设置级别筛选
  void setLevel(int? level) {
    state = state.copyWith(
      selectedLevel: level,
      clearLevel: level == null,
      page: 1,
    );
  }

  /// 加载更多
  void loadMore() {
    if (state.hasMore) {
      state = state.copyWith(page: state.page + 1);
    }
  }

  /// 清除筛选
  void clearFilters() {
    state = state.copyWith(
      searchTerm: '',
      clearLevel: true,
      page: 1,
    );
  }

  /// 刷新
  Future<void> refresh() async {
    await loadPublicBooks();
  }
}

/// 探索 Provider
final exploreProvider =
    StateNotifierProvider<ExploreNotifier, ExploreState>((ref) {
  return ExploreNotifier();
});

/// 便捷 Providers
final displayedBooksProvider = Provider<List<Book>>((ref) {
  return ref.watch(exploreProvider).displayedBooks;
});

final hasMoreBooksProvider = Provider<bool>((ref) {
  return ref.watch(exploreProvider).hasMore;
});

final filteredBooksEmptyProvider = Provider<bool>((ref) {
  return ref.watch(exploreProvider).filteredBooks.isEmpty;
});