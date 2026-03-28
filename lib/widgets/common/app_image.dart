import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A universal image widget that handles both local assets and network images
class AppImage extends StatelessWidget {
  final String? image;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  const AppImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  bool get isLocalAsset => image != null && image!.startsWith('assets/');
  bool get hasImage => image != null && image!.isNotEmpty;

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

    return CachedNetworkImage(
      imageUrl: image!,
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