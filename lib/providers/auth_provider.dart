import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storycoe_flutter/models/user_profile.dart';
import 'package:storycoe_flutter/services/api_service.dart' show authApi, ApiException;

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
  AuthNotifier() : super(const AuthState());

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
      final response = await authApi.verifyCode(phone, code);
      final user = UserProfile.fromJson(response['user']);
      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        user: user,
      );
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
      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        user: user,
      );
    } catch (e) {
      state = const AuthState();
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await authApi.logout();
    } catch (_) {
      // Ignore errors on logout
    }
    state = const AuthState();
  }

  /// 免登录模式：使用测试账号登录
  Future<bool> devLogin() async {
    state = state.copyWith(isLoading: true);
    try {
      // 使用测试账号 13800000000 和验证码 123456
      const phone = '13800000000';
      const code = '123456';

      debugPrint('[devLogin] 开始登录: phone=$phone');

      // 先发送验证码
      try {
        await authApi.sendCode(phone);
        debugPrint('[devLogin] 验证码已发送');
      } catch (e) {
        debugPrint('[devLogin] 发送验证码失败（继续尝试登录）: $e');
      }

      // 使用验证码登录
      debugPrint('[devLogin] 尝试验证登录: code=$code');
      final response = await authApi.verifyCode(phone, code);
      debugPrint('[devLogin] 登录响应: $response');

      final user = UserProfile.fromJson(response['user']);
      debugPrint('[devLogin] 用户信息: id=${user.id}, name=${user.name}');

      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        user: user,
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('[devLogin] 登录失败: ${e.message}, code=${e.errorCode}');
      // 如果登录失败，使用 Mock 用户
      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        user: MockUserProfile.profile,
      );
      return true;
    } catch (e) {
      debugPrint('[devLogin] 异常: $e');
      // 使用 Mock 用户
      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        user: MockUserProfile.profile,
      );
      return true;
    }
  }

  /// Login (for development mode - bypasses verification)
  void login() {
    state = AuthState(
      isLoggedIn: true,
      isLoading: false,
      user: MockUserProfile.profile,
    );
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
      debugPrint('[refreshProfile] 用户信息已刷新: ${user.name}');
    } catch (e) {
      debugPrint('[refreshProfile] 刷新失败: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
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