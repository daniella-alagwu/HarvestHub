import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/models/order_model.dart';
import '../../../data/repositories/farmer_dashboard_repository.dart';

import '../../theme/colors/app_colors.dart';

class FarmerOrdersScreen
    extends StatefulWidget {
  const FarmerOrdersScreen({
    super.key,
    this.onBackToOverview,
  });

  final VoidCallback?
      onBackToOverview;

  @override
  State<FarmerOrdersScreen>
      createState() =>
          _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState
    extends State<FarmerOrdersScreen> {
  final _repo =
      FarmerDashboardRepository();

  int _tabIndex = 0;

  final _tabs = const [
    'Active',
    'Past orders',
  ];

  static const _activeStatuses = [
    'Pending',
    'Confirmed',
    'Ready for Pickup',
    'Packing',
  ];

  static const _pastStatuses = [
    'Rejected',
    'Completed',
    'Cancelled',
  ];

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'Ready for Pickup':
        return AppColors.success;

      case 'Confirmed':
        return AppColors.mainGreen;

      case 'Packing':
        return AppColors.wheatGold;

      case 'Completed':
        return AppColors.textSecondary;

      case 'Rejected':
        return AppColors.error;

      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final farmerId =
        FirebaseAuth.instance
            .currentUser
            ?.uid;

    if (farmerId == null) {
      return Scaffold(
        backgroundColor:
            AppColors.background,
        appBar: _buildAppBar(),
        body: const Center(
          child: Text(
            'Not signed in.',
            style: TextStyle(
              color: AppColors
                  .textSecondary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildTabs(),
              const SizedBox(
                height: 16,
              ),
              Expanded(
                child:
                    StreamBuilder<
                        List<OrderModel>>(
                  stream:
                      _repo.streamOrders(
                    farmerId,
                  ),
                  builder:
                      (context, snap) {
                    final allOrders =
                        snap.data ?? [];

                    final targetStatuses =
                        _tabIndex == 0
                            ? _activeStatuses
                            : _pastStatuses;

                    final filtered =
                        allOrders
                            .where(
                              (order) =>
                                  targetStatuses
                                      .contains(
                                order.status,
                              ),
                            )
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          _tabIndex == 0
                              ? 'No active orders yet.'
                              : 'No past orders yet.',
                          style: const TextStyle(
                            color: AppColors
                                .textMuted,
                          ),
                        ),
                      );
                    }

                    return ListView
                        .separated(
                      itemCount:
                          filtered.length,
                      separatorBuilder:
                          (_, __) =>
                              const SizedBox(
                        height: 10,
                      ),
                      itemBuilder:
                          (context, i) =>
                              _buildOrderCard(
                        filtered[i],
                      ),
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

  PreferredSizeWidget
      _buildAppBar() {
    return AppBar(
      backgroundColor:
          AppColors.mainGreen,
      elevation: 0,
      automaticallyImplyLeading:
          false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
        ),
        onPressed:
            widget.onBackToOverview,
      ),
      title: const Text(
        'Orders',
        style: TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      iconTheme:
          const IconThemeData(
        color: Colors.white,
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: List.generate(
        _tabs.length,
        (i) {
          final isActive =
              i == _tabIndex;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child:
                GestureDetector(
              onTap: () => setState(
                () =>
                    _tabIndex = i,
              ),
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration:
                    BoxDecoration(
                  color: isActive
                      ? AppColors
                          .mainGreen
                      : Colors
                          .transparent,
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : AppColors
                            .textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _nextStatuses(
    String current,
  ) {
    switch (current) {
      case 'Pending':
        return const [
          'Confirmed',
          'Cancelled',
        ];

      case 'Confirmed':
      case 'Packing':
        return const [
          'Ready for Pickup',
          'Cancelled',
        ];

      case 'Ready for Pickup':
        return const [
          'Completed',
        ];

      default:
        return const [];
    }
  }

  Future<void> _setStatus(
    String orderId,
    String status,
  ) async {
    try {
      await _repo.updateOrderStatus(
        orderId,
        status,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Order updated to $status',
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
            'Could not update order: $e',
          ),
        ),
      );
    }
  }

  Widget _buildOrderCard(
    OrderModel order,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            AppColors.surface,
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Text(
                '#${order.orderId.substring(
                  0,
                  order.orderId.length
                      .clamp(0, 6),
                )}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                  color: AppColors
                      .textPrimary,
                ),
              ),
              Text(
                order.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      _statusColor(
                    order.status,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            '${order.itemQuantity} item(s)',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors
                  .textSecondary,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            '\$${order.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color: AppColors
                  .textPrimary,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          if (![
            'Completed',
            'Cancelled',
            'Rejected',
          ].contains(
            order.status,
          ))
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _nextStatuses(
                order.status,
              ).map(
                (status) {
                  return OutlinedButton(
                    onPressed: () =>
                        _setStatus(
                      order.id,
                      status,
                    ),
                    child:
                        Text(status),
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }
}