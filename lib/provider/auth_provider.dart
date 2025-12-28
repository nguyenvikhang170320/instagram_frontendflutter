import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:instagram/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- ĐĂNG KÝ ---
  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String fullname,
    required BuildContext context, // Để show Toast nếu cần
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.register(
        email: email,
        password: password,
        username: username,
        fullname: fullname,
      );
      _isLoading = false;
      notifyListeners();
      return true; // Đăng ký thành công
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Lỗi đăng ký: $e"); // Bạn có thể show Toast lỗi ở UI dựa vào return false
      return false;
    }
  }

  // --- ĐĂNG NHẬP ---
  // --- ĐĂNG NHẬP ---
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);

      if (data['success'] == true) {
        String token = data['token'];
        String userId = data['userId'];

        // 1. Lưu Token và UserId vào bộ nhớ (Code cũ)
        await _storage.write(key: "auth_token", value: token);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("userId", userId);
        await prefs.setString("token", token);

        // 👇 2. BƯỚC QUAN TRỌNG: Đăng nhập vào Firebase SDK 👇
        try {
          print("🔄 Đang xác thực Firebase SDK với token...");
          await FirebaseAuth.instance.signInWithCustomToken(token);
          print("✅ Đăng nhập Firebase SDK thành công!");
        } catch (e) {
          print("❌ Lỗi đăng nhập Firebase SDK: $e");
          // Nếu bước này lỗi, Firestore sẽ vẫn bị permission-denied
        }
        // ☝️ Hết phần thêm mới ☝️

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(data['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("❌ Lỗi đăng nhập: $e");
      return false;
    }
  }
}
