// verification_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VerificationService {
  static Future<Map<String, dynamic>> checkStatus(String userId) async {
    final url = '${dotenv.env['BASE_URL']}/verify-request/status/$userId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return {'isVerified': false, 'status': 'none'};
    } else {
      throw Exception('Lỗi khi kiểm tra trạng thái xác minh');
    }
  }

  static Future<bool> sendRequest({
    required String userId,
    required String username,
    required String fullName,
    required String bio,
  }) async {
    final url = '${dotenv.env['BASE_URL']}/verify-request/$userId';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'fullName': fullName,
        'bio': bio,
      }),
    );

    if (response.statusCode == 200) return true;
    throw Exception(
        jsonDecode(response.body)['message'] ?? 'Gửi yêu cầu thất bại');
  }
}
