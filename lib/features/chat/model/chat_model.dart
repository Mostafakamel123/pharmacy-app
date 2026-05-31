import 'chat_user_model.dart';

class ChatModel {
  final String id;
  final ChatUserModel otherUser; // pharmacy or patient
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;
  
  // Prescription context metadata
  final String? prescriptionId;
  final String? prescriptionImage;
  final String? prescriptionNotes;
  final double? prescriptionPrice;

  ChatModel({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isArchived = false,
    this.prescriptionId,
    this.prescriptionImage,
    this.prescriptionNotes,
    this.prescriptionPrice,
  });

  ChatModel copyWith({
    String? id,
    ChatUserModel? otherUser,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isMuted,
    bool? isArchived,
    String? prescriptionId,
    String? prescriptionImage,
    String? prescriptionNotes,
    double? prescriptionPrice,
  }) {
    return ChatModel(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      prescriptionImage: prescriptionImage ?? this.prescriptionImage,
      prescriptionNotes: prescriptionNotes ?? this.prescriptionNotes,
      prescriptionPrice: prescriptionPrice ?? this.prescriptionPrice,
    );
  }

  @override
  String toString() =>
      'ChatModel(id: $id, otherUser: ${otherUser.name}, unreadCount: $unreadCount)';
}
