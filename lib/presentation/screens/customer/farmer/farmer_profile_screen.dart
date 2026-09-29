import 'package:firebase_auth/firebase_auth.dart';
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
  double? _customerRating;
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<ProductProvider>();
    if (provider.allProducts.isEmpty) await provider.load();
    final farmer = await provider.farmerById(widget.farmerId);
    final currentUser = FirebaseAuth.instance.currentUser;
    final myRating = currentUser == null
        ? null
        : await context
            .read<WishlistProvider>()
            .myRatingForFarmer(widget.farmerId);
    if (!mounted) return;
    setState(() {
      _farmer = farmer;
      _customerRating = myRating;
      _isLoading = false;
    });
  }

  Future<void> _submitRating(double value) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    setState(() => _isSubmittingRating = true);
    await context.read<WishlistProvider>().rateFarmer(widget.farmerId, value);
    final rated = await context
        .read<WishlistProvider>()
        .myRatingForFarmer(widget.farmerId);
    if (!mounted) return;
    setState(() {
      _customerRating = rated;
      _isSubmittingRating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.mainGreen)),
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

    final products =
        context.watch<ProductProvider>().productsByFarmer(farmer.id);
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
                backgroundImage: farmer.avatarUrl != null
                    ? NetworkImage(farmer.avatarUrl!)
                    : null,
                child: farmer.avatarUrl == null
                    ? const Icon(Icons.agriculture,
                        color: AppColors.mainGreen, size: 26)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farmer.businessName,
                        style: AppTextStyles.headingMedium),
                    FutureBuilder(
                      future: Future.wait([
                        context
                            .read<WishlistProvider>()
                            .followersCountFor(farmer.id),
                        context
                            .read<WishlistProvider>()
                            .farmerRatingFor(farmer.id),
                      ]),
                      builder: (context, snapshot) {
                        final count = (snapshot.data?[0] as int?) ?? 0;
                        final average =
                            (snapshot.data?[1] as double?) ?? farmer.rating;
                        final textValue =
                            average == 0 ? 'New' : average.toStringAsFixed(1);
                        return Text(
                          '$textValue ★ • $count followers',
                          style: AppTextStyles.bodyMuted,
                        );
                      },
                    ),
                    Text(
                      farmer.marketDay,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (farmer.farmImageUrl != null &&
              farmer.farmImageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                farmer.farmImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (farmer.description.isNotEmpty) ...[
            Text(farmer.description, style: AppTextStyles.bodyRegular),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rate this farmer', style: AppTextStyles.headingMedium),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    final selected = (_customerRating ?? 0) >= value;
                    return IconButton(
                      onPressed: FirebaseAuth.instance.currentUser == null ||
                              _isSubmittingRating
                          ? null
                          : () => _submitRating(value.toDouble()),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: selected
                            ? AppColors.wheatGold
                            : AppColors.textSecondary,
                        size: 30,
                      ),
                    );
                  }),
                ),
                if (FirebaseAuth.instance.currentUser == null)
                  Text(
                    'Sign in to rate this farmer.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  )
                else if (_customerRating != null)
                  Text(
                    'Your rating: ${_customerRating!.toStringAsFixed(1)} / 5',
                    style: AppTextStyles.caption,
                  )
                else
                  Text(
                    'Tap a star to rate this farmer.',
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () =>
                context.read<WishlistProvider>().toggleFollow(farmer.id),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: isFollowing ? AppColors.mainGreen : AppColors.border),
              foregroundColor:
                  isFollowing ? AppColors.mainGreen : AppColors.textPrimary,
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(isFollowing ? 'Following' : 'Follow'),
          ),
          const SizedBox(height: 22),
          Text('Products', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const EmptyState(
                icon: Icons.eco_outlined, title: 'No products listed yet')
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
                    MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsScreen(productId: product.id)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
