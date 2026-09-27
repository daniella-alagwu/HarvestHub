import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/products/product_provider.dart';
import '../../../../application/wishlist/wishlist_provider.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/category_filter_row.dart';
import '../../../widgets/nearby_farmer_card.dart';
import '../../../widgets/pill_search_field.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/section_header.dart';
import '../farmer/farmer_profile_screen.dart';
import '../product/product_details_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../../../widgets/logout.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key, this.onOpenSearch});

  final VoidCallback? onOpenSearch;

  static const routeName = '/customer/home';
  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().load();
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName {
    final displayName = FirebaseAuth.instance.currentUser?.displayName;
    if (displayName == null || displayName.trim().isEmpty) return 'there';
    return displayName.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final wishlistCount = context.watch<WishlistProvider>().wishlistCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ProductProvider>().load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup near • Portland, OR',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 2),
                        Text('$_greeting, $_firstName', style: AppTextStyles.headingLarge),
                      ],
                    ),
                  ),
                  const LogoutButton(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WishlistScreen()),
                        ),
                      ),
                      if (wishlistCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.autumnRust,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$wishlistCount',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PillSearchField(
                hint: 'Search fresh produce',
                readOnly: true,
                onTap: widget.onOpenSearch,
              ),
              const SizedBox(height: 22),
              CategoryFilterRow(
                selectedCategory: products.selectedCategory,
                onSelected: products.setCategory,
              ),
              const SizedBox(height: 26),
              const SectionHeader(title: 'Nearby farmers'),
              const SizedBox(height: 12),
              if (products.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.mainGreen)),
                )
              else
                  SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.farmers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final farmer = products.farmers[index];
                      return SizedBox(
                        width: 280,
                        child: NearbyFarmerCard(
                          farmer: farmer,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FarmerProfileScreen(farmerId: farmer.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 26),
              const SectionHeader(title: 'Fresh today'),
              const SizedBox(height: 12),
              if (!products.isLoading)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.freshToday.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    final product = products.freshToday[index];
                    return ProductCard(
                      product: product,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(productId: product.id),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}