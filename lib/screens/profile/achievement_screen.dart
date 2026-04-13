import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/models/achievement.dart';
import 'package:storycoe_flutter/providers/gamification_provider.dart';

/// 成就展示页面
class AchievementScreen extends ConsumerStatefulWidget {
  const AchievementScreen({super.key});

  @override
  ConsumerState<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends ConsumerState<AchievementScreen> {
  @override
  void initState() {
    super.initState();
    // 加载成就数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationProvider.notifier).loadAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider);
    final isLoading = ref.watch(gamificationLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              size: 20,
              color: AppColors.onPrimaryFixed,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.trophy,
                size: 18,
                color: AppColors.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '成就徽章',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.onPrimaryFixed,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 进度统计
                    _buildProgressSummary(achievements),

                    const SizedBox(height: 24),

                    // 已解锁成就
                    if (achievements.achievements.where((a) => a.unlocked).isNotEmpty)
                      _buildSectionTitle('已解锁', achievements.totalUnlocked, true),
                    if (achievements.achievements.where((a) => a.unlocked).isNotEmpty)
                      const SizedBox(height: 12),
                    ...achievements.achievements
                        .where((a) => a.unlocked)
                        .map((achievement) => _buildAchievementItem(achievement, true)),

                    const SizedBox(height: 24),

                    // 未解锁成就
                    if (achievements.achievements.where((a) => !a.unlocked).isNotEmpty)
                      _buildSectionTitle('待解锁', achievements.total - achievements.totalUnlocked, false),
                    if (achievements.achievements.where((a) => !a.unlocked).isNotEmpty)
                      const SizedBox(height: 12),
                    ...achievements.achievements
                        .where((a) => !a.unlocked)
                        .map((achievement) => _buildAchievementItem(achievement, false)),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  /// 进度统计卡片
  Widget _buildProgressSummary(AchievementListResponse achievements) {
    final progressPercent = achievements.total > 0
        ? achievements.totalUnlocked / achievements.total * 100
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.15),
            AppColors.secondaryContainer.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.award,
                size: 32,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 12),
              Text(
                '${achievements.totalUnlocked}',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${achievements.total}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已解锁 ${progressPercent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 分组标题
  Widget _buildSectionTitle(String title, int count, bool isUnlocked) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppColors.secondaryContainer.withValues(alpha: 0.15)
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isUnlocked ? LucideIcons.checkCircle : LucideIcons.lock,
            size: 16,
            color: isUnlocked
                ? AppColors.onSecondaryContainer
                : AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$title ($count)',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isUnlocked ? AppColors.onPrimaryFixed : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 成就项卡片
  Widget _buildAchievementItem(Achievement achievement, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? AppColors.secondaryContainer.withValues(alpha: 0.3)
              : AppColors.surfaceContainerHigh,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // 徽章图标
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: [
                        AppColors.secondaryContainer,
                        AppColors.tertiaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUnlocked ? null : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isUnlocked ? Colors.white : Colors.transparent,
                width: isUnlocked ? 2 : 0,
              ),
            ),
            child: Center(
              child: Icon(
                _getAchievementIcon(achievement.icon),
                size: 28,
                color: isUnlocked
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 成就信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isUnlocked ? AppColors.onPrimaryFixed : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                // 奖励标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppColors.secondaryContainer.withValues(alpha: 0.15)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.star,
                        size: 14,
                        color: isUnlocked
                            ? AppColors.secondaryContainer
                            : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${achievement.rewardStars}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppColors.secondaryContainer
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 解锁时间或锁图标
          if (isUnlocked && achievement.unlockedAt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _formatDate(achievement.unlockedAt!),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onTertiaryContainer,
                ),
              ),
            ),
          if (!isUnlocked)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.lock,
                size: 18,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }

  /// 获取成就图标
  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'book-open':
        return LucideIcons.bookOpen;
      case 'books':
        return LucideIcons.books;
      case 'library':
        return LucideIcons.library;
      case 'award':
        return LucideIcons.award;
      case 'star':
        return LucideIcons.star;
      case 'flame':
        return LucideIcons.flame;
      case 'calendar':
        return LucideIcons.calendar;
      case 'calendar-check':
        return LucideIcons.calendarCheck;
      case 'medal':
        return LucideIcons.medal;
      case 'crown':
        return LucideIcons.crown;
      case 'rocket':
        return LucideIcons.rocket;
      case 'trophy':
        return LucideIcons.trophy;
      case 'target':
        return LucideIcons.target;
      default:
        return LucideIcons.award;
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}