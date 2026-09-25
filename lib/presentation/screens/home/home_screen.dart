import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import '../customer/assistant/ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.role});

  final String? role;
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Position offset for the draggable mascot bubble
  Offset _mascotOffset = Offset.zero;

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
                // Drag handle for bottom sheet
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
  Widget build(BuildContext context) {
    final userName = widget.role == 'farmer' ? 'Farmer' : 'Maya';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.mainGreen, size: 18),
            const SizedBox(width: 4),
            Text(
              'Pickup near Lagos, NG',
              style: AppTextStyles.caption.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Scrollable Page Content (Original Green Theme)
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Dynamic Greeting
                Text(
                  'Good morning, $userName',
                  style: AppTextStyles.headingLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search fresh produce',
                    prefixIcon: const Icon(Icons.search, color: Colors.black45),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Category Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _CategoryChip(icon: Icons.eco_outlined, label: 'Vegetables'),
                    _CategoryChip(icon: Icons.apple_outlined, label: 'Fruit'),
                    _CategoryChip(icon: Icons.bakery_dining_outlined, label: 'Bakery'),
                    _CategoryChip(icon: Icons.water_drop_outlined, label: 'Dairy'),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Nearby Farmers Header & Card Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby farmers',
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 20, color: Colors.black87),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _FarmCard(
                        farmName: 'Maple Row Farm',
                        subtext: '2.4 mi • Saturday Market\nOrganic produce • 18 products',
                      ),
                      SizedBox(width: 12),
                      _FarmCard(
                        farmName: 'Green Valley Acres',
                        subtext: '1.8 mi • Daily Pickup\nFresh dairy & poultry',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Fresh Today Section
                Text(
                  'Fresh today',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(
                      child: _ProductCard(
                        title: 'Heirloom Tomatoes',
                        farm: 'Maple Row Farm',
                        price: '\$4.80 / lb',
                        icon: Icons.grass,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _ProductCard(
                        title: 'Garden Kale',
                        farm: 'Maple Row Farm',
                        price: '\$3.25 / bunch',
                        icon: Icons.eco,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 90), // Bottom padding for mascot
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // DRAGGABLE MASCOT CHAT BUBBLE (UNTOUCHED)
          // -------------------------------------------------------------------
          Positioned(
            bottom: 24,
            right: 16,
            child: Transform.translate(
              offset: _mascotOffset,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _mascotOffset += details.delta;
                  });
                },
                onTap: () => _openAiAssistantModal(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Outer Chat-Bubble Container with Autumn Rust Border
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(6), // Chat bubble notch
                        ),
                        border: Border.all(color: AppColors.autumnRust, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
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
                            child: const Icon(
                              Icons.support_agent,
                              color: AppColors.mainGreen,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top-Right Wheat Gold Chat Badge Indicator
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.wheatGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.mainGreen,
        unselectedItemColor: Colors.black45,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER COMPONENTS
// -----------------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.softGreen.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.mainGreen, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _FarmCard extends StatelessWidget {
  final String farmName;
  final String subtext;

  const _FarmCard({required this.farmName, required this.subtext});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mainGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            farmName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final String farm;
  final String price;
  final IconData icon;

  const _ProductCard({
    required this.title,
    required this.farm,
    required this.price,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.softGreen.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(icon, size: 40, color: AppColors.mainGreen),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  farm,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const Icon(Icons.add_circle_outline, color: AppColors.mainGreen, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}