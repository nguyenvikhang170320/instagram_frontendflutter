import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
class PostService {
  Future<String> _idToken() async {
    final token = await getToken();
    if (token == null) throw Exception("Chưa đăng nhập / không lấy được ID token");
    return token;
  }

  /// 1) Upload post: POST /posts/upload (auth, multipart: image + caption)
  Future<Map<String, dynamic>> uploadPost({
    required File imageFile,
    required String caption,
  }) async {
    final token = await _idToken();
    final uri = Uri.parse("${dotenv.env['BASE_URL']}/posts/upload");

    final request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer $token"; // header auth [web:35][web:442]
    request.fields["caption"] = caption;

    request.files.add(
      await http.MultipartFile.fromPath(
        "image",
        imageFile.path,
        filename: p.basename(imageFile.path),
        contentType: () {
          final mime = lookupMimeType(imageFile.path) ?? "image/jpeg";
          final parts = mime.split("/");
          return MediaType(parts[0], parts[1]);
        }(),
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>; // {postId, imageUrl, message}
    }
    throw Exception("Upload failed: ${streamed.statusCode} - $body");
  }

  /// 2) Get posts of a user: GET /posts/:userId
  Future<List<Map<String, dynamic>>> fetchUserPosts(String userId) async {
    final uri = Uri.parse("${dotenv.env['BASE_URL']}/posts/$userId");
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception("Fetch posts failed: ${res.statusCode} - ${res.body}");
  }

  /// 3) Delete post: DELETE /posts/:postId (auth)
  Future<void> deletePost(String postId) async {
    final token = await _idToken();
    final uri = Uri.parse("${dotenv.env['BASE_URL']}/posts/$postId");

    final res = await http.delete(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Delete failed: ${res.statusCode} - ${res.body}");
    }
  }
}
