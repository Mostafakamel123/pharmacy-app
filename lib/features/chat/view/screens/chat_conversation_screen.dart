// ignore_for_file: use_super_parameters, unused_result, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/config/env_config.dart';
import 'package:pharmacy_app/features/chat/model/chat_model.dart';
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
  bool _isContextExpanded = true;

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
    
    // Resolve current chat context dynamically from chatsProvider
    final chatsAsync = ref.watch(chatsProvider);
    final chatModel = chatsAsync.maybeWhen(
      data: (list) {
        try {
          return list.firstWhere((c) => c.id == widget.chatId);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

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
            if (chatModel != null && chatModel.prescriptionId != null)
              _buildPrescriptionContextBanner(chatModel, isDark),
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

  Widget _buildPrescriptionContextBanner(ChatModel chat, bool isDark) {
    final textPrimary = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final cardBg = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    final borderCol = isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB);
    
    final price = chat.prescriptionPrice ?? 0.0;
    final notes = chat.prescriptionNotes ?? 'لا توجد ملاحظات';
    final imageUrl = chat.prescriptionImage;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header toggler
          InkWell(
            onTap: () {
              setState(() {
                _isContextExpanded = !_isContextExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_rounded, color: Color(0xFF0EA5E9), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Prescription Context / تفاصيل الروشتة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.24)),
                        ),
                        child: Text(
                          '$price EGP',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isContextExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (_isContextExpanded) ...[
            Divider(height: 1, thickness: 1, color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview thumbnail
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _showContextImage(imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 54,
                          height: 54,
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          child: imageUrl.startsWith('assets/')
                              ? Image.asset(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                )
                              : imageUrl.startsWith('/images')
                              ? Image.network(
                                  '${EnvConfig.apiBaseUrl}$imageUrl',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey);
                                  },
                                )
                              : Image.file(
                                  File(imageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey);
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Description / Notes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notes,
                          style: TextStyle(
                            fontSize: 12,
                            color: textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Offer Accepted & Preparing / تم قبول العرض وجاري التجهيز',
                                style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showContextImage(String imageUrl) {
    final String fullUrl = imageUrl.startsWith('assets/') 
        ? imageUrl 
        : imageUrl.startsWith('/images') 
        ? '${EnvConfig.apiBaseUrl}$imageUrl' 
        : imageUrl;

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Prescription Zoom / تكبير الروشتة',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: InteractiveViewer(
                maxScale: 6.0,
                minScale: 1.0,
                child: fullUrl.startsWith('assets/')
                    ? Image.asset(fullUrl, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
                    : fullUrl.startsWith('http')
                    ? Image.network(
                        fullUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                      )
                    : Image.file(
                        File(fullUrl),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
            ),
          );
        },
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
