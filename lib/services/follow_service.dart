import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../sharepreference/sharepre.dart';

class FollowService {
  String get _base => dotenv.env['BASE_URL'] ?? "";

  Future<String> _idToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Chưa đăng nhập / không có token");
    }
    return token;
  }

  Future<Map<String, dynamic>> getFollowCounts(String userId) async {
    final res = await http.get(Uri.parse("$_base/follow/$userId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Get follow counts failed: ${res.statusCode} - ${res.body}");
  }

  Future<List<String>> getFollowingIds(String userId) async {
    final res = await http.get(Uri.parse("$_base/follow/check-following/$userId"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = (data["followingList"] as List?) ?? [];
      return list.map((e) => e.toString()).toList();
    }
    throw Exception("Get following ids failed: ${res.statusCode} - ${res.body}");
  }

  Future<List<Map<String, dynamic>>> getFollowingUsers(String userId) async {
    final res = await http.get(Uri.parse("$_base/follow/following/$userId"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception("Get following users failed: ${res.statusCode} - ${res.body}");
  }

  Future<List<Map<String, dynamic>>> getFollowersUsers(String userId) async {
    final res = await http.get(Uri.parse("$_base/follow/followers/$userId"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception("Get followers users failed: ${res.statusCode} - ${res.body}");
  }

  Future<void> followUser({required String followingId}) async {
    final token = await _idToken();
    final res = await http.post(
      Uri.parse("$_base/follow"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"followingId": followingId}),
    );

    if (res.statusCode == 200) return;
    throw Exception("Follow failed: ${res.statusCode} - ${res.body}");
  }

  Future<void> unfollowUser({required String followingId}) async {
    final token = await _idToken();

    // http.delete có body được (Object? body) [web:743]
    final res = await http.delete(
      Uri.parse("$_base/follow"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"followingId": followingId}),
    );

    if (res.statusCode == 200) return;
    throw Exception("Unfollow failed: ${res.statusCode} - ${res.body}");
  }
}
