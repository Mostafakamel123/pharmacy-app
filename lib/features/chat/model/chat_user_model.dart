class ChatUserModel {
  final String id;
  final String name;
  final String? avatar;
  final String? type; // 'pharmacy' or 'patient'
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUserModel({
    required this.id,
    required this.name,
    this.avatar,
    this.type,
    this.isOnline = false,
    this.lastSeen,
  });

  ChatUserModel copyWith({
    String? id,
    String? name,
    String? avatar,
    String? type,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ChatUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      type: type ?? this.type,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  String toString() => 'ChatUserModel(id: $id, name: $name, isOnline: $isOnline)';
}
