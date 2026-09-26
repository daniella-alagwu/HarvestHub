import 'package:flutter/foundation.dart';

/// Local favorite/follow state for the current session.
/// TODO: persist to `wishlists/{userId}/items` and
/// `follows/{userId}/farmers` per PROJECT_BLUEPRINT.md §4 once wired
/// to a signed-in user.
class WishlistProvider extends ChangeNotifier {
  final Set<String> _wishlistedProductIds = {};
  final Set<String> _followedFarmerIds = {};

  bool isWishlisted(String productId) =>
      _wishlistedProductIds.contains(productId);

  bool isFollowing(String farmerId) => _followedFarmerIds.contains(farmerId);

  void toggleWishlist(String productId) {
    if (!_wishlistedProductIds.remove(productId)) {
      _wishlistedProductIds.add(productId);
    }
    notifyListeners();
  }

  void toggleFollow(String farmerId) {
    if (!_followedFarmerIds.remove(farmerId)) {
      _followedFarmerIds.add(farmerId);
    }
    notifyListeners();
  }

  int get wishlistCount => _wishlistedProductIds.length;
}