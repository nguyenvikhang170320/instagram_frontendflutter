import 'package:flutter/material.dart';
import 'package:instagram/pages/story/story_feed_widget.dart';
import 'package:provider/provider.dart';

import 'package:instagram/provider/feed_provider.dart';
import 'package:instagram/provider/like_provider.dart';
import 'package:instagram/provider/post_provider.dart';
import 'package:instagram/provider/notification_provider.dart';
import 'package:instagram/sharepreference/sharepre.dart';

import 'package:instagram/pages/home/posthome_widget.dart';
import 'package:instagram/pages/notification/notification_screen.dart';
import 'package:instagram/pages/chat/chat_list_screen.dart';
import 'package:instagram/pages/story/story_feed_widget.dart';

import '../../provider/save_provider.dart';

class FeedScreen extends StatefulWidget {
  final String userId;
  const FeedScreen({super.key, required this.userId});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final Map<String, bool> savedPosts = {}; // tạm giữ local như bạn đang làm
  String currentUserId = "";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = await getUserId();
      if (!mounted || uid == null) return;

      setState(() => currentUserId = uid);

      // Feed chung (following feed)
      await context.read<FeedProvider>().fetchFeed(uid);

      // Like state
      await context.read<LikeProvider>().fetchLikedPosts(uid);

      //comment,save
      context.read<SaveProvider>().fetchSavedPosts();
      context.read<LikeProvider>().fetchLikedPosts(uid);

      // Notifications
      await context.read<NotificationProvider>().fetchNotifications();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Instagram TK",
            style: TextStyle(fontFamily: 'Billabong', fontSize: 32)),
        centerTitle: false,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, noti, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) =>  NotificationScreen()),
                      );
                    },
                  ),

                  if (noti.unreadCount > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${noti.unreadCount}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatListScreen(currentUserId: currentUserId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Story: tạm giữ widget bạn đang có
           StoryFeedWidget(),

          Expanded(
            child: Consumer<FeedProvider>(
              builder: (context, feedProvider, child) {
                if (feedProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (feedProvider.posts.isEmpty) {
                  return const Center(child: Text("Không có bài viết nào"));
                }

                return ListView.builder(
                  itemCount: feedProvider.posts.length,
                  itemBuilder: (context, index) {
                    final post = feedProvider.posts[index];
                    final postId = post['postId'];
                    print("Id ảnh:"+postId);

                    return PostWidget(post: post);

                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
