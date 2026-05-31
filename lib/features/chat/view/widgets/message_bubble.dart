// ignore_for_file: use_super_parameters, unused_local_variable

import 'package:flutter/material.dart';
import '../../model/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        child: FractionallySizedBox(
          widthFactor: 0.75,
          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Align(
            alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: _buildMessageContent(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    switch (message.type) {
      case MessageType.text:
        return _TextMessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          isDark: isDark,
        );
      case MessageType.image:
        return _ImageMessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
        );
      case MessageType.voice:
        return _VoiceMessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          isDark: isDark,
        );
    }
  }
}

class _TextMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final bool isDark;

  const _TextMessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isCurrentUser
            ? LinearGradient(
                colors: [
                  const Color(0xFF06B6D4), // cyan
                  const Color(0xFF0EA5E9), // blue
                ],
              )
            : null,
        color: isCurrentUser ? null : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isCurrentUser ? Colors.white : theme.textTheme.bodyMedium?.color,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCurrentUser ? Colors.white70 : theme.textTheme.labelSmall?.color,
                  fontSize: 11,
                ),
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 4),
                _buildStatusIcon(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.schedule;
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: message.status == MessageStatus.read ? Colors.amber : Colors.white70,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _ImageMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;

  const _ImageMessageBubble({
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              message.imageUrl ?? '',
              width: 200,
              height: 200,
              cacheWidth: 400,
              cacheHeight: 400,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _VoiceMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final bool isDark;

  const _VoiceMessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = message.duration ?? 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isCurrentUser
            ? LinearGradient(
                colors: [
                  const Color(0xFF06B6D4),
                  const Color(0xFF0EA5E9),
                ],
              )
            : null,
        color: isCurrentUser ? null : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_filled,
            color: isCurrentUser ? Colors.white : theme.iconTheme.color,
            size: 28,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isCurrentUser ? Colors.white30 : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(duration),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCurrentUser ? Colors.white70 : theme.textTheme.labelSmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
