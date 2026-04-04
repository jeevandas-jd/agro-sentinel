import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String aadhaarLast4;
  final DateTime? createdAt;

  const FarmerModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.aadhaarLast4,
    this.createdAt,
  });

  factory FarmerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FarmerModel(
      uid: doc.id,
      name: (data['name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      aadhaarLast4: (data['aadhaar_last4'] as String?) ?? '',
      createdAt: _asDateTime(data['created_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'name': name,
      'phone': phone,
      'email': email,
      'aadhaar_last4': aadhaarLast4,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
