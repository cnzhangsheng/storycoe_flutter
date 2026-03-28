import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 日志工具
void _log(String message, [dynamic data]) {
  final timestamp = DateTime.now().toString().substring(11, 23);
  final logMsg = '[ApiService][$timestamp] $message';
  if (data != null) {
    debugPrint('$logMsg: $data');
  } else {
    debugPrint(logMsg);
  }
}

/// API configuration
class ApiConfig {
  // For Android emulator, use 10.0.2.2 to access localhost
  // For iOS simulator, use localhost
  // For web, use localhost
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const Duration timeoutDuration = Duration(seconds: 30);
}

/// API client for backend communication
class ApiClient {
  final http.Client _httpClient;
  String? _token;

  ApiClient({http.Client? client}) : _httpClient = client ?? http.Client();

  /// Get the underlying HTTP client for multipart requests
  http.Client get httpClient => _httpClient;

  /// Get stored auth token
  Future<String?> _getToken() async {
    if (_token != null) return _token;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  /// Save auth token
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Clear auth token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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

  /// GET request
  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: queryParams?.map((k, v) => MapEntry(k, v)),
    );

    final headers = await _buildHeaders(auth: auth);
    _log('GET请求', {'url': uri.toString(), 'auth': auth, 'headers': headers});

    try {
      final response = await _httpClient.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeoutDuration);

      _log('GET响应', {'status': response.statusCode, 'body': response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)});
      return _handleResponse(response);
    } catch (e) {
      _log('GET请求失败', {'url': uri.toString(), 'error': e.toString()});
      rethrow;
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String path, {
    bool auth = false,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await _httpClient.post(
      uri,
      headers: await _buildHeaders(auth: auth),
      body: jsonEncode(body ?? {}),
    ).timeout(ApiConfig.timeoutDuration);

    return _handleResponse(response);
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String path, {
    bool auth = false,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await _httpClient.put(
      uri,
      headers: await _buildHeaders(auth: auth),
      body: jsonEncode(body ?? {}),
    ).timeout(ApiConfig.timeoutDuration);

    return _handleResponse(response);
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await _httpClient.delete(
      uri,
      headers: await _buildHeaders(auth: auth),
    ).timeout(ApiConfig.timeoutDuration);

    return _handleResponse(response);
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
      throw ApiException(
        statusCode: response.statusCode,
        message: '认证失败，请重新登录',
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
  }) async {
    final body = <String, dynamic>{};

    if (title != null) body['title'] = title;
    if (level != null) body['level'] = level;
    if (progress != null) body['progress'] = progress;
    if (coverImage != null) body['cover_image'] = coverImage;
    if (isNew != null) body['is_new'] = isNew;
    if (hasAudio != null) body['has_audio'] = hasAudio;
    if (status != null) body['status'] = status;

    return _client.put('/books/$bookId', auth: true, body: body);
  }

  /// Delete book
  Future<void> deleteBook(String bookId) async {
    await _client.delete('/books/$bookId', auth: true);
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

  /// Generate book from images
  /// Returns a Stream<String> of SSE events
  Stream<String> generateBook({
    required String title,
    (String, List<int>)? cover, // (filename, bytes) - 封面图片
    required List<(String, List<int>)> images, // (filename, bytes)
    String? token,
  }) async* {
    final uri = Uri.parse('${ApiConfig.baseUrl}/generate/book');
    _log('准备请求', {'url': uri.toString(), 'title': title, 'imageCount': images.length, 'hasCover': cover != null});

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
    // Send request - use the underlying HTTP client's send method
    final streamedResponse = await _client.httpClient.send(request);

    _log('收到响应', {'statusCode': streamedResponse.statusCode});
    if (streamedResponse.statusCode != 200) {
      // 读取错误响应
      final errorBody = await streamedResponse.stream.bytesToString();
      _log('错误响应', {'statusCode': streamedResponse.statusCode, 'body': errorBody});
      yield 'data: {"error": "请求失败: ${streamedResponse.statusCode}"}';
      return;
    }

    // Stream the response
    int chunkCount = 0;
    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      chunkCount++;
      _log('数据块 #$chunkCount', {'length': chunk.length});
      yield chunk;
    }
    _log('流结束', {'totalChunks': chunkCount});
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