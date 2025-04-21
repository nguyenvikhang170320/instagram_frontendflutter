import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story_view/story_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoryViewScreen extends StatefulWidget {
  final dynamic story;

  StoryViewScreen({required this.story});

  @override
  _StoryViewScreenState createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final StoryController storyController = StoryController();
  String? userId;
  String? currentStoryId;
  Set<String> viewedStories = {}; // Lưu danh sách story đã xem

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) {
      if (widget.story?['stories'] != null &&
          widget.story['stories'].isNotEmpty) {
        String? firstStoryId = widget.story['stories'][0]['storyId'];
        if (firstStoryId != null && firstStoryId.isNotEmpty) {
          setState(() => currentStoryId = firstStoryId);
          _markStoryAsViewed(firstStoryId);
        }
      }
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    if (userId == null || userId!.isEmpty) {
      print("❌ [DEBUG] userId null, không thể gửi request");
    } else {
      print("🟢 [DEBUG] userId: $userId");
    }
  }

  void _markStoryAsViewed(String storyId) async {
    if (storyId.isEmpty || userId == null || userId!.isEmpty) return;
    if (viewedStories.contains(storyId)) return; // Nếu đã xem, bỏ qua

    viewedStories.add(storyId);
    print("📌 Gửi request đánh dấu đã xem story: $storyId");

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/stories/$storyId/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        print("✅ Đã xem story: $storyId");
      } else {
        print("❌ API lỗi khi đánh dấu đã xem: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối API: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> storiesData = widget.story['stories'] ?? [];
    List<StoryItem> storyItems = storiesData.map<StoryItem>((storyItem) {
      return StoryItem.pageImage(
        url: storyItem['imageUrl'],
        controller: storyController,
        caption: Text("Story"),
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.remove_red_eye, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StoryView(
        storyItems: storyItems,
        controller: storyController,
        onComplete: () {
          if (!mounted) return;
          print("Story đã hoàn thành!");
          Navigator.pop(context);
        },
        progressPosition: ProgressPosition.top,
        repeat: false,
        onStoryShow: (storyItem, index) {
          if (index > storiesData.length) {
            String newStoryId = storiesData[index]['storyId'];

            if (currentStoryId != newStoryId) {
              setState(() => currentStoryId = newStoryId);
              _markStoryAsViewed(newStoryId);
            }

            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                storyController.next();
              }
            });
          }
        },
      ),
    );
  }
}
