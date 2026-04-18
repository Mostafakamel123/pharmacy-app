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
