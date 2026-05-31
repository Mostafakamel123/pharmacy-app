import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/chat_model.dart';
import '../model/chat_user_model.dart';
import '../model/message_model.dart';

// Mock data - Replace with real API calls
class ChatsNotifier extends StateNotifier<AsyncValue<List<ChatModel>>> {
  ChatsNotifier() : super(const AsyncValue.loading()) {
    _initializeChats();
  }

  Future<void> _initializeChats() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));

      final chats = [
        ChatModel(
          id: 'chat_1',
          otherUser: ChatUserModel(
            id: 'cc29f0a9-9676-4949-5e44-08debf09c68b',
            name: 'kamal Pharmacy',
            avatar: '🏥',
            type: 'pharmacy',
            isOnline: true,
          ),
          lastMessage: 'ايه الاخبار دلوقتي',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
          unreadCount: 2,
        ),
        ChatModel(
          id: 'chat_2',
          otherUser: ChatUserModel(
            id: 'd0a4c281-a67b-4011-893c-a93108920199',
            name: 'الدولي ',
            avatar: '💊',
            type: 'pharmacy',
            isOnline: false,
            lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          lastMessage: 'هيتوفر الاسبوع الجاي ',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
          unreadCount: 0,
        ),
        ChatModel(
          id: 'chat_3',
          otherUser: ChatUserModel(
            id: 'pharmacy_3',
            name: 'صيدلية محمد عمر العلء',
            avatar: '⚕️',
            type: 'pharmacy',
            isOnline: true,
          ),
          lastMessage: 'مفيش حاجة تطول العلاقة شوية ',
          lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
          unreadCount: 0,
        ),
      ];

      state = AsyncValue.data(chats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() {
    state = const AsyncValue.loading();
    return _initializeChats();
  }

  void markChatAsRead(String chatId) {
    state.whenData((chats) {
      final updatedChats = chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(unreadCount: 0);
        }
        return chat;
      }).toList();
      state = AsyncValue.data(updatedChats);
    });
  }

  Future<void> deleteChat(String chatId) async {
    state.whenData((chats) {
      final updatedChats = chats.where((chat) => chat.id != chatId).toList();
      state = AsyncValue.data(updatedChats);
    });
  }

  Future<void> muteChat(String chatId) async {
    state.whenData((chats) {
      final updatedChats = chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(isMuted: !chat.isMuted);
        }
        return chat;
      }).toList();
      state = AsyncValue.data(updatedChats);
    });
  }

  Future<void> archiveChat(String chatId) async {
    state.whenData((chats) {
      final updatedChats = chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(isArchived: !chat.isArchived);
        }
        return chat;
      }).toList();
      state = AsyncValue.data(updatedChats);
    });
  }

  void createPrescriptionChat({
    required String chatId,
    required String pharmacyId,
    required String pharmacyName,
    required double price,
    required String message,
    String? prescriptionId,
    String? prescriptionImage,
    String? prescriptionNotes,
  }) {
    state.whenData((chats) {
      final exists = chats.any((c) => c.id == chatId);
      if (exists) return;

      final newChat = ChatModel(
        id: chatId,
        otherUser: ChatUserModel(
          id: pharmacyId,
          name: pharmacyName,
          avatar: '🏥',
          type: 'pharmacy',
          isOnline: true,
        ),
        lastMessage: 'تم قبول العرض: $price EGP - $message',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        prescriptionId: prescriptionId,
        prescriptionImage: prescriptionImage,
        prescriptionNotes: prescriptionNotes,
        prescriptionPrice: price,
      );

      state = AsyncValue.data([newChat, ...chats]);
    });
  }

  void updateLastMessage(String chatId, String message) {
    state.whenData((chats) {
      final updatedChats = chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(
            lastMessage: message,
            lastMessageTime: DateTime.now(),
          );
        }
        return chat;
      }).toList();
      state = AsyncValue.data(updatedChats);
    });
  }
}

final chatsProvider = StateNotifierProvider<ChatsNotifier, AsyncValue<List<ChatModel>>>((ref) {
  return ChatsNotifier();
});

// Search functionality
final chatSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredChatsProvider = FutureProvider<List<ChatModel>>((ref) async {
  final chatsAsyncValue = ref.watch(chatsProvider);
  
  // Extract chats from AsyncValue
  final chats = chatsAsyncValue.maybeWhen(
    data: (chats) => chats,
    orElse: () => <ChatModel>[],
  );
  
  final query = ref.watch(chatSearchQueryProvider);

  if (query.isEmpty) {
    return chats;
  }

  return chats
      .where((chat) => chat.otherUser.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
});

// Current chat messages
class MessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final String chatId;
  final Ref ref;

  MessagesNotifier(this.chatId, this.ref) : super(const AsyncValue.loading()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      List<MessageModel> messages;
      if (chatId.startsWith('chat_historical_') || chatId.startsWith('chat_pres_') || chatId.length > 10) {
        final chatsState = ref.read(chatsProvider).value;
        final currentChat = (chatsState != null && chatsState.any((c) => c.id == chatId))
            ? chatsState.firstWhere((c) => c.id == chatId)
            : null;
        
        if (currentChat != null && currentChat.prescriptionId != null) {
          final price = currentChat.prescriptionPrice ?? 0.0;
          final pharmName = currentChat.otherUser.name;
          messages = [
            MessageModel(
              id: 'msg_welcome_${DateTime.now().millisecondsSinceEpoch}',
              chatId: chatId,
              senderId: currentChat.otherUser.id,
              senderName: pharmName,
              senderAvatar: '🏥',
              content: 'مرحباً بك! شكراً لقبول عرض صيدليتنا بقيمة $price EGP. جاري الآن تجهيز طلبك، وسنتواصل معك هنا بخصوص الشحن والتوصيل.',
              timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
              status: MessageStatus.read,
              isSent: false,
            )
          ];
        } else {
          messages = _getMockMessages(chatId);
        }
      } else {
        messages = _getMockMessages(chatId);
      }
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<MessageModel> _getMockMessages(String chatId) {
    return [
      MessageModel(
        id: 'msg_1',
        chatId: chatId,
        senderId: 'cc29f0a9-9676-4949-5e44-08debf09c68b',
        senderName: 'kamal Pharmacy',
        senderAvatar: '🏥',
        content: 'Hello! How can we assist you today?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
        isSent: false,
      ),
      MessageModel(
        id: 'msg_2',
        chatId: chatId,
        senderId: 'user_1',
        senderName: 'You',
        content: 'عاوز استفسر عن دوا معين',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
        status: MessageStatus.read,
        isSent: true,
      ),
      MessageModel(
        id: 'msg_3',
        chatId: chatId,
        senderId: 'cc29f0a9-9676-4949-5e44-08debf09c68b',
        senderName: 'kamal Pharmacy',
        senderAvatar: '🏥',
        content: 'قول يصاحبي',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
        status: MessageStatus.read,
        isSent: false,
      ),
      MessageModel(
        id: 'msg_4',
        chatId: chatId,
        senderId: 'user_1',
        senderName: 'You',
        content: 'فياجرا',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        status: MessageStatus.read,
        isSent: true,
      ),
      MessageModel(
        id: 'msg_5',
        chatId: chatId,
        senderId: 'cc29f0a9-9676-4949-5e44-08debf09c68b',
        senderName: 'kamal Pharmacy',
        senderAvatar: '🏥',
        content: 'فاجرة',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: MessageStatus.read,
        isSent: false,
      ),
    ];
  }

  Future<void> sendMessage(String content, {MessageType type = MessageType.text}) async {
    try {
      final newMessage = MessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        senderId: 'user_1',
        senderName: 'You',
        content: content,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        isSent: true,
        type: type,
      );

      state.whenData((messages) {
        state = AsyncValue.data([...messages, newMessage]);
      });

      // Update last message in Chats list dynamically!
      ref.read(chatsProvider.notifier).updateLastMessage(chatId, content);

      // Simulate sending
      await Future.delayed(const Duration(milliseconds: 500));

      state.whenData((messages) {
        final updatedMessages = messages.map((msg) {
          if (msg.id == newMessage.id) {
            return msg.copyWith(status: MessageStatus.sent);
          }
          return msg;
        }).toList();
        state = AsyncValue.data(updatedMessages);
      });

      // Simulate delivery after 1 second
      await Future.delayed(const Duration(milliseconds: 500));

      state.whenData((messages) {
        final updatedMessages = messages.map((msg) {
          if (msg.id == newMessage.id) {
            return msg.copyWith(status: MessageStatus.delivered);
          }
          return msg;
        }).toList();
        state = AsyncValue.data(updatedMessages);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadOlderMessages() async {
    try {
      // Implement pagination
      await Future.delayed(const Duration(milliseconds: 800));
      // Add older messages
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final chatMessagesProvider =
    StateNotifierProvider.family<MessagesNotifier, AsyncValue<List<MessageModel>>, String>(
  (ref, chatId) => MessagesNotifier(chatId, ref),
);

// Current chat user
final currentChatUserProvider = Provider.family<AsyncValue<ChatUserModel>, String>((ref, chatId) {
  final chatsAsyncValue = ref.watch(chatsProvider);
  
  return chatsAsyncValue.whenData((chats) {
    try {
      final chat = chats.firstWhere((c) => c.id == chatId);
      return chat.otherUser;
    } catch (e) {
      throw Exception('Chat with ID $chatId not found');
    }
  });
});

// Message input state
final messageInputProvider = StateProvider<String>((ref) => '');

// Typing indicator
final isUserTypingProvider = StateProvider<bool>((ref) => false);

// Real-time typing status
final otherUserTypingProvider = StateProvider.family<bool, String>((ref, chatId) => false);
