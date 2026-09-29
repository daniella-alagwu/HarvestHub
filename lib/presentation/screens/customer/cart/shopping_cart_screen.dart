import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../application/cart/cart_provider.dart';
import '../../../../application/orders/order_provider.dart';

import '../../../../data/models/cart_item_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/market_model.dart';
import '../../../../data/repositories/market_repository.dart';
import '../checkout/checkout_screen.dart';

import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';

import '../../../widgets/empty_state.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/product_image.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({
    super.key,
  });

  static const routeName = '/customer/cart';

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  final _marketRepository = MarketRepository();

  List<Market> _markets = [];

  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  Future<void> _loadMarkets() async {
    final markets = await _marketRepository.fetchAll();

    if (!mounted) {
      return;
    }

    setState(() => _markets = markets);

    final cart = context.read<CartProvider>();

    if (cart.pickupMarket == null &&
        markets.isNotEmpty &&
        cart.itemList.isNotEmpty) {
      cart.setPickupMarket(
        markets.first,
      );
    }
  }

  void _pickMarket(
    CartProvider cart,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _markets
                .map(
                  (market) => ListTile(
                    leading: const Icon(
                      Icons.storefront,
                      color: AppColors.mainGreen,
                    ),
                    title: Text(
                      market.marketName,
                      style: AppTextStyles.bodyRegular.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      market.address,
                      style: AppTextStyles.bodyMuted,
                    ),
                    onTap: () {
                      cart.setPickupMarket(
                        market,
                      );

                      Navigator.of(
                        context,
                      ).pop();
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _confirmOrder(
    CartProvider cart,
  ) async {
    final total = cart.total;

    final groups = cart.itemsByFarmer;

    final pickupTime = _parsePickupTime(
      cart.pickupSlot?.label,
    );


    try {
      for (final entry in groups.entries) {
        final items = entry.value;

        final itemsJson = <String, dynamic>{
          for (final item in items)
            item.product.id: {
              'item_name': item.product.name,
              'quantity': item.quantity,
              'unit': item.product.unit,
              'price_per_unit': item.product.pricePerUnit,
            },
        };

        final subtotal = items.fold<double>(
          0,
          (
            sum,
            item,
          ) =>
              sum + item.lineTotal,
        );


        await context.read<OrderProvider>().placeOrder(
              farmerId: entry.key,
              marketName: cart.pickupMarket?.marketName ?? '',
              pickupSlotTime: pickupTime,
              itemsJson: itemsJson,
              total: subtotal,
            );
      }

      cart.clear();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Order confirmed • '
            '₦${total.toStringAsFixed(2)} '
            '— see you at pickup!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Could not place order: $e',
          ),
        ),
      );
    }
  }

  DateTime? _parsePickupTime(
    String? label,
  ) {
    if (label == null || label.trim().isEmpty) {
      return null;
    }

    final match = RegExp(
      r'(\d{1,2}):(\d{2})',
    ).firstMatch(label);

    if (match == null) {
      return null;
    }

    final now = DateTime.now();

    final hour = int.tryParse(
          match.group(1)!,
        ) ??
        now.hour;

    final minute = int.tryParse(
          match.group(2)!,
        ) ??
        0;

    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your cart'),
      ),
      body: cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add fresh produce from a farmer to get started.',
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        12,
                      ),
                      children: [
                        ...cart.itemList.map(
                          (item) => _CartItemRow(
                            item: item,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          'Pickup details',
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        _PickupDetailsCard(
                          cart: cart,
                          onChangeMarket: () => _pickMarket(
                            cart,
                          ),
                        ),
                        if (cart.pickupMarket != null) ...[
                          const SizedBox(
                            height: 14,
                          ),
                          Text(
                            'Choose a pickup slot',
                            style: AppTextStyles.bodyRegular.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: cart.pickupMarket!.pickupSlots.map(
                              (slot) {
                                final isSelected =
                                    cart.pickupSlot?.label == slot.label;

                                return ChoiceChip(
                                  label: Text(
                                    slot.label,
                                  ),
                                  selected: isSelected,
                                  onSelected: slot.isAvailable
                                      ? (_) => cart.setPickupSlot(
                                            slot,
                                          )
                                      : null,
                                  selectedColor: AppColors.mainGreen,
                                  labelStyle: AppTextStyles.caption.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                  backgroundColor: AppColors.surface,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ],
                        const SizedBox(
                          height: 20,
                        ),
                        _TotalsCard(
                          cart: cart,
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),
                      child: PrimaryButton(
                        label: 'Confirm order • ${Product.formatNaira(cart.total)}',
                        onPressed: cart.canCheckout
                            ? () => _confirmOrder(
                                  cart,
                                )
                            : null,
                        backgroundColor: cart.canCheckout
                            ? AppColors.mainGreen
                            : AppColors.disabledGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
  });

  final CartItem item;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: ProductImage(
              imageUrl: item.product.imageUrl,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.product.farmerName,
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  item.quantityLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.deepGreen,
                  ),
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                Product.formatNaira(item.lineTotal),
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.deepGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () => context.read<CartProvider>().removeItem(
                  item.product.id,
                ),
          ),
        ],
      ),
    );
  }
}

class _PickupDetailsCard extends StatelessWidget {
  const _PickupDetailsCard({
    required this.cart,
    required this.onChangeMarket,
  });

  final CartProvider cart;
  final VoidCallback onChangeMarket;

  @override
  Widget build(
    BuildContext context,
  ) {
    final market = cart.pickupMarket;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.mainGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup market',
                  style: AppTextStyles.caption,
                ),
                Text(
                  market?.marketName ?? 'Choose a market',
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (market != null)
                  Text(
                    market.address,
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeMarket,
            child: Text(
              'Change',
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.mainGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.cart,
  });

  final CartProvider cart;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _TotalsRow(
            label: 'Subtotal',
            value: cart.subtotal,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Divider(
              height: 1,
              color: AppColors.border,
            ),
          ),
          _TotalsRow(
            label: 'Total',
            value: cart.total,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final bool isTotal;

  @override
  Widget build(
    BuildContext context,
  ) {
    final style = isTotal
        ? AppTextStyles.bodyRegular.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          )
        : AppTextStyles.bodyRegular;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style,
        ),
        Text(
          Product.formatNaira(value),
          style: style,
        ),
      ],
    );
  }
}
