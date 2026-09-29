import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../application/cart/cart_provider.dart';
import '../../../../application/products/product_provider.dart';
import '../../../../application/wishlist/wishlist_provider.dart';

import '../../../../data/models/farmer_model.dart';
import '../../../../data/models/product_model.dart';

import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';

import '../../../widgets/primary_button.dart';
import '../../../widgets/product_image.dart';

import '../farmer/farmer_profile_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  final String productId;

  static const routeName = '/customer/product-details';

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _product;
  Farmer? _farmer;
  bool _isLoading = true;
  double _quantity = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<ProductProvider>();
    final product = await provider.productById(widget.productId);
    final farmer = product == null
        ? null
        : await provider.farmerById(product.farmerId);

    if (!mounted) return;

    setState(() {
      _product = product;
      _farmer = farmer;
      _quantity = 1;
      _isLoading = false;
    });
  }

  void _changeQuantity(double delta) {
    final product = _product;
    if (product == null) return;

    setState(() {
      final next = _quantity + delta;
      _quantity = next
          .clamp(1, product.stockQty <= 0 ? 1 : product.stockQty)
          .toDouble();
    });
  }

  void _addToCart(Product product) {
    context.read<CartProvider>().addItem(
          product,
          quantity: _quantity,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.mainGreen,
          ),
        ),
      );
    }

    final product = _product;

    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found')),
      );
    }

    final wishlist = context.watch<WishlistProvider>();
    final isWishlisted = wishlist.isWishlisted(product.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Product image stays in its own area. Nothing is positioned over
            // the details card, so large prices or long names cannot overlap.
            AspectRatio(
              aspectRatio: 1.08,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _CircleIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _CircleIconButton(
                      icon: isWishlisted
                          ? Icons.favorite
                          : Icons.favorite_border,
                      iconColor: isWishlisted
                          ? AppColors.autumnRust
                          : AppColors.textPrimary,
                      onTap: () => context
                          .read<WishlistProvider>()
                          .toggleWishlist(product.id),
                    ),
                  ),
                  if (product.isOrganic)
                    const Positioned(
                      left: 12,
                      bottom: 12,
                      child: _Badge(
                        label: 'ORGANIC',
                        color: AppColors.mainGreen,
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.isInStock
                            ? '${product.stockQty} ${product.unit} in stock'
                            : 'Out of stock',
                        style: AppTextStyles.caption.copyWith(
                          color: product.isInStock
                              ? AppColors.deepGreen
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details live below the image instead of overlapping it.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.priceLabel,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description.isEmpty
                        ? 'Fresh produce from a local farmer.'
                        : product.description,
                    style: AppTextStyles.bodyRegular,
                  ),
                  if (_farmer != null) ...[
                    const SizedBox(height: 20),
                    _FarmerRow(farmer: _farmer!),
                  ],
                  const SizedBox(height: 22),
                  if (product.isInStock) ...[
                    _QuantityStepper(
                      quantity: _quantity,
                      unit: product.unit,
                      onDecrement: () => _changeQuantity(-1),
                      onIncrement: () => _changeQuantity(1),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Add to cart • ${Product.formatNaira(product.pricePerUnit * _quantity)}',
                      onPressed: () => _addToCart(product),
                      backgroundColor: AppColors.mainGreen,
                    ),
                  ] else
                    const PrimaryButton(
                      label: 'Out of stock',
                      onPressed: null,
                      backgroundColor: AppColors.disabledGreen,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerRow extends StatelessWidget {
  const _FarmerRow({required this.farmer});

  final Farmer farmer;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isFollowing = wishlist.isFollowing(farmer.id);

    void openProfile() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FarmerProfileScreen(farmerId: farmer.id),
        ),
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: openProfile,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.softGreen,
            backgroundImage: farmer.avatarUrl != null
                ? NetworkImage(farmer.avatarUrl!)
                : null,
            child: farmer.avatarUrl == null
                ? const Icon(
                    Icons.agriculture,
                    color: AppColors.mainGreen,
                    size: 19,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: openProfile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmer.businessName,
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${farmer.rating} ★ • ${farmer.followersCount} followers',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => context
              .read<WishlistProvider>()
              .toggleFollow(farmer.id),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isFollowing ? AppColors.mainGreen : AppColors.border,
            ),
            foregroundColor:
                isFollowing ? AppColors.mainGreen : AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Text(isFollowing ? 'Following' : 'Follow'),
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.unit,
    required this.onDecrement,
    required this.onIncrement,
  });

  final double quantity;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final label = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: onDecrement,
          ),
          Text(
            '$label $unit',
            style: AppTextStyles.bodyRegular.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
