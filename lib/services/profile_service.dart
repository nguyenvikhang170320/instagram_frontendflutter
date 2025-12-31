import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http_parser/http_parser.dart';

class ProfileService {
  final Dio _dio = Dio();

  Future<String> _getIdToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null) throw Exception("Chưa đăng nhập / không lấy được ID token");
    return token;
  }

  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    final res = await _dio.get("${dotenv.env['BASE_URL']}/users/$userId");
    if (res.statusCode == 200) return Map<String, dynamic>.from(res.data);
    throw Exception("Fetch profile failed: ${res.statusCode} - ${res.data}");
  }

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String username,
    required String fullname,
    required String bio,
    File? avatarFile,
  }) async {
    final idToken = await _getIdToken();

    Response res;

    if (avatarFile == null) {
      res = await _dio.put(
        "${dotenv.env['BASE_URL']}/users/update/$userId",
        data: {"username": username, "fullname": fullname, "bio": bio},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
    } else {
      final formData = FormData.fromMap({
        if (username != null) "username": username,
        if (fullname != null) "fullname": fullname,
        if (bio != null) "bio": bio,
        "avatar": await await MultipartFile.fromFile(
      avatarFile.path,
      filename: "avatar.jpg",
      contentType: MediaType("image", "jpeg"),
      ),
      });


      res = await _dio.put(
        "${dotenv.env['BASE_URL']}/users/update/$userId",
        data: formData,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
    }

    if (res.statusCode == 200) return Map<String, dynamic>.from(res.data);
    throw Exception("Update profile failed: ${res.statusCode} - ${res.data}");
  }
}
