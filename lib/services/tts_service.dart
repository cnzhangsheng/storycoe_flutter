import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:storycoe_flutter/core/utils/logger.dart';

// Conditional import for Web Speech API
import 'tts_web_stub.dart'
    if (dart.library.js_interop) 'tts_web.dart' as tts_web;

/// ========================================
/// TTS 朗读进度信息
/// ========================================
class TtsProgress {
  final String text;
  final int start;
  final int end;
  final String word;

  const TtsProgress({
    required this.text,
    required this.start,
    required this.end,
    required this.word,
  });
}

/// ========================================
/// TTS 朗读状态枚举
/// ========================================
enum TtsState {
  idle,
  playing,
  paused,
}

/// ========================================
/// TTS 服务 - 优化国产手机兼容性（小米引擎优先）
/// ========================================
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  Completer<void>? _initCompleter;

  bool _isInitialized = false;
  TtsState _state = TtsState.idle;
  String? _currentText;
  double _speechRate = 0.5;
  String _language = 'en-US';
  String? _lastError;
  String? _currentEngine;

  final List<String> _debugLogs = [];
  List<String> _availableEngines = [];
  List<String> _availableLanguages = [];

  /// 常用国产 TTS 引擎包名（保留用于 debug 显示）
  static const Map<String, String> _knownEngines = {
    'xiaomi': 'com.xiaomi.mibrain.speech',
    'huawei': 'com.huawei.hiai',
    'iflytek': 'com.iflytek.speechcloud',
    'google': 'com.google.android.tts',
  };

  /// 状态变化回调列表（支持多个监听者）
  final List<VoidCallback> _stateCallbacks = [];

  /// 进度回调列表（支持单词级高亮）
  final List<void Function(TtsProgress)> _progressCallbacks = [];

  VoidCallback? onStateChanged;

  TtsState get state => _state;
  bool get isPlaying => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  String? get currentText => _currentText;
  double get speechRate => _speechRate;
  String? get lastError => _lastError;
  String get debugLogsText => _debugLogs.join('\n');
  String? get currentEngine => _currentEngine;
  List<String> get availableEngines => _availableEngines;
  List<String> get availableLanguages => _availableLanguages;

  /// 添加状态监听
  void addStateCallback(VoidCallback callback) {
    _stateCallbacks.add(callback);
  }

  /// 移除状态监听
  void removeStateCallback(VoidCallback callback) {
    _stateCallbacks.remove(callback);
  }

  /// 添加进度监听（单词级高亮）
  void addProgressCallback(void Function(TtsProgress) callback) {
    _progressCallbacks.add(callback);
  }

  /// 移除进度监听
  void removeProgressCallback(void Function(TtsProgress) callback) {
    _progressCallbacks.remove(callback);
  }

  void clearDebugLogs() {
    _debugLogs.clear();
  }

  void clearError() {
    _lastError = null;
  }

  void _log(String message) {
    if (kDebugMode) {
      log('[TTS] $message');
      final timestamp = DateTime.now().toString().substring(11, 23);
      final logLine = '[$timestamp] $message';
      _debugLogs.add(logLine);
      if (_debugLogs.length > 150) {
        _debugLogs.removeAt(0);
      }
    }
  }

  /// 获取 TTS 设置指南
  String getTtsSetupGuide() {
    if (kIsWeb) return '';
    return '''
请在手机上配置 TTS 引擎：
1. 打开「设置」→「更多设置」→「语言与输入法」→「文字转语音」
2. 选择「小米语音」或「科大讯飞语音」
3. 点击设置图标，下载英语语言包
4. 返回应用重试''';
  }

  /// 打开系统 TTS 设置（通过 Platform Channel）
  Future<void> openTtsSettings() async {
    if (kIsWeb) return;
    try {
      _log('尝试打开 TTS 设置...');
      // 使用 MethodChannel 调用原生代码打开设置
      const platform = MethodChannel('com.storycoe.tts/settings');
      await platform.invokeMethod('openTtsSettings');
      _log('已调用打开 TTS 设置');
    } on PlatformException catch (e) {
      _log('打开 TTS 设置失败: ${e.message}');
    } catch (e) {
      _log('打开设置异常: $e');
    }
  }

  /// 初始化 TTS（优先使用小米引擎）
  Future<bool> init() async {
    _log('init() 开始, _isInitialized=$_isInitialized');

    if (_isInitialized) {
      _log('已经初始化，跳过');
      return true;
    }

    if (_initCompleter != null) {
      _log('等待其他初始化完成...');
      await _initCompleter!.future;
      return _isInitialized;
    }

    _initCompleter = Completer<void>();

    try {
      if (kIsWeb) {
        _isInitialized = true;
        _initCompleter!.complete();
        _log('Web 平台初始化完成');
        return true;
      }

      _log('开始初始化移动端 TTS...');

      _flutterTts = FlutterTts();

      // 获取所有可用引擎（用于 debug）
      await _getAvailableEngines();

      // 获取可用语言列表
      await _getAvailableLanguages();

      // 设置基本参数
      _log('设置基本参数...');
      try {
        await _flutterTts!.setVolume(1.0);
        await _flutterTts!.setPitch(1.0);
      } catch (e) {
        _log('设置音量/音调失败（可忽略）: $e');
      }

      // 设置回调
      _flutterTts!.setStartHandler(() {
        _log('>>> 播放开始回调触发');
        _setState(TtsState.playing);
      });

      _flutterTts!.setCompletionHandler(() {
        _log('>>> 播放完成回调触发');
        _setState(TtsState.idle);
        _currentText = null;
      });

      _flutterTts!.setCancelHandler(() {
        _log('>>> 播放取消回调触发');
        _setState(TtsState.idle);
        _currentText = null;
      });

      _flutterTts!.setErrorHandler((message) {
        _log('>>> 播放错误回调触发: $message');
        _lastError = 'TTS 错误: $message';
        _setState(TtsState.idle);
        _currentText = null;
      });

      // 设置进度回调（某些设备支持）
      _flutterTts!.setProgressHandler((text, start, end, word) {
        _log('>>> 进度: start=$start, end=$end, word=$word');
        // 通知所有进度监听者
        final progress = TtsProgress(
          text: text,
          start: start,
          end: end,
          word: word,
        );
        for (final callback in _progressCallbacks) {
          callback(progress);
        }
      });

      // iOS 设置
      if (Platform.isIOS) {
        _log('iOS 平台设置...');
        try {
          await _flutterTts!.setSharedInstance(true);
          await _flutterTts!.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          );
        } catch (e) {
          _log('iOS 设置失败（可忽略）: $e');
        }
      }

      // Android 设置
      if (Platform.isAndroid) {
        _log('Android 平台设置...');

        try {
          await _flutterTts!.awaitSpeakCompletion(false);
          _log('awaitSpeakCompletion(false) 成功');
        } catch (e) {
          _log('awaitSpeakCompletion 失败（可忽略）: $e');
        }

        // 获取可用语言列表（用于判断引擎支持的语言）
        try {
          final languages = await _flutterTts!.getLanguages;
          _log('getLanguages 返回: $languages');
          if (languages is List) {
            _availableLanguages = languages.map((e) => e.toString()).toList();
          }
        } catch (e) {
          _log('getLanguages 失败（可忽略）: $e');
        }

        // 尝试设置语言
        await _trySetLanguage(_language);
        await _trySetSpeechRate(_speechRate);
      }

      _isInitialized = true;
      _initCompleter!.complete();
      _log('初始化完成!');
      return true;
    } catch (e, stack) {
      _log('初始化异常: $e');
      _log('堆栈: $stack');
      _lastError = '初始化失败: $e';
      _initCompleter!.complete();
      return false;
    }
  }

  Future<void> _trySetLanguage(String lang) async {
    try {
      _log('设置语言: $lang');
      _log('可用语言: $_availableLanguages');

      // 如果语言在可用列表中，直接设置
      if (_availableLanguages.contains(lang)) {
        await _flutterTts!.setLanguage(lang);
        _log('✓ 语言设置成功: $lang');
        return;
      }

      // 尝试匹配语言变体
      String? matchedLang;
      switch (lang) {
        case 'en-US':
        case '美式':
          // 优先查找 en-US
          matchedLang = _availableLanguages.firstWhere(
            (l) => l == 'en-US' || l.toLowerCase() == 'en-us',
            orElse: () => '',
          );
          if (matchedLang.isEmpty) {
            // 查找任何 en 开头的语言
            matchedLang = _availableLanguages.firstWhere(
              (l) => l.toLowerCase().startsWith('en'),
              orElse: () => '',
            );
          }
          break;
        case 'en-GB':
        case '英式':
          // 优先查找 en-GB
          matchedLang = _availableLanguages.firstWhere(
            (l) => l == 'en-GB' || l.toLowerCase() == 'en-gb',
            orElse: () => '',
          );
          if (matchedLang.isEmpty) {
            // 查找任何 en 开头的语言
            matchedLang = _availableLanguages.firstWhere(
              (l) => l.toLowerCase().startsWith('en'),
              orElse: () => '',
            );
          }
          break;
        default:
          // 查找相近语言
          matchedLang = _availableLanguages.firstWhere(
            (l) => l.toLowerCase().contains(lang.toLowerCase().split('-')[0]),
            orElse: () => '',
          );
      }

      if (matchedLang.isNotEmpty) {
        await _flutterTts!.setLanguage(matchedLang);
        _log('✓ 使用匹配语言: $matchedLang (请求: $lang)');
      } else {
        // 最后尝试直接设置，让系统处理
        await _flutterTts!.setLanguage(lang);
        _log('直接设置语言: $lang');
      }
    } catch (e) {
      _log('设置语言失败: $e');
    }
  }

  Future<void> _trySetSpeechRate(double rate) async {
    try {
      _log('设置语速: $rate');
      await _flutterTts!.setSpeechRate(rate);
      _log('✓ 语速设置成功: $rate');
    } catch (e) {
      _log('设置语速失败: $e');
    }
  }

  /// 获取所有可用的 TTS 引擎
  Future<void> _getAvailableEngines() async {
    try {
      final engines = await _flutterTts!.getEngines;
      _log('可用引擎列表: $engines');
      if (engines is List) {
        _availableEngines = engines.map((e) => e.toString()).toList();
      }
    } catch (e) {
      _log('获取引擎列表失败: $e');
      _availableEngines = [];
    }
  }

  /// 获取可用语言列表
  Future<void> _getAvailableLanguages() async {
    try {
      final languages = await _flutterTts!.getLanguages;
      _log('可用语言列表: $languages');
      if (languages is List) {
        _availableLanguages = languages.map((e) => e.toString()).toList();
      }
    } catch (e) {
      _log('获取语言列表失败: $e');
      _availableLanguages = [];
    }
  }

  /// 检查是否支持特定语言变体（美式/英式）
  bool isLanguageVariantSupported(String variant) {
    if (_availableLanguages.isEmpty) return false;

    switch (variant) {
      case 'en-US':
      case '美式':
        // 检查是否有 en-US 或类似变体
        return _availableLanguages.any((l) =>
          l == 'en-US' ||
          l == 'en-us' ||
          l.toLowerCase().contains('en-us') ||
          l.toLowerCase().contains('eng-us'));
      case 'en-GB':
      case '英式':
        // 检查是否有 en-GB 或类似变体
        return _availableLanguages.any((l) =>
          l == 'en-GB' ||
          l == 'en-gb' ||
          l.toLowerCase().contains('en-gb') ||
          l.toLowerCase().contains('eng-gb'));
      default:
        return _availableLanguages.contains(variant);
    }
  }

  /// 获取可用的发音选项
  List<String> getAvailableAccents() {
    final accents = <String>[];

    if (isLanguageVariantSupported('en-US')) {
      accents.add('美式');
    }
    if (isLanguageVariantSupported('en-GB')) {
      accents.add('英式');
    }

    // 如果没有找到具体变体，但有通用英语，添加默认选项
    if (accents.isEmpty && _availableLanguages.any((l) => l.toLowerCase().contains('en'))) {
      accents.add('默认');
    }

    return accents;
  }

  /// Debug: 打印引擎信息
  String getEnginesDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln('=== TTS 引擎信息 ===');

    // 引擎列表
    if (_availableEngines.isEmpty) {
      buffer.writeln('未获取到引擎列表');
    } else {
      buffer.writeln('可用引擎数量: ${_availableEngines.length}');
      for (var i = 0; i < _availableEngines.length; i++) {
        final engine = _availableEngines[i];
        final isKnown = _knownEngines.values.contains(engine);
        buffer.writeln('$i. $engine${isKnown ? " (已知)" : ""}');
      }
    }

    // 语言列表
    buffer.writeln('');
    buffer.writeln('=== 可用语言 ===');
    if (_availableLanguages.isEmpty) {
      buffer.writeln('未获取到语言列表');
    } else {
      for (final lang in _availableLanguages) {
        buffer.writeln('- $lang');
      }
    }

    // 发音选项
    buffer.writeln('');
    buffer.writeln('=== 发音选项 ===');
    final accents = getAvailableAccents();
    if (accents.isEmpty) {
      buffer.writeln('无英语发音选项');
    } else {
      for (final accent in accents) {
        buffer.writeln('- $accent');
      }
    }

    return buffer.toString();
  }

  void _setState(TtsState newState) {
    _state = newState;
    _log('_setState: $newState, 通知 ${_stateCallbacks.length} 个回调');
    // 通知所有监听者
    for (final callback in _stateCallbacks) {
      callback();
    }
    // 也通知旧的单回调（兼容）
    onStateChanged?.call();
  }

  /// 播放文本 - 每次播放前强制设置参数
  Future<bool> speak(String text) async {
    _log('========================================');
    _log('speak() 被调用');
    _log('文本: "$text"');
    _log('语速: $_speechRate, 语言: $_language');

    if (!_isInitialized) {
      _log('未初始化，开始初始化...');
      await init();
    }

    if (kIsWeb) {
      return await _speakWeb(text);
    }

    try {
      // 如果正在播放，先停止
      if (_state == TtsState.playing) {
        _log('正在播放中，先停止...');
        await stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _currentText = text;
      _lastError = null;

      // 强制设置参数（每次播放前）
      _log('强制设置 TTS 参数...');
      await _trySetLanguage(_language);
      await _trySetSpeechRate(_speechRate);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      _log('调用 _flutterTts.speak()...');
      final result = await _flutterTts!.speak(text);
      _log('speak() 返回: $result (${result.runtimeType})');

      // 直接返回成功（不等待回调）
      // 原因：部分设备的 setStartHandler 回调不可靠，会导致超时误判
      // 如果 speak() 返回成功，就认为播放已开始
      _setState(TtsState.playing);

      return true;
    } catch (e, stack) {
      _log('speak() 异常: $e');
      _log('堆栈: $stack');
      _lastError = '播放失败: $e';
      return false;
    }
  }

  Future<bool> _speakWeb(String text) async {
    try {
      final webRate = _speechRate * 2.0;
      final success = await tts_web.speak(
        text: text,
        rate: webRate,
        lang: _language,
        onStart: () {
          _log('Web TTS 开始');
          _setState(TtsState.playing);
        },
        onEnd: () {
          _log('Web TTS 结束');
          _setState(TtsState.idle);
          _currentText = null;
        },
        onError: (error) {
          _log('Web TTS 错误: $error');
          _setState(TtsState.idle);
          _currentText = null;
        },
      );
      return success;
    } catch (e) {
      _log('Web speak 失败: $e');
      return false;
    }
  }

  Future<void> pause() async {
    if (!_isInitialized || _state != TtsState.playing) return;
    try {
      if (kIsWeb) {
        tts_web.pause();
      } else {
        await _flutterTts?.pause();
      }
      _setState(TtsState.paused);
    } catch (e) {
      _log('pause 失败: $e');
    }
  }

  Future<void> resume() async {
    if (!_isInitialized || _state != TtsState.paused) return;
    if (_currentText != null) {
      await speak(_currentText!);
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    try {
      if (kIsWeb) {
        tts_web.cancel();
      } else {
        await _flutterTts?.stop();
      }
      _setState(TtsState.idle);
      _currentText = null;
    } catch (e) {
      _log('stop 失败: $e');
    }
  }

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

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    _log('语速设置: $_speechRate');
    if (!kIsWeb && _isInitialized) {
      await _trySetSpeechRate(_speechRate);
    }
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    _log('语言设置: $_language');
    if (!_isInitialized) {
      await init();
    }
    if (!kIsWeb && _isInitialized) {
      await _trySetLanguage(_language);
    }
  }

  Future<List<String>> getLanguages() async {
    if (!_isInitialized) await init();
    if (kIsWeb) {
      return ['en-US', 'en-GB'];
    }
    try {
      final languages = await _flutterTts?.getLanguages;
      if (languages is List) {
        return languages.map((e) => e.toString()).toList();
      }
    } catch (e) {
      _log('获取语言失败: $e');
    }
    return ['en-US', 'en-GB'];
  }

  void dispose() {
    stop();
    _isInitialized = false;
    _initCompleter = null;
    onStateChanged = null;
  }
}

final ttsService = TtsService();