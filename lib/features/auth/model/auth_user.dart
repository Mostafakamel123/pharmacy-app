/// User authentication model - Compatible with Elaaj API
class AuthUser {
  final String? id;
  final String? email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? role;
  final bool? emailVerified;
  final bool? phoneVerified;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthUser({
    this.id,
    this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.role,
    this.emailVerified,
    this.phoneVerified,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON - Compatible with Elaaj API response
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? json['userId'] as String?,
      email: json['email'] as String?,
      fullName: json['fullName'] as String? ?? 
                '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? json['phone'] as String?,
      role: json['role'] as String? ?? json['userRole'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? json['is_email_verified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String? ?? json['imageUrl'] as String? ?? json['avatar_url'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : json['created_at'] != null 
              ? DateTime.tryParse(json['created_at']) 
              : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : json['updated_at'] != null 
              ? DateTime.tryParse(json['updated_at']) 
              : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (fullName != null) 'fullName': fullName,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (role != null) 'role': role,
      if (emailVerified != null) 'emailVerified': emailVerified,
      if (phoneVerified != null) 'phoneVerified': phoneVerified,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Copy with method
  AuthUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? role,
    bool? emailVerified,
    bool? phoneVerified,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    if (firstName != null && lastName != null) return '$firstName $lastName'.trim();
    if (firstName != null) return firstName!;
    if (email != null) return email!;
    return 'User';
  }

  /// Sample user for testing
  static AuthUser sample() {
    return AuthUser(
      id: 'user_123',
      email: 'user@example.com',
      fullName: 'John Doe',
      phoneNumber: '+1234567890',
      emailVerified: true,
      avatarUrl: null,
      createdAt: DateTime.now(),
    );
  }
}
