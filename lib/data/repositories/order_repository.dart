import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatus {
  static const pending = 'Pending';
  static const confirmed = 'Confirmed';
  static const readyForPickup = 'Ready for Pickup';
  static const completed = 'Completed';
  static const cancelled = 'Cancelled';
}

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Future<String> placeOrder({
    required String customerId,
    required String farmerId,
    required List<Map<String, dynamic>> items,
    required DateTime pickupSlotTime,
    required double totalPrice,
  }) {
    return _firestore.runTransaction<String>((transaction) async {
      for (final item in items) {
        final productRef = _firestore
            .collection('products')
            .doc(item['product_id'] as String);
        final snapshot = await transaction.get(productRef);
        final currentStock =
            (snapshot.data()?['stock_qty'] as num?)?.toInt() ?? 0;
        final quantity = (item['quantity'] as num).toInt();
        if (currentStock < quantity) {
          throw Exception('${item['item_name'] ?? 'Item'} is out of stock.');
        }
        transaction
            .update(productRef, {'stock_qty': currentStock - quantity});
      }

      final orderRef = _orders.doc();
      transaction.set(orderRef, {
        'customer_id': customerId,
        'farmer_id': farmerId,
        'items_json': jsonEncode(items),
        'pickup_slot_time': Timestamp.fromDate(pickupSlotTime),
        'status': OrderStatus.pending,
        'total_price': totalPrice,
        'created_at': FieldValue.serverTimestamp(),
      });
      return orderRef.id;
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return _orders.doc(orderId).update({'status': status});
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getOrder(String orderId) {
    return _orders.doc(orderId).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrdersForCustomer(
      String customerId) {
    return _orders
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrdersForFarmer(
      String farmerId) {
    return _orders
        .where('farmer_id', isEqualTo: farmerId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}