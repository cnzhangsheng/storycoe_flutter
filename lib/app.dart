import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storycoe_flutter/core/router/app_router.dart';
import 'package:storycoe_flutter/core/theme/app_theme.dart';
import 'package:storycoe_flutter/providers/auth_provider.dart';

/// Main application widget
class StoryCoeApp extends ConsumerStatefulWidget {
  const StoryCoeApp({super.key});

  @override
  ConsumerState<StoryCoeApp> createState() => _StoryCoeAppState();
}

class _StoryCoeAppState extends ConsumerState<StoryCoeApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 应用启动时自动登录（免登录模式）
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn) {
      debugPrint('[StoryCoeApp] 自动登录中...');
      await ref.read(authProvider.notifier).devLogin();
      debugPrint('[StoryCoeApp] 自动登录完成');
    }
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // 显示启动画面直到登录完成
    if (!_isInitialized) {
      return MaterialApp(
        title: 'StoryCoe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'StoryCoe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}