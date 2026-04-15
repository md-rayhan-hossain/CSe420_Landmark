import 'package:flutter/material.dart';
import 'package:geo_entities_app/services/landmark_api_service.dart';

class LandmarkImage extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;

  const LandmarkImage({
    super.key,
    required this.imagePath,
    this.width = 88,
    this.height = 88,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = LandmarkApiService.imageUrlFor(imagePath);
    final borderRadius = BorderRadius.circular(8);

    if (imageUrl.isEmpty) {
      return _Frame(
        width: width,
        height: height,
        borderRadius: borderRadius,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _Frame(
            width: width,
            height: height,
            borderRadius: borderRadius,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _Frame(
            width: width,
            height: height,
            borderRadius: borderRadius,
            child: const Icon(Icons.broken_image_outlined),
          );
        },
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Widget child;

  const _Frame({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
