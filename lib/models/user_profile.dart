/// User profile model
class UserProfile {
  final String id;
  final String name;
  final String? phone;
  final String? avatar;
  final int level;
  final int booksRead;
  final int stars;
  final int streak;

  const UserProfile({
    required this.id,
    required this.name,
    this.phone,
    this.avatar,
    required this.level,
    required this.booksRead,
    required this.stars,
    required this.streak,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? avatar,
    int? level,
    int? booksRead,
    int? stars,
    int? streak,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      level: level ?? this.level,
      booksRead: booksRead ?? this.booksRead,
      stars: stars ?? this.stars,
      streak: streak ?? this.streak,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'avatar': avatar,
      'level': level,
      'books_read': booksRead,
      'stars': stars,
      'streak': streak,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      level: json['level'] as int? ?? 1,
      booksRead: json['books_read'] as int? ?? 0,
      stars: json['stars'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
    );
  }
}