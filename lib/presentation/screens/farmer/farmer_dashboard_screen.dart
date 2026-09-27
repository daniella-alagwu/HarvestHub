import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/colors/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/farmer_dashboard_repository.dart';
import 'farmer_notifications_screen.dart';

class FarmerDashboardScreen extends StatefulWidget {
  static const String routeName = '/farmer-dashboard';
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final _repo = FarmerDashboardRepository();
  String? _farmerId;
  String _farmerName = '';
  String _farmName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final profile = await _repo.getFarmerProfile(uid);
    setState(() {
      _farmerId = uid;
      _farmerName = profile['name'] ?? '';
      _farmName = profile['farmName'] ?? '';
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':
      case 'Completed':
      case 'Ready for Pickup':
        return AppColors.success;
      case 'Pending':
        return AppColors.wheatGold;
      case 'Cancelled':
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_farmerId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('No farmer profile found.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<ProductModel>>(
          stream: _repo.streamProducts(_farmerId!),
          builder: (context, productSnap) {
            final products = productSnap.data ?? [];
            return StreamBuilder<List<OrderModel>>(
              stream: _repo.streamOrders(_farmerId!),
              builder: (context, orderSnap) {
                final orders = orderSnap.data ?? [];

                final lowStock = products.where((p) => p.stockQty <= 5).toList();
                final pendingOrders = orders.where((o) => o.status == 'Pending').toList();

                _repo.syncNotifications(
                  farmerId: _farmerId!,
                  lowStockProducts: lowStock,
                  pendingOrders: pendingOrders,
                );

                return StreamBuilder<List<NotificationModel>>(
                  stream: _repo.streamNotifications(_farmerId!),
                  builder: (context, notifSnap) {
                    final unreadCount = (notifSnap.data ?? []).where((n) => !n.isRead).length;
                    return _buildContent(products, orders, lowStock, unreadCount);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    List<ProductModel> products,
    List<OrderModel> orders,
    List<ProductModel> lowStock,
    int unreadCount,
  ) {
    final sales = orders.fold<double>(0, (sum, o) => sum + o.total);
    final avgOrder = orders.isEmpty ? 0.0 : sales / orders.length;
    final recentOrders = orders.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(unreadCount),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _StatTile(label: 'Sales', value: '\$${sales.toStringAsFixed(2)}'),
              _StatTile(label: 'Orders', value: '${orders.length}'),
              _StatTile(label: 'Avg. order', value: '\$${avgOrder.toStringAsFixed(2)}'),
              _StatTile(label: 'Products', value: '${products.length}'),
            ],
          ),
          const SizedBox(height: 16),
          if (lowStock.isNotEmpty) _buildLowStockBanner(lowStock),
          const SizedBox(height: 20),
          const Text('Recent orders',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          if (recentOrders.isEmpty)
            const Text('No orders yet.', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
          else
            ...recentOrders.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildOrderRow(o),
                )),
        ],
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, $_farmerName',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(_farmName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mainGreen)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            if (_farmerId == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => FarmerNotificationsScreen(farmerId: _farmerId!)),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.mainGreen, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockBanner(List<ProductModel> lowStock) {
    final names = lowStock.map((p) => p.itemName).join(', ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.wheatGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.wheatGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.wheatGold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Low-stock attention',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(names, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(OrderModel order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('#${order.orderId.substring(0, order.orderId.length.clamp(0, 6))}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(order.status, style: TextStyle(fontSize: 12, color: _statusColor(order.status))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
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
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}