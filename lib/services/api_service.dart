import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storycoe_flutter/core/events/auth_event.dart';
import 'package:storycoe_flutter/core/utils/logger.dart';

/// Internal log function using AppLogger
void _log(String message, [dynamic data]) {
  if (kDebugMode) {
    final logMsg = data != null ? '$message: $data' : message;
    log('[ApiService] $logMsg');
  }
}

/// ========================================
/// 环境配置
/// ========================================
class Environment {
  /// 当前环境类型
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// 是否为生产环境
  static bool get isProduction => environment == 'production';

  /// 是否为开发环境
  static bool get isDevelopment => environment == 'development';

  /// API 基础地址
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}

/// API configuration
class ApiConfig {
  // 开发环境: localhost (Web) 或 10.0.2.2 (Android Emulator)
  // 生产环境: 47.85.201.118:8000
  static String get baseUrl {
    // 如果通过环境变量指定了地址，直接使用
    if (Environment.apiBaseUrl != 'http://localhost:8000') {
      return Environment.apiBaseUrl;
    }

    // 开发环境下，根据平台自动选择
    if (Environment.isDevelopment) {
      if (kIsWeb) {
        return 'http://localhost:8000';
      }
      // Android 模拟器需要使用 10.0.2.2 访问宿主机
      return 'http://10.0.2.2:8000';
    }

    return Environment.apiBaseUrl;
  }

  static const Duration timeoutDuration = Duration(seconds: 60);
}

/// API client for backend communication
class ApiClient {
  final http.Client _httpClient;
  String? _token;

  /// Secure storage for sensitive data (tokens)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Maximum retry attempts for failed requests
  static const int _maxRetries = 3;

  /// Base delay between retries (exponential backoff)
  static const Duration _retryDelay = Duration(seconds: 1);

  ApiClient({http.Client? client}) : _httpClient = client ?? http.Client();

  /// Get the underlying HTTP client for multipart requests
  http.Client get httpClient => _httpClient;

  /// Get stored auth token from secure storage
  Future<String?> _getToken() async {
    if (_token != null) return _token;

    try {
      _token = await _secureStorage.read(key: 'auth_token');
      return _token;
    } catch (e) {
      debugPrint('[ApiClient] Error reading token from secure storage: $e');
      return null;
    }
  }

  /// Save auth token to secure storage
  Future<void> saveToken(String token) async {
    _token = token;
    try {
      await _secureStorage.write(key: 'auth_token', value: token);
    } catch (e) {
      debugPrint('[ApiClient] Error saving token to secure storage: $e');
    }
  }

  /// Clear auth token from secure storage
  Future<void> clearToken() async {
    _token = null;
    try {
      await _secureStorage.delete(key: 'auth_token');
    } catch (e) {
      debugPrint('[ApiClient] Error clearing token from secure storage: $e');
    }
  }

  /// Migrate token from SharedPreferences to SecureStorage (one-time migration)
  /// Also clears any old tokens from SharedPreferences
  Future<void> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if there's an old token in SharedPreferences
      final oldToken = prefs.getString('auth_token');

      if (oldToken != null && oldToken.isNotEmpty) {
        _log('发现旧的 SharedPreferences token，正在迁移...');

        // Check if we already have a token in SecureStorage
        final existingToken = await _secureStorage.read(key: 'auth_token');

        if (existingToken == null || existingToken.isEmpty) {
          // Migrate to SecureStorage
          await _secureStorage.write(key: 'auth_token', value: oldToken);
          _token = oldToken;
          _log('Token 已迁移到 SecureStorage');
        }

        // Always clear the old token from SharedPreferences
        await prefs.remove('auth_token');
        _log('已清除旧的 SharedPreferences token');
      }
    } catch (e) {
      debugPrint('[ApiClient] Error migrating token: $e');
    }
  }

  /// Get auth token (public method for external access)
  Future<String?> getToken() async {
    return _getToken();
  }

  /// Build headers for requests
  Future<Map<String, String>> _buildHeaders({bool auth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// GET request with retry support
  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: queryParams?.map((k, v) => MapEntry(k, v)),
    );

    final headers = await _buildHeaders(auth: auth);
    _log('GET请求', {'url': uri.toString(), 'auth': auth});

    return _executeWithRetry(
      () => _httpClient.get(uri, headers: headers).timeout(ApiConfig.timeoutDuration),
    );
  }

  /// POST request with retry support
  Future<Map<String, dynamic>> post(
    String path, {
    bool auth = false,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _buildHeaders(auth: auth);

    return _executeWithRetry(
      () => _httpClient.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(ApiConfig.timeoutDuration),
    );
  }

  /// PUT request with retry support
  Future<Map<String, dynamic>> put(
    String path, {
    bool auth = false,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _buildHeaders(auth: auth);

    return _executeWithRetry(
      () => _httpClient.put(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(ApiConfig.timeoutDuration),
    );
  }

  /// DELETE request with retry support
  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _buildHeaders(auth: auth);

    return _executeWithRetry(
      () => _httpClient.delete(uri, headers: headers).timeout(ApiConfig.timeoutDuration),
    );
  }

  /// Check if an error is retryable (network issues, timeouts)
  bool _isRetryableError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socketexception') ||
           errorStr.contains('timeoutexception') ||
           errorStr.contains('connection') ||
           errorStr.contains('network') ||
           errorStr.contains('httpclientexception') ||
           errorStr.contains('clientexception');
  }

  /// Execute a request with retry logic
  Future<Map<String, dynamic>> _executeWithRetry(
    Future<http.Response> Function() request, {
    int retries = _maxRetries,
  }) async {
    try {
      final response = await request();
      return _handleResponse(response);
    } catch (e) {
      if (retries > 0 && _isRetryableError(e)) {
        final delay = _retryDelay * (_maxRetries - retries + 1);
        _log('请求失败，${delay.inSeconds}秒后重试', {
          'remainingRetries': retries - 1,
          'error': e.toString(),
        });
        await Future.delayed(delay);
        return _executeWithRetry(request, retries: retries - 1);
      }
      rethrow;
    }
  }

  /// Handle API response (适配后端统一响应格式)
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    // 后端统一响应格式: {"code": 0/非0, "message": "...", "data": ...}
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 成功响应
      if (body is Map<String, dynamic>) {
        // 如果响应包含 code 字段，说明是新的统一格式
        if (body.containsKey('code') && body['code'] == 0) {
          return body['data'] as Map<String, dynamic>? ?? body;
        }
        // 兼容旧格式或直接返回数据
        return body;
      }
      return {'data': body};
    }

    // 错误响应 - 解析统一格式的错误信息
    String errorMessage = '请求失败';
    String? errorCode;

    if (body is Map<String, dynamic>) {
      // 新格式: {"code": "ERROR_CODE", "message": "错误信息", "data": null}
      errorCode = body['code']?.toString();
      errorMessage = body['message']?.toString() ??
                     body['detail']?.toString() ??
                     '请求失败';
    }

    // 根据状态码或错误码抛出特定异常
    if (response.statusCode == 401 || errorCode == 'UNAUTHORIZED' || errorCode == 'AUTH_FAILED') {
      // 清除本地 Token 并触发全局登出事件
      clearToken();
      authEventBus.emitLogout();
      throw ApiException(
        statusCode: response.statusCode,
        message: '认证已过期，请重新登录',
        errorCode: errorCode,
      );
    }

    if (response.statusCode == 404 || errorCode == 'NOT_FOUND') {
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        errorCode: errorCode,
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      errorCode: errorCode,
    );
  }
}

/// API exception with error code support
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode; // 后端返回的业务错误码

  ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  @override
  String toString() => 'ApiException: $message (code: $statusCode, error: $errorCode)';
}

/// Auth API service
class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  /// Send verification code
  Future<Map<String, dynamic>> sendCode(String phone) async {
    return _client.post('/auth/send-code', body: {'phone': phone});
  }

  /// Verify code and login/register
  Future<Map<String, dynamic>> verifyCode(String phone, String code) async {
    final response = await _client.post('/auth/verify', body: {
      'phone': phone,
      'code': code,
    });

    // Save token
    if (response['access_token'] != null) {
      await _client.saveToken(response['access_token'] as String);
    }

    return response;
  }

  /// Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    return _client.get('/auth/me', auth: true);
  }

  /// Logout
  Future<void> logout() async {
    await _client.post('/auth/logout', auth: true);
    await _client.clearToken();
  }
}

/// Books API service
class BooksApi {
  final ApiClient _client;

  BooksApi(this._client);

  /// List books
  Future<Map<String, dynamic>> listBooks({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (status != null) {
      queryParams['status'] = status;
    }

    return _client.get('/books', auth: true, queryParams: queryParams);
  }

  /// List public books (no authentication required)
  Future<Map<String, dynamic>> listPublicBooks({
    int page = 1,
    int pageSize = 20,
    int? level,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (level != null) {
      queryParams['level'] = level.toString();
    }

    return _client.get('/books/public', auth: false, queryParams: queryParams);
  }

  /// Get book by ID
  Future<Map<String, dynamic>> getBook(String bookId) async {
    return _client.get('/books/$bookId', auth: true);
  }

  /// Create book
  Future<Map<String, dynamic>> createBook({
    required String title,
    int level = 1,
    String? coverImage,
  }) async {
    return _client.post('/books', auth: true, body: {
      'title': title,
      'level': level,
      'cover_image': coverImage,
    });
  }

  /// Update book
  Future<Map<String, dynamic>> updateBook(
    String bookId, {
    String? title,
    int? level,
    int? progress,
    String? coverImage,
    bool? isNew,
    bool? hasAudio,
    String? status,
    String? shareType,
  }) async {
    final body = <String, dynamic>{};

    if (title != null) body['title'] = title;
    if (level != null) body['level'] = level;
    if (progress != null) body['progress'] = progress;
    if (coverImage != null) body['cover_image'] = coverImage;
    if (isNew != null) body['is_new'] = isNew;
    if (hasAudio != null) body['has_audio'] = hasAudio;
    if (status != null) body['status'] = status;
    if (shareType != null) body['share_type'] = shareType;

    return _client.put('/books/$bookId', auth: true, body: body);
  }

  /// Delete book
  Future<void> deleteBook(String bookId) async {
    await _client.delete('/books/$bookId', auth: true);
  }

  /// Add book to shelf
  Future<void> addToShelf(String bookId) async {
    await _client.post('/books/$bookId/shelf', auth: true);
  }

  /// Remove book from shelf
  Future<void> removeFromShelf(String bookId) async {
    await _client.delete('/books/$bookId/shelf', auth: true);
  }

  /// Check if book is in shelf
  Future<bool> checkShelfStatus(String bookId) async {
    final response = await _client.get('/books/$bookId/shelf-status', auth: true);
    return response['in_shelf'] as bool? ?? false;
  }

  /// Get book page
  Future<Map<String, dynamic>> getBookPage(String bookId, int pageNumber) async {
    return _client.get('/books/$bookId/pages/$pageNumber', auth: true);
  }

  /// Generate book from images
  Future<Map<String, dynamic>> generateBook({
    String? title,
    required List<String> images,
    int level = 1,
  }) async {
    return _client.post('/books/generate', auth: true, body: {
      'title': title,
      'images': images,
      'level': level,
    });
  }

  /// Update sentence text
  Future<Map<String, dynamic>> updateSentence({
    required String bookId,
    required String sentenceId,
    required String text,
  }) async {
    return _client.put('/books/$bookId/sentences/$sentenceId', auth: true, body: {
      'en': text,  // 后端期望 'en' 字段
    });
  }

  /// Create new sentence in a page
  Future<Map<String, dynamic>> createSentence({
    required String bookId,
    required int pageNumber,
    required String en,
    String zh = '',
  }) async {
    final path = '/books/$bookId/pages/$pageNumber/sentences';
    _log('createSentence请求', {'path': path, 'en': en, 'zh': zh});
    return _client.post(path, auth: true, body: {
      'en': en,
      'zh': zh,
    });
  }

  /// Reorder sentences in a page
  Future<void> reorderSentences({
    required String bookId,
    required int pageNumber,
    required List<String> sentenceIds,
  }) async {
    await _client.put('/books/$bookId/pages/$pageNumber/sentences/reorder', auth: true, body: {
      'sentence_ids': sentenceIds,
    });
  }

  /// Delete a sentence
  Future<void> deleteSentence({
    required String bookId,
    required String sentenceId,
  }) async {
    await _client.delete('/books/$bookId/sentences/$sentenceId', auth: true);
  }

  /// Create a new page with image
  Future<Map<String, dynamic>> createPage({
    required String bookId,
    int? pageNumber,
    required String filename,
    required List<int> imageBytes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/books/$bookId/pages');
    final request = http.MultipartRequest('POST', uri);

    // Add authorization header
    final token = await _client.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add page_number if specified
    if (pageNumber != null) {
      request.fields['page_number'] = pageNumber.toString();
    }

    // Add image file
    request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: filename));

    final streamedResponse = await _client.httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to create page: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Delete a page
  Future<void> deletePage(String bookId, int pageNumber) async {
    await _client.delete('/books/$bookId/pages/$pageNumber', auth: true);
  }
}

/// Users API service
class UsersApi {
  final ApiClient _client;

  UsersApi(this._client);

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    return _client.get('/users/me', auth: true);
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatar,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatar != null) body['avatar'] = avatar;

    return _client.put('/users/me', auth: true, body: body);
  }

  /// Upload avatar
  Future<Map<String, dynamic>> uploadAvatar({
    required String filename,
    required List<int> bytes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/avatar');
    final request = http.MultipartRequest('POST', uri);

    // Add authorization header
    final token = await _client._getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add avatar file
    final file = http.MultipartFile.fromBytes(
      'avatar',
      bytes,
      filename: filename,
    );
    request.files.add(file);

    final streamedResponse = await _client.httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    return _client._handleResponse(response);
  }

  /// Get user settings
  Future<Map<String, dynamic>> getSettings() async {
    return _client.get('/users/settings', auth: true);
  }

  /// Update user settings
  Future<Map<String, dynamic>> updateSettings({
    String? speedLabel,
    String? accent,
    bool? loopEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (speedLabel != null) body['speed_label'] = speedLabel;
    if (accent != null) body['accent'] = accent;
    if (loopEnabled != null) body['loop_enabled'] = loopEnabled;

    return _client.put('/users/settings', auth: true, body: body);
  }

  /// Get user stats
  Future<Map<String, dynamic>> getStats() async {
    return _client.get('/users/stats', auth: true);
  }
}

/// Reading API service
class ReadingApi {
  final ApiClient _client;

  ReadingApi(this._client);

  /// Get reading progress
  Future<Map<String, dynamic>> getProgress(String bookId) async {
    return _client.get('/reading/$bookId', auth: true);
  }

  /// Update reading progress
  Future<Map<String, dynamic>> updateProgress(
    String bookId, {
    int? currentPage,
    bool? completed,
  }) async {
    final body = <String, dynamic>{};
    if (currentPage != null) body['current_page'] = currentPage;
    if (completed != null) body['completed'] = completed;

    return _client.put('/reading/$bookId', auth: true, body: body);
  }

  /// Mark book as completed
  Future<Map<String, dynamic>> markCompleted(String bookId) async {
    return _client.post('/reading/$bookId/complete', auth: true);
  }
}

/// Generate API service
class GenerateApi {
  final ApiClient _client;

  GenerateApi(this._client);

  /// Generate book from images (async version)
  /// Returns immediately after upload, OCR runs in background
  Future<Map<String, dynamic>> generateBook({
    required String title,
    (String, List<int>)? cover, // (filename, bytes) - 封面图片
    required List<(String, List<int>)> images, // (filename, bytes)
    String shareType = 'private', // 'public' or 'private'
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/generate/book');
    _log('准备请求', {'url': uri.toString(), 'title': title, 'imageCount': images.length, 'hasCover': cover != null, 'shareType': shareType});

    final request = http.MultipartRequest('POST', uri);

    // Add authorization header
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
      _log('设置 Authorization header', {'tokenLength': token.length});
    } else {
      _log('警告: 没有 token');
    }

    // Add title
    request.fields['title'] = title;

    // Add share_type
    request.fields['share_type'] = shareType;

    // 调试：打印所有字段
    _log('请求字段', request.fields);

    // Add cover image (optional)
    if (cover != null) {
      final (filename, bytes) = cover;
      final coverFile = http.MultipartFile.fromBytes(
        'cover',
        bytes,
        filename: filename,
      );
      request.files.add(coverFile);
      _log('添加封面文件', {'filename': filename, 'size': bytes.length});
    }

    // Add images
    for (var i = 0; i < images.length; i++) {
      final (filename, bytes) = images[i];
      final file = http.MultipartFile.fromBytes(
        'images',
        bytes,
        filename: filename,
      );
      request.files.add(file);
      _log('添加图片文件', {'index': i, 'filename': filename, 'size': bytes.length});
    }

    _log('发送请求...');
    // Send request
    final streamedResponse = await _client.httpClient.send(request);

    _log('收到响应', {'statusCode': streamedResponse.statusCode});

    // Read response body
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      _log('错误响应', {'statusCode': streamedResponse.statusCode, 'body': responseBody});
      throw ApiException(
        statusCode: streamedResponse.statusCode,
        message: responseBody,
      );
    }

    final result = jsonDecode(responseBody) as Map<String, dynamic>;
    _log('上传成功', result);
    return result;
  }

  /// Generate book from images (sync version - deprecated)
  /// Returns a Stream<String> of SSE events
  @Deprecated('Use generateBook instead - this is the old sync version')
  Stream<String> generateBookSync({
    required String title,
    (String, List<int>)? cover,
    required List<(String, List<int>)> images,
    String? token,
  }) async* {
    final uri = Uri.parse('${ApiConfig.baseUrl}/generate/book/sync');
    _log('准备请求', {'url': uri.toString(), 'title': title, 'imageCount': images.length, 'hasCover': cover != null});

    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['title'] = title;

    if (cover != null) {
      final (filename, bytes) = cover;
      request.files.add(http.MultipartFile.fromBytes('cover', bytes, filename: filename));
    }

    for (var i = 0; i < images.length; i++) {
      final (filename, bytes) = images[i];
      request.files.add(http.MultipartFile.fromBytes('images', bytes, filename: filename));
    }

    final streamedResponse = await _client.httpClient.send(request);

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      yield 'data: {"error": "请求失败: ${streamedResponse.statusCode}"}';
      return;
    }

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      yield chunk;
    }
  }
}

/// Global API client instance
final apiClient = ApiClient();

/// API service instances
final authApi = AuthApi(apiClient);
final booksApi = BooksApi(apiClient);
final usersApi = UsersApi(apiClient);
final readingApi = ReadingApi(apiClient);
final generateApi = GenerateApi(apiClient);
final gamificationApi = GamificationApi(apiClient);
final leaderboardApi = LeaderboardApi(apiClient);


/// ========================================
/// Gamification API (游戏化激励系统)
/// ========================================

class GamificationApi {
  final ApiClient _client;

  GamificationApi(this._client);

  /// 获取用户游戏化统计数据
  Future<Map<String, dynamic>> getStats({String? token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gamification/stats');
    _log('获取游戏化统计', {'url': uri.toString()});

    final response = await _client.get(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('游戏化统计结果', data);
    return data;
  }

  /// 获取所有成就列表（包含解锁状态）
  Future<Map<String, dynamic>> getAchievements({String? token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gamification/achievements');
    _log('获取成就列表', {'url': uri.toString()});

    final response = await _client.get(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('成就列表结果', data);
    return data;
  }

  /// 检查并解锁成就
  Future<Map<String, dynamic>> checkAchievements({String? token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gamification/achievements/check');
    _log('检查成就', {'url': uri.toString()});

    final response = await _client.get(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('检查成就结果', data);
    return data;
  }

  /// 获取今日任务状态
  Future<Map<String, dynamic>> getDailyTask({String? token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gamification/daily-task');
    _log('获取每日任务', {'url': uri.toString()});

    final response = await _client.get(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('每日任务结果', data);
    return data;
  }

  /// 领取每日任务奖励
  Future<Map<String, dynamic>> claimDailyTaskReward({String? token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gamification/daily-task/claim');
    _log('领取每日任务奖励', {'url': uri.toString()});

    final response = await _client.post(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('领取奖励结果', data);
    return data;
  }

  /// 初始化默认成就数据
  Future<Map<String, dynamic>> initAchievements({String? token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/gamification/init');
    _log('初始化成就数据', {'url': uri.toString()});

    final response = await _client.post(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('初始化结果', data);
    return data;
  }
}


/// ========================================
/// Leaderboard API (排行榜)
/// ========================================

class LeaderboardApi {
  final ApiClient _client;

  LeaderboardApi(this._client);

  /// 获取热门绘本榜
  Future<Map<String, dynamic>> getHotBooks({
    int limit = 10,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/leaderboard/books/hot?limit=$limit');
    _log('获取热门绘本榜', {'url': uri.toString()});

    final response = await _client.get(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('热门绘本榜结果', data);
    return data;
  }

  /// 获取新星绘本榜
  Future<Map<String, dynamic>> getNewBooks({
    int days = 7,
    int limit = 10,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/leaderboard/books/new?days=$days&limit=$limit');
    _log('获取新星绘本榜', {'url': uri.toString()});

    final response = await _client.get(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('新星绘本榜结果', data);
    return data;
  }

  /// 获取活跃作者榜
  Future<Map<String, dynamic>> getAuthors({
    int limit = 10,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/leaderboard/authors?limit=$limit');
    _log('获取活跃作者榜', {'url': uri.toString()});

    final response = await _client.get(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('活跃作者榜结果', data);
    return data;
  }

  /// 获取排行榜摘要（各榜单前3名）
  Future<Map<String, dynamic>> getSummary({String? token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/leaderboard/summary');
    _log('获取排行榜摘要', {'url': uri.toString()});

    final response = await _client.get(uri, token: token);
    final data = jsonDecode(response) as Map<String, dynamic>;
    _log('排行榜摘要结果', data);
    return data;
  }
}