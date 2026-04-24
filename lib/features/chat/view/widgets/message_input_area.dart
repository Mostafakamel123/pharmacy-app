// ignore_for_file: prefer_final_fields, unused_field

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controller/chat_providers.dart';

class MessageInputArea extends ConsumerStatefulWidget {
  final String chatId;
  final VoidCallback? onMessageSent;

  const MessageInputArea({
    Key? key,
    required this.chatId,
    this.onMessageSent,
  }) : super(key: key);

  @override
  ConsumerState<MessageInputArea> createState() => _MessageInputAreaState();
}

class _MessageInputAreaState extends ConsumerState<MessageInputArea> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    ref.read(chatMessagesProvider(widget.chatId).notifier).sendMessage(_controller.text);
    _controller.clear();
    widget.onMessageSent?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasText = _controller.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            onPressed: () {
              // Handle attachment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attachment feature coming soon')),
              );
            },
            icon: const Icon(Icons.attach_file),
            color: const Color(0xFF0EA5E9),
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            padding: EdgeInsets.zero,
            tooltip: 'Attach file',
          ),
          // Camera button
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera feature coming soon')),
              );
            },
            icon: const Icon(Icons.camera_alt),
            color: const Color(0xFF0EA5E9),
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            padding: EdgeInsets.zero,
            tooltip: 'Take photo',
          ),
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                onChanged: (_) {
                  ref.read(messageInputProvider.notifier).state = _controller.text;
                },
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                gradient: hasText
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF06B6D4), // cyan
                          Color(0xFF0EA5E9), // blue
                        ],
                      )
                    : null,
                color: !hasText ? const Color(0xFFE5E7EB) : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: hasText ? _sendMessage : null,
                icon: const Icon(Icons.send_rounded),
                color: hasText ? Colors.white : const Color(0xFF9CA3AF),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Send message',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
