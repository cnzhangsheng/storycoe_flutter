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
  final String shareType; // 'public' or 'private'

  const Book({
    required this.id,
    required this.title,
    required this.level,
    required this.progress,
    this.image,
    this.isNew = false,
    this.hasAudio = false,
    this.status,
    this.shareType = 'private',
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
    String? shareType,
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
      shareType: shareType ?? this.shareType,
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
      'share_type': shareType,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '未命名绘本') as String,
      level: json['level'] as int? ?? 1,
      progress: json['progress'] as int? ?? 0,
      image: json['cover_image'] as String? ?? json['image'] as String?,
      isNew: json['is_new'] as bool? ?? false,
      hasAudio: json['has_audio'] as bool? ?? false,
      status: json['status'] as String?,
      shareType: json['share_type'] as String? ?? 'private',
    );
  }
}