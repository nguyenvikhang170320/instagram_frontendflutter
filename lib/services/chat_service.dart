import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../model/chat_model.dart';

class ChatService {
  Future<List<ChatModel>> getChats(String token) async {
    final res = await http.get(
      Uri.parse('${dotenv.env['BASE_URL']}/chats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => ChatModel.fromJson(e)).toList();
    }
    throw Exception('Load chats failed');
  }

  Future<ChatModel> getOrCreateChat(
      String token, String receiverId) async {
    final res = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/chats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'receiverId': receiverId}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return ChatModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Create chat failed');
  }
}
