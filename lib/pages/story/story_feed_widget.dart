import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../provider/story_provider.dart';
import '../../model/story_model.dart';
import 'create_story_screen.dart';
import 'story_view_screen.dart';

class StoryFeedWidget extends StatefulWidget {
  const StoryFeedWidget({Key? key}) : super(key: key);

  @override
  State<StoryFeedWidget> createState() => _StoryFeedWidgetState();
}

class _StoryFeedWidgetState extends State<StoryFeedWidget> {
  @override
  void initState() {
    super.initState();
    // Load story khi init widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).loadStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    final stories = storyProvider.storyGroups;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        // +1 cho nút "Tạo tin" của mình
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {

          // --- ITEM ĐẦU TIÊN: NÚT TẠO STORY CỦA TÔI ---
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Chuyển sang màn hình tạo story
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const CreateStoryScreen())
                          );
                        },
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: const NetworkImage("https://cdn.vectorstock.com/i/500p/68/24/instagram-logo-icon-ig-app-editable-svg-png-vector-56166824.jpg"), // Thay bằng avatar user hiện tại
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2))
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text("Tin của bạn", style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          }

          // --- CÁC ITEM SAU: STORY CỦA NGƯỜI KHÁC ---
          final group = stories[index - 1];
          // Check xem có story nào chưa xem không
          bool hasUnseen = group.stories.any((s) => !s.isViewed);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                // Mở màn hình xem Story, bắt đầu từ user này (index - 1 vì trừ đi nút Add)
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StoryViewScreen(
                        storyGroups: stories,
                        initialUserIndex: index - 1
                    )
                ));
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Viền: Đỏ nếu chưa xem, Xám nếu đã xem
                      gradient: hasUnseen
                          ? const LinearGradient(colors: [Colors.purple, Colors.orange])
                          : null,
                      color: hasUnseen ? null : Colors.grey[300],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: group.avatar.isNotEmpty
                            ? NetworkImage(group.avatar)
                            : null,
                        child: group.avatar.isEmpty ? const Icon(Icons.person) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    group.username.length > 10
                        ? '${group.username.substring(0, 8)}...'
                        : group.username,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}