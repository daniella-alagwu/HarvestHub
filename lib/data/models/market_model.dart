import 'package:cloud_firestore/cloud_firestore.dart';

class Market {
  const Market({
    required this.id,
    required this.marketName,
    required this.address,
    required this.pickupSlots,
    this.activeStatus = true,
  });

  final String id;
  final String marketName;
  final String address;
  final List<PickupSlot> pickupSlots;
  final bool activeStatus;

  factory Market.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data =
        doc.data() ?? const <String, dynamic>{};

    final rawSlots =
        data['pickup_slots'] ??
        data['pickupSlots'] ??
        const [];

    final slots = rawSlots is List
        ? rawSlots
            .map((slot) {
              if (slot is Map) {
                return PickupSlot(
                  label: slot['label']?.toString() ?? '',
                  isAvailable:
                      slot['is_available'] is bool
                          ? slot['is_available'] as bool
                          : slot['isAvailable'] is bool
                              ? slot['isAvailable'] as bool
                              : true,
                );
              }

              return PickupSlot(
                label: slot.toString(),
              );
            })
            .where(
              (slot) => slot.label.isNotEmpty,
            )
            .toList()
        : <PickupSlot>[];

    return Market(
      id: doc.id,
      marketName:
          data['market_name']?.toString() ??
              'Local Farmers Market',
      address:
          data['address']?.toString() ?? '',
      pickupSlots: slots,
      activeStatus:
          data['active_status'] is bool
              ? data['active_status'] as bool
              : true,
    );
  }
}

class PickupSlot {
  const PickupSlot({
    required this.label,
    this.isAvailable = true,
  });

  final String label;
  final bool isAvailable;
}