import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:instagram/model/message_model.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
class MessageService {
  // Gửi tin nhắn mới
  static Future<MessageModel> sendText({
    required String chatId,
    required String text,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/messages/send-text'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'chatId': chatId,
        'text': text,
      }),
    );

    if (res.statusCode == 201) {
      return MessageModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Send text failed');
    }
  }


  /// 🆕 Upload media (ảnh/video) lên backend
  static Future<MessageModel> sendMedia({
    required String chatId,
    required File imageFile,
    required String token,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${dotenv.env['BASE_URL']}/messages/send-media'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['chatId'] = chatId;

    request.files.add(
      await http.MultipartFile.fromPath(
        "image",
        imageFile.path,
        filename: p.basename(imageFile.path),
        contentType: () {
          final mime = lookupMimeType(imageFile.path) ?? "image/jpeg";
          final parts = mime.split("/");
          return MediaType(parts[0], parts[1]);
        }(),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      return MessageModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Upload media failed');
    }
  }

  static Future<List<MessageModel>> fetchMessages({
    required String chatId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('${dotenv.env['BASE_URL']}/messages/$chatId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => MessageModel.fromJson(e)).toList();
    } else {
      throw Exception('Fetch messages failed');
    }
  }


}
