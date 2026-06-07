dynamic getVal(Map<String, dynamic> map, String key) {
  for (var entry in map.entries) {
    if (entry.key.toLowerCase() == key.toLowerCase()) {
      return entry.value;
    }
  }
  return null;
}

class Prescription {
  final String id;
  final String? imageUrl;
  final String? notes;
  final DateTime createdAt;
  final bool isResolved;
  final int status;
  final List<dynamic> replies;

  Prescription({
    required this.id,
    this.imageUrl,
    this.notes,
    required this.createdAt,
    required this.isResolved,
    required this.status,
    required this.replies,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = getVal(json, 'createdAt');
    
    // Support all possible keys returned by the backend for replies/offers
    final rawReplies = getVal(json, 'replies') ?? 
                       getVal(json, 'offers') ?? 
                       getVal(json, 'prescriptionReplies');
                       
    return Prescription(
      id: getVal(json, 'id')?.toString() ?? '',
      imageUrl: getVal(json, 'imageUrl')?.toString(),
      notes: getVal(json, 'notes')?.toString() ?? 
             getVal(json, 'textContent')?.toString() ?? 
             getVal(json, 'description')?.toString(),
      createdAt: rawCreatedAt != null ? (DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now()) : DateTime.now(),
      isResolved: getVal(json, 'isResolved') as bool? ?? false,
      status: (getVal(json, 'status') as num?)?.toInt() ?? 0,
      replies: rawReplies is List ? rawReplies : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved,
      'status': status,
      'replies': replies,
    };
  }
}
