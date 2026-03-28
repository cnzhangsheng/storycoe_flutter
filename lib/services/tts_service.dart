import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
/// - 慢速儿童适配朗读
/// - 支持播放/暂停/继续/停止
/// - 播放状态回调
/// ========================================
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  TtsState _state = TtsState.idle;
  String? _currentText;

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

  /// 初始化 TTS
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 设置语言为美式英语
      await _flutterTts.setLanguage('en-US');

      // 设置语速（适合儿童的较慢语速：0.4）
      await _flutterTts.setSpeechRate(0.4);

      // 设置音高
      await _flutterTts.setPitch(1.0);

      // 设置音量
      await _flutterTts.setVolume(1.0);

      // 设置完成回调
      _flutterTts.setCompletionHandler(() {
        _setState(TtsState.idle);
        _currentText = null;
      });

      // 设置开始回调
      _flutterTts.setStartHandler(() {
        _setState(TtsState.playing);
      });

      // 设置暂停回调
      _flutterTts.setCancelHandler(() {
        _setState(TtsState.idle);
        _currentText = null;
      });

      // 设置错误回调
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
      debugPrint('TTS Service initialized');
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

  /// 暂停播放
  Future<void> pause() async {
    if (!_isInitialized || _state != TtsState.playing) return;

    try {
      await _flutterTts.pause();
      _setState(TtsState.paused);
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
      await _flutterTts.stop();
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
          // 切换到新句子
          await speak(text);
        }
        break;
      case TtsState.paused:
        if (_currentText == text) {
          await resume();
        } else {
          // 切换到新句子
          await speak(text);
        }
        break;
    }
  }

  /// 设置语速
  /// [rate] 语速，0.0 - 1.0，默认 0.4（适合儿童）
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await init();
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await init();
    await _flutterTts.setLanguage(language);
  }

  /// 获取可用语言列表
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) await init();

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