import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart' as order_model;

class OrderRepository {
  OrderRepository({
    FirebaseFirestore? firestore,
  }) : _firestore =
          firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>>
      get _orders =>
          _firestore.collection('orders');

  Future<List<order_model.Order>> fetchActive(
    String customerId,
  ) async {
    final snapshot = await _orders
        .where(
          'customer_id',
          isEqualTo: customerId,
        )
        .get();

    final orders = _sortNewest(
      snapshot.docs
          .map(order_model.Order.fromFirestore)
          .toList(),
    );

    return orders.where((order) {
      final status =
          order.status.toLowerCase();

      return status != 'completed' &&
          status != 'picked up' &&
          status != 'cancelled';
    }).toList();
  }

  Future<List<order_model.Order>> fetchPast(
    String customerId,
  ) async {
    final snapshot = await _orders
        .where(
          'customer_id',
          isEqualTo: customerId,
        )
        .get();

    final orders = _sortNewest(
      snapshot.docs
          .map(order_model.Order.fromFirestore)
          .toList(),
    );

    return orders.where((order) {
      final status =
          order.status.toLowerCase();

      return status == 'completed' ||
          status == 'picked up' ||
          status == 'cancelled';
    }).toList();
  }

  Stream<List<order_model.Order>>
      watchForCustomer(
    String customerId,
  ) {
    return _orders
        .where(
          'customer_id',
          isEqualTo: customerId,
        )
        .snapshots()
        .map(
          (snapshot) => _sortNewest(
            snapshot.docs
                .map(
                  order_model
                      .Order
                      .fromFirestore,
                )
                .toList(),
          ),
        );
  }

  Stream<List<order_model.Order>>
      watchForFarmer(
    String farmerId,
  ) {
    return _orders
        .where(
          'farmer_id',
          isEqualTo: farmerId,
        )
        .snapshots()
        .map(
          (snapshot) => _sortNewest(
            snapshot.docs
                .map(
                  order_model
                      .Order
                      .fromFirestore,
                )
                .toList(),
          ),
        );
  }

  Future<order_model.Order> getOrderById(
    String orderId,
  ) async {
    final doc =
        await _orders.doc(orderId).get();

    if (!doc.exists) {
      throw StateError(
        'Order $orderId not found',
      );
    }

    return order_model.Order.fromFirestore(
      doc,
    );
  }

  // Create all farmer sub-orders together so a multi-farmer cart is atomic.
  Future<List<String>> placeOrders({
    required String customerId,
    required List<Map<String, dynamic>> orders,
    DateTime? pickupSlotTime,
    required String marketName,
  }) async {
    if (orders.isEmpty) {
      throw ArgumentError('An order must contain at least one farmer group.');
    }
    final batch = _firestore.batch();
    final orderRefs = <DocumentReference<Map<String, dynamic>>>[];
    for (final order in orders) {
      final ref = _orders.doc();
      orderRefs.add(ref);
      batch.set(ref, {
        'customer_id': customerId,
        'farmer_id': order['farmer_id'],
        'items_json': order['items_json'],
        'pickup_slot_time': pickupSlotTime == null
            ? null
            : Timestamp.fromDate(pickupSlotTime),
        'status': 'Pending',
        'total_price': order['total_price'],
        'market_name': marketName,
        'payment_method': 'demo_card',
        'payment_status': 'demo_only',
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return orderRefs.map((ref) => ref.id).toList();
  }

  Future<void> updatePickupSlot(
    String orderId,
    DateTime newSlotTime,
  ) async {
    await _orders.doc(orderId).update({
      'pickup_slot_time':
          Timestamp.fromDate(newSlotTime),
    });
  }

  Future<void> updateStatus(
    String orderId,
    String status,
  ) async {
    await _orders.doc(orderId).update({
      'status': status,
    });
  }

  static List<order_model.Order>
      _sortNewest(
    List<order_model.Order> orders,
  ) {
    orders.sort(
      (a, b) =>
          (b.createdAt ??
                  DateTime(1970))
              .compareTo(
        a.createdAt ??
            DateTime(1970),
      ),
    );

    return orders;
  }
}
