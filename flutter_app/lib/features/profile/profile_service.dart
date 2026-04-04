import '../auth/auth_models.dart';
import '../auth/auth_service.dart';

class ProfileService {
  final AuthService _authService;

  ProfileService(this._authService);

  Future<AppUser> updateProfile({
    required String name,
    required String region,
  }) {
    return _authService.updateProfile(
      name: name,
      region: region,
    );
  }
}
