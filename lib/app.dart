import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybird_flutter/core/router/app_router.dart';
import 'package:storybird_flutter/core/theme/app_theme.dart';

/// Main application widget
class StoryBirdApp extends ConsumerWidget {
  const StoryBirdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'StoryBird',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}