import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/greeting.dart';
import '../../../data/models/farmer_account.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/farmer_dashboard_repository.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import 'farmer_add_product_screen.dart';
import 'farmer_notifications_screen.dart';

class FarmerDashboardScreen extends StatefulWidget {
  static const String routeName = '/farmer-dashboard';

  const FarmerDashboardScreen({
    super.key,
    this.onOpenProfile,
    this.onOpenInventory,
    this.onOpenOrders,
    this.onOpenReports,
  });

  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenInventory;
  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenReports;

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final _repo = FarmerDashboardRepository();

  String? _farmerId;
  Stream<FarmerAccount>? _accountStream;
  Stream<List<ProductModel>>? _productsStream;
  Stream<List<OrderModel>>? _ordersStream;
  Stream<List<NotificationModel>>? _notificationsStream;

  String _lastSyncKey = '';

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _farmerId = uid;
      _accountStream = _repo.watchFarmerAccount(uid);
      _productsStream = _repo.streamProducts(uid);
      _ordersStream = _repo.streamOrders(uid);
      _notificationsStream = _repo.streamNotifications(uid);
    }
  }

  static bool _isCounted(OrderModel o) {
    final s = o.status.trim().toLowerCase();
    return s != 'cancelled' && s != 'rejected';
  }

  static String _naira(double value) {
    final fixed = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '₦$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
  }

  static String _ago(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'confirmed':
      case 'completed':
      case 'picked up':
      case 'ready for pickup':
      case 'ready':
        return AppColors.success;
      case 'pending':
      case 'placed':
        return AppColors.wheatGold;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'confirmed':
      case 'packed':
        return Icons.inventory_2_outlined;
      case 'ready for pickup':
      case 'ready':
        return Icons.shopping_bag_outlined;
      case 'completed':
      case 'picked up':
        return Icons.check_circle_outline;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  void _maybeSyncNotifications(
    List<ProductModel> products,
    List<OrderModel> pending,
  ) {
    final farmerId = _farmerId;
    if (farmerId == null) return;

    int bucket(int qty) => qty <= 0
        ? 0
        : qty <= 5
            ? 5
            : qty <= 10
                ? 10
                : 99;

    final key = '${products.map((p) => '${p.productId}:${bucket(p.stockQty)}').join(',')}'
        '|${pending.map((o) => o.orderId).join(',')}';
    if (key == _lastSyncKey) return;
    _lastSyncKey = key;

    _repo
        .syncNotifications(
          farmerId: farmerId,
          allProducts: products,
          pendingOrders: pending,
        )
        .catchError((_) {});
  }

  void _openNotifications() {
    final id = _farmerId;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FarmerNotificationsScreen(farmerId: id),
      ),
    );
  }

  void _openAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FarmerAddProductScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_farmerId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('No farmer profile found.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<FarmerAccount>(
        stream: _accountStream,
        builder: (context, accountSnap) {
          final account = accountSnap.data;
          return StreamBuilder<List<ProductModel>>(
            stream: _productsStream,
            builder: (context, productSnap) {
              final products = productSnap.data ?? const <ProductModel>[];
              return StreamBuilder<List<OrderModel>>(
                stream: _ordersStream,
                builder: (context, orderSnap) {
                  final orders = [...(orderSnap.data ?? const <OrderModel>[])]
                    ..sort((a, b) {
                      final ad = a.createdAt;
                      final bd = b.createdAt;
                      if (ad == null && bd == null) return 0;
                      if (ad == null) return 1;
                      if (bd == null) return -1;
                      return bd.compareTo(ad);
                    });

                  final pending = orders
                      .where((o) => o.status.trim().toLowerCase() == 'pending')
                      .toList();

                  if (productSnap.hasData && orderSnap.hasData) {
                    _maybeSyncNotifications(products, pending);
                  }

                  return StreamBuilder<List<NotificationModel>>(
                    stream: _notificationsStream,
                    builder: (context, notifSnap) {
                      final unread =
                          (notifSnap.data ?? const <NotificationModel>[])
                              .where((n) => !n.isRead)
                              .length;

                      final loading =
                          !productSnap.hasData || !orderSnap.hasData;

                      return _buildContent(
                        account: account,
                        products: products,
                        orders: orders,
                        pending: pending,
                        unread: unread,
                        loading: loading,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }

  Widget _buildContent({
    required FarmerAccount? account,
    required List<ProductModel> products,
    required List<OrderModel> orders,
    required List<OrderModel> pending,
    required int unread,
    required bool loading,
  }) {
    final counted = orders.where(_isCounted).toList();
    final sales = counted.fold<double>(0, (sum, o) => sum + o.totalPrice);
    final avgOrder = counted.isEmpty ? 0.0 : sales / counted.length;
    final lowStock = products.where((p) => p.stockQty <= 5).toList();
    final recentOrders = orders.take(5).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroHeader(
            account: account,
            greeting: timeBasedGreeting(),
            unread: unread,
            sales: sales,
            avgOrderLabel: _naira(avgOrder),
            orderCount: counted.length,
            pendingCount: pending.length,
            productCount: products.length,
            loading: loading,
            formatNaira: _naira,
            onOpenProfile: widget.onOpenProfile,
            onOpenNotifications: _openNotifications,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuickActions(
                  onAddProduct: _openAddProduct,
                  onInventory: widget.onOpenInventory,
                  onOrders: widget.onOpenOrders,
                  onReports: widget.onOpenReports,
                ),
                const SizedBox(height: 22),
                _AttentionSection(
                  pendingCount: pending.length,
                  lowStock: lowStock,
                  loading: loading,
                  onReviewOrders: widget.onOpenOrders,
                  onOpenInventory: widget.onOpenInventory,
                ),
                const SizedBox(height: 22),
                _WeeklySalesCard(
                  orders: counted,
                  formatNaira: _naira,
                  onTap: widget.onOpenReports,
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                  title: 'Recent orders',
                  actionLabel: orders.length > 5 ? 'View all' : null,
                  onAction: widget.onOpenOrders,
                ),
                const SizedBox(height: 10),
                if (recentOrders.isEmpty)
                  const _EmptyOrders()
                else
                  ...recentOrders.map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OrderTile(
                        order: o,
                        color: _statusColor(o.status),
                        icon: _statusIcon(o.status),
                        priceLabel: _naira(o.totalPrice),
                        ago: _ago(o.createdAt),
                        onTap: widget.onOpenOrders,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.account,
    required this.greeting,
    required this.unread,
    required this.sales,
    required this.avgOrderLabel,
    required this.orderCount,
    required this.pendingCount,
    required this.productCount,
    required this.loading,
    required this.formatNaira,
    required this.onOpenProfile,
    required this.onOpenNotifications,
  });

  final FarmerAccount? account;
  final String greeting;
  final int unread;
  final double sales;
  final String avgOrderLabel;
  final int orderCount;
  final int pendingCount;
  final int productCount;
  final bool loading;
  final String Function(double) formatNaira;
  final VoidCallback? onOpenProfile;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final firstName = account?.firstName ?? '';
    final farmName = account?.farmName.trim() ?? '';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.deepGreen, AppColors.mainGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.wheatGold.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: 22,
              bottom: 96,
              child: Icon(
                Icons.eco_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onOpenProfile,
                        child: _Avatar(account: account),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName.isEmpty
                                  ? greeting
                                  : '$greeting, $firstName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headingMedium
                                  .copyWith(color: Colors.white, fontSize: 17),
                            ),
                            if (farmName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.storefront_outlined,
                                      size: 13, color: AppColors.wheatGold),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      farmName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMuted.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _BellButton(unread: unread, onTap: onOpenNotifications),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Total sales',
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: sales),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatNaira(value),
                        style: AppTextStyles.headingLarge.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loading
                        ? 'Loading your numbers…'
                        : orderCount == 0
                            ? 'Your first sale will show up here'
                            : 'from $orderCount ${orderCount == 1 ? 'order' : 'orders'} · avg. $avgOrderLabel',
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroChip(
                          icon: Icons.receipt_long_outlined,
                          value: '$orderCount',
                          label: 'Orders',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroChip(
                          icon: Icons.hourglass_top_rounded,
                          value: '$pendingCount',
                          label: 'Pending',
                          highlight: pendingCount > 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroChip(
                          icon: Icons.inventory_2_outlined,
                          value: '$productCount',
                          label: 'Products',
                        ),
                      ),
                    ],
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.account});

  final FarmerAccount? account;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = account?.hasAvatar ?? false;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.wheatGold, width: 2.5),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(account!.avatarUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasPhoto
          ? null
          : (account == null
              ? const Icon(Icons.person_outline, color: AppColors.deepGreen)
              : Text(
                  account!.initials,
                  style: AppTextStyles.headingMedium
                      .copyWith(color: AppColors.deepGreen, fontSize: 16),
                )),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 24),
          ),
          if (unread > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                decoration: BoxDecoration(
                  color: AppColors.autumnRust,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.deepGreen, width: 2),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.wheatGold.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.wheatGold.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headingMedium
                .copyWith(color: Colors.white, fontSize: 20),
          ),
          Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddProduct,
    required this.onInventory,
    required this.onOrders,
    required this.onReports,
  });

  final VoidCallback onAddProduct;
  final VoidCallback? onInventory;
  final VoidCallback? onOrders;
  final VoidCallback? onReports;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.add_rounded,
            label: 'Add product',
            color: AppColors.mainGreen,
            onTap: onAddProduct,
          ),
        ),
        Expanded(
          child: _QuickAction(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            color: AppColors.earthySoil,
            onTap: onInventory,
          ),
        ),
        Expanded(
          child: _QuickAction(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            color: AppColors.autumnRust,
            onTap: onOrders,
          ),
        ),
        Expanded(
          child: _QuickAction(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            color: AppColors.deepGreen,
            onTap: onReports,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({
    required this.pendingCount,
    required this.lowStock,
    required this.loading,
    required this.onReviewOrders,
    required this.onOpenInventory,
  });

  final int pendingCount;
  final List<ProductModel> lowStock;
  final bool loading;
  final VoidCallback? onReviewOrders;
  final VoidCallback? onOpenInventory;

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox.shrink();

    final allClear = pendingCount == 0 && lowStock.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Needs your attention'),
        const SizedBox(height: 10),
        if (allClear)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softGreen.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.mainGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.mainGreen, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You\'re all caught up. No pending orders and stock looks healthy.',
                    style: AppTextStyles.bodyRegular
                        .copyWith(color: AppColors.deepGreen, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        if (pendingCount > 0)
          _AttentionCard(
            color: AppColors.autumnRust,
            icon: Icons.notifications_active_outlined,
            title: pendingCount == 1
                ? '1 order is waiting for you'
                : '$pendingCount orders are waiting for you',
            subtitle: 'Confirm them so customers know you\'ve got it.',
            actionLabel: 'Review',
            onTap: onReviewOrders,
          ),
        if (pendingCount > 0 && lowStock.isNotEmpty) const SizedBox(height: 10),
        if (lowStock.isNotEmpty)
          _AttentionCard(
            color: AppColors.wheatGold,
            icon: Icons.warning_amber_rounded,
            title: lowStock.length == 1
                ? '1 product is running low'
                : '${lowStock.length} products are running low',
            subtitle: lowStock.map((p) => p.itemName).take(3).join(', ') +
                (lowStock.length > 3 ? ' +${lowStock.length - 3} more' : ''),
            actionLabel: 'Restock',
            onTap: onOpenInventory,
          ),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyRegular
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              actionLabel,
              style: AppTextStyles.bodyRegular.copyWith(
                color: color == AppColors.wheatGold
                    ? AppColors.earthySoil
                    : color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color == AppColors.wheatGold
                    ? AppColors.earthySoil
                    : color),
          ],
        ),
      ),
    );
  }
}

class _WeeklySalesCard extends StatelessWidget {
  const _WeeklySalesCard({
    required this.orders,
    required this.formatNaira,
    required this.onTap,
  });

  final List<OrderModel> orders;
  final String Function(double) formatNaira;
  final VoidCallback? onTap;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final totals = List<double>.filled(7, 0);

    for (final o in orders) {
      final d = o.createdAt;
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      final index = day.difference(days.first).inDays;
      if (index >= 0 && index < 7) totals[index] += o.totalPrice;
    }

    final weekTotal = totals.fold<double>(0, (a, b) => a + b);
    final maxTotal = totals.fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last 7 days', style: AppTextStyles.headingMedium),
                    const SizedBox(height: 2),
                    Text(
                      weekTotal == 0
                          ? 'No sales yet this week'
                          : '${formatNaira(weekTotal)} in sales',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mainGreen,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Reports'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == 6;
                final fraction =
                    maxTotal == 0 ? 0.0 : (totals[i] / maxTotal).clamp(0.0, 1.0);
                return Expanded(
                  child: _Bar(
                    fraction: fraction,
                    hasValue: totals[i] > 0,
                    isToday: isToday,
                    label: isToday ? 'Today' : _dayNames[days[i].weekday - 1],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.hasValue,
    required this.isToday,
    required this.label,
  });

  final double fraction;
  final bool hasValue;
  final bool isToday;
  final String label;

  @override
  Widget build(BuildContext context) {
    const maxBar = 100.0;
    final target = hasValue ? (10 + fraction * (maxBar - 10)) : 6.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, h, _) => Container(
            width: 22,
            height: h,
            decoration: BoxDecoration(
              color: !hasValue
                  ? AppColors.border
                  : (isToday ? AppColors.autumnRust : AppColors.mainGreen),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10.5,
            color: isToday ? AppColors.autumnRust : AppColors.textSecondary,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.color,
    required this.icon,
    required this.priceLabel,
    required this.ago,
    required this.onTap,
  });

  final OrderModel order;
  final Color color;
  final IconData icon;
  final String priceLabel;
  final String ago;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.title,
                    style: AppTextStyles.bodyRegular
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.itemsSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                  ),
                  if (ago.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(ago, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceLabel,
                  style: AppTextStyles.bodyRegular
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status,
                    style: AppTextStyles.caption.copyWith(
                      color: color == AppColors.wheatGold
                          ? AppColors.earthySoil
                          : color,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.softGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_basket_outlined,
                color: AppColors.mainGreen, size: 28),
          ),
          const SizedBox(height: 12),
          Text('No orders yet', style: AppTextStyles.headingMedium),
          const SizedBox(height: 4),
          Text(
            'Once customers start ordering, they\'ll show up here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.headingMedium)),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mainGreen,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}