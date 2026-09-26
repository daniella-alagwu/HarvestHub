import '../models/farmer_model.dart';

/// Mock data today; field names mirror `farmers/{farmerId}` in
/// PROJECT_BLUEPRINT.md §4 for a straightforward Firestore swap later.
class FarmerRepository {
  static final List<Farmer> _mockFarmers = [
    const Farmer(
      id: 'f_maple_row',
      userId: 'u_nora',
      marketId: 'm_psu',
      businessName: 'Maple Row Farm',
      marketName: 'PSU Farmers Market',
      rating: 4.9,
      distanceMiles: 2.4,
      tagline: 'Organic greens',
      marketDay: 'Saturday Market',
      followersCount: 286,
      productsCount: 18,
      description: 'Family-run since 2011, growing organic vegetables, '
          'herbs, and free-range eggs just outside Portland.',
    ),
    const Farmer(
      id: 'f_riverbend',
      userId: 'u_riverbend',
      marketId: 'm_psu',
      businessName: 'Riverbend Organics',
      marketName: 'PSU Farmers Market',
      rating: 4.7,
      distanceMiles: 1.8,
      tagline: 'Certified organic produce',
      marketDay: 'Saturday Market',
      followersCount: 154,
      productsCount: 11,
    ),
    const Farmer(
      id: 'f_sunrise_acres',
      userId: 'u_sunrise',
      marketId: 'm_psu',
      businessName: 'Sunrise Acres',
      marketName: 'PSU Farmers Market',
      rating: 4.8,
      distanceMiles: 3.1,
      tagline: 'Berries & stone fruit',
      marketDay: 'Saturday Market',
      followersCount: 98,
      productsCount: 9,
    ),
  ];

  Future<List<Farmer>> fetchAll() async => List.unmodifiable(_mockFarmers);

  Future<Farmer?> fetchById(String id) async {
    for (final farmer in _mockFarmers) {
      if (farmer.id == id) return farmer;
    }
    return null;
  }
}