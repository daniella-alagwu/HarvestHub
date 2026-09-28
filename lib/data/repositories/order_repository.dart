import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart' as order_model;

class OrderRepository {
  OrderRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
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
      snapshot.docs.map(order_model.Order.fromFirestore).toList(),
    );

    return orders.where((order) {
      final status = order.status.toLowerCase();

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
      snapshot.docs.map(order_model.Order.fromFirestore).toList(),
    );

    return orders.where((order) {
      final status = order.status.toLowerCase();

      return status == 'completed' ||
          status == 'picked up' ||
          status == 'cancelled';
    }).toList();
  }

  Stream<List<order_model.Order>> watchForCustomer(
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
                  order_model.Order.fromFirestore,
                )
                .toList(),
          ),
        );
  }

  Stream<List<order_model.Order>> watchForFarmer(
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
                  order_model.Order.fromFirestore,
                )
                .toList(),
          ),
        );
  }

  Future<order_model.Order> getOrderById(
    String orderId,
  ) async {
    final doc = await _orders.doc(orderId).get();

    if (!doc.exists) {
      throw StateError(
        'Order $orderId not found',
      );
    }

    return order_model.Order.fromFirestore(
      doc,
    );
  }

  // Create one order for a single farmer
  Future<String> placeOrder({
    required String customerId,
    required String farmerId,
    required Map<String, dynamic> itemsJson,
    required double total,
    DateTime? pickupSlotTime,
    required String marketName,
  }) async {
    final batch = _firestore.batch();

    for (final entry in itemsJson.entries) {
      final productRef = _firestore.collection('products').doc(entry.key);
      final productDoc = await productRef.get();

      if (!productDoc.exists) {
        throw StateError('Product ${entry.key} no longer exists.');
      }

      final data = productDoc.data() ?? const <String, dynamic>{};

      final stock = (data['stock_qty'] as num?)?.toInt() ??
          (data['stockQty'] as num?)?.toInt() ??
          (data['quantity'] as num?)?.toInt() ??
          0;

      final quantity = _quantityFrom(entry.value);

      final productFarmerId =
          data['farmer_id']?.toString() ?? data['farmerId']?.toString() ?? '';

      if (productFarmerId != farmerId) {
        throw StateError('A cart item belongs to another farmer.');
      }

      if (quantity <= 0 || quantity > stock) {
        final name = data['item_name']?.toString() ??
            data['itemName']?.toString() ??
            entry.key;

        throw StateError('$name has insufficient stock.');
      }
    }

    final orderRef = _orders.doc();

    batch.set(orderRef, {
      'customer_id': customerId,
      'farmer_id': farmerId,
      'items_json': itemsJson,
      'pickup_slot_time':
          pickupSlotTime == null ? null : Timestamp.fromDate(pickupSlotTime),
      'status': 'Pending',
      'total_price': total,
      'market_name': marketName,
      'created_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return orderRef.id;
  }

  Future<void> updatePickupSlot(
    String orderId,
    DateTime newSlotTime,
  ) async {
    await _orders.doc(orderId).update({
      'pickup_slot_time': Timestamp.fromDate(newSlotTime),
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

  static int _quantityFrom(
    Object? value,
  ) {
    if (value is num) {
      return value.ceil();
    }

    if (value is Map) {
      final quantity = value['quantity'];

      if (quantity is num) {
        return quantity.ceil();
      }
    }

    return 0;
  }

  static List<order_model.Order> _sortNewest(
    List<order_model.Order> orders,
  ) {
    orders.sort(
      (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
        a.createdAt ?? DateTime(1970),
      ),
    );

    return orders;
  }
}
