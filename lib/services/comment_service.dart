import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../sharepreference/sharepre.dart';

class CommentService {
  static Future<int> fetchCommentCount(String postId) async {
    final res = await http.get(
      Uri.parse('${dotenv.env['BASE_URL']}/comments/count/$postId'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['commentCount'] ?? 0) as int;
    }
    throw Exception('Fetch comment count failed: ${res.statusCode} - ${res.body}');
  }

  static Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    final res = await http.get(
      Uri.parse('${dotenv.env['BASE_URL']}/comments/$postId'),
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }
    throw Exception('Fetch comments failed: ${res.statusCode} - ${res.body}');
  }

  static Future<Map<String, dynamic>> addComment({
    required String postId,
    required String commentText,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Thiếu token");

    final res = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/comment'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "postId": postId,
        "commentText": commentText,
      }),
    );

    if (res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    }
    throw Exception('Add comment failed: ${res.statusCode} - ${res.body}');
  }

  static Future<void> deleteComment({
    required String commentId,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Thiếu token");

    final res = await http.delete(
      Uri.parse('${dotenv.env['BASE_URL']}/comments/delete/$commentId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) return;
    throw Exception('Delete comment failed: ${res.statusCode} - ${res.body}');
  }
}
