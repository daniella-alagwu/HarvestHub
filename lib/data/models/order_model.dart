import 'package:cloud_firestore/cloud_firestore.dart';

//customers orders (fetched from the firestore), dynamically too
class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.farmerId,
    required this.itemsJson,
    required this.status,
    required this.total,
    this.pickupSlotTime,
    this.createdAt,
    this.marketName = 'Local Farmers Market',
  });

  final String id;
  final String customerId;
  final String farmerId;
  final Map<String, dynamic> itemsJson;
  final String status;
  final double total;
  final DateTime? pickupSlotTime;
  final DateTime? createdAt;
  final String marketName;

  static const steps = ['Placed', 'Packed', 'Ready', 'Picked up'];


  /// display  format
  String get title => id.length >= 6
      ? '#HH-${id.substring(0, 6).toUpperCase()}'
      : '#HH-$id';


  int get currentStep {
    final index = steps.indexOf(status);
    if (index != -1) return index;
    if (status.toLowerCase() == 'pending') return 0;
    return 0;
  }

 
  bool get isActive =>
      currentStep < steps.length - 1 && status.toLowerCase() != 'cancelled';

  String get statusBadge {
    if (status.toLowerCase() == 'ready') return 'Ready soon';
    if (status.toLowerCase() == 'picked up') return 'Completed';
    return status;
  }

  /// Total count items in an order
  int get itemQuantity =>
      itemsJson.values.fold<int>(0, (sum, v) => sum + (v is num ? v.toInt() : 0));

 
  String get itemsSummary {
    if (itemsJson.isEmpty) return 'No items';
    return itemsJson.entries
        .map((entry) => '${entry.key} × ${entry.value}')
        .join(', ');
  }

  
  String get scheduledLabel {
    if (pickupSlotTime == null) return 'Flexible Pickup';
    final date = pickupSlotTime!;
    return '${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

 
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Order(
      id: doc.id,
      customerId: data['customer_id'] ?? data['customerId'] ?? '',
      farmerId: data['farmer_id'] ?? data['farmerId'] ?? '',
      itemsJson: Map<String, dynamic>.from(data['items_json'] ?? data['itemsJson'] ?? {}),
      status: data['status'] ?? 'Placed',
      total: (data['total_price'] ?? data['totalPrice'] ?? data['total'] ?? 0.0).toDouble(),
      pickupSlotTime: (data['pickup_slot_time'] as Timestamp?)?.toDate() ??
          (data['pickupSlotTime'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate(),
      marketName: data['market_name'] ?? data['marketName'] ?? 'Local Farmers Market',
    );
  }

 
  Map<String, dynamic> toFirestore() {
    return {
      'customer_id': customerId,
      'farmer_id': farmerId,
      'items_json': itemsJson,
      'status': status,
      'total_price': total,
      'pickup_slot_time': pickupSlotTime != null ? Timestamp.fromDate(pickupSlotTime!) : null,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : Timestamp.now(),
      'market_name': marketName,
    };
  }

  Order copyWith({
    String? status,
    DateTime? pickupSlotTime,
    String? marketName,
  }) {
    return Order(
      id: id,
      customerId: customerId,
      farmerId: farmerId,
      itemsJson: itemsJson,
      status: status ?? this.status,
      total: total,
      pickupSlotTime: pickupSlotTime ?? this.pickupSlotTime,
      createdAt: createdAt,
      marketName: marketName ?? this.marketName,
    );
  }
}