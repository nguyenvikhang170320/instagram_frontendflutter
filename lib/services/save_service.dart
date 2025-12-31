import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../sharepreference/sharepre.dart';

class SavedService {
  static Future<List<Map<String, dynamic>>> getSavedPosts() async {
    final token = await getToken();
    if (token == null) return [];

    final res = await http.get(
      Uri.parse("${dotenv.env['BASE_URL']}/saved-posts"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }
    throw Exception('Fetch saved posts failed: ${res.statusCode} - ${res.body}');
  }



  static Future<void> savePost({
    required String postId,
    required String imageUrl,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Thiếu token");

    final res = await http.post(
      Uri.parse("${dotenv.env['BASE_URL']}/save"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "postId": postId,
        "imageUrl": imageUrl,
      }),
    );

    if (res.statusCode == 200) return;
    throw Exception('Save failed: ${res.statusCode} - ${res.body}');
  }

  static Future<void> unsavePost({
    required String postId,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Thiếu token");

    final res = await http.post(
      Uri.parse("${dotenv.env['BASE_URL']}/unsave"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"postId": postId}),
    );

    if (res.statusCode == 200) return;
    throw Exception('Unsave failed: ${res.statusCode} - ${res.body}');
  }
}
