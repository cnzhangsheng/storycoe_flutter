import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storycoe_flutter/models/achievement.dart';
import 'package:storycoe_flutter/providers/auth_provider.dart';
import 'package:storycoe_flutter/services/api_service.dart';

/// 游戏化状态
class GamificationState {
  final GamificationStats stats;
  final AchievementListResponse achievements;
  final DailyTask dailyTask;
  final bool isLoading;
  final String? error;

  const GamificationState({
    this.stats = const GamificationStats(),
    this.achievements = const AchievementListResponse(achievements: [], totalUnlocked: 0, total: 0),
    this.dailyTask = const DailyTask(),
    this.isLoading = false,
    this.error,
  });

  GamificationState copyWith({
    GamificationStats? stats,
    AchievementListResponse? achievements,
    DailyTask? dailyTask,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GamificationState(
      stats: stats ?? this.stats,
      achievements: achievements ?? this.achievements,
      dailyTask: dailyTask ?? this.dailyTask,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 游戏化 Notifier
class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier() : super(const GamificationState());

  /// 加载游戏化统计数据
  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await apiClient.getToken();
      final response = await gamificationApi.getStats(token: token);
      final stats = GamificationStats.fromJson(response);

      state = state.copyWith(
        stats: stats,
        isLoading: false,
      );

      debugPrint('[GamificationProvider] 加载统计数据成功: level=${stats.level}, stars=${stats.stars}');
    } catch (e) {
      debugPrint('[GamificationProvider] 加载统计数据失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 加载成就列表
  Future<void> loadAchievements() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await apiClient.getToken();
      final response = await gamificationApi.getAchievements(token: token);
      final achievements = AchievementListResponse.fromJson(response);

      state = state.copyWith(
        achievements: achievements,
        isLoading: false,
      );

      debugPrint('[GamificationProvider] 加载成就列表成功: ${achievements.totalUnlocked}/${achievements.total}');
    } catch (e) {
      debugPrint('[GamificationProvider] 加载成就列表失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 加载每日任务状态
  Future<void> loadDailyTask() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await apiClient.getToken();
      final response = await gamificationApi.getDailyTask(token: token);
      final dailyTask = DailyTask.fromJson(response);

      state = state.copyWith(
        dailyTask: dailyTask,
        isLoading: false,
      );

      debugPrint('[GamificationProvider] 加载每日任务成功: ${dailyTask.readBooks}/${dailyTask.targetBooks}');
    } catch (e) {
      debugPrint('[GamificationProvider] 加载每日任务失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 领取每日任务奖励
  Future<bool> claimDailyTaskReward() async {
    try {
      final token = await apiClient.getToken();
      final response = await gamificationApi.claimDailyTaskReward(token: token);

      final success = response['success'] as bool? ?? false;
      if (success) {
        // 更新每日任务状态
        state = state.copyWith(
          dailyTask: state.dailyTask.copyWith(rewardClaimed: true),
        );
        debugPrint('[GamificationProvider] 领取奖励成功: ${response['reward_stars']} 星星');
      }

      return success;
    } catch (e) {
      debugPrint('[GamificationProvider] 领取奖励失败: $e');
      return false;
    }
  }

  /// 刷新所有游戏化数据
  Future<void> refreshAll() async {
    await Future.wait([
      loadStats(),
      loadAchievements(),
      loadDailyTask(),
    ]);
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// 游戏化 Provider
final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier();
});

/// 便捷 Providers
final gamificationStatsProvider = Provider<GamificationStats>((ref) {
  return ref.watch(gamificationProvider).stats;
});

final achievementsProvider = Provider<AchievementListResponse>((ref) {
  return ref.watch(gamificationProvider).achievements;
});

final dailyTaskProvider = Provider<DailyTask>((ref) {
  return ref.watch(gamificationProvider).dailyTask;
});

final gamificationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(gamificationProvider).isLoading;
});

/// 等级进度 Provider
final levelProgressProvider = Provider<double>((ref) {
  final stats = ref.watch(gamificationStatsProvider);
  return stats.currentLevelProgress;
});

/// 成就解锁进度 Provider
final achievementProgressProvider = Provider<String>((ref) {
  final achievements = ref.watch(achievementsProvider);
  return '${achievements.totalUnlocked}/${achievements.total}';
});