import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

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
  String? _selectedLocation;
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
        _selectedLocation = market.address.isNotEmpty
            ? market.address
            : market.marketName;
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
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LocationSearchSheet(
        initialLocation: _selectedLocation,
      ),
    );

    if (!mounted || selected == null || selected.trim().isEmpty) return;

    setState(() => _selectedLocation = selected);
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
                  ? 'Finding your location...'
                  : 'Location • ${_selectedLocation ?? _selectedMarket?.marketName ?? 'Select location'}',
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

              SectionHeader(
                title: products.selectedCategory ?? 'Fresh today',
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


class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({this.initialLocation});

  final String? initialLocation;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<_LocationResult> _results = [];
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialLocation ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _isSearching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'format': 'jsonv2',
          'addressdetails': '1',
          'limit': '8',
          'countrycodes': 'ng',
          'q': query,
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'HarvestHub/1.0',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Location search failed');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw Exception('Invalid location response');

      final results = decoded
          .whereType<Map>()
          .map((item) => _LocationResult(
                displayName: item['display_name']?.toString() ?? '',
                latitude: item['lat']?.toString() ?? '',
                longitude: item['lon']?.toString() ?? '',
              ))
          .where((item) => item.displayName.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _error = 'Could not search locations. Check your internet connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose your location',
                    style: AppTextStyles.headingLarge.copyWith(fontSize: 20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search a city, area or address',
                    prefixIcon: const Icon(Icons.search, color: AppColors.mainGreen),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                          ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(color: AppColors.mainGreen),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!, textAlign: TextAlign.center),
                )
              else if (_results.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Search for a real Nigerian city, area or address.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted,
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.softGreen,
                          child: Icon(Icons.location_on_outlined, color: AppColors.mainGreen),
                        ),
                        title: Text(
                          result.shortName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          result.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(result.displayName),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationResult {
  const _LocationResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final String latitude;
  final String longitude;

  String get shortName {
    final parts = displayName.split(',').map((part) => part.trim()).toList();
    return parts.isEmpty ? displayName : parts.first;
  }
}
