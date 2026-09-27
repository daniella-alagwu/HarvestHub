import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String customerId;
  final String farmerId;
  final Map<String, dynamic> itemsJson;
  final DateTime? pickupSlotTime;
  final DateTime? createdAt;
  final String status;
  final double totalPrice;

  OrderModel({
    required this.orderId,
    required this.customerId,
    required this.farmerId,
    required this.itemsJson,
    required this.pickupSlotTime,
    required this.createdAt,
    required this.status,
    required this.totalPrice,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      orderId: doc.id,
      customerId: data['customer_id'] ?? '',
      farmerId: data['farmer_id'] ?? '',
      itemsJson: Map<String, dynamic>.from(data['items_json'] ?? {}),
      pickupSlotTime: (data['pickup_slot_time'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'Pending',
      totalPrice: (data['total_price'] ?? 0).toDouble(),
    );
  }

  int get itemQuantity =>
      itemsJson.values.fold<int>(0, (sum, v) => sum + (v is num ? v.toInt() : 0));
}