import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart' as order_model;

class OrderRepository {
  OrderRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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

  // Checkout is handled by a trusted Cloud Function that validates prices
  // and updates stock atomically across every farmer in the cart.
  Future<List<String>> placeOrders({
    required List<Map<String, dynamic>> items,
    DateTime? pickupSlotTime,
    required String marketName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before placing an order.');
    final token = await user.getIdToken();
    if (token == null) throw StateError('Could not authenticate your order. Sign in again.');
    final response = await http.post(
      Uri.parse('https://us-central1-harvest-hub-d7d24.cloudfunctions.net/placeOrder'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'data': {
          'items': items,
          'marketName': marketName,
          'pickupSlotTime': pickupSlotTime?.millisecondsSinceEpoch,
        },
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['error'] != null) {
      final error = body['error'];
      final message = error is Map ? error['message']?.toString() : null;
      throw StateError(message ?? 'Order could not be placed. Please try again.');
    }
    final result = body['result'] as Map<String, dynamic>?;
    final ids = result?['orderIds'];
    if (ids is! List) throw StateError('The order service returned an invalid response.');
    return ids.map((id) => id.toString()).toList();
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
