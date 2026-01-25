import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../services/video_service.dart';
import '../sharepreference/sharepre.dart';

class WatchProvider extends ChangeNotifier {
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> videos = [];

  List<String> get videoUrls => videos
      .map((v) => (v['videoUrl'] ?? '').toString())
      .where((u) => u.isNotEmpty)
      .toList();

  // Hàm này sẽ lấy Token chuẩn nhất
  Future<String?> _getFreshToken() async {
    // 1. Ưu tiên lấy từ Firebase vì nó tự làm mới (Refresh) nếu hết hạn
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      // Sau khi lấy được token mới, bạn có thể cập nhật lại vào SharedPreferences nếu muốn
      if (token != null) await saveIdToken(token);
      return token;
    }

    // 2. Nếu Firebase không có (offline hoặc lỗi), mới lấy từ SharedPreferences
    return await getToken();
  }

  // ✅ 1. UPLOAD VIDEO (Đã sửa verifyToken)
// File: provider/watch_provider.dart

  Future<bool> uploadVideo({
    required String filePath,
    required String token, // ✅ Ép buộc truyền token từ UI
    String caption = "",
  }) async {
    error = null;
    // loading = true; // Nếu bạn có biến loading thì bật ở đây
    // notifyListeners();

    try {
      // 🚩 ĐÃ XÓA dòng: final token = await _getFreshToken();
      // Để dùng đúng cái 'token' nhận từ tham số hàm.

      final res = await VideoService.uploadVideo(
        filePath: filePath,
        caption: caption,
        token: token,
      );

      if (res['success'] == true) {
        // Bạn có thể thông báo cập nhật dữ liệu ở đây nếu cần
        return true;
      } else {
        // Lưu lại message lỗi từ backend để UI hiển thị Toast
        error = res['message'] ?? "Đăng video thất bại";
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Lỗi Upload: $e");
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ✅ 2. DELETE VIDEO (Đã sửa verifyToken)
  Future<bool> deleteVideo(String videoId) async {
    error = null;

    // Optimistic remove: Xóa tạm trên UI để tạo cảm giác mượt mà
    final prev = List<Map<String, dynamic>>.from(videos);
    videos = prev.where((v) => (v['id'] ?? '').toString() != videoId).toList();
    notifyListeners();

    try {
      final token = await _getFreshToken();
      if (token == null) throw Exception("Token không tồn tại");

      await VideoService.deleteVideo(videoId: videoId, token: token);
      return true;
    } catch (e) {
      // Nếu lỗi (ví dụ backend báo 403) thì rollback lại danh sách cũ
      videos = prev;
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ✅ 3. FETCH USER VIDEOS
  Future<void> fetchUserVideos(String userId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      // Đối với trang Profile cá nhân, thường backend cũng cần verifyToken
      // để đảm bảo chỉ chủ sở hữu mới thấy được video riêng tư (nếu có)
      final token = await _getFreshToken();
      videos = await VideoService.fetchUserVideos(userId, token: token);
    } catch (e) {
      error = e.toString();
      videos = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    loading = false;
    error = null;
    videos = [];
    notifyListeners();
  }
}