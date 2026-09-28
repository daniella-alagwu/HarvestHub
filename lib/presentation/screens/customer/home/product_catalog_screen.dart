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
import '../../../widgets/logout.dart';

import '../farmer/farmer_profile_screen.dart';
import '../product/product_details_screen.dart';
import '../wishlist/wishlist_screen.dart';

import '../../../../core/greeting.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/repositories/user_repository.dart';

import '../../../../data/models/market_model.dart';
import '../../../../data/repositories/market_repository.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({
    super.key,
    this.onOpenSearch,
  });

  final VoidCallback? onOpenSearch;

  static const routeName = '/customer/home';

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _userRepository = UserRepository();
  final _marketRepository = MarketRepository();

  late final Stream<UserProfile?> _profileStream =
      _userRepository.watchCurrentUserProfile();

  Market? _selectedMarket;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().load();
      _loadLocation();
    });
  }


  String _firstNameFrom(UserProfile? profile) {
    var fullName = profile?.name.trim() ?? '';

    if (fullName.isEmpty) {
      fullName =
          FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    }

    if (fullName.isEmpty) {
      return 'there';
    }

    final first = fullName.split(RegExp(r'\s+')).first;

    return first[0].toUpperCase() + first.substring(1);
  }


  Future<void> _loadLocation() async {
    try {
      final market = await _marketRepository.fetchDefault();

      if (!mounted) return;

      setState(() {
        _selectedMarket = market;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingLocation = false;
      });
    }
  }

  // ------------------------------------------------------------
  // LOCATION PICKER
  // ------------------------------------------------------------

  Future<void> _chooseLocation() async {
    try {
      final markets = await _marketRepository.fetchAll();

      if (!mounted) return;

      final selected = await showModalBottomSheet<Market>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Choose your location',
                    style: AppTextStyles.headingLarge.copyWith(
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Select a pickup location near you.',
                    style: AppTextStyles.bodyMuted,
                  ),

                  const SizedBox(height: 18),

                  if (markets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 42,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No locations available',
                              style: AppTextStyles.bodyMuted,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...markets.map(
                      (market) {
                        final isSelected =
                            _selectedMarket?.id == market.id;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,

                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.softGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.mainGreen,
                            ),
                          ),

                          title: Text(
                            market.marketName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          subtitle: Text(
                            market.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.mainGreen,
                                )
                              : const Icon(
                                  Icons.chevron_right,
                                ),

                          onTap: () {
                            Navigator.pop(
                              context,
                              market,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      );

      if (selected == null || !mounted) return;

      setState(() {
        _selectedMarket = selected;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load locations right now.',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // LOCATION WIDGET
  // ------------------------------------------------------------

  Widget _buildLocationSelector() {
    return GestureDetector(
      onTap: _loadingLocation ? null : _chooseLocation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.mainGreen,
            size: 17,
          ),

          const SizedBox(width: 4),

          Flexible(
            child: Text(
              _loadingLocation
                  ? 'Selecting location...'
                  : 'Pickup near • ${_selectedMarket?.marketName ?? 'Select location'}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 2),

          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();

    final wishlistCount =
        context.watch<WishlistProvider>().wishlistCount;

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              context.read<ProductProvider>().load(),

          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24,
            ),

            children: [
              // --------------------------------------------------
              // TOP HEADER
              // --------------------------------------------------

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        // SELECTABLE LOCATION
                        _buildLocationSelector(),

                        const SizedBox(height: 2),

                        // GREETING
                        StreamBuilder<UserProfile?>(
                          stream: _profileStream,

                          builder: (
                            context,
                            snapshot,
                          ) {
                            return Text(
                              '${timeBasedGreeting()}, ${_firstNameFrom(snapshot.data)}',
                              style:
                                  AppTextStyles.headingLarge,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // LOGOUT
                  const LogoutButton(),

                  // WISHLIST
                  Stack(
                    clipBehavior: Clip.none,

                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                          color: AppColors.textPrimary,
                        ),

                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const WishlistScreen(),
                            ),
                          );
                        },
                      ),

                      if (wishlistCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,

                          child: Container(
                            padding:
                                const EdgeInsets.all(3),

                            decoration:
                                const BoxDecoration(
                              color:
                                  AppColors.autumnRust,
                              shape: BoxShape.circle,
                            ),

                            constraints:
                                const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),

                            child: Text(
                              '$wishlistCount',

                              textAlign:
                                  TextAlign.center,

                              style: AppTextStyles.caption
                                  .copyWith(
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

              // --------------------------------------------------
              // SEARCH
              // --------------------------------------------------

              PillSearchField(
                hint: 'Search fresh produce',
                readOnly: true,
                onTap: widget.onOpenSearch,
              ),

              const SizedBox(height: 22),

              // --------------------------------------------------
              // CATEGORIES
              // --------------------------------------------------

              CategoryFilterRow(
                selectedCategory:
                    products.selectedCategory,

                onSelected:
                    products.setCategory,
              ),

              const SizedBox(height: 26),

              // --------------------------------------------------
              // NEARBY FARMERS
              // --------------------------------------------------

              const SectionHeader(
                title: 'Nearby farmers',
              ),

              const SizedBox(height: 12),

              if (products.isLoading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 20),

                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.mainGreen,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 92,

                  child: ListView.separated(
                    scrollDirection:
                        Axis.horizontal,

                    itemCount:
                        products.farmers.length,

                    separatorBuilder: (
                      _,
                      __,
                    ) =>
                        const SizedBox(width: 10),

                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final farmer =
                          products.farmers[index];

                      return SizedBox(
                        width: 280,

                        child: NearbyFarmerCard(
                          farmer: farmer,

                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    FarmerProfileScreen(
                                  farmerId: farmer.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 26),

              // --------------------------------------------------
              // FRESH TODAY
              // --------------------------------------------------

              const SectionHeader(
                title: 'Fresh today',
              ),

              const SizedBox(height: 12),

              if (!products.isLoading)
                GridView.builder(
                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  itemCount:
                      products.freshToday.length,

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),

                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final product =
                        products.freshToday[index];

                    return ProductCard(
                      product: product,

                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailsScreen(
                              productId: product.id,
                            ),
                          ),
                        );
                      },
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
