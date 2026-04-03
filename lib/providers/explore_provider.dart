import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storycoe_flutter/models/book.dart';

/// 探索状态
class ExploreState {
  final List<Book> officialBooks;
  final String searchTerm;
  final int? selectedLevel;
  final int page;
  final bool isLoading;

  const ExploreState({
    this.officialBooks = const [],
    this.searchTerm = '',
    this.selectedLevel,
    this.page = 1,
    this.isLoading = false,
  });

  /// 过滤后的绘本列表
  List<Book> get filteredBooks {
    return officialBooks.where((book) {
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
    List<Book>? officialBooks,
    String? searchTerm,
    int? selectedLevel,
    int? page,
    bool? isLoading,
    bool clearLevel = false,
  }) {
    return ExploreState(
      officialBooks: officialBooks ?? this.officialBooks,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedLevel: clearLevel ? null : (selectedLevel ?? this.selectedLevel),
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 探索 Notifier
class ExploreNotifier extends StateNotifier<ExploreState> {
  ExploreNotifier() : super(const ExploreState()) {
    _loadOfficialBooks();
  }

  /// 官方绘本数据（Mock）
  static final List<Book> _mockOfficialBooks = [
    Book(
      id: 'o1',
      title: 'The Magic Forest',
      level: 1,
      progress: 0,
      image:
          'https://picsum.photos/seed/forest/400/600',
      isNew: true,
    ),
    Book(
      id: 'o2',
      title: 'Space Adventure',
      level: 2,
      progress: 0,
      image:
          'https://picsum.photos/seed/space/400/600',
    ),
    Book(
      id: 'o3',
      title: 'Ocean Friends',
      level: 1,
      progress: 0,
      image:
          'https://picsum.photos/seed/ocean/400/600',
    ),
    Book(
      id: 'o4',
      title: 'Dinosaur World',
      level: 3,
      progress: 0,
      image:
          'https://picsum.photos/seed/dino/400/600',
    ),
    Book(
      id: 'o5',
      title: 'The Brave Knight',
      level: 2,
      progress: 0,
      image:
          'https://picsum.photos/seed/knight/400/600',
    ),
    Book(
      id: 'o6',
      title: 'Little Red Riding Hood',
      level: 1,
      progress: 0,
      image:
          'https://picsum.photos/seed/red/400/600',
    ),
    Book(
      id: 'o7',
      title: 'The Ugly Duckling',
      level: 1,
      progress: 0,
      image:
          'https://picsum.photos/seed/duck/400/600',
    ),
    Book(
      id: 'o8',
      title: 'Jack and the Beanstalk',
      level: 2,
      progress: 0,
      image:
          'https://picsum.photos/seed/bean/400/600',
    ),
  ];

  void _loadOfficialBooks() {
    state = state.copyWith(officialBooks: _mockOfficialBooks);
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