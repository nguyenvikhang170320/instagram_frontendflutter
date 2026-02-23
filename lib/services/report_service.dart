import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/sharepreference/sharepre.dart'; // để lấy token

class ReportService {
  static Future<List<dynamic>> getMyReports() async {
    final token = await getToken();
    print("TOKEN: $token");

    final url = Uri.parse("${dotenv.env['BASE_URL']}/report/my-reports");
    print("URL: $url");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Không thể tải danh sách báo cáo");
    }
  }

  static Future<bool> reportPost(
      String targetId,
      String reason,
      String targetType,
      ) async {

    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse("${dotenv.env['BASE_URL']}/report");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "targetId": targetId,
        "targetType": targetType,
        "reason": reason,
        "description": "",
      }),
    );

    return response.statusCode == 201;
  }
}