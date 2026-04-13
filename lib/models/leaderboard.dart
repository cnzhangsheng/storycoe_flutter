// 排行榜数据模型

/// 排行榜绘本
class LeaderboardBook {
  final String id;
  final String title;
  final String? coverImage;
  final int level;
  final int readCount;
  final int shelfCount;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final int rank;

  const LeaderboardBook({
    required this.id,
    required this.title,
    this.coverImage,
    this.level = 1,
    this.readCount = 0,
    this.shelfCount = 0,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.rank = 0,
  });

  factory LeaderboardBook.fromJson(Map<String, dynamic> json) {
    return LeaderboardBook(
      id: json['id'] as String,
      title: json['title'] as String,
      coverImage: json['cover_image'] as String?,
      level: json['level'] as int? ?? 1,
      readCount: json['read_count'] as int? ?? 0,
      shelfCount: json['shelf_count'] as int? ?? 0,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorAvatar: json['author_avatar'] as String?,
      rank: json['rank'] as int? ?? 0,
    );
  }

  /// 格式化阅读数显示（如 1.2k）
  String get formattedReadCount {
    if (readCount >= 1000) {
      return '${(readCount / 1000).toStringAsFixed(1)}k';
    }
    return readCount.toString();
  }

  /// 格式化收藏数显示
  String get formattedShelfCount {
    if (shelfCount >= 1000) {
      return '${(shelfCount / 1000).toStringAsFixed(1)}k';
    }
    return shelfCount.toString();
  }
}


/// 排行榜绘本列表响应
class LeaderboardBookListResponse {
  final String leaderboardType;
  final List<LeaderboardBook> books;
  final int total;

  const LeaderboardBookListResponse({
    this.leaderboardType = 'hot',
    this.books = const [],
    this.total = 0,
  });

  factory LeaderboardBookListResponse.fromJson(Map<String, dynamic> json) {
    final booksList = json['books'] as List? ?? [];
    return LeaderboardBookListResponse(
      leaderboardType: json['leaderboard_type'] as String? ?? 'hot',
      books: booksList
          .map((item) => LeaderboardBook.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}


/// 排行榜作者
class LeaderboardAuthor {
  final String id;
  final String name;
  final String? avatar;
  final int level;
  final int booksCreated;
  final int totalShelfCount;
  final int rank;

  const LeaderboardAuthor({
    required this.id,
    required this.name,
    this.avatar,
    this.level = 1,
    this.booksCreated = 0,
    this.totalShelfCount = 0,
    this.rank = 0,
  });

  factory LeaderboardAuthor.fromJson(Map<String, dynamic> json) {
    return LeaderboardAuthor(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      level: json['level'] as int? ?? 1,
      booksCreated: json['books_created'] as int? ?? 0,
      totalShelfCount: json['total_shelf_count'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
    );
  }

  /// 格式化创作数显示
  String get formattedBooksCreated {
    if (booksCreated >= 100) {
      return '$booksCreated本';
    }
    return booksCreated.toString();
  }

  /// 格式化收藏数显示
  String get formattedShelfCount {
    if (totalShelfCount >= 1000) {
      return '${(totalShelfCount / 1000).toStringAsFixed(1)}k';
    }
    return totalShelfCount.toString();
  }
}


/// 排行榜作者列表响应
class LeaderboardAuthorListResponse {
  final List<LeaderboardAuthor> authors;
  final int total;

  const LeaderboardAuthorListResponse({
    this.authors = const [],
    this.total = 0,
  });

  factory LeaderboardAuthorListResponse.fromJson(Map<String, dynamic> json) {
    final authorsList = json['authors'] as List? ?? [];
    return LeaderboardAuthorListResponse(
      authors: authorsList
          .map((item) => LeaderboardAuthor.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}


/// 排行榜摘要（首页展示用）
class LeaderboardSummary {
  final List<LeaderboardBook> hotBooks;
  final List<LeaderboardBook> newBooks;
  final List<LeaderboardAuthor> authors;

  const LeaderboardSummary({
    this.hotBooks = const [],
    this.newBooks = const [],
    this.authors = const [],
  });

  factory LeaderboardSummary.fromJson(Map<String, dynamic> json) {
    final hotBooksList = json['hot_books'] as List? ?? [];
    final newBooksList = json['new_books'] as List? ?? [];
    final authorsList = json['authors'] as List? ?? [];

    return LeaderboardSummary(
      hotBooks: hotBooksList
          .map((item) => LeaderboardBook.fromJson(item as Map<String, dynamic>))
          .toList(),
      newBooks: newBooksList
          .map((item) => LeaderboardBook.fromJson(item as Map<String, dynamic>))
          .toList(),
      authors: authorsList
          .map((item) => LeaderboardAuthor.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}