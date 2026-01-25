import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../model/story_model.dart';

class StoryService {

  // 1. Lấy danh sách Story (Feed)
  Future<List<StoryGroup>> fetchStories(String token) async {
    final response = await http.get(
      Uri.parse('${dotenv.env['BASE_URL']}/stories/list'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => StoryGroup.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stories: ${response.body}');
    }
  }

  // 2. Upload Story (Multipart File)
  Future<bool> uploadStory(String token, File imageFile) async {
    try {
      var url = Uri.parse('${dotenv.env['BASE_URL']}/stories/upload');
      var request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';

      // --- SỬA ĐOẠN NÀY ---
      // Xác định loại ảnh (JPEG hay PNG)
      String path = imageFile.path.toLowerCase();
      MediaType contentType;

      if (path.endsWith(".png")) {
        contentType = MediaType('image', 'png');
      } else if (path.endsWith(".jpg") || path.endsWith(".jpeg")) {
        contentType = MediaType('image', 'jpeg');
      } else {
        contentType = MediaType('image', 'jpeg'); // Mặc định
      }

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: contentType, // 👈 QUAN TRỌNG NHẤT: Gửi kèm Content-Type
      ));
      // --------------------

      print("📤 Đang gửi ảnh lên: $url với type $contentType");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("🔁 Status Code: ${response.statusCode}");
      print("📦 Server Response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Lỗi upload: $e");
      return false;
    }
  }

  // 3. Đánh dấu đã xem Story
  Future<void> viewStory(String token, String storyId) async {
    await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/stories/$storyId/view'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  // 4. Lấy danh sách người xem (Backend trả về List User)
  Future<List<Map<String, dynamic>>> fetchViewers(String token, String storyId) async {
    final response = await http.get(
      Uri.parse('${dotenv.env['BASE_URL']}/stories/$storyId/viewers'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    return []; // Trả về rỗng nếu lỗi hoặc không có quyền
  }
  // 5. Xóa Story
  Future<bool>deleteStory(String token, String storyId) async {
    final response = await http.delete(
      Uri.parse('${dotenv.env['BASE_URL']}/stories/$storyId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete story');
    }
    return response.statusCode == 200;
  }
}