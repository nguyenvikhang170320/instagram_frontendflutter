import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/model/message_model.dart';

class MessageService {
  // Gửi tin nhắn mới
  static Future<MessageModel> sendMessageAndReturn({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
    String type = 'text',
    String? mediaUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/chats/$chatId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
          'type': type,
          'mediaUrl': mediaUrl,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MessageModel.fromJson(data);
      } else {
        throw Exception('Lỗi khi gửi tin nhắn');
      }
    } catch (e) {
      print("Error sending message: $e");
      throw Exception('Lỗi khi gửi tin nhắn');
    }
  }

  /// 🆕 Upload media (ảnh/video) lên backend
  static Future<MessageModel?> uploadMediaMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File file,
    required String type, // 'image' hoặc 'video'
  }) async {
    final uri = Uri.parse('${dotenv.env['BASE_URL']}/chats/$chatId/messages');
    final request = http.MultipartRequest('POST', uri)
      ..fields['senderId'] = senderId
      ..fields['receiverId'] = receiverId
      ..fields['type'] = type
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return MessageModel.fromJson(data);
      } else {
        print('❌ Upload thất bại: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Lỗi khi upload media: $e');
      return null;
    }
  }
}
