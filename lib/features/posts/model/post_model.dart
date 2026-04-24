enum PostCategory {
  general('General'),
  prescription('Prescription'),
  emergency('Emergency'),
  advice('Advice');

  final String label;
  const PostCategory(this.label);
}

enum PostStatus { open, replied, closed }

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

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.category,
    this.imageUrl,
    this.replyCount = 0,
    this.isBookmarked = false,
    this.status = PostStatus.open,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
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
      PostModel(
        id: '3',
        userId: 'u3',
        userName: 'Ahmed K.',
        content:
            'What is the best vitamin D supplement available in Egyptian pharmacies? My doctor recommended 5000 IU daily.',
        category: PostCategory.general,
        replyCount: 1,
        status: PostStatus.open,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      PostModel(
        id: '4',
        userId: 'u4',
        userName: 'Nour H.',
        content:
            'Emergency: Need insulin injection (NovoRapid) right now. Anyone knows which nearby pharmacy is open and has it?',
        category: PostCategory.emergency,
        replyCount: 7,
        status: PostStatus.replied,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PostModel(
        id: '5',
        userId: 'u5',
        userName: 'Youssef T.',
        content:
            'Can someone recommend a good baby skincare routine? Looking for gentle products available at local pharmacies.',
        category: PostCategory.advice,
        replyCount: 0,
        status: PostStatus.open,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
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
      ReplyModel(
        id: 'r2',
        postId: postId,
        pharmacyId: 'p2',
        pharmacyName: 'Seif Pharmacy',
        content:
            'We have Brufen 400mg available. It is also effective for pain relief. Price is affordable.',
        price: 22.0,
        medicineName: 'Brufen 400mg',
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ReplyModel(
        id: 'r3',
        postId: postId,
        pharmacyId: 'p3',
        pharmacyName: 'Dr. Ragab Pharmacy',
        content:
            'Available: Cataflam 50mg - good for pain and anti-inflammatory. We also have stomach protection tablets if needed.',
        price: 45.0,
        medicineName: 'Cataflam 50mg',
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }
}
