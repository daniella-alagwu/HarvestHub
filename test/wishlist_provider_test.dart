import 'package:flutter_test/flutter_test.dart';
import 'package:harvesthub/application/wishlist/wishlist_provider.dart';

void main() {
  test('follow relationship uses the nested user/farmer path', () {
    const uid = 'user_123';
    const farmerId = 'farmer_456';

    expect(
      WishlistProvider.followPathFor(uid, farmerId),
      'follows/user_123/farmers/farmer_456',
    );
  });

  test('follow state reloads when the authenticated user changes', () {
    expect(
      WishlistProvider.shouldReloadFollowState('user_2', 'user_1'),
      isTrue,
    );
    expect(
      WishlistProvider.shouldReloadFollowState('user_1', 'user_1'),
      isFalse,
    );
    expect(
      WishlistProvider.shouldReloadFollowState(null, 'user_1'),
      isTrue,
    );
  });

  test('follow documents match the target farmer id', () {
    final doc = {'user_id': 'user_123', 'farmer_id': 'farmer_456'};

    expect(
      WishlistProvider.hasFollowDocumentForFarmer(doc, 'farmer_456'),
      isTrue,
    );
    expect(
      WishlistProvider.hasFollowDocumentForFarmer(doc, 'farmer_999'),
      isFalse,
    );
  });

  test('rating average is computed from all submitted customer scores', () {
    expect(
      WishlistProvider.computeAverageRating([3, 5]),
      4.0,
    );
  });
}
