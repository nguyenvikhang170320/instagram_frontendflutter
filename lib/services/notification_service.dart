import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../sharepreference/sharepre.dart';

class NotificationService {
  String get _base => dotenv.env['BASE_URL'] ?? "";

  Future<String> _token() async {
    final t = await getToken();
    if (t == null || t.isEmpty) throw Exception("Missing token");
    return t;
  }

  Future<List<dynamic>> fetchMyNotifications() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse("$_base/notifications"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception("Fetch notifications failed: ${res.statusCode} - ${res.body}");
  }

  Future<void> createNotification({
    required String receiverId,
    required String type,
    String? postId,
    String? message,
  }) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse("$_base/notifications/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "receiverId": receiverId,
        "type": type,
        "postId": postId,
        "message": message ?? "",
      }),
    );

    if (res.statusCode == 201) return;
    throw Exception("Create notification failed: ${res.statusCode} - ${res.body}");
  }

  Future<void> markAsRead(String notificationId) async {
    final token = await _token();
    final res = await http.put(
      Uri.parse("$_base/notifications/read/$notificationId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) return;
    throw Exception("Mark read failed: ${res.statusCode} - ${res.body}");
  }
}
