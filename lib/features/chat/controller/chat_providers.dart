// ignore_for_file: avoid_print, unused_element

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/chat_model.dart';
import '../model/chat_user_model.dart';
import '../model/message_model.dart';
import '../model/chat_message.dart';
import 'chat_notifier.dart';
import 'chat_repository.dart';
import 'package:Elaaj/core/network/api_endpoints.dart';
import 'package:Elaaj/features/auth/controller/auth_providers.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:Elaaj/features/prescription/controller/patient_prescription_providers.dart';

/// Provider for chat history (typed using ChatMessage and ChatParams)
final chatHistoryProvider = FutureProvider.family<List<ChatMessage>, ChatParams>((ref, params) async {
  final repository = ChatRepository();
  return repository.getChatHistory(
    prescriptionId: params.prescriptionId,
    otherUserId: params.otherUserId,
    pharmacyId: params.isPharmacy ? params.pharmacyId : null,
  );
});

// Mock data - Replace with real API calls
class ChatsNotifier extends StateNotifier<AsyncValue<List<ChatModel>>> {
  final Ref ref;

  ChatsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initializeChats();
  }

  Future<void> _initializeChats() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 200));

      final isPharmacy = ref.read(isPharmacyModeProvider);
      final List<ChatModel> activePrescriptionChats = [];

      // 1. Scan and dynamically load accepted/completed chats from real backend API!
      try {
        final api = ApiEndpoints();
        final List<dynamic> allPrescriptions = await api.getMyPrescriptions(pageSize: 100);
        
        for (var p in allPrescriptions) {
          if (p is! Map) continue;

          final id = p['id']?.toString() ?? '';
          final statusVal = (p['status'] as num?)?.toInt() ?? 0;
          final repliesRaw = p['replies'] ?? p['offers'] ?? p['prescriptionReplies'] ?? [];
          final List<dynamic> replies = repliesRaw is List ? repliesRaw : [];

          // Chats are for status 2 (Accepted/Preparing) or 3 (Completed/Ready)
          if (statusVal == 2 || statusVal == 3) {
            // Find the accepted reply/offer
            final acceptedReply = replies.firstWhere((r) => r is Map, orElse: () => null);
            if (acceptedReply != null) {
              final rPharmacyId = acceptedReply['pharmacyId']?.toString() ?? 'pharm_001';
              final rPharmacyName = acceptedReply['pharmacyName']?.toString() ?? 'Pharmacy';
              final double rPrice = (acceptedReply['totalPrice'] as num?)?.toDouble() ?? 0.0;
              final rMsg = acceptedReply['message']?.toString() ?? '';

              // Find the last reply to show as the lastMessage in chats list
              var lastMsgText = 'تم قبول العرض: $rPrice EGP - $rMsg';
              var lastMsgTime = DateTime.tryParse(p['createdAt']?.toString() ?? '') ?? DateTime.now();

              if (replies.isNotEmpty) {
                final lastReply = replies.lastWhere((r) => r is Map, orElse: () => null);
                if (lastReply != null) {
                  var rawText = lastReply['message']?.toString() ?? '';
                  // strip prefix
                  if (rawText.startsWith('[PATIENT] ')) {
                    rawText = rawText.substring('[PATIENT] '.length);
                  } else if (rawText.startsWith('[PHARMACY] ')) {
                    rawText = rawText.substring('[PHARMACY] '.length);
                  }
                  lastMsgText = rawText;
                  lastMsgTime = DateTime.tryParse(lastReply['createdAt']?.toString() ?? '') ?? lastMsgTime;
                }
              }

              final String resolvedPatientId = (p['patientId'] ?? p['userId'] ?? acceptedReply['patientId'] ?? 'patient_123').toString();

              activePrescriptionChats.add(
                ChatModel(
                  id: 'chat_historical_$id',
                  otherUser: ChatUserModel(
                    id: isPharmacy ? resolvedPatientId : rPharmacyId,
                    name: isPharmacy ? 'Customer / زبون' : rPharmacyName,
                    avatar: isPharmacy ? '👤' : '🏥',
                    type: isPharmacy ? 'patient' : 'pharmacy',
                    isOnline: true,
                  ),
                  lastMessage: lastMsgText,
                  lastMessageTime: lastMsgTime,
                  unreadCount: 0,
                  prescriptionId: id,
                  prescriptionImage: p['imageUrl']?.toString(),
                  prescriptionNotes: p['notes']?.toString(),
                  prescriptionPrice: rPrice,
                ),
              );
            }
          }
        }
      } catch (e) {
        print('DEBUG: Error scanning prescriptions for chats: $e');
      }

      // De-duplicate chats by ID
      final seenIds = <String>{};
      final uniqueChats = <ChatModel>[];
      for (var chat in activePrescriptionChats) {
        if (!seenIds.contains(chat.id)) {
          seenIds.add(chat.id);
          uniqueChats.add(chat);
        }
      }

      state = AsyncValue.data(uniqueChats);
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

// USER-SCOPED: auto-resets when auth user changes.
final chatsProvider = StateNotifierProvider<ChatsNotifier, AsyncValue<List<ChatModel>>>((ref) {
  ref.watch(authProvider.select((s) => '${s.isAuthenticated}_${s.user?.id ?? 'none'}'));
  return ChatsNotifier(ref);
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

  String? _getPrescriptionId() {
    if (chatId.startsWith('chat_historical_')) {
      return chatId.substring('chat_historical_'.length);
    }
    if (chatId.startsWith('chat_pres_')) {
      return chatId.substring('chat_pres_'.length);
    }
    if (chatId.startsWith('chat_')) {
      final suffix = chatId.substring(5);
      if (RegExp(r'^\d+$').hasMatch(suffix)) {
        return null;
      }
      return suffix;
    }
    return null;
  }

  Future<void> _loadMessages() async {
    try {
      final presId = _getPrescriptionId();
      if (presId != null) {
        print('⚡ ELAAJ CHAT: Resolving prescription chat for prescriptionId: "$presId"');
        final api = ApiEndpoints();
        final isPharmacy = ref.read(isPharmacyModeProvider);
        
        Map<String, dynamic>? presData;
        try {
          presData = await api.getPrescriptionById(id: presId);
        } catch (e) {
          print('DEBUG: Error calling getPrescriptionById from chat: $e. Falling back to history list.');
          final historyList = ref.read(patientPrescriptionsProvider).value ?? [];
          final matched = historyList.firstWhere(
            (p) {
              if (p is! Map) return false;
              final idStr = (p['id'] ?? p['prescriptionId'])?.toString().toLowerCase();
              return idStr == presId.toLowerCase();
            },
            orElse: () => null,
          );
          if (matched is Map) {
            presData = Map<String, dynamic>.from(matched);
          }
        }

        if (presData != null && presData.isNotEmpty) {
          final repliesRaw = presData['replies'] ?? presData['offers'] ?? presData['prescriptionReplies'] ?? [];
          final List<dynamic> replies = repliesRaw is List ? repliesRaw : [];
          
          print('⚡ ELAAJ CHAT: Parsed replies list length: ${replies.length}');

          final acceptedReply = replies.firstWhere((r) => r is Map, orElse: () => null);
          if (acceptedReply != null) {
            final pId = acceptedReply['pharmacyId']?.toString() ?? 'pharm_001';
            final pName = acceptedReply['pharmacyName']?.toString() ?? 'Pharmacy';
            final price = (acceptedReply['totalPrice'] as num?)?.toDouble() ?? 0.0;
            final msg = acceptedReply['message']?.toString() ?? '';

            Future.microtask(() {
              ref.read(chatsProvider.notifier).createPrescriptionChat(
                chatId: chatId,
                pharmacyId: pId,
                pharmacyName: pName,
                price: price,
                message: msg,
                prescriptionId: presId,
                prescriptionImage: presData?['imageUrl']?.toString(),
                prescriptionNotes: presData?['notes']?.toString(),
              );
            });
          }

          final List<MessageModel> parsedMessages = [];
          for (int i = 0; i < replies.length; i++) {
            final r = replies[i];
            if (r is! Map) continue;

            final rId = r['id']?.toString() ?? 'reply_msg_$i';
            final rMsg = r['message']?.toString() ?? '';
            final rPharmacyId = r['pharmacyId']?.toString() ?? 'pharm_001';
            final rPharmacyName = r['pharmacyName']?.toString() ?? 'Pharmacy';
            final rCreatedAt = DateTime.tryParse(r['createdAt']?.toString() ?? '') ?? DateTime.now();

            bool isFromPatient = false;
            bool isFromPharmacy = false;

            if (rMsg.startsWith('[PATIENT] ')) {
              isFromPatient = true;
            } else if (rMsg.startsWith('[PHARMACY] ')) {
              isFromPharmacy = true;
            } else {
              isFromPharmacy = true;
            }

            String content = rMsg;
            if (content.startsWith('[PATIENT] ')) {
              content = content.substring('[PATIENT] '.length);
            } else if (content.startsWith('[PHARMACY] ')) {
              content = content.substring('[PHARMACY] '.length);
            }

            bool isSentByMe = false;
            if (isPharmacy) {
              isSentByMe = isFromPharmacy && !rMsg.startsWith('[PATIENT] ');
            } else {
              isSentByMe = isFromPatient;
            }

            parsedMessages.add(
              MessageModel(
                id: rId,
                chatId: chatId,
                senderId: isFromPatient ? 'patient' : rPharmacyId,
                senderName: isFromPatient ? (isPharmacy ? 'Patient' : 'You') : (isPharmacy ? 'You' : rPharmacyName),
                senderAvatar: isFromPatient ? '👤' : '🏥',
                content: content,
                timestamp: rCreatedAt,
                status: MessageStatus.read,
                isSent: isSentByMe,
              ),
            );
          }

          parsedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          state = AsyncValue.data(parsedMessages);
          return;
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));
      state = const AsyncValue.data([]);
    } catch (e, st) {
      print('DEBUG: Error in _loadMessages: $e');
      state = AsyncValue.error(e, st);
    }
  }

  List<MessageModel> _getMockMessages(String chatId) {
    return [];
  }

  Future<void> sendMessage(String content, {MessageType type = MessageType.text}) async {
    try {
      final presId = _getPrescriptionId();
      final isPharmacy = ref.read(isPharmacyModeProvider);

      if (presId != null) {
        final tempMessage = MessageModel(
          id: 'temp_msg_${DateTime.now().millisecondsSinceEpoch}',
          chatId: chatId,
          senderId: isPharmacy ? 'pharmacy' : 'patient',
          senderName: 'You',
          content: content,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
          isSent: true,
          type: type,
        );

        state.whenData((messages) {
          state = AsyncValue.data([...messages, tempMessage]);
        });

        ref.read(chatsProvider.notifier).updateLastMessage(chatId, content);

        String? pharmacyId;
        final chatsState = ref.read(chatsProvider).value;
        final currentChat = (chatsState != null && chatsState.any((c) => c.id == chatId))
            ? chatsState.firstWhere((c) => c.id == chatId)
            : null;

        if (isPharmacy) {
          pharmacyId = ref.read(pharmacyModeProvider).currentPharmacy?.id ?? currentChat?.otherUser.id;
        } else {
          pharmacyId = currentChat?.otherUser.id;
        }

        if (pharmacyId == null) {
          try {
            final api = ApiEndpoints();
            final presData = await api.getPrescriptionById(id: presId);
            final rawReplies = presData['replies'] ?? presData['offers'] ?? [];
            if (rawReplies is List && rawReplies.isNotEmpty) {
              final firstReply = rawReplies.firstWhere((r) => r is Map && r['pharmacyId'] != null, orElse: () => null);
              if (firstReply != null) {
                pharmacyId = firstReply['pharmacyId']?.toString();
              }
            }
          } catch (e) {
            print('DEBUG: Error resolving pharmacyId in sendMessage: $e');
          }
        }

        final String finalPharmId = pharmacyId ?? 'pharm_001';
        final String prefixedMsg = isPharmacy ? '[PHARMACY] $content' : '[PATIENT] $content';

        final api = ApiEndpoints();
        await api.replyToPrescription(
          prescriptionId: presId,
          pharmacyId: finalPharmId,
          message: prefixedMsg,
          totalPrice: 0.0,
          isAvailable: true,
        );

        await _loadMessages();
      } else {
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

        ref.read(chatsProvider.notifier).updateLastMessage(chatId, content);

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
      }
    } catch (e, st) {
      print('DEBUG: Error sending chat message: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadOlderMessages() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
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
