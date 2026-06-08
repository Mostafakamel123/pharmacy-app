// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/features/chat/model/chat_message.dart';
import 'package:Elaaj/features/chat/controller/chat_repository.dart';

// ============================================================================
// STATE
// ============================================================================

abstract class ChatState {
  const ChatState();
}

/// Initial state — screen not yet loaded.
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Loading the first batch of messages on screen open.
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Messages loaded and ready to display.
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;

  /// True while a send-message request is in flight (disables send button).
  final bool isSending;

  const ChatLoaded({
    required this.messages,
    this.isSending = false,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

/// An error state — optionally preserves the previous messages list so the
/// UI doesn't go blank while still surfacing the error via a SnackBar.
class ChatError extends ChatState {
  final String message;
  final List<ChatMessage>? previousMessages;

  const ChatError({
    required this.message,
    this.previousMessages,
  });
}

// ============================================================================
// NOTIFIER PARAMS  (used as the family key)
// ============================================================================

/// Immutable parameter bag passed to the provider family.
class ChatParams {
  final String prescriptionId;
  final String otherUserId;
  final String currentUserId;
  final bool isPharmacy;

  /// Pharmacy's own ID — only needed when [isPharmacy] is true.
  final String? pharmacyId;

  const ChatParams({
    required this.prescriptionId,
    required this.otherUserId,
    required this.currentUserId,
    required this.isPharmacy,
    this.pharmacyId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatParams &&
          prescriptionId == other.prescriptionId &&
          otherUserId == other.otherUserId &&
          currentUserId == other.currentUserId &&
          isPharmacy == other.isPharmacy &&
          pharmacyId == other.pharmacyId;

  @override
  int get hashCode => Object.hash(
        prescriptionId,
        otherUserId,
        currentUserId,
        isPharmacy,
        pharmacyId,
      );
}

// ============================================================================
// NOTIFIER
// ============================================================================

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final ChatParams _params;

  ChatNotifier(this._params, {ChatRepository? repository})
      : _repository = repository ?? ChatRepository(),
        super(const ChatInitial());

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Load full history (called once on screen open — shows spinner).
  Future<void> loadHistory() async {
    emit(const ChatLoading());
    try {
      final messages = await _fetchHistory();
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(message: _clean(e)));
    }
  }

  /// Silent poll — does NOT replace the current state with a spinner.
  /// Only updates the messages list if the fetch succeeds.
  Future<void> pollHistory() async {
    try {
      final messages = await _fetchHistory();
      final sending = state is ChatLoaded ? (state as ChatLoaded).isSending : false;
      emit(ChatLoaded(messages: messages, isSending: sending));
    } catch (e) {
      // Swallow poll errors silently — don't disrupt the UI.
      print('DEBUG ChatNotifier.pollHistory: ${_clean(e)}');
    }
  }

  /// Send a message then immediately reload history.
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final previous = state is ChatLoaded
        ? (state as ChatLoaded).messages
        : <ChatMessage>[];

    // Disable the send button.
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isSending: true));
    }

    try {
      await _repository.sendMessage(
        prescriptionId: _params.prescriptionId,
        senderId: _params.isPharmacy ? (_params.pharmacyId ?? _params.currentUserId) : _params.currentUserId,
        receiverId: _params.otherUserId,
        content: content.trim(),
      );

      // Reload so the new message is reflected immediately.
      final messages = await _fetchHistory();
      emit(ChatLoaded(messages: messages, isSending: false));
    } catch (e) {
      // Re-enable send button and surface error so the screen can show a snackbar.
      emit(ChatLoaded(messages: previous, isSending: false));
      emit(ChatError(message: _clean(e), previousMessages: previous));
      // Immediately restore loaded state so user can retry.
      emit(ChatLoaded(messages: previous, isSending: false));
    }
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  Future<List<ChatMessage>> _fetchHistory() {
    return _repository.getChatHistory(
      prescriptionId: _params.prescriptionId,
      otherUserId: _params.otherUserId,
      pharmacyId: _params.isPharmacy ? _params.pharmacyId : null,
    );
  }

  String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  // ignore: use_setters_to_change_properties
  void emit(ChatState newState) => state = newState;
}

// ============================================================================
// PROVIDER
// ============================================================================

/// Family provider keyed by [ChatParams].
///
/// Usage:
/// ```dart
/// final params = ChatParams(
///   prescriptionId: ...,
///   otherUserId: ...,
///   currentUserId: ...,
///   isPharmacy: ...,
///   pharmacyId: ...,
/// );
/// final notifier = ref.read(chatNotifierProvider(params).notifier);
/// final state    = ref.watch(chatNotifierProvider(params));
/// ```
final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, ChatParams>(
  (ref, params) => ChatNotifier(params),
);
