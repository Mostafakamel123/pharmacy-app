import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/services/websocket_chat_service.dart';

/// Singleton WebSocket service provider
final webSocketChatServiceProvider = Provider<WebSocketChatService>((ref) {
  final service = WebSocketChatService();
  
  // Cleanup on dispose
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Listen to WebSocket events for a specific chat
final chatSocketEventsProvider = StreamProvider.family<ChatSocketEvent, String>((ref, chatId) {
  final service = ref.watch(webSocketChatServiceProvider);
  return service.events.where((event) => event.chatId == chatId);
});

/// Listen to connection status for a specific chat
final chatConnectionStatusProvider = StreamProvider.family<ConnectionStatusChange, String>((ref, chatId) {
  final service = ref.watch(webSocketChatServiceProvider);
  return service.getConnectionStatus(chatId);
});

/// Connect to a chat room
class ChatConnectionNotifier extends StateNotifier<AsyncValue<void>> {
  final WebSocketChatService _service;
  final String chatId;
  final String userId;

  ChatConnectionNotifier({
    required WebSocketChatService service,
    required this.chatId,
    required this.userId,
  })  : _service = service,
        super(const AsyncValue.data(null));

  Future<void> connect() async {
    state = const AsyncValue.loading();
    try {
      await _service.connectToChat(chatId, userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> disconnect() async {
    await _service.disconnectFromChat(chatId);
    state = const AsyncValue.data(null);
  }
}

final chatConnectionProvider = StateNotifierProvider.family<
    ChatConnectionNotifier,
    AsyncValue<void>,
    ({String chatId, String userId})>((ref, params) {
  final service = ref.watch(webSocketChatServiceProvider);
  return ChatConnectionNotifier(
    service: service,
    chatId: params.chatId,
    userId: params.userId,
  );
});
