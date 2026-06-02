class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? location;
  final String? avatarUrl;
  final double? latitude;
  final double? longitude;
  final String? dateOfBirth;
  final int postsCount;
  final int repliesCount;
  final int savedCount;
  final double completionPercentage;
  final DateTime joinDate;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.location,
    this.avatarUrl,
    this.latitude,
    this.longitude,
    this.dateOfBirth,
    this.postsCount = 0,
    this.repliesCount = 0,
    this.savedCount = 0,
    this.completionPercentage = 0,
    required this.joinDate,
  });

  String get initials {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String get joinDateFormatted {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[joinDate.month - 1]} ${joinDate.year}';
  }

  /// Create from API response (Elaaj API)
  factory UserProfileModel.fromApi(Map<String, dynamic> json) {
    final name = json['fullName'] as String? ?? 
            '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();
    final cleanName = name.isEmpty ? 'User' : name;
    final email = json['email'] as String? ?? '';
    final address = json['address'] as String? ?? json['location'] as String?;
    final dob = json['dateOfBirth'] as String?;
    
    // Dynamic completion percentage calculation
    double score = 0;
    if (cleanName != 'User' && cleanName.isNotEmpty) score += 0.3;
    if (email.isNotEmpty) score += 0.3;
    if (address != null && address.isNotEmpty) score += 0.2;
    if (dob != null && dob.isNotEmpty) score += 0.2;

    return UserProfileModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? 'unknown',
      name: cleanName,
      email: email,
      phone: json['phoneNumber'] as String? ?? json['phone'] as String? ?? '',
      location: address,
      avatarUrl: json['imageUrl'] as String? ?? json['avatarUrl'] as String?,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      dateOfBirth: dob,
      postsCount: 0, 
      repliesCount: 0,
      savedCount: 0,
      completionPercentage: score,
      joinDate: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
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

  static UserProfileModel sample() {
    return UserProfileModel(
      id: 'u1',
      name: 'Mostafa Kamel',
      email: 'mostafa.k@email.com',
      phone: '+20 101 234 5678',
      location: 'Mohandessin, Giza',
      latitude: 27.189,
      longitude: 31.1954,
      dateOfBirth: '2000-01-01',
      postsCount: 12,
      repliesCount: 8,
      savedCount: 5,
      completionPercentage: 1.0,
      joinDate: DateTime(2024, 6),
    );
  }
}

enum ProfileMenuItem {
  myPosts('My Posts', 'View your medical inquiries'),
  savedPosts('Saved Posts', 'Bookmarked prescriptions'),
  notifications('Notifications', 'Manage notification preferences'),
  language('Language', 'Choose your preferred language'),
  security('Security', 'Password and account security'),
  help('Help & Support', 'Get help or contact support'),
  about('About Elaaj', 'Learn more about the app');

  final String title;
  final String subtitle;
  const ProfileMenuItem(this.title, this.subtitle);
}
