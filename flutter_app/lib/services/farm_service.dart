import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/farm_model.dart';

class FarmService {
  FarmService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'farms';

  /// Adds a new farm document to Firestore. Returns the generated document ID.
  Future<String> addFarm(FarmModel farm) async {
    final data = farm.toFirestore();
    // Always use server-side timestamp for accuracy
    data['created_at'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection(_collection).add(data);
    return ref.id;
  }

  /// Real-time stream of all farms belonging to [farmerUid], newest first.
  /// Sorted in Dart to avoid requiring a Firestore composite index.
  Stream<List<FarmModel>> farmsStream(String farmerUid) {
    return _firestore
        .collection(_collection)
        .where('farmer_uid', isEqualTo: farmerUid)
        .snapshots()
        .map((snap) {
      final farms = snap.docs
          .map(FarmModel.fromFirestore)
          .toList(growable: true);
      farms.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return farms;
    });
  }
}
