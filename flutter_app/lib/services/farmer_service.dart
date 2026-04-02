import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/farmer_model.dart';

class FarmerService {
  FarmerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Reads the `users/{uid}` document and returns a [FarmerModel].
  /// Returns `null` if the document does not exist.
  Future<FarmerModel?> getFarmerProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return FarmerModel.fromFirestore(doc);
  }
}
