import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storycoe_flutter/core/utils/logger.dart';
import 'package:storycoe_flutter/models/user_profile.dart';
import 'package:storycoe_flutter/providers/books_provider.dart';
import 'package:storycoe_flutter/services/api_service.dart' show authApi, ApiException, apiClient;

/// Auth state
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final UserProfile? user;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    UserProfile? user,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  /// Clear all user-related caches when logging out or switching users
  void _clearUserCaches() {
    log('[AuthProvider] 清除用户缓存');
    // Clear books list - this will force a reload when the new user logs in
    // Note: We reset the state to empty, not reload (to avoid showing wrong user's data)
  }

  /// Send verification code to phone
  Future<bool> sendCode(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await authApi.sendCode(phone);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Verify code and login/register
  Future<bool> verifyCode(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Clear any existing user data before login
      _clearUserCaches();

      final response = await authApi.verifyCode(phone, code);
      final user = UserProfile.fromJson(response['user']);

      log('[AuthProvider] 登录成功: phone=$phone, user_id=${user.id}');

      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        user: user,
      );

      // Load books for the new user
      _ref.read(booksProvider.notifier).loadBooks();

      return true;
    } on ApiException catch (e) {
      // 根据错误码提供更友好的错误提示
      String errorMsg = e.message;
      if (e.errorCode == 'CODE_INVALID') {
        errorMsg = '验证码错误，请重新输入';
      } else if (e.errorCode == 'CODE_EXPIRED') {
        errorMsg = '验证码已过期，请重新获取';
      } else if (e.errorCode == 'CODE_USED') {
        errorMsg = '验证码已使用，请重新获取';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Check if user is already logged in
  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await authApi.getCurrentUser();
      final user = UserProfile.fromJson(response);

      log('[AuthProvider] checkAuth 成功: user_id=${user.id}, phone=${user.phone}');

      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        user: user,
      );

      // Load books for the user
      _ref.read(booksProvider.notifier).loadBooks();
    } catch (e) {
      log('[AuthProvider] checkAuth 失败: $e');
      state = const AuthState();
    }
  }

  /// Logout
  Future<void> logout() async {
    log('[AuthProvider] 用户登出');

    // Clear token
    try {
      await authApi.logout();
    } catch (_) {
      // Ignore errors on logout
    }

    // Clear all user caches
    _clearUserCaches();

    // Reset auth state
    state = const AuthState();
  }

  /// 免登录模式：开发环境自动登录
  /// 注意：生产环境应禁用此功能，需要后端配合提供开发登录接口
  Future<bool> devLogin() async {
    state = state.copyWith(isLoading: true);
    try {
      // 尝试获取当前用户信息（如果已有 token）
      final response = await authApi.getCurrentUser();
      final user = UserProfile.fromJson(response);

      log('[AuthProvider] devLogin 成功: user_id=${user.id}, phone=${user.phone}');

      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        user: user,
      );

      // Load books for the user
      _ref.read(booksProvider.notifier).loadBooks();

      return true;
    } on ApiException catch (e) {
      log('[AuthProvider] 自动登录失败: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: '请登录',
      );
      return false;
    } catch (e) {
      log('[AuthProvider] 异常: $e');
      state = state.copyWith(
        isLoading: false,
        error: '请登录',
      );
      return false;
    }
  }

  /// Update user profile
  void updateUser(UserProfile user) {
    state = state.copyWith(user: user);
  }

  /// Refresh user profile from server
  Future<void> refreshProfile() async {
    try {
      final response = await authApi.getCurrentUser();
      final user = UserProfile.fromJson(response);
      state = state.copyWith(user: user);
      log('[AuthProvider] 用户信息已刷新: ${user.name}');
    } catch (e) {
      logWarn('[AuthProvider] 刷新失败: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

/// Convenience providers
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final userProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).user;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

/// 头像更新时间戳，用于强制刷新缓存的头像图片
final avatarTimestampProvider = StateProvider<String>((ref) {
  return DateTime.now().millisecondsSinceEpoch.toString();
});