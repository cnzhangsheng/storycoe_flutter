/// Book model
class Book {
  final String id;
  final String title;
  final int level;
  final int progress;
  final String? image;
  final bool isNew;
  final bool hasAudio;
  final String? status;

  const Book({
    required this.id,
    required this.title,
    required this.level,
    required this.progress,
    this.image,
    this.isNew = false,
    this.hasAudio = false,
    this.status,
  });

  Book copyWith({
    String? id,
    String? title,
    int? level,
    int? progress,
    String? image,
    bool? isNew,
    bool? hasAudio,
    String? status,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      level: level ?? this.level,
      progress: progress ?? this.progress,
      image: image ?? this.image,
      isNew: isNew ?? this.isNew,
      hasAudio: hasAudio ?? this.hasAudio,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'level': level,
      'progress': progress,
      'cover_image': image,
      'is_new': isNew,
      'has_audio': hasAudio,
      'status': status,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      level: json['level'] as int? ?? 1,
      progress: json['progress'] as int? ?? 0,
      image: json['cover_image'] as String? ?? json['image'] as String?,
      isNew: json['is_new'] as bool? ?? false,
      hasAudio: json['has_audio'] as bool? ?? false,
      status: json['status'] as String?,
    );
  }
}

/// Mock books for development
class MockBooks {
  MockBooks._();

  static final List<Book> books = [
    Book(
      id: '1',
      title: "The Blue Bird's Journey",
      level: 1,
      progress: 65,
      image: 'assets/images/book_blue_bird.png',
      isNew: true,
    ),
    Book(
      id: '2',
      title: 'Moonlight Magic',
      level: 2,
      progress: 30,
      image: 'assets/images/book_moonlight.png',
      hasAudio: true,
    ),
    Book(
      id: '3',
      title: 'The Curious Fox',
      level: 1,
      progress: 100,
      image: 'assets/images/book_curious_fox.png',
    ),
  ];
}