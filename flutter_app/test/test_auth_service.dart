import 'package:agrisentinel/features/auth/auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

AuthService buildTestAuthService({
  firebase_auth.User? user,
  bool signedIn = false,
}) {
  final mockUser = user ??
      MockUser(
        uid: 'test-uid',
        email: 'demo@agrisentinel.app',
        displayName: 'Demo Farmer',
      );

  final mockAuth = MockFirebaseAuth(
    signedIn: signedIn,
    mockUser: mockUser as MockUser,
  );

  return AuthService(
    auth: mockAuth,
    firestore: FakeFirebaseFirestore(),
  );
}

