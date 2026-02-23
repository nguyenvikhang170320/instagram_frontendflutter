import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/chat_provider.dart';
import 'chat_bubble.dart';
import 'new_message_input.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Load message lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.chatId);
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final messages = provider.messages;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết tin nhắn')),
      body: Column(
        children: [
          Expanded(
            child: provider.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(child: Text('Hãy bắt đầu cuộc trò chuyện!'))
                : ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderId == widget.currentUserId;

                return ChatBubble(
                  message: msg,
                  isMe: isMe,
                );
              },
            ),
          ),

          // INPUT
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: NewMessageInput(
              chatId: widget.chatId,
              currentUserId: widget.currentUserId,
            ),

          ),
        ],
      ),
    );
  }
}
