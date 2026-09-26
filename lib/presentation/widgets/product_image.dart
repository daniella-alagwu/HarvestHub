import 'package:flutter/material.dart';
import '../theme/colors/app_colors.dart';

/// Shows [imageUrl] when present; otherwise falls back to a soft-green
/// tile with a leaf icon so cards never look broken while farmers are
/// still uploading real photos.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.imageUrl,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  final String? imageUrl;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? _placeholder()
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _placeholder(loading: true);
              },
            ),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      color: AppColors.softGreen,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.mainGreen,
              ),
            )
          : const Icon(Icons.eco_outlined, color: AppColors.mainGreen, size: 28),
    );
  }
}