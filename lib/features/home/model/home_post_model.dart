import 'package:Elaaj/features/posts/model/post_model.dart';

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
    return formatTimeAgoArabic(dateTime, includePublishedPrefix: true);
  }

}
