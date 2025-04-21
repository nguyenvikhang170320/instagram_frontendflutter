import 'package:flutter/material.dart';
import 'package:instagram/provider/feed_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserId(String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', userId);
}

Future<void> saveToken(String token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}

Future<String?> getUserId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');
  if (userId == null || userId.isEmpty) {
    print("⚠ userId không hợp lệ, cần kiểm tra lại quá trình đăng nhập.");
  } else {
    print("✅ userId lấy từ SharedPreferences: $userId");
  } // Debug
  return userId;
}

Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  print("🟢 [SharedPreferences] getToken(): $token"); // Debug
  return token;
}

Future<void> logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Xóa userId và dữ liệu trong SharedPreferences
  await prefs.clear();
  print("✅ Đã xóa SharedPreferences");

  // Xóa userId trong FeedProvider
  Provider.of<FeedProvider>(context, listen: false).clearFeed();

  // Đợi một chút để đảm bảo dữ liệu cũ bị xóa trước khi chuyển màn hình
  await Future.delayed(Duration(milliseconds: 300));

  // Kiểm tra xem widget có còn tồn tại không trước khi chuyển trang
  if (context.mounted) {
    Navigator.pushReplacementNamed(context, "/login");
  }
}
