/// User authentication model
class AuthUser {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final bool isEmailVerified;
  final String? avatarUrl;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.isEmailVerified = false,
    this.avatarUrl,
    required this.createdAt,
  });

  /// Create from JSON
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'is_email_verified': isEmailVerified,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy with method
  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    bool? isEmailVerified,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Sample user for testing
  static AuthUser sample() {
    return AuthUser(
      id: 'user_123',
      email: 'user@example.com',
      name: 'John Doe',
      phone: '+1234567890',
      isEmailVerified: true,
      avatarUrl: null,
      createdAt: DateTime.now(),
    );
  }
}