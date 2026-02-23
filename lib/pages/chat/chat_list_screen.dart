import 'package:flutter/material.dart';
import 'package:instagram/model/chat_model.dart';
import 'package:instagram/pages/chat/chat_details_screen.dart';
import 'package:instagram/pages/chat/chat_tile.dart';
import 'package:instagram/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;

  const ChatListScreen({super.key, required this.currentUserId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Future<List<ChatModel>>? _chatListFuture;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }



  void _loadChats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdToken(true);

    setState(() {
      _chatListFuture = ChatService().getChats(token!); // ✅ token
    });
  }


  // Hàm làm mới danh sách cuộc trò chuyện
  Future<void> _refreshChats() async {
    _loadChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        centerTitle: true, // căn giữa tiêu đề
        backgroundColor: Colors.blueAccent, // màu nền appBar
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<ChatModel>>(
        future: _chatListFuture,
        builder: (context, snapshot) {
          // Khi đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          // Khi có lỗi
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          // Nếu không có cuộc trò chuyện nào
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có cuộc trò chuyện nào.'));
          }

          final chats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshChats, // kích hoạt khi kéo xuống
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ChatTile(
                  chat: chat,
                  onTap: () {
                    final uid = FirebaseAuth.instance.currentUser!.uid;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          chatId: chat.chatId,
                          currentUserId: uid, // ✅ UID Firebase
                          otherUserId: chat.otherUserId,
                        ),
                      ),
                    );
                    // làm mới danh sách chat sau khi quay lại
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
