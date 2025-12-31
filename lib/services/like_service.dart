import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class LikeService {
  Future<String> _idToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception("Chưa đăng nhập / không lấy được ID token");
    return token;
  }

  Map<String, String> _authHeaders(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  /// 4️⃣ GET /likes/user/:userId  -> [{postId:...}]
  Future<Map<String, bool>> fetchLikedPostsMap(String userId) async {
    final url = Uri.parse("${dotenv.env['BASE_URL']}/likes/user/$userId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      return {
        for (final item in data)
          (item['postId'] ?? '').toString(): true,
      }..removeWhere((k, _) => k.isEmpty);
    }
    throw Exception("Fetch liked posts failed: ${res.statusCode} - ${res.body}");
  }

  /// 3️⃣ GET /likes/:postId -> { likeCount: number, likes: [userId...] }
  Future<Map<String, dynamic>> fetchLikeInfo(String postId) async {
    final url = Uri.parse("${dotenv.env['BASE_URL']}/likes/$postId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception("Fetch like info failed: ${res.statusCode} - ${res.body}");
  }

  /// 1️⃣ POST /likes/like (auth) body: {postId}
  Future<void> like(String postId) async {
    final token = await _idToken();
    final url = Uri.parse("${dotenv.env['BASE_URL']}/likes/like");

    final res = await http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode({"postId": postId}),
    );

    if (res.statusCode != 200) {
      throw Exception("Like failed: ${res.statusCode} - ${res.body}");
    }
  }

  /// 2️⃣ DELETE /likes/unlike (auth) body: {postId}
  Future<void> unlike(String postId) async {
    final token = await _idToken();
    final url = Uri.parse("${dotenv.env['BASE_URL']}/likes/unlike");

    final res = await http.delete(
      url,
      headers: _authHeaders(token),
      body: jsonEncode({"postId": postId}),
    );

    if (res.statusCode != 200) {
      throw Exception("Unlike failed: ${res.statusCode} - ${res.body}");
    }
  }
}
