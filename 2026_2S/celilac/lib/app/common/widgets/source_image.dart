import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SourceImage extends StatelessWidget {
  const SourceImage({
    super.key,
    required this.source,
    required this.displayWidth,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String source;
  final double displayWidth;
  final Widget fallback;
  final BoxFit fit;
  final String? semanticLabel;

  ImageProvider _providerFor(String source) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return NetworkImage(source);
    }
    return AssetImage(source);
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final decodeWidth = (displayWidth * pixelRatio).round();

    return Image(
      image: ResizeImage(_providerFor(source), width: decodeWidth),
      fit: fit,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null || wasSynchronouslyLoaded) {
          return child;
        }
        return ColoredBox(color: AppColors.navy.withValues(alpha: 0.06));
      },
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
