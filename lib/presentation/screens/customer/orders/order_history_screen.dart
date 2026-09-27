import 'package:flutter/material.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/repositories/market_repository.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/empty_state.dart';
import 'package:provider/provider.dart';
import '../../../../application/orders/order_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  static const routeName = '/customer/orders';

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _marketRepository = MarketRepository();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPickupCode(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pickup code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              order.id.replaceAll('HH-', ''),
              style: AppTextStyles.headingLarge.copyWith(letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Text('Show this to the farmer at pickup.', style: AppTextStyles.bodyMuted),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeSlot(Order order) async {
    final market = await _marketRepository.fetchDefault();
    if (!mounted) return;

    final newSlotLabel = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose a new pickup slot', style: AppTextStyles.headingMedium),
                ),
              ),
              ...market.pickupSlots.map(
                (slot) => ListTile(
                  enabled: slot.isAvailable,
                  leading: const Icon(Icons.schedule, color: AppColors.mainGreen),
                  title: Text(slot.label),
                  onTap: () => Navigator.of(context).pop(slot.label),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (newSlotLabel == null || !mounted) return;
    context.read<OrderProvider>().updateSlot(order.id, newSlotLabel);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pickup slot updated to $newSlotLabel')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.mainGreen,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.mainGreen,
          labelStyle: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Active'), Tab(text: 'Past orders')],
        ),
      ),
      body: orders.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.mainGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _OrderList(
                  orders: orders.active,
                  onViewCode: _showPickupCode,
                  onChangeSlot: _changeSlot,
                  emptyLabel: 'No active orders',
                ),
                _OrderList(
                  orders: orders.past,
                  onViewCode: _showPickupCode,
                  onChangeSlot: _changeSlot,
                  emptyLabel: 'No past orders yet',
                ),
              ],
            ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.onViewCode,
    required this.onChangeSlot,
    required this.emptyLabel,
  });

  final List<Order> orders;
  final ValueChanged<Order> onViewCode;
  final ValueChanged<Order> onChangeSlot;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(icon: Icons.receipt_long_outlined, title: emptyLabel);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = orders[index];
        return order.currentStep < Order.steps.length - 1 || index == 0
            ? _ActiveOrderCard(
                order: order,
                onViewCode: () => onViewCode(order),
                onChangeSlot: () => onChangeSlot(order),
              )
            : _CompactOrderRow(order: order);
      },
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.order,
    required this.onViewCode,
    required this.onChangeSlot,
  });

  final Order order;
  final VoidCallback onViewCode;
  final VoidCallback onChangeSlot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.title, style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.wheatGold.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusBadge,
                  style: AppTextStyles.caption.copyWith(color: AppColors.earthySoil, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(order.marketName, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 14),
          _ProgressSteps(currentStep: order.currentStep),
          const SizedBox(height: 14),
          Text(order.scheduledLabel, style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(order.itemsSummary, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onViewCode,
                  child: const Text('View pickup code'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onChangeSlot,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
                  child: const Text('Change slot'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(Order.steps.length, (index) {
        final isDone = index <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(left: index == 0 ? 0 : 4, right: index == Order.steps.length - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.mainGreen : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CompactOrderRow extends StatelessWidget {
  const _CompactOrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.softGreen, shape: BoxShape.circle),
            child: const Icon(Icons.shopping_basket_outlined, color: AppColors.mainGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.title, style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600)),
                Text(order.scheduledLabel, style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              ],
            ),
          ),
          Text(order.itemsSummary, style: AppTextStyles.caption),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}