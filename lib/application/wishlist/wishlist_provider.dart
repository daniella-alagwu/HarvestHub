import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class WishlistProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  final Set<String> _wishlistedProductIds = {};
  final Set<String> _followedFarmerIds = {};

  bool _followsLoaded = false;

  bool isWishlisted(String productId) => _wishlistedProductIds.contains(productId);

  bool isFollowing(String farmerId) => _followedFarmerIds.contains(farmerId);

  void toggleWishlist(String productId) {
    if (!_wishlistedProductIds.remove(productId)) {
      _wishlistedProductIds.add(productId);
    }
    notifyListeners();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _followDocId(String uid, String farmerId) => '${uid}_$farmerId';

  Future<void> loadFollows() async {
    final uid = _uid;
    if (uid == null || _followsLoaded) return;
    _followsLoaded = true;

    try {
      final snap = await _firestore
          .collection('follows')
          .where('user_id', isEqualTo: uid)
          .get();

      _followedFarmerIds
        ..clear()
        ..addAll(snap.docs.map((d) => d.data()['farmer_id'] as String));

      notifyListeners();
    } catch (e) {
      debugPrint('Could not load follows: $e');
    }
  }

  Future<void> toggleFollow(String farmerId) async {
    final uid = _uid;
    if (uid == null) return;

    final nowFollowing = !_followedFarmerIds.contains(farmerId);

    if (nowFollowing) {
      _followedFarmerIds.add(farmerId);
    } else {
      _followedFarmerIds.remove(farmerId);
    }
    notifyListeners();

    final docRef = _firestore.collection('follows').doc(_followDocId(uid, farmerId));

    try {
      if (nowFollowing) {
        await docRef.set({
          'user_id': uid,
          'farmer_id': farmerId,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.delete();
      }
    } catch (e) {
      if (nowFollowing) {
        _followedFarmerIds.remove(farmerId);
      } else {
        _followedFarmerIds.add(farmerId);
      }
      notifyListeners();
    }
  }

  Future<int> followersCountFor(String farmerId) async {
    try {
      final result = await _firestore
          .collection('follows')
          .where('farmer_id', isEqualTo: farmerId)
          .count()
          .get();
      return result.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  int get wishlistCount => _wishlistedProductIds.length;
}