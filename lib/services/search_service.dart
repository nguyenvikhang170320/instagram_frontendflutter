import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SearchService {
  String get _base => dotenv.env['BASE_URL'] ?? "";

  Future<List<Map<String, dynamic>>> fetchUsersForSearch({
    required String currentUserId,
  }) async {
    final uri = Uri.parse("$_base/users/all/$currentUserId");
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception("Fetch users failed: ${res.statusCode} - ${res.body}");
  }
}
