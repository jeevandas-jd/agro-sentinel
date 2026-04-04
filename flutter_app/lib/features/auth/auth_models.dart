class AppUser {
  final String name;
  final String email;
  final String region;

  const AppUser({
    required this.name,
    required this.email,
    required this.region,
  });

  AppUser copyWith({String? name, String? email, String? region}) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      region: region ?? this.region,
    );
  }

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

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
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
