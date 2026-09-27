import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/products/product_provider.dart';
import '../../../../application/wishlist/wishlist_provider.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/product_list_tile.dart';
import '../product/product_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  static const routeName = '/customer/wishlist';

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      if (provider.allProducts.isEmpty) provider.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final items = products.allProducts.where((p) => wishlist.isWishlisted(p.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved items')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              title: 'No saved items yet',
              subtitle: 'Tap the heart on a product to save it for later.',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final product = items[index];
                return ProductListTile(
                  product: product,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id)),
                  ),
                );
              },
            ),
    );
  }
}