import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Conditional import for Web Speech API
import 'tts_web_stub.dart'
    if (dart.library.js_interop) 'tts_web.dart' as tts_web;

/// ========================================
/// TTS 朗读状态枚举
/// ========================================
enum TtsState {
  /// 空闲状态
  idle,
  /// 播放中
  playing,
  /// 暂停中
  paused,
}

/// ========================================
/// TTS (Text-to-Speech) 服务
///
/// 特性：
/// - 标准美式英语发音 (en-US)
/// - 支持语速调节（慢速/中速/正常）
/// - 支持播放/暂停/继续/停止
/// - 播放状态回调
/// - Web 平台使用原生 Web Speech API
/// ========================================
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  TtsState _state = TtsState.idle;
  String? _currentText;
  double _speechRate = 0.45; // 默认中速
  String _language = 'en-US'; // 默认美式发音

  /// 状态变化回调
  VoidCallback? onStateChanged;

  /// 当前状态
  TtsState get state => _state;

  /// 是否正在播放
  bool get isPlaying => _state == TtsState.playing;

  /// 是否暂停中
  bool get isPaused => _state == TtsState.paused;

  /// 当前播放的文本
  String? get currentText => _currentText;

  /// 当前语速
  double get speechRate => _speechRate;

  /// 初始化 TTS
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Web 平台使用原生 Web Speech API
      if (kIsWeb) {
        _isInitialized = true;
        debugPrint('TTS Service initialized for Web (using Web Speech API)');
        return;
      }

      // 移动端使用 Flutter TTS
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setCompletionHandler(() {
        _setState(TtsState.idle);
        _currentText = null;
      });

      _flutterTts.setStartHandler(() {
        _setState(TtsState.playing);
      });

      _flutterTts.setCancelHandler(() {
        _setState(TtsState.idle);
        _currentText = null;
      });

      _flutterTts.setErrorHandler((message) {
        _setState(TtsState.idle);
        _currentText = null;
        debugPrint('TTS Error: $message');
      });

      // iOS 特定设置
      if (Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      _isInitialized = true;
      debugPrint('TTS Service initialized for Mobile');
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
    }
  }

  /// 更新状态并通知
  void _setState(TtsState newState) {
    _state = newState;
    onStateChanged?.call();
  }

  /// 播放文本
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      // 如果正在播放，先停止
      if (_state == TtsState.playing) {
        await stop();
      }

      _currentText = text;

      // Web 平台使用原生 Web Speech API
      if (kIsWeb) {
        return await _speakWeb(text);
      }

      // 移动端使用 Flutter TTS
      final result = await _flutterTts.speak(text);
      if (result == 1) {
        _setState(TtsState.playing);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      return false;
    }
  }

  /// Web 平台播放（使用 Web Speech API）
  Future<bool> _speakWeb(String text) async {
    try {
      // 语速映射：Flutter TTS 的 0.0-1.0 映射到 Web Speech API 的 rate
      // Web Speech API rate: 0.1 (最慢) 到 10 (最快), 1.0 是正常
      // 我们的映射: 慢(0.3) -> 0.6, 中(0.45) -> 0.85, 正常(0.6) -> 1.1
      final webRate = _speechRate * 2.0; // 转换为 Web Speech API 的 rate

      final success = await tts_web.speak(
        text: text,
        rate: webRate,
        lang: _language, // 使用当前设置的语言
        onStart: () {
          _setState(TtsState.playing);
        },
        onEnd: () {
          _setState(TtsState.idle);
          _currentText = null;
        },
        onError: (error) {
          debugPrint('Web TTS Error: $error');
          _setState(TtsState.idle);
          _currentText = null;
        },
      );

      return success;
    } catch (e) {
      debugPrint('Web TTS speak failed: $e');
      return false;
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    if (!_isInitialized || _state != TtsState.playing) return;

    try {
      if (kIsWeb) {
        tts_web.pause();
        _setState(TtsState.paused);
      } else {
        await _flutterTts.pause();
        _setState(TtsState.paused);
      }
    } catch (e) {
      debugPrint('TTS pause failed: $e');
    }
  }

  /// 继续播放（重新朗读当前文本）
  Future<void> resume() async {
    if (!_isInitialized || _state != TtsState.paused) return;

    if (_currentText != null) {
      await speak(_currentText!);
    }
  }

  /// 停止播放
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      if (kIsWeb) {
        tts_web.cancel();
      } else {
        await _flutterTts.stop();
      }
      _setState(TtsState.idle);
      _currentText = null;
    } catch (e) {
      debugPrint('TTS stop failed: $e');
    }
  }

  /// 切换播放/暂停
  Future<void> togglePlayPause(String text) async {
    switch (_state) {
      case TtsState.idle:
        await speak(text);
        break;
      case TtsState.playing:
        if (_currentText == text) {
          await pause();
        } else {
          await speak(text);
        }
        break;
      case TtsState.paused:
        if (_currentText == text) {
          await resume();
        } else {
          await speak(text);
        }
        break;
    }
  }

  /// 设置语速
  /// [rate] 语速，0.0 - 1.0
  /// - 慢速: 0.3
  /// - 中速: 0.45 (默认)
  /// - 正常: 0.6
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    debugPrint('TTS speech rate set to: $_speechRate');

    // 移动端需要更新 Flutter TTS
    if (!kIsWeb && _isInitialized) {
      await _flutterTts.setSpeechRate(_speechRate);
    }
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    _language = language;
    debugPrint('TTS language set to: $_language');

    if (!_isInitialized) await init();

    if (!kIsWeb) {
      await _flutterTts.setLanguage(language);
    }
  }

  /// 获取可用语言列表
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) await init();

    if (kIsWeb) {
      return ['en-US', 'en-GB'];
    }

    try {
      final languages = await _flutterTts.getLanguages;
      if (languages is List) {
        return languages.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('Get languages failed: $e');
    }
    return ['en-US', 'en-GB'];
  }

  /// 释放资源
  void dispose() {
    stop();
    _isInitialized = false;
    onStateChanged = null;
  }
}

/// 全局 TTS 服务实例
final ttsService = TtsService();