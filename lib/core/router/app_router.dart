import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storycoe_flutter/providers/auth_provider.dart';
import 'package:storycoe_flutter/screens/explore/explore_screen.dart';
import 'package:storycoe_flutter/screens/create/create_screen.dart';
import 'package:storycoe_flutter/screens/create/generate_progress_screen.dart';
import 'package:storycoe_flutter/screens/create/image_preview_screen.dart';
import 'package:storycoe_flutter/screens/home/home_screen.dart';
import 'package:storycoe_flutter/screens/login/login_screen.dart';
import 'package:storycoe_flutter/screens/profile/profile_screen.dart';
import 'package:storycoe_flutter/screens/profile/parental_control_screen.dart';
import 'package:storycoe_flutter/screens/profile/help_feedback_screen.dart';
import 'package:storycoe_flutter/screens/profile/achievement_screen.dart';
import 'package:storycoe_flutter/screens/explore/leaderboard_detail_screen.dart';
import 'package:storycoe_flutter/screens/reading/reading_screen.dart';
import 'package:storycoe_flutter/providers/create_provider.dart';

/// App router configuration
final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      // 如果已登录且在登录页，重定向到首页
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      // 如果未登录且不在登录页，重定向到登录页
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/explore',
        name: 'explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/explore/leaderboard/:type',
        name: 'leaderboard-detail',
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return LeaderboardDetailScreen(type: type);
        },
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        builder: (context, state) => const CreateScreen(),
      ),
      GoRoute(
        path: '/create/progress',
        name: 'generate-progress',
        builder: (context, state) => const GenerateProgressScreen(),
      ),
      GoRoute(
        path: '/create/preview',
        name: 'image-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final image = extra?['image'] as SelectedImage?;
          final pageIndex = extra?['pageIndex'] as int? ?? 0;
          final totalPages = extra?['totalPages'] as int? ?? 1;

          if (image == null) {
            return const Scaffold(body: Center(child: Text('未找到图片')));
          }

          return ImagePreviewScreen(
            image: image,
            pageIndex: pageIndex,
            totalPages: totalPages,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/parental',
        name: 'parental-control',
        builder: (context, state) => const ParentalControlScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        name: 'help-feedback',
        builder: (context, state) => const HelpFeedbackScreen(),
      ),
      GoRoute(
        path: '/profile/achievements',
        name: 'achievements',
        builder: (context, state) => const AchievementScreen(),
      ),
      GoRoute(
        path: '/reading/:bookId',
        name: 'reading',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return ReadingScreen(bookId: bookId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});