// ignore_for_file: avoid_print

dynamic getVal(Map<String, dynamic> map, String key) {
  for (var entry in map.entries) {
    if (entry.key.toLowerCase() == key.toLowerCase()) {
      return entry.value;
    }
  }
  return null;
}

/// Model representing a single chat message from /api/Chat endpoints.
///
/// Uses case-insensitive key lookup to handle varying JSON casing from
/// different backend languages (C#, Python, etc.).
class ChatMessage {
  final String id;
  final String prescriptionId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final String senderName;

  const ChatMessage({
    required this.id,
    required this.prescriptionId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.senderName,
  });

  /// Parse a [ChatMessage] from a JSON map with case-insensitive key lookup.
  factory ChatMessage.fromJson(Map<dynamic, dynamic> json) {
    final stringKeyMap = Map<String, dynamic>.from(json);
    return ChatMessage(
      id: getVal(stringKeyMap, 'id')?.toString() ?? '',
      prescriptionId: getVal(stringKeyMap, 'prescriptionId')?.toString() ?? '',
      senderId: getVal(stringKeyMap, 'senderId')?.toString() ?? '',
      receiverId: getVal(stringKeyMap, 'receiverId')?.toString() ?? '',
      content: getVal(stringKeyMap, 'content')?.toString() ?? '',
      createdAt: DateTime.tryParse(
            getVal(stringKeyMap, 'createdAt')?.toString() ?? '',
          ) ??
          DateTime.now(),
      senderName: getVal(stringKeyMap, 'senderName')?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prescriptionId': prescriptionId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'senderName': senderName,
      };
}
