import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    print('SafeNetworkImage loading: $imageUrl');
    if (imageUrl.isEmpty) return _fallbackContainer();

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _shimmerLoader(),
      errorWidget: (context, url, error) => _fallbackContainer(),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    return image;
  }

  Widget _shimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.zero,
        ),
      ),
    );
  }

  Widget _fallbackContainer() {
    double iconSize = 24;
    if (width != null && width != double.infinity) {
      iconSize = width! * 0.3;
    } else if (height != null && height != double.infinity) {
      iconSize = height! * 0.3;
    }

    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceContainerHigh,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_outlined, color: AppColors.textMuted, size: iconSize),
          const SizedBox(height: 4),
          Text('Image error', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
