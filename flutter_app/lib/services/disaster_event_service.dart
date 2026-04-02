import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/disaster_event_model.dart';

class DisasterEventService {
  DisasterEventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'disaster_events';

  /// Real-time stream of all disaster events for [farmerUid], newest first.
  /// Sorts in Dart to avoid requiring a Firestore composite index.
  Stream<List<DisasterEventModel>> eventsStream(String farmerUid) {
    return _firestore
        .collection(_collection)
        .where('farmer_uid', isEqualTo: farmerUid)
        .snapshots()
        .map((snap) {
      final events = snap.docs
          .map(DisasterEventModel.fromFirestore)
          .toList(growable: true);
      events.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      return events;
    });
  }

  /// Saves a disaster event. Creates a new document if [event.id] is empty
  /// or a local temp ID (starts with "evt-"), otherwise overwrites by ID.
  Future<String> saveEvent(DisasterEventModel event) async {
    final data = event.toFirestore();
    final isNew = event.id.isEmpty || event.id.startsWith('evt-');
    if (isNew) {
      final ref = await _firestore.collection(_collection).add(data);
      return ref.id;
    } else {
      await _firestore.collection(_collection).doc(event.id).set(data);
      return event.id;
    }
  }
}
