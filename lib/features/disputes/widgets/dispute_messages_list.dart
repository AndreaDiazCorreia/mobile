import 'package:flutter/material.dart';
import 'package:mostro_mobile/core/app_theme.dart';
import 'package:mostro_mobile/data/models/dispute_chat.dart';
import 'package:mostro_mobile/data/models/dispute.dart';
import 'package:mostro_mobile/features/disputes/widgets/dispute_message_bubble.dart';
import 'package:mostro_mobile/features/disputes/widgets/dispute_info_card.dart';
import 'package:mostro_mobile/generated/l10n.dart';

class DisputeMessagesList extends StatefulWidget {
  final String disputeId;
  final String status;
  final DisputeData disputeData;
  final ScrollController? scrollController;

  const DisputeMessagesList({
    super.key,
    required this.disputeId,
    required this.status,
    required this.disputeData,
    this.scrollController,
  });

  @override
  State<DisputeMessagesList> createState() => _DisputeMessagesListState();
}

class _DisputeMessagesListState extends State<DisputeMessagesList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    
    // Scroll to bottom on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    
    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate mock messages based on status
    final messages = _getMockMessages();
    
    
    return Container(
      color: AppTheme.backgroundDark,
      child: Column(
        children: [
          // Admin assignment notification (if applicable)
          _buildAdminAssignmentNotification(context),
          
          // Messages list with info card at top (scrolleable)
          Expanded(
            child: messages.isEmpty 
              ? Column(
                  children: [
                    DisputeInfoCard(dispute: widget.disputeData),
                    // Show appropriate content based on status
                    Expanded(
                      child: _buildEmptyAreaContent(context)
                    ),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _getItemCount(messages),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // First item is the dispute info card
                      return DisputeInfoCard(dispute: widget.disputeData);
                    }
                    
                    // Check if this is the last item and we need to show chat closed message
                    final isLastItem = index == _getItemCount(messages) - 1;
                    final normalizedStatus = _normalizeStatus(widget.status);
                    final isResolvedStatus = normalizedStatus == 'resolved' || normalizedStatus == 'solved' || normalizedStatus == 'seller-refunded';
                    
                    if (isLastItem && isResolvedStatus && messages.isNotEmpty) {
                      // Show chat closed message at the end
                      return _buildChatClosedMessage(context);
                    }
                    
                    // Regular message (adjust index for messages)
                    final messageIndex = isResolvedStatus && messages.isNotEmpty 
                        ? index - 1  // Account for info card
                        : index - 1; // Account for info card
                    
                    if (messageIndex >= messages.length) {
                      return _buildChatClosedMessage(context);
                    }
                    
                    final message = messages[messageIndex];
                    return DisputeMessageBubble(
                      message: message.message,
                      isFromUser: message.isFromUser,
                      timestamp: message.timestamp,
                      adminPubkey: message.adminPubkey,
                    );
                  },
                ),
          ),
          
          // Resolution notification (if resolved)
          if (widget.status == 'resolved')
            _buildResolutionNotification(context),
        ],
      ),
    );
  }

  Widget _buildWaitingForAdmin(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              S.of(context)?.waitingAdminAssignment ?? 'Waiting for admin assignment',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context)?.waitingAdminDescription ?? 'Your dispute has been submitted. An admin will be assigned to help resolve this issue.',
              style: TextStyle(
                color: AppTheme.textInactive,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatArea(BuildContext context) {
    // Empty chat area for when admin is assigned but no messages yet
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          S.of(context)?.noMessagesYet ?? 'No messages yet',
          style: TextStyle(
            color: AppTheme.textInactive,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAdminAssignmentNotification(BuildContext context) {
    // Only show admin assignment notification for 'in-progress' status
    // Don't show for 'initiated' (no admin yet) or 'resolved' (dispute finished)
    final normalizedStatus = _normalizeStatus(widget.status);
    if (normalizedStatus != 'in-progress') {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.admin_panel_settings,
            color: Colors.blue[300],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context)?.adminAssigned ?? 'Admin has been assigned to this dispute',
              style: TextStyle(
                color: Colors.blue[300],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionNotification(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[300],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context)?.disputeResolvedMessage ?? 'This dispute has been resolved. Check your wallet for any refunds or payments.',
              style: TextStyle(
                color: Colors.green[300],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DisputeChat> _getMockMessages() {
    // For now, return empty list for real implementation
    // In the future, this should load real dispute chat messages
    // from the dispute chat provider or repository
    
    // Always return empty list - no mock messages should appear
    // Mock messages were causing confusion in the UI
    return [];
  }

  /// Normalizes status string by trimming, lowercasing, and replacing spaces/underscores with hyphens
  String _normalizeStatus(String status) {
    if (status.isEmpty) return '';
    // Trim, lowercase, and replace spaces/underscores with hyphens
    return status.trim().toLowerCase().replaceAll(RegExp(r'[\s_]+'), '-');
  }

  /// Build content for empty message area based on status
  Widget _buildEmptyAreaContent(BuildContext context) {
    final normalizedStatus = _normalizeStatus(widget.status);
    
    if (normalizedStatus == 'initiated') {
      return _buildWaitingForAdmin(context);
    } else if (normalizedStatus == 'resolved' || normalizedStatus == 'solved' || normalizedStatus == 'seller-refunded') {
      return _buildChatClosedArea(context);
    } else {
      // in-progress or other status
      return _buildEmptyChatArea(context);
    }
  }

  /// Get the total item count for ListView (info card + messages + chat closed message if needed)
  int _getItemCount(List<DisputeChat> messages) {
    int count = 1; // Always include info card
    count += messages.length; // Add messages
    
    // Add chat closed message for resolved disputes
    final normalizedStatus = _normalizeStatus(widget.status);
    if (normalizedStatus == 'resolved' || normalizedStatus == 'solved' || normalizedStatus == 'seller-refunded') {
      count += 1;
    }
    
    return count;
  }

  /// Build chat closed area for when there are no messages but dispute is resolved
  Widget _buildChatClosedArea(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              S.of(context)?.noMessagesYet ?? 'No messages yet',
              style: TextStyle(
                color: AppTheme.textInactive,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildChatClosedMessage(context),
          ],
        ),
      ),
    );
  }

  /// Build message indicating that chat is closed for resolved disputes
  Widget _buildChatClosedMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dark1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context)!.disputeChatClosed,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}