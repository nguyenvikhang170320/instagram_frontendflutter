import 'package:dio/dio.dart';
import 'package:instagram/baseapi.dart';

class AuthService {
  final BaseApi _baseApi = BaseApi();

  // 1. Đăng ký
  Future<dynamic> register({
    required String email,
    required String password,
    required String username,
    required String fullname,
  }) async {
    try {
      final response = await _baseApi.dio.post("/auth/register", data: {
        "email": email,
        "password": password,
        "username": username,
        "fullname": fullname,
        // avatar, bio để rỗng như logic backend bạn gửi
      });
      return response.data;
    } catch (e) {
      throw e;
    }
  }

  // 2. Đăng nhập
  Future<dynamic> login(String email, String password) async {
    try {
      final response = await _baseApi.dio.post("/auth/login", data: {
        "email": email,
        "password": password,
      });
      // Backend trả về: { success: true, token: "...", userId: "..." }
      return response.data;
    } catch (e) {
      throw e;
    }
  }

  // 3. Quên mật khẩu
  Future<void> forgotPassword(String email) async {
    try {
      await _baseApi.dio.post("/auth/forgot-password", data: {"email": email});
    } catch (e) {
      throw e;
    }
  }
}