import '../models/order_model.dart';

/// Mock data today; mirrors `orders/{orderId}` in PROJECT_BLUEPRINT.md
/// §4 for a straightforward Firestore swap once orders are written by
/// the checkout flow.
class OrderRepository {
  static const List<Order> _mockOrders = [
    Order(
      id: 'HH-1048',
      title: 'Order #HH-1048',
      marketName: 'PSU Farmers Market',
      scheduledLabel: 'Saturday, Sep 26 • 9:00–10:00 AM',
      itemsSummary: 'Heirloom Tomatoes × 2 lb • Garden Kale × 1',
      total: 10.35,
      statusBadge: 'Ready soon',
      currentStep: 2,
      isActive: true,
    ),
    Order(
      id: 'HH-1052',
      title: 'Sunday Market order',
      marketName: 'PSU Farmers Market',
      scheduledLabel: 'Confirmed • Sep 27, 11:00 AM',
      itemsSummary: '4 items',
      total: 28.40,
      statusBadge: 'Confirmed',
      currentStep: 0,
      isActive: true,
    ),
  ];

  Future<List<Order>> fetchActive() async =>
      _mockOrders.where((o) => o.isActive).toList();

  Future<List<Order>> fetchPast() async =>
      _mockOrders.where((o) => !o.isActive).toList();
}