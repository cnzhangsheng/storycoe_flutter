import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybird_flutter/models/book.dart';
import 'package:storybird_flutter/services/api_service.dart';
import 'package:uuid/uuid.dart';

/// 日志工具
void _log(String message, [dynamic data]) {
  final timestamp = DateTime.now().toString().substring(11, 23);
  final logMsg = '[BooksProvider][$timestamp] $message';
  if (data != null) {
    debugPrint('$logMsg: $data');
  } else {
    debugPrint(logMsg);
  }
}

/// Books state
class BooksState {
  final List<Book> books;
  final bool isLoading;
  final String? error;

  const BooksState({
    this.books = const [],
    this.isLoading = false,
    this.error,
  });

  BooksState copyWith({
    List<Book>? books,
    bool? isLoading,
    String? error,
  }) {
    return BooksState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Books notifier
class BooksNotifier extends StateNotifier<BooksState> {
  BooksNotifier() : super(const BooksState()) {
    // Load books on init
    loadBooks();
  }

  /// Load books from API
  Future<void> loadBooks() async {
    _log('开始加载书籍列表');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await booksApi.listBooks();
      _log('API 响应', response);

      final booksList = response['books'] as List;
      _log('书籍数量: ${booksList.length}');

      final books = booksList
          .map((json) {
            _log('解析书籍: ${json['id']} - ${json['title']}');
            return Book.fromJson(json as Map<String, dynamic>);
          })
          .toList();

      _log('加载完成，共 ${books.length} 本书');
      state = BooksState(books: books, isLoading: false);
    } catch (e, stackTrace) {
      _log('加载失败: $e');
      _log('堆栈: $stackTrace');
      // Fallback to mock data in development
      _log('使用 Mock 数据');
      state = BooksState(books: MockBooks.books, isLoading: false);
    }
  }

  /// Add a new book
  Future<Book?> addBook({
    required String title,
    String? image,
    int level = 1,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await booksApi.createBook(
        title: title,
        level: level,
        coverImage: image,
      );
      final book = Book.fromJson(response);
      state = state.copyWith(
        books: [book, ...state.books],
        isLoading: false,
      );
      return book;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update a book
  Future<bool> updateBook(Book updatedBook) async {
    try {
      await booksApi.updateBook(
        updatedBook.id,
        title: updatedBook.title,
        level: updatedBook.level,
        progress: updatedBook.progress,
        coverImage: updatedBook.image,
        isNew: updatedBook.isNew,
        hasAudio: updatedBook.hasAudio,
      );
      state = state.copyWith(
        books: state.books.map((book) {
          return book.id == updatedBook.id ? updatedBook : book;
        }).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove a book
  Future<bool> removeBook(String bookId) async {
    try {
      await booksApi.deleteBook(bookId);
      state = state.copyWith(
        books: state.books.where((book) => book.id != bookId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Create a new book (for development mode without API)
  Book createBook({
    required String title,
    String? image,
    int level = 1,
  }) {
    final book = Book(
      id: const Uuid().v4(),
      title: title,
      level: level,
      progress: 0,
      image: image ?? 'assets/images/book_blue_bird.png',
      isNew: true,
    );
    state = state.copyWith(books: [book, ...state.books]);
    return book;
  }

  /// Update progress
  Future<void> updateProgress(String bookId, int progress) async {
    final book = state.books.firstWhere((b) => b.id == bookId);
    final updatedBook = book.copyWith(progress: progress);
    await updateBook(updatedBook);
  }

  /// Generate book from images
  Future<String?> generateBook({
    String? title,
    required List<String> images,
    int level = 1,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await booksApi.generateBook(
        title: title,
        images: images,
        level: level,
      );
      // Reload books to get the new one
      await loadBooks();
      return response['book_id'] as String?;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }
}

/// Books provider
final booksProvider =
    StateNotifierProvider<BooksNotifier, BooksState>((ref) {
  return BooksNotifier();
});

/// Convenience providers
final booksListProvider = Provider<List<Book>>((ref) {
  return ref.watch(booksProvider).books;
});

final booksLoadingProvider = Provider<bool>((ref) {
  return ref.watch(booksProvider).isLoading;
});

final bookByIdProvider = Provider.family<Book?, String>((ref, bookId) {
  return ref.watch(booksProvider).books.firstWhere(
        (book) => book.id == bookId,
        orElse: () => throw StateError('Book not found: $bookId'),
      );
});