import 'package:cloud_firestore/cloud_firestore.dart';

//order model used by both customer and farmers
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


  String get orderId => id;
  double get totalPrice => total;

  static const steps = [
    'Placed',
    'Packed',
    'Ready',
    'Picked up',
  ];

  String get title => id.length >= 6
      ? '#HH-${id.substring(0, 6).toUpperCase()}'
      : '#HH-$id';

  int get currentStep {
    switch (status.trim().toLowerCase()) {
      case 'placed':
      case 'pending':
        return 0;

      case 'packed':
      case 'confirmed':
        return 1;

      case 'ready':
      case 'ready for pickup':
        return 2;

      case 'picked up':
      case 'completed':
        return 3;

      case 'cancelled':
      case 'rejected':
        return 0;

      default:
        return 0;
    }
  }

  bool get isActive =>
      currentStep < steps.length - 1 &&
      status.toLowerCase() != 'cancelled';

  String get statusBadge {
    switch (status.trim().toLowerCase()) {
      case 'pending':
      case 'placed':
        return 'Placed';

      case 'confirmed':
      case 'packed':
        return 'Packed';

      case 'ready':
      case 'ready for pickup':
        return 'Ready soon';

      case 'picked up':
      case 'completed':
        return 'Completed';

      default:
        return status;
    }
  }

  int get itemQuantity {
    return itemsJson.values.fold<int>(
      0,
      (sum, value) {
        if (value is num) {
          return sum + value.toInt();
        }

        if (value is Map) {
          final quantity = value['quantity'];

          if (quantity is num) {
            return sum + quantity.toInt();
          }
        }

        return sum;
      },
    );
  }

  String get itemsSummary {
    if (itemsJson.isEmpty) {
      return 'No items';
    }

    return itemsJson.entries.map((entry) {
      final value = entry.value;

      if (value is Map) {
        final name =
            value['item_name'] ??
            value['itemName'] ??
            entry.key;

        final quantity = value['quantity'] ?? 0;
        final unit = value['unit'];

        return unit == null
            ? '$name × $quantity'
            : '$name × $quantity $unit';
      }

      return '${entry.key} × $value';
    }).join(', ');
  }

  String get scheduledLabel {
    if (pickupSlotTime == null) {
      return 'Flexible Pickup';
    }

    final date = pickupSlotTime!;

    return '${date.day}/${date.month} • '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  factory Order.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};

    final rawItems =
        data['items_json'] ??
        data['itemsJson'] ??
        {};

    final items = rawItems is Map
        ? Map<String, dynamic>.from(rawItems)
        : <String, dynamic>{};

    return Order(
      id: doc.id,
      customerId: _asString(
        data['customer_id'] ?? data['customerId'],
      ),
      farmerId: _asString(
        data['farmer_id'] ?? data['farmerId'],
      ),
      itemsJson: items,
      status: _asString(
        data['status'],
        fallback: 'Pending',
      ),
      total: _asDouble(
        data['total_price'] ??
            data['totalPrice'] ??
            data['total'],
      ),
      pickupSlotTime: _timestampToDate(
        data['pickup_slot_time'] ??
            data['pickupSlotTime'],
      ),
      createdAt: _timestampToDate(
        data['created_at'] ??
            data['createdAt'],
      ),
      marketName: _asString(
        data['market_name'] ??
            data['marketName'],
        fallback: 'Local Farmers Market',
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customer_id': customerId,
      'farmer_id': farmerId,
      'items_json': itemsJson,
      'status': status,
      'total_price': total,
      'pickup_slot_time': pickupSlotTime == null
          ? null
          : Timestamp.fromDate(pickupSlotTime!),
      'created_at': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
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
      pickupSlotTime:
          pickupSlotTime ?? this.pickupSlotTime,
      createdAt: createdAt,
      marketName: marketName ?? this.marketName,
    );
  }

  static String _asString(
    Object? value, {
    String fallback = '',
  }) {
    return value?.toString() ?? fallback;
  }

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _timestampToDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}

typedef OrderModel = Order;