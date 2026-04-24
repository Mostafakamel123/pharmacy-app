
enum MessageType { text, image, voice }

enum MessageStatus { sending, sent, delivered, read }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? imageUrl;
  final String? voiceUrl;
  final int? duration; // for voice messages
  final bool isSent;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.imageUrl,
    this.voiceUrl,
    this.duration,
    required this.isSent,
  });

  // CopyWith for immutable updates
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? imageUrl,
    String? voiceUrl,
    int? duration,
    bool? isSent,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      duration: duration ?? this.duration,
      isSent: isSent ?? this.isSent,
    );
  }

  @override
  String toString() => 'MessageModel(id: $id, content: $content, status: $status)';
}
