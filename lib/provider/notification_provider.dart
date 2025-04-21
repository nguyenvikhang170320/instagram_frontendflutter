import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:instagram/model/notification.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;

  // Lấy danh sách notification từ backend
  Future<void> fetchNotifications(String userId) async {
    final response = await http
        .get(Uri.parse('${dotenv.env['BASE_URL']}/notifications/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _notifications =
          data.map((item) => NotificationModel.fromMap(item)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Tạo notification mới
  Future<void> createNotification(
      String userId, String senderId, String postId, String type) async {
    final response = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/notifications/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'senderId': senderId,
        'postId': postId,
        'type': type,
        'seen': false,
      }),
    );

    if (response.statusCode == 201) {
      await fetchNotifications(
          userId); // Lấy lại danh sách sau khi thêm thông báo mới
    } else {
      throw Exception('Failed to create notification');
    }
  }

  // Đánh dấu tất cả notification đã xem
  int unreadCount = 0;

  Future<void> fetchUnreadNotifications(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('seen', isEqualTo: false) // 🔹 Đổi từ isRead thành seen
          .get();

      unreadCount = snapshot.docs.length;
      print("🔹 Unread notifications: ${unreadCount}");

      notifyListeners();
    } catch (error) {
      print("Lỗi khi lấy số thông báo chưa đọc: $error");
    }
  }

  void markAllAsRead(String userId) async {
    var batch = FirebaseFirestore.instance.batch();

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('seen', isEqualTo: false) // 🔹 Đổi từ isRead thành seen
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {"seen": true});
    }

    await batch.commit();
    unreadCount = 0;
    notifyListeners();
  }
}
