import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/pages/story/story_upload.dart';
import 'package:instagram/pages/story/story_view_screen.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/widgets/story_view.dart';

class StoryWidget extends StatefulWidget {
  @override
  _StoryWidgetState createState() => _StoryWidgetState();
}

class _StoryWidgetState extends State<StoryWidget> {
  List<dynamic> stories = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    String? id = await getUserId();
    setState(() {
      userId = id;
    });
    fetchStories(); // Gọi fetchStories sau khi có userId
  }

  Future<void> fetchStories() async {
    final response =
        await http.get(Uri.parse('${dotenv.env['BASE_URL']}/stories/list'));
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          stories = jsonDecode(response.body);
        });
      }
    }
  }

  void _onStoryUploaded() {
    fetchStories(); // Reload danh sách story sau khi đăng
  }

  @override
  Widget build(BuildContext context) {
    bool hasUserStory = stories.any((story) => story['userId'] == userId);

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1, // Luôn có nút "Tin của bạn"
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryButton(context, hasUserStory);
          }
          final story = stories[index - 1];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryViewScreen(story: story),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: (story['avatar'] != null &&
                            story['avatar'].isNotEmpty)
                        ? CachedNetworkImageProvider(story['avatar'])
                        : AssetImage('assets/images/user.jpg') as ImageProvider,
                  ),
                  SizedBox(height: 5),
                  Text(story['username'], style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Hiển thị nút "Tin của bạn"
  Widget _buildAddStoryButton(BuildContext context, bool hasUserStory) {
    return GestureDetector(
      onTap: () async {
        String? userId = await getUserId();
        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StoryUploadScreen(userId: userId), // Mở trang đăng story
            ),
          ).then((_) => _onStoryUploaded()); // Reload stories sau khi đăng
        } else {
          print("⚠️ Chưa tìm thấy userId trong SharedPreferences");
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.purple.withOpacity(0.2),
                  backgroundImage:
                      AssetImage("assets/images/user.jpg") as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text("Tin của bạn", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
