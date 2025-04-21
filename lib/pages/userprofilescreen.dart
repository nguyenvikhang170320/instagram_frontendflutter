import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:instagram/pages/chat/chat_details_screen.dart';
import 'package:instagram/sharepreference/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String currentUserId;
  final String profileUserId;
  final String username;
  final String fullname;
  final String bio;
  final String avatar;

  const UserProfileScreen({
    Key? key,
    required this.currentUserId,
    required this.profileUserId,
    required this.username,
    required this.fullname,
    required this.bio,
    required this.avatar,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  void _handleStartChat() async {
    String? currentUserId = await getUserId();
    print("UserId: $currentUserId");

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy tài khoản hiện tại')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/chats'), // Hoặc localhost tương ứng
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'senderId': currentUserId,
        'receiverId': widget.profileUserId,
      }),
    );

    print('🔁 Status: ${response.statusCode}');
    print('📦 Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final chatId = data['chatId'];

      if (chatId == null) {
        print('❌ chatId is null từ response!');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatId: chatId,
            currentUserId: currentUserId,
            otherUserId: widget.profileUserId,
          ),
        ),
      );
    } else {
      print('❌ Lỗi từ server: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.username)),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.avatar.isNotEmpty
                      ? NetworkImage(widget.avatar)
                      : AssetImage("assets/images/user.jpg") as ImageProvider,
                ),
                SizedBox(height: 10),
                Text(
                  widget.fullname,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.bio,
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 20),

                // 📩 Nút Nhắn tin
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleStartChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                        ),
                        child: Text("Nhắn tin",
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    SizedBox(width: 10),

                    // 📞 Nút Liên hệ
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          print("📞 Mở liên hệ với ${widget.username}");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[100],
                        ),
                        child: Text("Liên hệ",
                            style: TextStyle(color: Colors.green)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
