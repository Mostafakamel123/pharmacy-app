// ignore_for_file: use_super_parameters, unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controller/chat_providers.dart';
import '../widgets/chat_widgets.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_area.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String? pharmacyName;

  const ChatConversationScreen({
    Key? key,
    required this.chatId,
    this.pharmacyName,
  }) : super(key: key);

  @override
  ConsumerState<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen> {
  late ScrollController _scrollController;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Mark chat as read when opened
    Future.microtask(() {
      ref.read(chatsProvider.notifier).markChatAsRead(widget.chatId);
    });
  }

  @override
  void didUpdateWidget(ChatConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      ref.read(chatsProvider.notifier).markChatAsRead(widget.chatId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final chatUserAsync = ref.watch(currentChatUserProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: chatUserAsync.when(
          data: (user) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.isOnline ? 'Online' : 'Offline',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: user.isOnline
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          loading: () => Shimmer.fromColors(
            baseColor: Colors.grey[400]!,
            highlightColor: Colors.grey[300]!,
            child: Container(
              height: 40,
              width: 150,
              color: Colors.grey,
            ),
          ),
          error: (error, stack) => Text(widget.pharmacyName ?? 'Chat'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: const Color(0xFF0EA5E9),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call feature coming soon')),
              );
            },
            icon: const Icon(Icons.call),
            color: const Color(0xFF0EA5E9),
            tooltip: 'Voice call',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            iconColor: const Color(0xFF0EA5E9),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat info coming soon')),
                  );
                  break;
                case 'block':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Block user coming soon')),
                  );
                  break;
                case 'report':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report feature coming soon')),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'info',
                child: Text('View info'),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text('Block user'),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.length != _lastMessageCount) {
                    final isNewMessage = messages.length > _lastMessageCount;
                    _lastMessageCount = messages.length;
                    if (isNewMessage) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });
                    }
                  }

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation now',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length + 1,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Center(
                            child: ref.watch(otherUserTypingProvider(widget.chatId))
                                ? TypingIndicator()
                                : const SizedBox.shrink(),
                          ),
                        );
                      }

                      final message = messages[index];
                      return MessageBubble(
                        message: message,
                        isCurrentUser: message.isSent,
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Loading messages...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text('Error loading messages'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.refresh(chatMessagesProvider(widget.chatId));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            MessageInputArea(
              chatId: widget.chatId,
              onMessageSent: _scrollToBottom,
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer effect for loading state
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const Shimmer({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 1),
    required this.baseColor,
    required this.highlightColor,
  }) : super(key: key);

  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  factory Shimmer.fromColors({
    Key? key,
    required Widget child,
    required Color baseColor,
    required Color highlightColor,
    Duration duration = const Duration(seconds: 1),
  }) {
    return Shimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
      child: child,
    );
  }

  @override
  State<Shimmer> createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.lighten,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0),
              end: Alignment(1.0 - _controller.value * 2, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
