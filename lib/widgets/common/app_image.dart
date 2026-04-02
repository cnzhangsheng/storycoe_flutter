import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:storycoe_flutter/services/api_service.dart';

/// A universal image widget that handles both local assets and network images
class AppImage extends StatelessWidget {
  final String? image;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  /// 缓存破坏参数，用于强制刷新图片（如头像更新）
  final String? cacheBuster;

  const AppImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.cacheBuster,
  });

  bool get isLocalAsset => image != null && image!.startsWith('assets/');
  bool get hasImage => image != null && image!.isNotEmpty;

  /// 获取完整的图片URL
  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('assets/')) return url;
    // 拼接后端静态资源地址
    return '${ApiConfig.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    if (!hasImage) {
      return errorWidget ??
          Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
    }

    if (isLocalAsset) {
      return Image.asset(
        image!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      );
    }

    // 构建URL，添加缓存破坏参数
    String finalUrl = _getFullUrl(image!);
    if (cacheBuster != null && cacheBuster!.isNotEmpty) {
      finalUrl = '$finalUrl?t=$cacheBuster';
    }

    return CachedNetworkImage(
      imageUrl: finalUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder != null
          ? (context, url) => placeholder!
          : (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget!
          : (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
    );
  }
}