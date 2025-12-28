import 'package:flutter/material.dart';
import 'package:instagram/provider/feed_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ QUAN TRỌNG: Import cái này

// 1. Lưu UserId
Future<void> saveUserId(String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', userId);
}

// 2. Lưu Custom Token (Chỉ dùng để debug hoặc login lại khi cần thiết)
Future<void> saveToken(String token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Đổi key thành 'custom_token' để phân biệt với ID Token
  await prefs.setString('custom_token', token);
}

// 3. Lấy UserId
Future<String?> getUserId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');

  if (userId == null || userId.isEmpty) {
    print("⚠️ [Utils] Không tìm thấy userId trong bộ nhớ.");
    // Nếu app đang chạy mà mất userId, thử lấy từ Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("♻️ [Utils] Fallback: Lấy userId từ Firebase Auth: ${user.uid}");
      return user.uid;
    }
  }
  return userId;
}

// 4. Lấy Token (HÀM QUAN TRỌNG NHẤT - ĐÃ SỬA LỖI TYPE)
Future<String?> getToken() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      // ✅ SỬA Ở ĐÂY: Thêm dấu ? sau chữ String
      String? idToken = await user.getIdToken(true);
      print("🟢 [FirebaseAuth] Lấy ID Token mới thành công!");
      return idToken;
    } catch (e) {
      print("❌ [FirebaseAuth] Lỗi lấy ID Token: $e");
    }
  }

  // ... (Phần lấy từ SharedPreferences giữ nguyên) ...
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedToken = prefs.getString('custom_token') ?? prefs.getString('token');
  print("⚠️ [Utils] Đang dùng Token lưu trữ: $storedToken");
  return storedToken;
}

// 5. Đăng xuất (ĐÃ SỬA)
Future<void> logout(BuildContext context) async {
  try {
    print("🔄 Bắt đầu đăng xuất...");

    // B1: Xóa dữ liệu SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Hoặc xóa từng cái: await prefs.remove('userId'); await prefs.remove('custom_token');
    print("✅ Đã xóa SharedPreferences");

    // B2: Đăng xuất khỏi Firebase SDK (CỰC KỲ QUAN TRỌNG)
    // Nếu thiếu dòng này, lần sau mở app lên Firebase vẫn tưởng user đang login
    await FirebaseAuth.instance.signOut();
    print("✅ Đã đăng xuất Firebase Auth");

    // B3: Reset State của Provider (để tránh hiện dữ liệu cũ)
    if (context.mounted) {
      Provider.of<FeedProvider>(context, listen: false).clearFeed();
      // Nếu có ProfileProvider, NotificationProvider... thì clear luôn ở đây
    }

    // B4: Chuyển về màn hình Login
    await Future.delayed(const Duration(milliseconds: 300));
    if (context.mounted) {
      // Dùng pushNamedAndRemoveUntil để xóa sạch lịch sử back về home
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    }
  } catch (e) {
    print("❌ Lỗi khi đăng xuất: $e");
  }
}