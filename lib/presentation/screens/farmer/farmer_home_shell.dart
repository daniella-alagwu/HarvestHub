import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../customer/assistant/ai_assistant_screen.dart';
import 'farmer_dashboard_screen.dart';
import 'farmer_products_screen.dart';
import 'farmer_orders_screen.dart';
import 'farmer_reports_screen.dart';

class FarmerHomeShell extends StatefulWidget {
  const FarmerHomeShell({super.key});

  static const routeName = '/farmer-home';

  @override
  State<FarmerHomeShell> createState() => _FarmerHomeShellState();
}

class _FarmerHomeShellState extends State<FarmerHomeShell> {
  int _index = 0;
  Offset _mascotOffset = Offset.zero;

  void _goToOverview() => setState(() => _index = 0);

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
  Widget build(BuildContext context) {
    final screens = [
      const FarmerDashboardScreen(),
      FarmerProductsScreen(onBackToOverview: _goToOverview),
      FarmerOrdersScreen(onBackToOverview: _goToOverview),
      FarmerReportsScreen(onBackToOverview: _goToOverview),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: screens),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.mainGreen,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
        ],
      ),
    );
  }
}