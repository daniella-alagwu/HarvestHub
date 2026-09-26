/// Mirrors the `farmers_market/{marketId}` Firestore document
/// (see PROJECT_BLUEPRINT.md §4).
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
}

class PickupSlot {
  const PickupSlot({
    required this.label,
    this.isAvailable = true,
  });

  /// e.g. "Sat 9:00–10:00"
  final String label;
  final bool isAvailable;
}