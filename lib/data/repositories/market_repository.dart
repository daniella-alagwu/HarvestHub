import '../models/market_model.dart';

/// Mock data today; field names mirror `farmers_market/{marketId}` in
/// PROJECT_BLUEPRINT.md §4 for a straightforward Firestore swap later.
class MarketRepository {
  static const List<Market> _mockMarkets = [
    Market(
      id: 'm_psu',
      marketName: 'PSU Farmers Market',
      address: '1803 SW Park Ave, Portland',
      pickupSlots: [
        PickupSlot(label: 'Sat 9:00–10:00'),
        PickupSlot(label: '10:00–11:00'),
        PickupSlot(label: '11:00–12:00'),
      ],
    ),
    Market(
      id: 'm_hollywood',
      marketName: 'Hollywood Farmers Market',
      address: '4420 NE Sandy Blvd, Portland',
      pickupSlots: [
        PickupSlot(label: 'Sun 9:00–10:00'),
        PickupSlot(label: '10:00–11:00'),
      ],
    ),
  ];

  Future<List<Market>> fetchAll() async => _mockMarkets;

  Future<Market> fetchDefault() async => _mockMarkets.first;
}