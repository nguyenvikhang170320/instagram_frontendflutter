import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ReportService {
  static Future<bool> reportPost(String postId, String userId, String reason) async {
    final url = Uri.parse("${dotenv.env['BASE_URL']}/report");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "postId": postId,
        "reporterId": userId,
        "reason": reason,
      }),
    );

    return response.statusCode == 200;
  }
}