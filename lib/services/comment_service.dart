import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CommentService {

  static Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    final res = await http.get(
      Uri.parse('${dotenv.env['BASE_URL']}/comments/$postId'),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(decoded);
    }

    throw Exception("Fetch comments failed");
  }


  static Future<void> addComment({
    required String postId,
    required String userId,
    required String commentText,
  }) async {

    final res = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/comments'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "postId": postId,
        "userId": userId,
        "commentText": commentText,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception("Add comment failed");
    }
  }


  static Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {

    final res = await http.delete(
      Uri.parse('${dotenv.env['BASE_URL']}/comments/$postId/$commentId'),
    );

    if (res.statusCode != 200) {
      throw Exception("Delete failed");
    }
  }
}