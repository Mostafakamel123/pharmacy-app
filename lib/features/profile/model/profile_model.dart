class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? location;
  final String? avatarUrl;
  final String role;
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
    this.role = 'Patient',
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

  static UserProfileModel sample() {
    return UserProfileModel(
      id: 'u1',
      name: 'Mostafa Kamel',
      email: 'mostafa.k@email.com',
      phone: '+20 101 234 5678',
      location: 'Mohandessin, Giza',
      role: 'Patient',
      postsCount: 12,
      repliesCount: 8,
      savedCount: 5,
      completionPercentage: 85,
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
