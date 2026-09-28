import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/market_model.dart';

class MarketRepository {
  MarketRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _markets =>
      _firestore.collection(
        'farmers_market',
      );

  Future<List<Market>> fetchAll() async {
    final snapshot = await _markets.get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) {
        final market = Market.fromFirestore(doc);

        return market.pickupSlots.isEmpty
            ? Market(
                id: market.id,
                marketName: market.marketName,
                address: market.address,
                pickupSlots: const [
                  PickupSlot(
                    label: 'Sat 9:00–10:00',
                  ),
                  PickupSlot(
                    label: '10:00–11:00',
                  ),
                  PickupSlot(
                    label: '11:00–12:00',
                  ),
                ],
                activeStatus: market.activeStatus,
              )
            : market;
      }).toList();
    }

    return _fallbackMarkets;
  }

  Future<Market> fetchDefault() async {
    final markets = await fetchAll();

    return markets.first;
  }

  static const _fallbackMarkets = <Market>[
    Market(
      id: 'm_local',
      marketName: 'HarvestHub Market',
      address: 'Main Farm Gate, Ibadan',
      pickupSlots: [
        PickupSlot(
          label: 'Sat 9:00-10:00',
        ),
        PickupSlot(
          label: '10:00-11:00',
        ),
        PickupSlot(
          label: '11:00-12:00',
        ),
      ],
    ),
  ];
}
