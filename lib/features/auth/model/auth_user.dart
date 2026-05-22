/// User authentication model - Compatible with Elaaj API
class AuthUser {
  final String? id;
  final String? email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? role;
  final bool emailVerified;
  final bool phoneVerified;
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
    this.emailVerified = false,
    this.phoneVerified = false,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON - Compatible with Elaaj API response
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    // Handle ID that could be String or int
    String? id;
    final rawId = json['id'] ?? json['userId'];
    if (rawId != null) {
      id = rawId.toString();
    }

    return AuthUser(
      id: id,
      email: json['email'] as String?,
      fullName: json['fullName'] as String? ?? 
                '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? json['phone'] as String?,
      role: json['role'] as String? ?? json['userRole'] as String?,
      emailVerified: _parseBool(json['emailVerified']) || _parseBool(json['is_email_verified']),
      phoneVerified: _parseBool(json['phoneVerified']),
      avatarUrl: json['avatarUrl'] as String? ?? json['imageUrl'] as String? ?? json['avatar_url'] as String?,
      createdAt: _parseDateTime(json['createdAt']) ?? _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt']) ?? _parseDateTime(json['updated_at']),
    );
  }

  /// Helper to parse bool from different types
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true' || value == '1') return true;
      if (value.toLowerCase() == 'false' || value == '0') return false;
    }
    return false;
  }

  /// Helper to parse DateTime from different formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      // Unix timestamp in seconds or milliseconds
      if (value > 9999999999) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
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
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
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
      emailVerified: emailVerified != null ? emailVerified : this.emailVerified,
      phoneVerified: phoneVerified != null ? phoneVerified : this.phoneVerified,
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
