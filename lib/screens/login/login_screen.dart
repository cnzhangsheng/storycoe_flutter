import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storycoe_flutter/core/theme/app_colors.dart';
import 'package:storycoe_flutter/providers/auth_provider.dart'
    show
        authProvider,
        authErrorProvider,
        isLoggedInProvider,
        AuthNotifier;

/// Login screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _agreementChecked = false;
  bool _codeSent = false;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _sendCode() async {
    if (_phoneController.text.isEmpty) {
      _showError('请输入手机号码');
      return;
    }

    final success = await ref.read(authProvider.notifier).sendCode(_phoneController.text);
    if (success) {
      setState(() {
        _codeSent = true;
        _countdown = 60;
      });
      _startCountdown();
      _showSuccess('验证码已发送');
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
        return true;
      }
      return false;
    });
  }

  /// 验证码登录
  Future<void> _handleVerifyLogin() async {
    if (_phoneController.text.isEmpty) {
      _showError('请输入手机号码');
      return;
    }
    if (_codeController.text.isEmpty) {
      _showError('请输入验证码');
      return;
    }
    if (!_agreementChecked) {
      _showError('请先同意用户协议');
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyCode(
      _phoneController.text,
      _codeController.text,
    );

    if (success) {
      context.go('/home');
    }
  }

  /// 开发模式直接登录
  Future<void> _handleDevLogin() async {
    final success = await ref.read(authProvider.notifier).devLogin();
    if (success && mounted) {
      context.go('/home');
    }
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示成功提示
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 监听认证错误
    ref.listen<String?>(authErrorProvider, (previous, next) {
      if (next != null && next != previous) {
        _showError(next);
        ref.read(authProvider.notifier).clearError();
      }
    });

    // 监听登录状态
    final isLoggedIn = ref.watch(isLoggedInProvider);
    if (isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(256, 256),
                  topRight: Radius.elliptical(256, 256),
                  bottomLeft: Radius.elliptical(256, 256),
                  bottomRight: Radius.elliptical(256, 256),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(320, 320),
                  topRight: Radius.elliptical(320, 320),
                  bottomLeft: Radius.elliptical(320, 320),
                  bottomRight: Radius.elliptical(320, 320),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppColors.gummyShadowBlue,
                            ),
                            transform: Matrix4.rotationZ(0.05),
                            child: const Icon(
                              LucideIcons.bookOpen,
                              size: 48,
                              color: AppColors.onPrimaryFixed,
                            ),
                          ),
                          Positioned(
                            top: -16,
                            right: -16,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppColors.gummyShadowCoral,
                              ),
                              child: const Icon(
                                LucideIcons.volume2,
                                size: 20,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // App name
                      const Text(
                        'StoryCoe',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.onPrimaryFixed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '绘本朗读 · 奇妙世界',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Login form
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.onSurface.withValues(alpha: 0.08),
                              blurRadius: 60,
                              offset: const Offset(0, 30),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '欢迎回来',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '开启今日的英文冒险之旅',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Phone input
                            const Text(
                              '手机号码',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '请输入手机号',
                                prefixIcon: const Icon(
                                  LucideIcons.smartphone,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Verification code input
                            const Text(
                              '验证码',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _codeController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '6位验证码',
                                      prefixIcon: const Icon(
                                        LucideIcons.shieldCheck,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.surfaceContainerLow,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(32),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _countdown > 0 ? null : _sendCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.tertiaryContainer,
                                    foregroundColor:
                                        AppColors.onTertiaryContainer,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  child: Text(
                                    _countdown > 0 ? '${_countdown}s' : '获取验证码',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _agreementChecked ? _handleVerifyLogin : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondaryContainer,
                                  foregroundColor:
                                      AppColors.onSecondaryContainer,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '开始探索',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(LucideIcons.rocket),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Agreement checkbox
                            Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Checkbox(
                                    value: _agreementChecked,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreementChecked = value ?? false;
                                      });
                                    },
                                    activeColor: AppColors.secondaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: '我已阅读并同意 ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '用户协议',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onPrimaryFixed,
                                          ),
                                        ),
                                        const TextSpan(text: ' 与 '),
                                        TextSpan(
                                          text: '隐私政策',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onPrimaryFixed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Divider with text
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.surfaceContainerHighest,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    '第三方登录',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.surfaceContainerHighest,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Third-party login (开发模式快捷登录)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _handleDevLogin,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(
                                      LucideIcons.messageCircle,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}