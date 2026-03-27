import '../auth/auth_models.dart';
import '../auth/auth_service.dart';

class ProfileService {
  final AuthService _authService;

  ProfileService(this._authService);

  Future<DemoUser> updateProfile({
    required DemoUser user,
    required String name,
    required String region,
  }) {
    return _authService.updateProfile(
      email: user.email,
      name: name,
      region: region,
    );
  }
}
