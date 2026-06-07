// ignore_for_file: use_super_parameters, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:Elaaj/core/models/pharmacy_model.dart';
import 'package:Elaaj/core/network/api_endpoints.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/chat/controller/chat_notifier.dart';
import 'package:Elaaj/features/chat/model/chat_message.dart';
import 'package:Elaaj/features/pharmacies/view/pharmacy_details_screen.dart';

/// Full-featured polling-based chat screen.
///
/// Accepts all required context via constructor — no global provider needed.
///
/// Parameters:
///  - [prescriptionId] — GUID of the prescription.
///  - [otherUserId]    — ID of the other party (receiver).
///  - [currentUserId]  — ID of the currently logged-in user.
///  - [isPharmacy]     — whether the current user is a pharmacy.
///  - [pharmacyId]     — pharmacy's own ID (required when [isPharmacy] is true).
///  - [otherUserName]  — display name for the AppBar.
class ChatScreen extends ConsumerStatefulWidget {
  final String prescriptionId;
  final String otherUserId;
  final String currentUserId;
  final bool isPharmacy;
  final String? pharmacyId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    required this.prescriptionId,
    required this.otherUserId,
    required this.currentUserId,
    required this.isPharmacy,
    this.pharmacyId,
    this.otherUserName = 'Chat',
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final ChatParams _params;
  late final ScrollController _scrollController;
  late final TextEditingController _textController;
  Timer? _pollingTimer;

  /// Track the last error message so we only show the SnackBar once per error.
  String? _lastShownError;

  @override
  void initState() {
    super.initState();

    _params = ChatParams(
      prescriptionId: widget.prescriptionId,
      otherUserId: widget.otherUserId,
      currentUserId: widget.currentUserId,
      isPharmacy: widget.isPharmacy,
      pharmacyId: widget.pharmacyId,
    );

    _scrollController = ScrollController();
    _textController = TextEditingController();

    // 7. Load history immediately on screen open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatNotifierProvider(_params).notifier).loadHistory();
    });

    // 2. Start 5-second polling timer.
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.read(chatNotifierProvider(_params).notifier).pollHistory();
      }
    });
  }

  @override
  void dispose() {
    // 2. Cancel timer when screen is disposed.
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await ref.read(chatNotifierProvider(_params).notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatState = ref.watch(chatNotifierProvider(_params));

    // ── Side-effects: scroll + error SnackBar ──────────────────────────────
    if (chatState is ChatLoaded) {
      _scrollToBottom();
    }
    if (chatState is ChatError && chatState.message != _lastShownError) {
      _lastShownError = chatState.message;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(chatState.message),
              backgroundColor: AppColors.accentRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      });
    }

    final messages = _resolveMessages(chatState);
    final isSending = chatState is ChatLoaded && chatState.isSending;

    return Scaffold(
      backgroundColor:
          isDark ? DarkColors.background : LightColors.background,
      appBar: _buildAppBar(context, isDark, theme),
      body: Column(
        children: [
          // ── Context Banner ──────────────────────────────────────────────
          _buildContextBanner(isDark),
          // ── Message List ────────────────────────────────────────────────
          Expanded(
            child: _buildMessageList(context, chatState, messages, isDark, theme),
          ),
          // ── Input Area ──────────────────────────────────────────────────
          _buildInputArea(context, isDark, isSending),
        ],
      ),
    );
  }

  Future<void> _navigateToPharmacyDetails(BuildContext context, String pharmacyId, String pharmacyName) async {
    if (pharmacyId.isEmpty && pharmacyName.isEmpty) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? DarkColors.card : LightColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark ? DarkColors.divider : LightColors.divider,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: Text(
                  'جاري تحميل تفاصيل الصيدلية...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final api = ApiEndpoints();
      PharmacyModel? pharmacy;
      
      if (pharmacyId.isNotEmpty) {
        final response = await api.getPharmacyById(id: pharmacyId);
        pharmacy = PharmacyModel.fromJson(response);
      } else {
        // Fallback: Search for pharmacy by name
        final results = await api.searchPharmacies(keyword: pharmacyName);
        if (results.isNotEmpty) {
          pharmacy = PharmacyModel.fromJson(results.first as Map<String, dynamic>);
        }
      }
      
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        if (pharmacy != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PharmacyDetailsScreen(pharmacy: pharmacy!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر العثور على تفاصيل هذه الصيدلية',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تحميل تفاصيل الصيدلية: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, bool isDark, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? DarkColors.surface : Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        color: AppColors.primaryBlue,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: GestureDetector(
        onTap: widget.isPharmacy
            ? null
            : () => _navigateToPharmacyDetails(context, widget.otherUserId, widget.otherUserName),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.isPharmacy ? '👤' : '🏥',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? DarkColors.textPrimary
                          : LightColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryGreen,
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
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          color: AppColors.primaryBlue,
          tooltip: 'Prescription details',
          onPressed: () => _showPrescriptionInfoSheet(context),
        ),
      ],
    );
  }

  // ── Context Banner ─────────────────────────────────────────────────────────

  Widget _buildContextBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(isDark ? 0.3 : 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prescription Chat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Text(
                  'ID: ${widget.prescriptionId.length >= 8 ? widget.prescriptionId.substring(0, 8).toUpperCase() : widget.prescriptionId.toUpperCase()}...',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? DarkColors.textSecondary
                        : LightColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.3)),
            ),
            child: const Text(
              'Offer Accepted ✓',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Message List ───────────────────────────────────────────────────────────

  Widget _buildMessageList(
    BuildContext context,
    ChatState state,
    List<ChatMessage> messages,
    bool isDark,
    ThemeData theme,
  ) {
    if (state is ChatLoading) return _buildLoadingState();

    if (state is ChatError && messages.isEmpty) {
      return _buildErrorState(context, state.message);
    }

    if (messages.isEmpty) return _buildEmptyState(isDark, theme);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        // 3. Compare senderId with currentUserId to determine bubble side.
        final isMe = message.senderId == widget.currentUserId;
        final showDateHeader = _shouldShowDateHeader(messages, index);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateHeader) _buildDateHeader(message.createdAt, isDark),
            _buildMessageBubble(message, isMe, isDark, index, messages),
          ],
        );
      },
    );
  }

  bool _shouldShowDateHeader(List<ChatMessage> messages, int index) {
    if (index == 0) return true;
    final prev = messages[index - 1].createdAt;
    final curr = messages[index].createdAt;
    return prev.day != curr.day ||
        prev.month != curr.month ||
        prev.year != curr.year;
  }

  Widget _buildDateHeader(DateTime date, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? DarkColors.divider : LightColors.divider,
              thickness: 1,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? DarkColors.surface
                  : LightColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDateHeader(date),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? DarkColors.textSecondary
                    : LightColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: isDark ? DarkColors.divider : LightColors.divider,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, y').format(date);
  }

  // ── Message Bubble ─────────────────────────────────────────────────────────

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isMe,
    bool isDark,
    int index,
    List<ChatMessage> messages,
  ) {
    final isLastInGroup = index == messages.length - 1 ||
        messages[index + 1].senderId != message.senderId;

    final sentGradient = const LinearGradient(
      colors: [AppColors.primaryBlue, AppColors.primaryCyan],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final receivedBg =
        isDark ? DarkColors.surface : const Color(0xFFF3F4F6);

    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 8 : 2, top: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Receiver avatar (only on last bubble in group)
          if (!isMe) ...[
            if (isLastInGroup)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 6, bottom: 2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen, AppColors.primaryCyan],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child:
                      Text('🏥', style: TextStyle(fontSize: 14)),
                ),
              )
            else
              const SizedBox(width: 34),
          ],

          // Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(message.content),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                margin: EdgeInsets.only(
                  left: isMe ? 48 : 0,
                  right: isMe ? 0 : 48,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe ? sentGradient : null,
                  color: isMe ? null : receivedBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isMe
                        ? const Radius.circular(18)
                        : (isLastInGroup
                            ? const Radius.circular(4)
                            : const Radius.circular(18)),
                    bottomRight: isMe
                        ? (isLastInGroup
                            ? const Radius.circular(4)
                            : const Radius.circular(18))
                        : const Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(isDark ? 0.2 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender name (received bubbles only)
                    if (!isMe &&
                        isLastInGroup &&
                        message.senderName.isNotEmpty)
                      GestureDetector(
                        onTap: widget.isPharmacy
                            ? null
                            : () => _navigateToPharmacyDetails(context, widget.otherUserId, message.senderName),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            message.senderName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryCyan,
                            ),
                          ),
                        ),
                      ),

                    // Content
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isMe
                            ? Colors.white
                            : (isDark
                                ? DarkColors.textPrimary
                                : LightColors.textPrimary),
                      ),
                    ),

                    // Timestamp
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm')
                          .format(message.createdAt.toLocal()),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : (isDark
                                ? DarkColors.textHint
                                : LightColors.textHint),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Input Area ─────────────────────────────────────────────────────────────

  Widget _buildInputArea(
      BuildContext context, bool isDark, bool isSending) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? DarkColors.divider : LightColors.divider,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? DarkColors.background
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? DarkColors.divider
                        : LightColors.divider,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  enabled: !isSending,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? DarkColors.textPrimary
                        : LightColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? DarkColors.textHint
                          : LightColors.textHint,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => isSending ? null : _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 9. Send button — disabled while isSending.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: isSending
                  ? Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: _handleSend,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryCyan,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Placeholder States ─────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryBlue),
          SizedBox(height: 16),
          Text('Loading messages…'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.primaryCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start the conversation!',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to the ${widget.isPharmacy ? 'patient' : 'pharmacy'}.',
            style: TextStyle(
              color: isDark
                  ? DarkColors.textSecondary
                  : LightColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.accentRed),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.accentRed),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(chatNotifierProvider(_params).notifier)
                  .loadHistory(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Prescription Info Sheet ────────────────────────────────────────────────

  void _showPrescriptionInfoSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? DarkColors.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                Text(
                  'Prescription Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark
                        ? DarkColors.textPrimary
                        : LightColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow('Prescription ID', widget.prescriptionId, isDark),
            _infoRow('Talking with', widget.otherUserName, isDark),
            _infoRow('Your role',
                widget.isPharmacy ? 'Pharmacy' : 'Patient', isDark),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? DarkColors.textSecondary
                    : LightColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? DarkColors.textPrimary
                    : LightColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  List<ChatMessage> _resolveMessages(ChatState state) {
    if (state is ChatLoaded) return state.messages;
    if (state is ChatError && state.previousMessages != null) {
      return state.previousMessages!;
    }
    return [];
  }
}
