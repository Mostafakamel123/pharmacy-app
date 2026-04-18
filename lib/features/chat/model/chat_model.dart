import 'chat_user_model.dart';

class ChatModel {
  final String id;
  final ChatUserModel otherUser; // pharmacy or patient
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;

  ChatModel({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isArchived = false,
  });

  ChatModel copyWith({
    String? id,
    ChatUserModel? otherUser,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isMuted,
    bool? isArchived,
  }) {
    return ChatModel(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  String toString() =>
      'ChatModel(id: $id, otherUser: ${otherUser.name}, unreadCount: $unreadCount)';
}
