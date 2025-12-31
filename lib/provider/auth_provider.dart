import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:instagram/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sharepreference/sharepre.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;
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
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? "Đăng nhập thất bại");
      }

      final String customToken = data['token'];
      final String userId = data['userId'];

      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      final String? idToken =
      await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) throw Exception("Không lấy được Firebase ID token");

      await saveUserId(userId);
      await saveIdToken(idToken); // SharedPreferences setString [web:477]

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }




  // --- QUÊN MẬT KHẨU ---
  // Backend trả: { message: "...", otp: "123456" } (theo code bạn gửi)
  Future<String?> forgotPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // state đổi thì notify [web:61]

    try {
      final res = await _authService.forgotPassword(email: email);
      return res['otp']?.toString();
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners(); // state đổi thì notify [web:61]
    }
  }

  // --- RESET MẬT KHẨU ---
  // Backend trả status 200 nếu OK: { message: "..." }
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // [web:61]

    try {
      await _authService.resetPassword(
        email: email,
        newPassword: newPassword,
        otp: otp,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // [web:61]
    }
  }

  void clear() {
    _isLoading = false;
    _error = null;
    notifyListeners(); // [web:61]
  }
}
