import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/order_model.dart'
    as order_model;
import '../../data/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({
    OrderRepository? repository,
  }) : _repository =
          repository ?? OrderRepository();

  final OrderRepository _repository;

  List<order_model.Order> _active = [];
  List<order_model.Order> _past = [];

  bool _isLoading = false;

  StreamSubscription<
      List<order_model.Order>>?
      _ordersSubscription;

  List<order_model.Order> get active =>
      List.unmodifiable(_active);

  List<order_model.Order> get past =>
      List.unmodifiable(_past);

  bool get isLoading =>
      _isLoading;

  Future<void> loadOrders(
    String userId,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final activeOrders =
          await _repository.fetchActive(
        userId,
      );

      final pastOrders =
          await _repository.fetchPast(
        userId,
      );

      _active = activeOrders;
      _past = pastOrders;
    } catch (e) {
      debugPrint(
        'Error loading orders: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> watchOrders(
    String userId,
  ) async {
    await _ordersSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _ordersSubscription =
        _repository
            .watchForCustomer(userId)
            .listen(
      (
        List<order_model.Order> orders,
      ) {
        _active = orders.where(
          (
            order_model.Order order,
          ) {
            final status =
                order.status
                    .toLowerCase();

            return status != 'completed' &&
                status != 'picked up' &&
                status != 'cancelled';
          },
        ).toList();

        _past = orders.where(
          (
            order_model.Order order,
          ) {
            final status =
                order.status
                    .toLowerCase();

            return status == 'completed' ||
                status == 'picked up' ||
                status == 'cancelled';
          },
        ).toList();

        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint(
          'Order stream failed: $error',
        );

        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<List<String>> placeOrders({
    required List<Map<String, dynamic>> items,
    DateTime? pickupSlotTime,
    required String marketName,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError(
        'You must be signed in to place an order.',
      );
    }
    return _repository.placeOrders(
      items: items,
      pickupSlotTime:
          pickupSlotTime,
      marketName: marketName,
    );
  }

  Future<void> updateSlot(
    String orderId,
    String newSlotLabel,
  ) async {
    final now =
        DateTime.now();

    final parsed = _parseSlot(
      newSlotLabel,
      now,
    );

    await _repository
        .updatePickupSlot(
      orderId,
      parsed,
    );

    final updatedActive =
        <order_model.Order>[];

    for (final order
        in _active) {
      updatedActive.add(
        order.id == orderId
            ? order.copyWith(
                pickupSlotTime:
                    parsed,
              )
            : order,
      );
    }

    final updatedPast =
        <order_model.Order>[];

    for (final order
        in _past) {
      updatedPast.add(
        order.id == orderId
            ? order.copyWith(
                pickupSlotTime:
                    parsed,
              )
            : order,
      );
    }

    _active = updatedActive;
    _past = updatedPast;

    notifyListeners();
  }

  Future<void> updateOrderSlot(
    String orderId,
    DateTime newSlotTime,
  ) async {
    await _repository
        .updatePickupSlot(
      orderId,
      newSlotTime,
    );

    _active = _active.map(
      (order) {
        return order.id == orderId
            ? order.copyWith(
                pickupSlotTime:
                    newSlotTime,
              )
            : order;
      },
    ).toList();

    _past = _past.map(
      (order) {
        return order.id == orderId
            ? order.copyWith(
                pickupSlotTime:
                    newSlotTime,
              )
            : order;
      },
    ).toList();

    notifyListeners();
  }

  Future<void> updateStatus(
    String orderId,
    String status,
  ) async {
    await _repository
        .updateStatus(
      orderId,
      status,
    );

    _active = _active.map(
      (order) {
        return order.id == orderId
            ? order.copyWith(
                status: status,
              )
            : order;
      },
    ).toList();

    _past = _past.map(
      (order) {
        return order.id == orderId
            ? order.copyWith(
                status: status,
              )
            : order;
      },
    ).toList();

    notifyListeners();
  }

  static DateTime _parseSlot(
    String label,
    DateTime base,
  ) {
    final match = RegExp(
      r'(\d{1,2}):(\d{2})',
    ).firstMatch(label);

    if (match == null) {
      return base.add(
        const Duration(days: 1),
      );
    }

    final hour =
        int.tryParse(
              match.group(1)!,
            ) ??
            base.hour;

    final minute =
        int.tryParse(
              match.group(2)!,
            ) ??
            0;

    return DateTime(
      base.year,
      base.month,
      base.day,
      hour,
      minute,
    );
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
