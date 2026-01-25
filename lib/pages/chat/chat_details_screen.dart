import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:instagram/model/message_model.dart';
import 'package:instagram/pages/chat/chat_bubble.dart';
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
  }

  // Hàm tự động cuộn xuống cuối danh sách
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết tin nhắn')),
      body: Column(
        children: [
          Expanded(
            // SỬ DỤNG STREAM ĐỂ NHẬN TIN NHẮN REAL-TIME
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages') // Backend lưu ở root collection 'messages'
                  .where('chatId', isEqualTo: widget.chatId) // Lọc theo chatId
                  .orderBy('createdAt', descending: false) // Cũ trên, mới dưới
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Hãy bắt đầu cuộc trò chuyện!'));
                }

                // Convert Docs sang Models
                final messages = snapshot.data!.docs.map((doc) {
                  // doc.data() trả về Map, cần ép kiểu an toàn
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  // Thêm ID vào data để Model parse được
                  data['id'] = doc.id;
                  // Xử lý Timestamp Firestore thành String ISO cho Model nếu cần
                  if (data['createdAt'] is Timestamp) {
                    data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
                  }

                  return MessageModel.fromJson(data);
                }).toList();

                // Tự động cuộn xuống khi có tin nhắn mới
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.only(bottom: 10, top: 10),
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

          // PHẦN NHẬP TIN NHẮN
          // Lưu ý: NewMessageInput nên gọi Provider để gửi tin nhắn qua API
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: NewMessageInput(
              chatId: widget.chatId,
              currentUserId: widget.currentUserId,
              otherUserId: widget.otherUserId,
              messages: [], // Không cần truyền list messages vào đây nữa vì Stream tự lo
              onMessageSent: (MessageModel message) {
                // Không cần làm gì ở đây vì Stream sẽ tự cập nhật UI
                _scrollToBottom();
              },
            ),
          ),
        ],
      ),
    );
  }
}