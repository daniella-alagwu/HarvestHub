import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/cart/cart_provider.dart';
import '../../data/models/product_model.dart';
import '../theme/colors/app_colors.dart';
import '../theme/text_styles.dart';
import 'product_image.dart';

/// Square-ish image on top, name/farmer/price below, with a small
/// add-to-cart circle in the bottom-right corner of the image — matches
/// the "Fresh today" tiles on the Home screen.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductImage(imageUrl: product.imageUrl),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _AddButton(product: product),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            product.farmerName,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            product.priceLabel,
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.deepGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: product.isInStock
          ? () => context.read<CartProvider>().addItem(product)
          : null,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: product.isInStock ? AppColors.mainGreen : AppColors.disabledGreen,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 16),
      ),
    );
  }
}