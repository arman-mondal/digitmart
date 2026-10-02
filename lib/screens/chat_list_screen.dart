import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../models/chat_model.dart';
import '../services/supabase_service.dart';
import 'chat_details_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final SupabaseService _service = SupabaseService();
  List<ChatModel> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.currentProfile != null) {
      final res = await _service.getUserChats(appState.currentProfile!.id);
      setState(() {
        _chats = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer - Seller Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentAmber),
            )
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Conversations',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When you bid or inquire on listings, chats will appear here.',
                        style: GoogleFonts.outfit(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    final isBuyer = chat.buyerId == appState.currentProfile?.id;
                    final otherUser = isBuyer ? chat.seller : chat.buyer;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppTheme.cardDark,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailsScreen(chat: chat),
                            ),
                          ).then((_) => _loadChats());
                        },
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            otherUser?.profileImage ??
                                'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=300&q=80',
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              otherUser?.name ?? 'User',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeago.format(chat.lastMessageAt),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'Product: ${chat.product?.title ?? "Listing"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.accentAmber,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chat.lastMessage ?? 'No messages',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
