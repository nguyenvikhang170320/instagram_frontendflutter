import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
class VideoService {
  static String get _base => '${dotenv.env['BASE_URL']}/video';

  /// GET /video/videos (feed)
  static Future<List<Map<String, dynamic>>> fetchAllVideos() async {
    final res = await http.get(
      Uri.parse('$_base/videos'),
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final videos = body['videos'];
      if (body['success'] == true && videos is List) {
        return videos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }
    throw Exception('Fetch all videos failed: ${res.statusCode} - ${res.body}');
  }

  /// GET /video/videos/:userId (profile videos)
  static Future<List<Map<String, dynamic>>> fetchUserVideos(String userId) async {
    final res = await http.get(
      Uri.parse('$_base/videos/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final videos = body['videos'];
      if (body['success'] == true && videos is List) {
        return videos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }
    throw Exception('Fetch user videos failed: ${res.statusCode} - ${res.body}');
  }

  /// POST /video/upload (multipart)
  static Future<Map<String, dynamic>> uploadVideo({
    required String filePath,
    String caption = "",
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Missing token");

    final req = http.MultipartRequest('POST', Uri.parse('$_base/upload'));
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['caption'] = caption;

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

    if (streamed.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(respStr) as Map);
    }
    Map<String, dynamic>? errJson;
    try { errJson = jsonDecode(respStr) as Map<String, dynamic>; } catch (_) {}

    final msg = (errJson?['message'] ?? respStr).toString();
    throw Exception(msg);
  }

  /// DELETE /video/delete/:videoId
  static Future<void> deleteVideo(String videoId) async {
    final token = await getToken();
    if (token == null) throw Exception("Missing token");

    final res = await http.delete(
      Uri.parse('$_base/delete/$videoId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) return;
    throw Exception('Delete video failed: ${res.statusCode} - ${res.body}');
  }
}
