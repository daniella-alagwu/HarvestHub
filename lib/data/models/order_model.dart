/// Mirrors the `orders/{orderId}` Firestore document shape from
/// PROJECT_BLUEPRINT.md §4, simplified for the customer order list.
class Order {
  const Order({
    required this.id,
    required this.title,
    required this.marketName,
    required this.scheduledLabel,
    required this.itemsSummary,
    required this.total,
    required this.statusBadge,
    required this.currentStep,
    this.isActive = true,
  });

  final String id;

  /// e.g. "#HH-1048" or "Sunday Market order"
  final String title;
  final String marketName;
  final String scheduledLabel;
  final String itemsSummary;
  final double total;
  final String statusBadge;

  /// Index into [steps]: 0 Placed, 1 Packed, 2 Ready, 3 Picked up.
  final int currentStep;
  final bool isActive;

  Order copyWith({String? scheduledLabel}) {
    return Order(
      id: id,
      title: title,
      marketName: marketName,
      scheduledLabel: scheduledLabel ?? this.scheduledLabel,
      itemsSummary: itemsSummary,
      total: total,
      statusBadge: statusBadge,
      currentStep: currentStep,
      isActive: isActive,
    );
  }

  static const steps = ['Placed', 'Packed', 'Ready', 'Picked up'];
}