class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? location;
  final String? avatarUrl;
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
    this.postsCount = 0,
    this.repliesCount = 0,
    this.savedCount = 0,
    this.completionPercentage = 0,
    required this.joinDate,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
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
    return UserProfileModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? 'unknown',
      name: json['fullName'] as String? ?? 
            '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim() ?? 'User',
      email: json['email'] as String? ?? '',
      phone: json['phoneNumber'] as String? ?? json['phone'] as String? ?? '',
      location: json['address'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['imageUrl'] as String?,
      postsCount: 0, // Can be extended with actual data
      repliesCount: 0,
      savedCount: 0,
      completionPercentage: 0, // Will be calculated
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
      postsCount: 12,
      repliesCount: 8,
      savedCount: 5,
      completionPercentage: 100,
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
