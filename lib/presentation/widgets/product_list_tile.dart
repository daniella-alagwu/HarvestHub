import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/wishlist/wishlist_provider.dart';
import '../../data/models/product_model.dart';
import '../theme/colors/app_colors.dart';
import '../theme/text_styles.dart';
import 'product_image.dart';

/// Horizontal row: thumbnail, name/farmer/distance/stock, price, and a
/// wishlist heart — matches the "Find local food" search results list.
class ProductListTile extends StatelessWidget {
  const ProductListTile({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isWishlisted = wishlist.isWishlisted(product.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ProductImage(imageUrl: product.imageUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(product.farmerName, style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 2),
                  Text(
                    '${product.distanceLabel} • ${product.isInStock ? "In stock" : "Out of stock"}',
                    style: AppTextStyles.caption.copyWith(
                      color: product.isInStock ? AppColors.textSecondary : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => context.read<WishlistProvider>().toggleWishlist(product.id),
                  child: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isWishlisted ? AppColors.autumnRust : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  product.priceLabel,
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}