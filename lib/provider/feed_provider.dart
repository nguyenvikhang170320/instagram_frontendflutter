import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FeedProvider extends ChangeNotifier {
  String userId = "";
  List<dynamic> posts = [];
  bool isLoading = true;

  FeedProvider() {
    _initUserId();
  }

  /// Hàm khởi tạo userId từ SharedPreferences
  Future<void> _initUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId") ?? "";
    print("🟢 [FeedProvider] Lấy userId từ SharedPreferences: $userId");

    if (userId.isNotEmpty) {
      await fetchFeed(); // Gọi API khi có userId
    } else {
      isLoading = false; // Không có userId => không cần loading
      notifyListeners();
    }
  }

  /// Hàm lấy dữ liệu bài viết
  Future<void> fetchFeed() async {
    if (userId.isEmpty) {
      print("⚠️ userId chưa được khởi tạo, không gọi API.");
      return;
    }

    final apiUrl = "${dotenv.env['BASE_URL']}/profile/feed/$userId";
    isLoading = true;
    notifyListeners(); // Bắt đầu tải dữ liệu

    try {
      print("📡 Fetching feed from: $apiUrl");

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));

      print("API Response Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        posts = data["posts"] ?? [];
        print("✅ Posts fetched: ${posts.length}");
      } else {
        print("❌ Lỗi khi lấy dữ liệu: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối API: $e");
    }

    isLoading = false;
    notifyListeners(); // Cập nhật UI sau khi tải xong
  }

  /// Xóa bài viết khi đăng xuất
  void clearFeed() {
    posts = [];
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserId(String newUserId) async {
    userId = newUserId;
    notifyListeners(); // Cập nhật UI ngay khi userId thay đổi
    await fetchFeed(); // Gọi API lấy bài đăng mới
  }
}
