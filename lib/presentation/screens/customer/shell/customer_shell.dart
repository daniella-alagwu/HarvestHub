import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../application/cart/cart_provider.dart';
import '../../../../application/orders/order_provider.dart';

import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';

import '../assistant/ai_assistant_screen.dart';
import '../cart/shopping_cart_screen.dart';
import '../home/product_catalog_screen.dart';
import '../orders/order_history_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../search/search_screen.dart';

class CustomerShell
    extends StatefulWidget {
  const CustomerShell({
    super.key,
  });

  static const routeName =
      '/customer';

  @override
  State<CustomerShell>
      createState() =>
          _CustomerShellState();
}

class _CustomerShellState
    extends State<CustomerShell> {
  int _index = 0;
  Offset _mascotOffset = Offset.zero;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      final uid =
          FirebaseAuth.instance
              .currentUser
              ?.uid;

      if (uid != null) {
        context
            .read<OrderProvider>()
            .watchOrders(uid);
      }
    });
  }

  void _goToTab(
    int index,
  ) {
    setState(() =>
        _index = index);
  }
    void _openAiAssistantModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Expanded(child: AiAssistantScreen()),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final cartCount =
        context.watch<CartProvider>()
            .itemCount;

    final tabs = [
      ProductCatalogScreen(
        onOpenSearch: () =>
            _goToTab(1),
      ),
      const SearchScreen(),
      const OrderHistoryScreen(),
      const ShoppingCartScreen(),
      CustomerProfileScreen(
        onOpenOrders: () => _goToTab(2),
        onBackToHome: () => _goToTab(0),
      ),
    ];

    return Scaffold(
            body: Stack(
        children: [
          IndexedStack(index: _index, children: tabs),
          if (_index == 0)
            Positioned(
              bottom: 24,
              right: 16,
              child: Transform.translate(
                offset: _mascotOffset,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() => _mascotOffset += details.delta);
                  },
                  onTap: () => _openAiAssistantModal(context),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(6),
                          ),
                          border: Border.all(
                              color: AppColors.autumnRust, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(4),
                          ),
                          child: Image.asset(
                            'assets/images/mascot/flora_avatar_160.png',
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 54,
                              height: 54,
                              color: AppColors.softGreen,
                              child: const Icon(Icons.support_agent,
                                  color: AppColors.mainGreen, size: 30),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.wheatGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          NavigationBarTheme(
        data:
            NavigationBarThemeData(
          labelTextStyle:
              WidgetStateProperty
                  .resolveWith(
            (states) =>
                AppTextStyles.caption
                    .copyWith(
              color: states.contains(
                WidgetState.selected,
              )
                  ? AppColors
                      .mainGreen
                  : AppColors
                      .textSecondary,
              fontWeight: states.contains(
                WidgetState.selected,
              )
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
          indicatorColor:
              AppColors.softGreen,
        ),
        child: NavigationBar(
          backgroundColor:
              AppColors.surface,
          selectedIndex: _index,
          onDestinationSelected:
              (value) => setState(
            () =>
                _index = value,
          ),
          destinations: [
            const NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
              ),
              selectedIcon:
                  Icon(
                Icons.home,
                color:
                    AppColors.mainGreen,
              ),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(
                Icons.search_outlined,
              ),
              selectedIcon:
                  Icon(
                Icons.search,
                color:
                    AppColors.mainGreen,
              ),
              label: 'Search',
            ),
            const NavigationDestination(
              icon: Icon(
                Icons
                    .receipt_long_outlined,
              ),
              selectedIcon:
                  Icon(
                Icons.receipt_long,
                color:
                    AppColors.mainGreen,
              ),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: cartCount > 0
                  ? Badge(
                      label:
                          Text(
                        '$cartCount',
                      ),
                      child: const Icon(
                        Icons
                            .shopping_bag_outlined,
                      ),
                    )
                  : const Icon(
                      Icons
                          .shopping_bag_outlined,
                    ),
              selectedIcon:
                  const Icon(
                Icons.shopping_bag,
                color:
                    AppColors.mainGreen,
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(
                Icons.person_outline,
              ),
              selectedIcon:
                  Icon(
                Icons.person,
                color:
                    AppColors.mainGreen,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}