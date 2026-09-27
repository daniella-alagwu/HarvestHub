import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/farmer_model.dart';

class FarmerRepository {
  FarmerRepository({
    FirebaseFirestore? firestore,
  }) : _firestore =
          firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>>
      get _farmers =>
          _firestore.collection('farmers');

  Future<List<Farmer>> fetchAll() async {
    final snapshot =
        await _farmers.get();

    return snapshot.docs
        .map(Farmer.fromFirestore)
        .toList();
  }

  Future<Farmer?> fetchById(
    String id,
  ) async {
    final doc =
        await _farmers.doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return Farmer.fromFirestore(doc);
  }

  Stream<List<Farmer>> watchAll() =>
      _farmers.snapshots().map(
        (snapshot) => snapshot.docs
            .map(Farmer.fromFirestore)
            .toList(),
      );
}