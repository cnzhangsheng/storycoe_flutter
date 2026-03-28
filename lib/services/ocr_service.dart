import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// OCR 识别结果句子
class OcrSentence {
  final String en;
  final String? zh;

  const OcrSentence({
    required this.en,
    this.zh,
  });

  factory OcrSentence.fromJson(Map<String, dynamic> json) {
    return OcrSentence(
      en: json['en'] as String? ?? '',
      zh: json['zh'] as String?,
    );
  }
}

/// OCR 识别结果
class OcrResult {
  final List<OcrSentence> sentences;
  final String? error;

  const OcrResult({
    this.sentences = const [],
    this.error,
  });

  bool get isSuccess => error == null && sentences.isNotEmpty;
}

/// OCR 服务
/// 调用后端 API 进行图片文字识别
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  static const String _baseUrl = 'http://localhost:8000';

  /// 识别图片中的英文文字
  /// [imageBytes] 图片字节数据
  /// [fileName] 文件名（用于确定 MIME 类型）
  Future<OcrResult> recognize(Uint8List imageBytes, String fileName) async {
    try {
      // 创建 multipart request
      final uri = Uri.parse('$_baseUrl/ocr/recognize');
      final request = http.MultipartRequest('POST', uri);

      // 确定 MIME 类型
      String mimeType = 'image/jpeg';
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      // 添加图片文件
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // 解析句子列表
        final sentencesList = data['sentences'] as List? ?? [];
        final sentences = sentencesList
            .map((s) => OcrSentence.fromJson(s as Map<String, dynamic>))
            .where((s) => s.en.isNotEmpty)
            .toList();

        return OcrResult(sentences: sentences);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>? ??
            {'message': '识别失败'};
        return OcrResult(
          error: errorData['message']?.toString() ?? '识别失败',
        );
      }
    } catch (e) {
      return OcrResult(error: '网络错误: $e');
    }
  }

  /// Mock 识别（用于开发和测试）
  /// 返回模拟的识别结果
  Future<OcrResult> mockRecognize() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 2));

    return OcrResult(
      sentences: [
        const OcrSentence(en: 'Once upon a time, there was a little bird.'),
        const OcrSentence(en: 'She lived in a big, green forest.'),
        const OcrSentence(en: 'One sunny morning, she decided to fly away.'),
        const OcrSentence(en: 'Where will she go?', zh: '她会去哪里呢？'),
        const OcrSentence(en: 'The adventure begins!'),
      ],
    );
  }
}

/// 全局 OCR 服务实例
final ocrService = OcrService();