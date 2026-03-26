class DemoUser {
  final String name;
  final String email;
  final String region;

  const DemoUser({
    required this.name,
    required this.email,
    required this.region,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'name': name, 'email': email, 'region': region};
  }

  factory DemoUser.fromJson(Map<String, dynamic> json) {
    return DemoUser(
      name: json['name'] as String? ?? 'Farmer',
      email: json['email'] as String? ?? '',
      region: json['region'] as String? ?? 'Unknown Region',
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String region;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.region,
  });
}
