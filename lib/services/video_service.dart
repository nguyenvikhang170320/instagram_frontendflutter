import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class VideoService {
  static String get _base => '${dotenv.env['BASE_URL']}/video';

  /// ✅ Lấy video theo UserId (Nếu backend cần verify thì thêm header)
  static Future<List<Map<String, dynamic>>> fetchUserVideos(String userId, {String? token}) async {
    final headers = {"Content-Type": "application/json"};
    // Nếu backend yêu cầu đăng nhập mới được xem video profile:
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    final res = await http.get(
      Uri.parse('$_base/videos/$userId'),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final videos = body['videos'];
      if (body['success'] == true && videos is List) {
        return videos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }
    throw Exception('Fetch user videos failed: ${res.statusCode}');
  }

  /// ✅ Đăng video mới (Nhận token trực tiếp từ Provider)
  static Future<Map<String, dynamic>> uploadVideo({
    required String filePath,
    required String token, // <--- Yêu cầu truyền token từ ngoài vào
    String caption = "",
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/upload'));

    // Gắn Token vào Header
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['caption'] = caption;

    // Xử lý File
    final mimeType = lookupMimeType(filePath) ?? 'video/mp4';
    final parts = mimeType.split('/');

    req.files.add(
      await http.MultipartFile.fromPath(
        'video',
        filePath,
        filename: p.basename(filePath),
        contentType: MediaType(parts[0], parts[1]),
      ),
    );

    final streamed = await req.send();
    final respStr = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(respStr) as Map);
    }

    Map<String, dynamic>? errJson;
    try { errJson = jsonDecode(respStr) as Map<String, dynamic>; } catch (_) {}
    final msg = (errJson?['message'] ?? "Lỗi Upload ($streamed.statusCode)").toString();
    throw Exception(msg);
  }

  /// ✅ Xóa video (Nhận token trực tiếp từ Provider)
  static Future<void> deleteVideo({
    required String videoId,
    required String token, // <--- Yêu cầu truyền token từ ngoài vào
  }) async {
    final res = await http.delete(
      Uri.parse('$_base/delete/$videoId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Gửi token để verify quyền chủ sở hữu
      },
    );

    if (res.statusCode == 200) return;

    Map<String, dynamic>? errJson;
    try { errJson = jsonDecode(res.body) as Map<String, dynamic>; } catch (_) {}
    final msg = (errJson?['message'] ?? "Lỗi Xóa video").toString();
    throw Exception(msg);
  }
}