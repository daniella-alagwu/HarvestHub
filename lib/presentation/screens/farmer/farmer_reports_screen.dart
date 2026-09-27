import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/colors/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/farmer_dashboard_repository.dart';

class FarmerReportsScreen extends StatefulWidget {
  const FarmerReportsScreen({super.key, this.onBackToOverview});

  final VoidCallback? onBackToOverview;

  @override
  State<FarmerReportsScreen> createState() => _FarmerReportsScreenState();
}

class _FarmerReportsScreenState extends State<FarmerReportsScreen> {
  final _repo = FarmerDashboardRepository();
  int _periodIndex = 0;
  final _periods = const ['Daily', 'Weekly', 'Monthly'];

  bool _isInSelectedPeriod(DateTime? createdAt) {
    if (createdAt == null) return false;
    final now = DateTime.now();

    switch (_periodIndex) {
      case 0: // Daily — same calendar day
        return createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;
      case 1: // Weekly — last 7 days
        final weekAgo = now.subtract(const Duration(days: 7));
        return createdAt.isAfter(weekAgo);
      case 2: // Monthly — same calendar month
        return createdAt.year == now.year && createdAt.month == now.month;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmerId = FirebaseAuth.instance.currentUser?.uid;

    if (farmerId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Center(child: Text('Not signed in.', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodTabs(),
              const SizedBox(height: 20),
              StreamBuilder<List<OrderModel>>(
                stream: _repo.streamOrders(farmerId),
                builder: (context, snap) {
                  final allOrders = snap.data ?? [];
                  final periodOrders = allOrders.where((o) => _isInSelectedPeriod(o.createdAt)).toList();

                  final totalOrders = periodOrders.length;
                  final revenue = periodOrders.fold<double>(0, (sum, o) => sum + o.totalPrice);
                  final productsSold = periodOrders.fold<int>(0, (sum, o) => sum + o.itemQuantity.toInt());
                  final avgOrderValue = totalOrders == 0 ? 0.0 : revenue / totalOrders;

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.7,
                    children: [
                      _ReportTile(label: 'Total orders', value: '$totalOrders'),
                      _ReportTile(label: 'Revenue', value: '\$${revenue.toStringAsFixed(2)}'),
                      _ReportTile(label: 'Products sold', value: '$productsSold'),
                      _ReportTile(label: 'Avg. order value', value: '\$${avgOrderValue.toStringAsFixed(2)}'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.mainGreen,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: widget.onBackToOverview,
      ),
      title: const Text('Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildPeriodTabs() {
    return Row(
      children: List.generate(_periods.length, (i) {
        final isActive = i == _periodIndex;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _periodIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.mainGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _periods[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}