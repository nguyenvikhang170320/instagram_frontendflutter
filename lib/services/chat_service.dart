import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../model/chat_model.dart';
import '../model/message_model.dart';

class ChatService {


  // 1. Lấy danh sách cuộc trò chuyện (Gọi API Backend)
  Future<List<ChatModel>> getChats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // Map dữ liệu JSON từ server vào Model
        return data.map((json) => ChatModel.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi tải chats: ${response.body}');
      }
    } catch (e) {
      print('🔥 Lỗi Service getChats: $e');
      return []; // Trả về rỗng nếu lỗi để app không crash
    }
  }

  // 2. Lấy danh sách tin nhắn của 1 chat (Gọi API Backend)
  Future<List<MessageModel>> getMessages(String token, String chatId) async {
    try {
      // URL đúng theo Backend: /api/messages/:chatId
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/messages/$chatId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi tải tin nhắn: ${response.body}');
      }
    } catch (e) {
      print("🔥 Lỗi Service getMessages: $e");
      return [];
    }
  }

  // 3. Gửi tin nhắn (Cần thêm hàm này)
  Future<bool> sendMessage(String token, String chatId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/messages/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "chatId": chatId,
          "text": text,
        }),
      );

      return response.statusCode == 201; // 201 là Created
    } catch (e) {
      print("🔥 Lỗi Service sendMessage: $e");
      return false;
    }
  }
}