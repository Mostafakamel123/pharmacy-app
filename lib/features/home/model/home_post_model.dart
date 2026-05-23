class HomePostModel {
  final String id;
  final String question;
  final String preview;
  final String pharmacyName;
  final int replyCount;
  final String timeAgo;
  final bool hasResponse;
  final String? attachmentUrl;
  final DateTime createdAt;

  const HomePostModel({
    required this.id,
    required this.question,
    required this.preview,
    required this.pharmacyName,
    required this.replyCount,
    required this.timeAgo,
    this.hasResponse = false,
    this.attachmentUrl,
    required this.createdAt,
  });

  // Factory constructor to create from JSON (API response)
  factory HomePostModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    DateTime createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }

    return HomePostModel(
      id: json['id'] as String? ?? '',
      question: json['content'] as String? ?? json['question'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      pharmacyName: json['pharmacyName'] as String? ?? 
                    json['pharmacy_name'] as String? ?? 
                    json['userName'] as String? ?? 'Pharmacy',
      replyCount: json['replyCount'] as int? ?? 
                  json['reply_count'] as int? ?? 
                  0,
      timeAgo: _calculateTimeAgo(createdAt),
      hasResponse: json['hasResponse'] as bool? ?? 
                   json['has_response'] as bool? ?? 
                   (json['replyCount'] as int? ?? 0) > 0,
      attachmentUrl: json['attachmentUrl'] as String? ?? 
                     json['attachment_url'] as String? ?? 
                     json['imageUrl'] as String?,
      createdAt: createdAt,
    );
  }

  static String _calculateTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  static List<HomePostModel> sample() {
    return [
      HomePostModel(
        id: '1',
        question: 'What is the alternative for Panadol?',
        preview: 'I need a substitute for Panadol that is safe for...',
        pharmacyName: 'صيدلية الدولييي',
        replyCount: 3,
        timeAgo: '2h',
        hasResponse: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      HomePostModel(
        id: '2',
        question: 'Best vitamin D supplement?',
        preview: 'Can you recommend a good vitamin D supplement with...',
        pharmacyName: 'صيدلية الدولييي',
        replyCount: 5,
        timeAgo: '5h',
        hasResponse: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
       HomePostModel(
        id: '3',
        question: 'Is Amoxicillin available nearby?',
        preview: 'Looking for Amoxicillin 500mg, any pharmacy have it...',
        pharmacyName: 'صيدلية الدولييي',
        replyCount: 1,
        timeAgo: '1d',
        hasResponse: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
       HomePostModel(
        id: '4',
        question: 'Baby skincare recommendations',
        preview: 'Need recommendations for baby skincare products...',
        pharmacyName: 'صيدلية الدولييي',
        replyCount: 7,
        timeAgo: '2d',
        hasResponse: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
