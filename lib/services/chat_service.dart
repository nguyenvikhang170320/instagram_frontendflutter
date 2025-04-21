import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/model/chat_model.dart';
import 'package:instagram/model/message_model.dart';

class ChatService {
  /// Lấy danh sách các cuộc chat của user
  Future<List<ChatModel>> getChats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final chats = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatModel.fromMap(doc.id, data, userId);
      }).toList();

      return chats;
    } catch (e, stackTrace) {
      print('🔥 Lỗi khi tải chat: $e');
      print('📌 StackTrace: $stackTrace');
      throw Exception('Lỗi khi tải danh sách chat: $e');
    }
  }

  /// Lấy danh sách tin nhắn trong 1 cuộc chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final res = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/chats/$chatId/messages'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("chat service lấy danh sách tin nhắn: $data");
        return (data as List).map((e) => MessageModel.fromJson(e)).toList();
      }
      throw Exception('Lỗi khi tải tin nhắn');
    } catch (e) {
      print("Error fetching messages: $e");
      throw Exception('Error fetching messages: $e');
    }
  }
}
