import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../application/cart/cart_provider.dart';
import '../../../../application/orders/order_provider.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/primary_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _submitting = false;

  Future<void> _placeOrder(CartProvider cart) async {
    if (!cart.canCheckout || _submitting) return;
    setState(() => _submitting = true);

    final groupedOrders = <Map<String, dynamic>>[];
    var feeRemaining = cart.fee;
    for (final entry in cart.itemsByFarmer.entries) {
      final rows = <String, dynamic>{};
      var subtotal = 0.0;
      for (final item in entry.value) {
        rows[item.product.id] = {
          'item_name': item.product.itemName,
          'quantity': item.quantity,
          'unit': item.product.unit,
          'price_per_unit': item.product.pricePerUnit,
        };
        subtotal += item.lineTotal;
      }
      final feeForOrder = feeRemaining;
      feeRemaining = 0;
      groupedOrders.add({
        'farmer_id': entry.key,
        'items_json': rows,
        'total_price': subtotal + feeForOrder,
      });
    }

    try {
      await context.read<OrderProvider>().placeOrders(
            orders: groupedOrders,
            marketName: cart.pickupMarket!.marketName,
            pickupSlotTime: _pickupDateTime(cart.pickupSlot!.label),
          );
      final orderTotal = cart.total;
      cart.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order placed for ₦${orderTotal.toStringAsFixed(2)}. Demo payment only; no charge was made.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place order: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  DateTime? _pickupDateTime(String label) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(label);
    if (match == null) return null;
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Order summary', style: AppTextStyles.headingMedium),
                        const SizedBox(height: 8),
                        _CardSection(
                          child: Column(
                            children: [
                              ...cart.itemList.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.product.itemName} × ${item.quantityLabel}',
                                            style: AppTextStyles.bodyRegular,
                                          ),
                                        ),
                                        Text('₦${item.lineTotal.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  )),
                              const Divider(height: 20),
                              _PriceRow(label: 'Subtotal', value: cart.subtotal),
                              const SizedBox(height: 7),
                              _PriceRow(label: 'Market fee', value: cart.fee),
                              const Divider(height: 20),
                              _PriceRow(label: 'Total', value: cart.total, bold: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Pickup', style: AppTextStyles.headingMedium),
                        const SizedBox(height: 8),
                        _CardSection(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.mainGreen),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cart.pickupMarket?.marketName ?? 'No market selected',
                                        style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600)),
                                    Text(cart.pickupSlot?.label ?? 'No pickup slot selected',
                                        style: AppTextStyles.bodyMuted),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Payment', style: AppTextStyles.headingMedium),
                        const SizedBox(height: 8),
                        _CardSection(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.credit_card_rounded, color: AppColors.mainGreen, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Demo Visa  •••• 4242',
                                        style: AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('Sample payment details for preview only.', style: AppTextStyles.bodyMuted),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Demo payment only. No card is charged and no real payment details are collected.',
                                      style: TextStyle(color: AppColors.deepGreen, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.verified_outlined, color: AppColors.mainGreen),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: PrimaryButton(
                      label: 'Place order · ₦${cart.total.toStringAsFixed(2)}',
                      icon: Icons.shopping_bag_outlined,
                      isLoading: _submitting,
                      onPressed: cart.canCheckout ? () => _placeOrder(cart) : null,
                      backgroundColor: cart.canCheckout
                          ? AppColors.mainGreen
                          : AppColors.disabledGreen,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.bold = false});

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyRegular.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('₦${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
