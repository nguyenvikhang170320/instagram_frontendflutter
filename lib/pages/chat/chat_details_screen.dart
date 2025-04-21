import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram/model/message_model.dart';
import 'package:instagram/pages/chat/chat_bubble.dart';
import 'package:instagram/services/chat_service.dart';
import 'package:instagram/services/message_service.dart';
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
  late Future<void> _loadFuture;
  List<MessageModel> messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFuture =
        _loadMessagesAndMarkSeen(); // Tải tin nhắn ngay khi mở màn hình
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMessagesAndMarkSeen();
  }

  Future<void> _loadMessagesAndMarkSeen() async {
    try {
      // Lấy tất cả tin nhắn từ Firestore cho chatId hiện tại
      final loadedMessages = await ChatService().getMessages(widget.chatId);

      // Cập nhật danh sách tin nhắn
      setState(() {
        messages = loadedMessages;
      });

      // Cuộn xuống cuối khi tải xong
      _scrollToBottom();
    } catch (e) {
      print('Lỗi khi tải tin nhắn: $e');
    }
  }

  // Cuộn đến cuối danh sách
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết tin nhắn')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId) // ID của cuộc trò chuyện
                  .collection('messages')
                  .orderBy('createdAt',
                      descending: false) // Tin nhắn mới sẽ nằm dưới tin nhắn cũ
                  .snapshots(), // Sử dụng snapshots() để nhận cập nhật trong thời gian thực
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có tin nhắn.'));
                }

                final messages = snapshot.data!.docs.map((doc) {
                  return MessageModel.fromJson(
                      doc.data() as Map<String, dynamic>);
                }).toList();

                return ListView.builder(
                  reverse: false, // Tin nhắn mới nằm dưới tin nhắn cũ
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == widget.currentUserId;
                    return ChatBubble(
                      message: msg,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: NewMessageInput(
              chatId: widget.chatId,
              currentUserId: widget.currentUserId,
              otherUserId: widget.otherUserId,
              messages: messages,
              onMessageSent: (MessageModel message) {
                setState(() {
                  messages.insert(0, message);
                });

                // Cuộn xuống khi gửi tin nhắn mới
                _scrollToBottom();
              },
            ),
          ),
        ],
      ),
    );
  }
}
