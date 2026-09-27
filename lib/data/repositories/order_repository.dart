import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderStatus {
  static const pending = 'Placed';
  static const packed = 'Packed';
  static const readyForPickup = 'Ready';
  static const completed = 'Picked up';
  static const cancelled = 'Cancelled';
}

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  //validating stocks...
  Future<String> placeOrder({
    required String customerId,
    required String farmerId,
    required List<Map<String, dynamic>> items,
    required DateTime pickupSlotTime,
    required double totalPrice,
    String marketName = 'Local Farmers Market',
  }) {
    return _firestore.runTransaction<String>((transaction) async {
      final Map<String, dynamic> itemsSummaryMap = {};

      for (final item in items) {
        final productId = item['product_id'] as String;
        final productName = item['item_name'] ?? 'Item';
        final productRef = _firestore.collection('products').doc(productId);

        final snapshot = await transaction.get(productRef);
        final currentStock =
            (snapshot.data()?['stock_qty'] as num?)?.toInt() ?? 0;
        final quantity = (item['quantity'] as num).toInt();

        if (currentStock < quantity) {
          throw Exception('$productName is out of stock.');
        }

        // deduction
        transaction.update(productRef, {'stock_qty': currentStock - quantity});

        
        itemsSummaryMap[productName] = quantity;
      }

      final orderRef = _orders.doc();
      transaction.set(orderRef, {
        'customer_id': customerId,
        'farmer_id': farmerId,
        'items_json': itemsSummaryMap,
        'pickup_slot_time': Timestamp.fromDate(pickupSlotTime),
        'status': OrderStatus.pending,
        'total_price': totalPrice,
        'market_name': marketName,
        'created_at': FieldValue.serverTimestamp(),
      });

      return orderRef.id;
    });
  }

 //update
  Future<void> updateOrderStatus(String orderId, String status) {
    return _orders.doc(orderId).update({'status': status});
  }

  
  Future<Order?> getOrder(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (!doc.exists) return null;
    return Order.fromFirestore(doc);
  }

  
  Stream<List<Order>> watchOrdersForCustomer(String customerId) {
    return _orders
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  
  Stream<List<Order>> watchOrdersForFarmer(String farmerId) {
    return _orders
        .where('farmer_id', isEqualTo: farmerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  Future<List<Order>> fetchActive(String customerId) async {
    final snapshot = await _orders
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Order.fromFirestore(doc))
        .where((o) => o.isActive)
        .toList();
  }
 
  Future<List<Order>> fetchPast(String customerId) async {
    final snapshot = await _orders
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Order.fromFirestore(doc))
        .where((o) => !o.isActive)
        .toList();
  }
}