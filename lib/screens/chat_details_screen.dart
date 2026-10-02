import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/supabase_service.dart';
import 'report_screen.dart';

class ChatDetailsScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatDetailsScreen({super.key, required this.chat});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _messageCtrl = TextEditingController();

  Future<void> _sendMessage(String text, {String type = 'text'}) async {
    if (text.trim().isEmpty) return;
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    _messageCtrl.clear();
    await _service.sendMessage(
      chatId: widget.chat.id,
      senderId: appState.currentProfile!.id,
      message: text,
      messageType: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isBuyer = widget.chat.buyerId == appState.currentProfile?.id;
    final otherUser = isBuyer ? widget.chat.seller : widget.chat.buyer;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                otherUser?.profileImage ??
                    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=300&q=80',
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUser?.name ?? 'User',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.chat.product?.title ?? 'Product Chat',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.accentAmber,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showPeerSafetyInfo(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. CONTEXTUAL ACTION PILLS BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppTheme.primaryLight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionPill(
                    icon: Icons.location_on,
                    label: 'Arrange Meeting',
                    color: AppTheme.accentAmber,
                    onTap: () {
                      _sendMessage(
                        '📍 Proposal: Let\'s arrange a public meetup in New Town, Kolkata tomorrow. What time works best for you?',
                        type: 'action_meeting',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: Icons.local_shipping,
                    label: 'Discuss Shipping',
                    color: AppTheme.accentIndigo,
                    onTap: () {
                      _sendMessage(
                        '📦 Would you prefer courier delivery or direct pickup?',
                        type: 'action_shipping',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: Icons.check_circle,
                    label: 'Mark Completed',
                    color: AppTheme.accentEmerald,
                    onTap: () {
                      _sendMessage(
                        '✅ Transaction Completed! Thank you for the smooth peer-to-peer deal.',
                        type: 'action_completed',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: Icons.report_problem,
                    label: 'Report User',
                    color: AppTheme.accentRose,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportScreen(
                            reportedUserId: otherUser?.id,
                            productId: widget.chat.productId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2. REALTIME MESSAGES STREAM LIST
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _service.streamChatMessages(widget.chat.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accentAmber),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Send a message to start!',
                      style: GoogleFonts.outfit(color: AppTheme.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == appState.currentProfile?.id;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),

          // 3. INPUT BAR
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.primary,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.accentAmber),
                  onPressed: () => _sendMessage(_messageCtrl.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    final timeStr = DateFormat('hh:mm a').format(msg.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.accentAmber : AppTheme.cardDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isMe ? AppTheme.accentAmber : AppTheme.borderDark,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.message,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isMe ? Colors.black : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: isMe ? Colors.black54 : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPeerSafetyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Peer-to-Peer Transaction Tips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.verified_user, color: AppTheme.accentEmerald),
              title: Text('Meet in Public Places'),
              subtitle: Text('Choose malls, metro stations, or cafes.'),
            ),
            const ListTile(
              leading: Icon(Icons.remove_red_eye, color: AppTheme.accentAmber),
              title: Text('Inspect Item First'),
              subtitle: Text('Test functionality before paying.'),
            ),
            const ListTile(
              leading: Icon(Icons.gavel, color: AppTheme.accentIndigo),
              title: Text('No Platform Payments'),
              subtitle: Text('Pay seller directly in cash or UPI.'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
