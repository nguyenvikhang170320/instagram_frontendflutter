import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['BASE_URL'] ?? '',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {"Content-Type": "application/json"},
      ),
    );
  }

  Future<dynamic> register({
    required String email,
    required String password,
    required String username,
    required String fullname,
  }) async {
    final response = await _dio.post(
      "/auth/register",
      data: {
        "email": email,
        "password": password,
        "username": username,
        "fullname": fullname,
      },
    );
    return response.data;
  }

  Future<dynamic> login(String email, String password) async {
    final response = await _dio.post(
      "/auth/login",
      data: {"email": email, "password": password},
    );
    return response.data;
  }

  Future<dynamic> forgotPassword({required String email}) async {
    final response = await _dio.post(
      "/auth/forgot-password",
      data: {"email": email},
    );
    return response.data;
  }

  Future<dynamic> resetPassword({
    required String email,
    required String newPassword,
    required String otp,
  }) async {
    final response = await _dio.post(
      "/auth/reset-password",
      data: {"email": email, "newPassword": newPassword, "otp": otp},
    );
    return response.data;
  }
}
