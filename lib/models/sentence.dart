/// ========================================
/// 绘本句子模型
/// 对应后端 sentences 表
/// ========================================
class Sentence {
  final String id;
  final String pageId;
  final int sentenceOrder;
  final String en;
  final String zh;
  final String? audioUrl;

  const Sentence({
    required this.id,
    required this.pageId,
    required this.sentenceOrder,
    required this.en,
    required this.zh,
    this.audioUrl,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: (json['id'] ?? '') as String,
      pageId: (json['page_id'] ?? '') as String,
      sentenceOrder: json['sentence_order'] as int? ?? 1,
      en: json['en'] as String? ?? '',
      zh: json['zh'] as String? ?? '',
      audioUrl: json['audio_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page_id': pageId,
      'sentence_order': sentenceOrder,
      'en': en,
      'zh': zh,
      'audio_url': audioUrl,
    };
  }

  /// 复制并修改
  Sentence copyWith({
    String? id,
    String? pageId,
    int? sentenceOrder,
    String? en,
    String? zh,
    String? audioUrl,
  }) {
    return Sentence(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      sentenceOrder: sentenceOrder ?? this.sentenceOrder,
      en: en ?? this.en,
      zh: zh ?? this.zh,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

/// ========================================
/// 绘本页面模型
/// 对应后端 book_pages 表
/// ========================================
class BookPage {
  final String id;
  final String bookId;
  final int pageNumber;
  final String? imageUrl;
  final String status; // processing, completed, error
  final List<Sentence> sentences;
  final DateTime? createdAt;

  const BookPage({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    this.imageUrl,
    this.status = 'completed',
    this.sentences = const [],
    this.createdAt,
  });

  /// 是否正在识别中
  bool get isProcessing => status == 'processing';

  /// 是否识别失败
  bool get isError => status == 'error';

  /// 复制并修改
  BookPage copyWith({
    String? id,
    String? bookId,
    int? pageNumber,
    String? imageUrl,
    String? status,
    List<Sentence>? sentences,
    DateTime? createdAt,
  }) {
    return BookPage(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageNumber: pageNumber ?? this.pageNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      sentences: sentences ?? this.sentences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BookPage.fromJson(Map<String, dynamic> json) {
    final sentences = <Sentence>[];
    if (json['sentences'] is List) {
      for (final s in json['sentences'] as List) {
        sentences.add(Sentence.fromJson(s as Map<String, dynamic>));
      }
    }

    return BookPage(
      id: (json['id'] ?? '') as String,
      bookId: (json['book_id'] ?? '') as String,
      pageNumber: json['page_number'] as int? ?? 1,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'completed',
      sentences: sentences,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'page_number': pageNumber,
      'image_url': imageUrl,
      'status': status,
      'sentences': sentences.map((s) => s.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// ========================================
/// 绘本详情模型
/// 对应后端 books 表（包含页面列表）
/// ========================================
class BookDetail {
  final String id;
  final String userId;
  final String title;
  final int level;
  final int progress;
  final String? coverImage;
  final bool isNew;
  final bool hasAudio;
  final String status;
  final String shareType;
  final List<BookPage> pages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookDetail({
    required this.id,
    required this.userId,
    required this.title,
    this.level = 1,
    this.progress = 0,
    this.coverImage,
    this.isNew = false,
    this.hasAudio = false,
    this.status = 'draft',
    this.shareType = 'private',
    this.pages = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// 总页数
  int get totalPages => pages.length;

  /// 复制并修改部分字段
  BookDetail copyWith({
    String? id,
    String? userId,
    String? title,
    int? level,
    int? progress,
    String? coverImage,
    bool? isNew,
    bool? hasAudio,
    String? status,
    String? shareType,
    List<BookPage>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookDetail(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      level: level ?? this.level,
      progress: progress ?? this.progress,
      coverImage: coverImage ?? this.coverImage,
      isNew: isNew ?? this.isNew,
      hasAudio: hasAudio ?? this.hasAudio,
      status: status ?? this.status,
      shareType: shareType ?? this.shareType,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    final pages = <BookPage>[];
    if (json['pages'] is List) {
      for (final p in json['pages'] as List) {
        pages.add(BookPage.fromJson(p as Map<String, dynamic>));
      }
    }

    return BookDetail(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      title: json['title'] as String? ?? '未命名绘本',
      level: json['level'] as int? ?? 1,
      progress: json['progress'] as int? ?? 0,
      coverImage: json['cover_image'] as String?,
      isNew: json['is_new'] as bool? ?? false,
      hasAudio: json['has_audio'] as bool? ?? false,
      status: json['status'] as String? ?? 'draft',
      shareType: json['share_type'] as String? ?? 'private',
      pages: pages,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'level': level,
      'progress': progress,
      'cover_image': coverImage,
      'is_new': isNew,
      'has_audio': hasAudio,
      'status': status,
      'share_type': shareType,
      'pages': pages.map((p) => p.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// ========================================
/// Mock 数据（用于开发测试）
/// ========================================
class MockSentences {
  MockSentences._();

  static final List<Sentence> mockSentences = [
    Sentence(
      id: '1',
      pageId: 'page-1',
      sentenceOrder: 1,
      en: 'Once upon a time, there was a little blue bird.',
      zh: '从前，有一只蓝色的小鸟。',
    ),
    Sentence(
      id: '2',
      pageId: 'page-1',
      sentenceOrder: 2,
      en: 'She lived in a big, green forest.',
      zh: '她住在一个大大的绿色森林里。',
    ),
    Sentence(
      id: '3',
      pageId: 'page-2',
      sentenceOrder: 1,
      en: 'One day, she decided to go on a long journey.',
      zh: '有一天，她决定去进行一次长途旅行。',
    ),
  ];

  static final List<BookPage> mockPages = [
    BookPage(
      id: 'page-1',
      bookId: 'book-1',
      pageNumber: 1,
      imageUrl: 'assets/images/book_blue_bird.png',
      sentences: mockSentences.where((s) => s.pageId == 'page-1').toList(),
    ),
    BookPage(
      id: 'page-2',
      bookId: 'book-1',
      pageNumber: 2,
      imageUrl: 'assets/images/book_moonlight.png',
      sentences: mockSentences.where((s) => s.pageId == 'page-2').toList(),
    ),
  ];
}