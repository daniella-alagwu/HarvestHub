import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/products/product_provider.dart';
import '../../../../application/wishlist/wishlist_provider.dart';
import '../../../../data/models/farmer_model.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/product_card.dart';
import '../product/product_details_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key, required this.farmerId});

  final String farmerId;

  static const routeName = '/customer/farmer';

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  Farmer? _farmer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<ProductProvider>();
    if (provider.allProducts.isEmpty) await provider.load();
    final farmer = await provider.farmerById(widget.farmerId);
    if (!mounted) return;
    setState(() {
      _farmer = farmer;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.mainGreen)),
      );
    }

    final farmer = _farmer;
    if (farmer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Farmer')),
        body: const Center(child: Text('Farmer not found')),
      );
    }

    final products = context.watch<ProductProvider>().productsByFarmer(farmer.id);
    final wishlist = context.watch<WishlistProvider>();
    final isFollowing = wishlist.isFollowing(farmer.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(farmer.businessName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.softGreen,
                backgroundImage: farmer.avatarUrl != null ? NetworkImage(farmer.avatarUrl!) : null,
                child: farmer.avatarUrl == null
                    ? const Icon(Icons.agriculture, color: AppColors.mainGreen, size: 26)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farmer.businessName, style: AppTextStyles.headingMedium),
                    Text(
                      '${farmer.rating} ★ • ${farmer.followersCount} followers',
                      style: AppTextStyles.bodyMuted,
                    ),
                    Text(
                      '${farmer.distanceLabel} • ${farmer.marketDay}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (farmer.description.isNotEmpty) ...[
            Text(farmer.description, style: AppTextStyles.bodyRegular),
            const SizedBox(height: 14),
          ],
          OutlinedButton(
            onPressed: () => context.read<WishlistProvider>().toggleFollow(farmer.id),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isFollowing ? AppColors.mainGreen : AppColors.border),
              foregroundColor: isFollowing ? AppColors.mainGreen : AppColors.textPrimary,
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(isFollowing ? 'Following' : 'Follow'),
          ),
          const SizedBox(height: 22),
          Text('Products', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const EmptyState(icon: Icons.eco_outlined, title: 'No products listed yet')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}