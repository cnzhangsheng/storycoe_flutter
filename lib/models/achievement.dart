/// 成就数据模型
class Achievement {
  final String id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final String requirementType;
  final int requirementValue;
  final int rewardStars;
  final bool unlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirementType,
    required this.requirementValue,
    required this.rewardStars,
    this.unlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      requirementType: json['requirement_type'] as String,
      requirementValue: json['requirement_value'] as int,
      rewardStars: json['reward_stars'] as int,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'icon': icon,
      'requirement_type': requirementType,
      'requirement_value': requirementValue,
      'reward_stars': rewardStars,
      'unlocked': unlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  Achievement copyWith({
    bool? unlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      code: code,
      name: name,
      description: description,
      icon: icon,
      requirementType: requirementType,
      requirementValue: requirementValue,
      rewardStars: rewardStars,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}


/// 成就列表响应
class AchievementListResponse {
  final List<Achievement> achievements;
  final int totalUnlocked;
  final int total;

  const AchievementListResponse({
    required this.achievements,
    required this.totalUnlocked,
    required this.total,
  });

  factory AchievementListResponse.fromJson(Map<String, dynamic> json) {
    final achievementsList = json['achievements'] as List;
    return AchievementListResponse(
      achievements: achievementsList
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalUnlocked: json['total_unlocked'] as int,
      total: json['total'] as int,
    );
  }
}


/// 每日任务模型
class DailyTask {
  final String? id;
  final DateTime? taskDate;
  final int readBooks;
  final int targetBooks;
  final bool completed;
  final bool rewardClaimed;
  final int rewardStars;
  final double progressPercent;

  const DailyTask({
    this.id,
    this.taskDate,
    this.readBooks = 0,
    this.targetBooks = 3,
    this.completed = false,
    this.rewardClaimed = false,
    this.rewardStars = 20,
    this.progressPercent = 0,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] as String?,
      taskDate: json['task_date'] != null
          ? DateTime.parse(json['task_date'] as String)
          : null,
      readBooks: json['read_books'] as int? ?? 0,
      targetBooks: json['target_books'] as int? ?? 3,
      completed: json['completed'] as bool? ?? false,
      rewardClaimed: json['reward_claimed'] as bool? ?? false,
      rewardStars: json['reward_stars'] as int? ?? 20,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
    );
  }

  DailyTask copyWith({
    int? readBooks,
    bool? completed,
    bool? rewardClaimed,
    double? progressPercent,
  }) {
    return DailyTask(
      id: id,
      taskDate: taskDate,
      readBooks: readBooks ?? this.readBooks,
      targetBooks: targetBooks,
      completed: completed ?? this.completed,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
      rewardStars: rewardStars,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }
}


/// 游戏化统计数据模型
class GamificationStats {
  final int level;
  final String levelName;
  final int stars;
  final int streak;
  final int booksRead;
  final int totalSentencesRead;
  final int nextLevelStars;
  final double currentLevelProgress;
  final String title;

  const GamificationStats({
    this.level = 1,
    this.levelName = '小读者',
    this.stars = 0,
    this.streak = 0,
    this.booksRead = 0,
    this.totalSentencesRead = 0,
    this.nextLevelStars = 100,
    this.currentLevelProgress = 0,
    this.title = '森林探索者',
  });

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    return GamificationStats(
      level: json['level'] as int? ?? 1,
      levelName: json['level_name'] as String? ?? '小读者',
      stars: json['stars'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      booksRead: json['books_read'] as int? ?? 0,
      totalSentencesRead: json['total_sentences_read'] as int? ?? 0,
      nextLevelStars: json['next_level_stars'] as int? ?? 100,
      currentLevelProgress: (json['current_level_progress'] as num?)?.toDouble() ?? 0,
      title: json['title'] as String? ?? '森林探索者',
    );
  }

  GamificationStats copyWith({
    int? level,
    String? levelName,
    int? stars,
    int? streak,
    int? booksRead,
    int? totalSentencesRead,
    int? nextLevelStars,
    double? currentLevelProgress,
    String? title,
  }) {
    return GamificationStats(
      level: level ?? this.level,
      levelName: levelName ?? this.levelName,
      stars: stars ?? this.stars,
      streak: streak ?? this.streak,
      booksRead: booksRead ?? this.booksRead,
      totalSentencesRead: totalSentencesRead ?? this.totalSentencesRead,
      nextLevelStars: nextLevelStars ?? this.nextLevelStars,
      currentLevelProgress: currentLevelProgress ?? this.currentLevelProgress,
      title: title ?? this.title,
    );
  }
}


/// 星星奖励响应
class StarRewardResponse {
  final int starsAdded;
  final String reason;
  final int totalStars;
  final bool levelUp;
  final int? newLevel;
  final List<Achievement> achievementsUnlocked;

  const StarRewardResponse({
    this.starsAdded = 0,
    this.reason = '',
    this.totalStars = 0,
    this.levelUp = false,
    this.newLevel,
    this.achievementsUnlocked = const [],
  });

  factory StarRewardResponse.fromJson(Map<String, dynamic> json) {
    final achievementsList = json['achievements_unlocked'] as List? ?? [];
    return StarRewardResponse(
      starsAdded: json['stars_added'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      totalStars: json['total_stars'] as int? ?? 0,
      levelUp: json['level_up'] as bool? ?? false,
      newLevel: json['new_level'] as int?,
      achievementsUnlocked: achievementsList
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}