import 'package:flutter/foundation.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({OrderRepository? repository})
      : _repository = repository ?? OrderRepository() {
    _load();
  }

  final OrderRepository _repository;
  List<Order> _active = [];
  List<Order> _past = [];
  bool _isLoading = true;
  int _sequence = 1052;

  bool get isLoading => _isLoading;
  List<Order> get active => _active;
  List<Order> get past => _past;

  Future<void> _load() async {
    final results = await Future.wait([
      _repository.fetchActive(),
      _repository.fetchPast(),
    ]);
    _active = results[0];
    _past = results[1];
    _isLoading = false;
    notifyListeners();
  }

  void placeOrder({
    required String marketName,
    required String scheduledLabel,
    required String itemsSummary,
    required double total,
  }) {
    _sequence += 1;
    final order = Order(
      id: 'HH-$_sequence',
      title: 'Order #HH-$_sequence',
      marketName: marketName,
      scheduledLabel: scheduledLabel,
      itemsSummary: itemsSummary,
      total: total,
      statusBadge: 'Confirmed',
      currentStep: 0,
      isActive: true,
    );
    _active = [order, ..._active];
    notifyListeners();
  }

  void updateSlot(String orderId, String newSlotLabel) {
    _active = _active
        .map((o) => o.id == orderId ? o.copyWith(scheduledLabel: newSlotLabel) : o)
        .toList();
    _past = _past
        .map((o) => o.id == orderId ? o.copyWith(scheduledLabel: newSlotLabel) : o)
        .toList();
    notifyListeners();
  }
}