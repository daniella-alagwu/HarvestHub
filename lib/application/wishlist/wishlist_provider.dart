import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class WishlistProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  final Set<String> _wishlistedProductIds = {};
  final Set<String> _followedFarmerIds = {};

  bool _followsLoaded = false;
  String? _activeUserId;

  static String followPathFor(String uid, String farmerId) =>
      'follows/$uid/farmers/$farmerId';

  static bool shouldReloadFollowState(String? nextUid, String? currentUid) {
    return nextUid != currentUid;
  }

  static bool hasFollowDocumentForFarmer(
      Map<String, dynamic> data, String farmerId) {
    final storedFarmerId = data['farmer_id'];
    if (storedFarmerId is String) {
      return storedFarmerId == farmerId;
    }
    return false;
  }

  static double computeAverageRating(List<num> values) {
    if (values.isEmpty) return 0;
    final total =
        values.fold<double>(0, (sum, value) => sum + value.toDouble());
    return total / values.length;
  }

  bool isWishlisted(String productId) =>
      _wishlistedProductIds.contains(productId);

  bool isFollowing(String farmerId) => _followedFarmerIds.contains(farmerId);

  Future<double?> myRatingForFarmer(String farmerId) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final doc = await _firestore
          .collection('farmer_ratings')
          .doc(farmerId)
          .collection('ratings')
          .doc(uid)
          .get();

      if (!doc.exists) return null;

      final value = doc.data()?['rating'];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    } catch (e) {
      debugPrint('Could not load my farmer rating: $e');
      return null;
    }
  }

  Future<double> farmerRatingFor(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('farmer_ratings')
          .doc(farmerId)
          .collection('ratings')
          .get();

      if (snapshot.docs.isEmpty) {
        final farmerDoc =
            await _firestore.collection('farmers').doc(farmerId).get();
        final rating = farmerDoc.data()?['rating'];
        if (rating is num) return rating.toDouble();
        return 0;
      }

      final scores = snapshot.docs
          .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0)
          .toList();
      final average = computeAverageRating(scores);

      await _firestore
          .collection('farmers')
          .doc(farmerId)
          .set({'rating': average}, SetOptions(merge: true));

      return average;
    } catch (e) {
      debugPrint('Could not load farmer rating: $e');
      return 0;
    }
  }

  Future<void> rateFarmer(String farmerId, double rating) async {
    final uid = _uid;
    if (uid == null) return;

    final score = rating.clamp(1.0, 5.0).toDouble();
    final docRef = _firestore
        .collection('farmer_ratings')
        .doc(farmerId)
        .collection('ratings')
        .doc(uid);

    try {
      await docRef.set({
        'user_id': uid,
        'farmer_id': farmerId,
        'rating': score,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      final snapshot = await _firestore
          .collection('farmer_ratings')
          .doc(farmerId)
          .collection('ratings')
          .get();

      final scores = snapshot.docs
          .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0)
          .toList();
      final average = computeAverageRating(scores);

      await _firestore
          .collection('farmers')
          .doc(farmerId)
          .set({'rating': average}, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      debugPrint('Could not save farmer rating: $e');
    }
  }

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

    if (shouldReloadFollowState(uid, _activeUserId)) {
      _followedFarmerIds.clear();
      _followsLoaded = false;
      _activeUserId = uid;
    }

    if (uid == null) {
      _followedFarmerIds.clear();
      _followsLoaded = false;
      _activeUserId = null;
      return;
    }

    if (_followsLoaded) return;
    _followsLoaded = true;

    try {
      final snap = await _firestore
          .collection('follows')
          .doc(uid)
          .collection('farmers')
          .get();

      _followedFarmerIds
        ..clear()
        ..addAll(snap.docs.map((d) => d.id));

      notifyListeners();
    } catch (e) {
      _followsLoaded = false;
      debugPrint('Could not load follows: $e');
    }
  }

  Future<void> toggleFollow(String farmerId) async {
    final uid = _uid;
    if (uid == null) return;

    if (shouldReloadFollowState(uid, _activeUserId)) {
      await loadFollows();
    }

    final nowFollowing = !_followedFarmerIds.contains(farmerId);

    if (nowFollowing) {
      _followedFarmerIds.add(farmerId);
    } else {
      _followedFarmerIds.remove(farmerId);
    }
    notifyListeners();

    final docRef = _firestore
        .collection('follows')
        .doc(uid)
        .collection('farmers')
        .doc(farmerId);

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
      final snapshot = await _firestore
          .collectionGroup('farmers')
          .where('farmer_id', isEqualTo: farmerId)
          .get();

      final matches = snapshot.docs.where((doc) {
        final data = doc.data();
        return hasFollowDocumentForFarmer(data, farmerId);
      }).length;

      return matches;
    } catch (e) {
      debugPrint('Could not load follower count: $e');
      return 0;
    }
  }

  Future<List<String>> customerNamesFollowingFarmer(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('farmers')
          .where('farmer_id', isEqualTo: farmerId)
          .get();

      final userIds = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final userId = data['user_id'] as String?;
            if (userId != null && userId.isNotEmpty) return userId;

            final path = doc.reference.path;
            final parts = path.split('/');
            if (parts.length >= 3 && parts[0] == 'follows') {
              return parts[1];
            }
            return null;
          })
          .whereType<String>()
          .toSet()
          .toList();

      final names = <String>[];
      for (final userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final name = (userDoc.data()?['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          names.add(name);
        }
      }

      names.sort();
      return names;
    } catch (e) {
      debugPrint('Could not load follower names: $e');
      return const [];
    }
  }

  int get wishlistCount => _wishlistedProductIds.length;
}
