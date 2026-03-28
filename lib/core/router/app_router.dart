import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storybird_flutter/providers/auth_provider.dart';
import 'package:storybird_flutter/screens/create/create_screen.dart';
import 'package:storybird_flutter/screens/create/image_preview_screen.dart';
import 'package:storybird_flutter/screens/home/home_screen.dart';
import 'package:storybird_flutter/screens/login/login_screen.dart';
import 'package:storybird_flutter/screens/profile/profile_screen.dart';
import 'package:storybird_flutter/screens/reading/reading_screen.dart';
import 'package:storybird_flutter/providers/create_provider.dart';

/// App router configuration
final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/home';
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
        path: '/create',
        name: 'create',
        builder: (context, state) => const CreateScreen(),
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