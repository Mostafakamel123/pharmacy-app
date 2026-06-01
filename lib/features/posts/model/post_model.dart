enum PostCategory {
  general('General'),
  prescription('Prescription'),
  emergency('Emergency'),
  advice('Advice');

  final String label;
  const PostCategory(this.label);
}

enum PostStatus { open, replied, closed }

/// Helper to build full image URL from relative path
String? buildImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  final cleanPath = path.startsWith('/') ? path : '/$path';
  return "http://elaaj.runasp.net$cleanPath";
}

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final PostCategory category;
  final String? imageUrl;
  final int replyCount;
  final bool isBookmarked;
  final PostStatus status;
  final DateTime createdAt;
  final List<ReplyModel> replies;

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    this.category = PostCategory.general,
    this.imageUrl,
    this.replyCount = 0,
    this.isBookmarked = false,
    this.status = PostStatus.open,
    required this.createdAt,
    this.replies = const [],
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['replies'] as List? ?? [];
    final repliesList = repliesJson
        .map((r) => ReplyModel.fromJson(r as Map<String, dynamic>))
        .toList();

    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    DateTime createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }

    // Map Category (if present in API, map it, else default to general)
    PostCategory cat = PostCategory.general;
    final catRaw = json['category'] ?? json['post_category'];
    if (catRaw is String) {
      for (var value in PostCategory.values) {
        if (value.name.toLowerCase() == catRaw.toLowerCase() ||
            value.label.toLowerCase() == catRaw.toLowerCase()) {
          cat = value;
          break;
        }
      }
    }

    return PostModel(
      id: (json['id'] ?? json['postId'] ?? '').toString(),
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? json['userFullName'] as String? ?? 'Patient',
      content: json['content'] as String? ?? '',
      category: cat,
      imageUrl: buildImageUrl(json['imageUrl'] as String? ?? json['imagePath'] as String?),
      replyCount: repliesList.length,
      isBookmarked: false, // will be handled by Riverpod provider
      status: repliesList.isNotEmpty ? PostStatus.replied : PostStatus.open,
      createdAt: createdAt,
      replies: repliesList,
    );
  }

  static List<PostModel> sample() {
    return [
      PostModel(
        id: '1',
        userId: 'u1',
        userName: 'Mostafa A.',
        content:
            'Looking for an alternative to Panadol that is safe for stomach ulcers. I have chronic pain but Panadol irritates my stomach. Any suggestions from pharmacists?',
        category: PostCategory.advice,
        replyCount: 3,
        status: PostStatus.replied,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      PostModel(
        id: '2',
        userId: 'u2',
        userName: 'Sara M.',
        content:
            'Need this prescription filled urgently. Doctor prescribed Amoxicillin 500mg for 7 days. Any nearby pharmacy have it in stock?',
        category: PostCategory.prescription,
        imageUrl: 'prescription_1',
        replyCount: 5,
        status: PostStatus.replied,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }
}

class ReplyModel {
  final String id;
  final String postId;
  final String pharmacyId;
  final String pharmacyName;
  final bool isVerified;
  final String content;
  final double? price;
  final String? medicineName;
  final bool isAvailable;
  final bool isBestReply;
  final DateTime createdAt;

  const ReplyModel({
    required this.id,
    required this.postId,
    required this.pharmacyId,
    required this.pharmacyName,
    this.isVerified = true,
    required this.content,
    this.price,
    this.medicineName,
    this.isAvailable = true,
    this.isBestReply = false,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    DateTime createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }

    return ReplyModel(
      id: (json['id'] ?? json['replyId'] ?? '').toString(),
      postId: (json['postId'] ?? '').toString(),
      pharmacyId: json['pharmacyId'] as String? ?? '',
      pharmacyName: json['pharmacyName'] as String? ?? 'Pharmacy',
      isVerified: json['isVerified'] as bool? ?? true,
      content: json['message'] as String? ?? json['content'] as String? ?? '',
      price: (json['price'] ?? json['totalPrice'] ?? 0.0) as double?,
      medicineName: json['medicineName'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isBestReply: json['isBestReply'] as bool? ?? false,
      createdAt: createdAt,
    );
  }

  static List<ReplyModel> sampleForPost(String postId) {
    return [
      ReplyModel(
        id: 'r1',
        postId: postId,
        pharmacyId: 'p1',
        pharmacyName: 'El-Ezaby Pharmacy',
        content:
            'We have Panadol Extra which is gentler on the stomach. Also available is Voltaren 50mg as an alternative. Both are in stock.',
        price: 35.0,
        medicineName: 'Panadol Extra',
        isAvailable: true,
        isBestReply: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }
}
