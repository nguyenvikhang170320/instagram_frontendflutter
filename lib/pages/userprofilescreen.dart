import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:instagram/pages/chat/chat_details_screen.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    // 1. Lấy User ID hiện tại
    String? currentUserId = await getUserId();

    // 2. Lấy Token xác thực từ Firebase Auth
    User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (currentUserId == null || firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại để tiếp tục.')),
      );
      return;
    }

    // Lấy token chuỗi
    String? token = await firebaseUser.getIdToken(true);

    print("🛠️ DEBUG START CHAT:");
    print(" - Sender: $currentUserId");
    print(" - Receiver: ${widget.profileUserId}");

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/chats'),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          // 👇 QUAN TRỌNG: Phải đổi 'userId' thành 'receiverId' để khớp với Backend
          'receiverId': widget.profileUserId
        }),
      );

      print('🔁 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Backend trả về object có chứa chatId
        String? chatId = data['chatId'];

        if (chatId != null) {
          // Chuyển sang màn hình nhắn tin
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
          print("❌ Lỗi: Backend không trả về chatId");
        }
      } else {
        print('❌ Lỗi từ server: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${response.body}')),
        );
      }
    } catch (e) {
      print("❌ Lỗi kết nối: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối server')),
      );
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
