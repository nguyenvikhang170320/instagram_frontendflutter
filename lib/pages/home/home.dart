import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:instagram/model/story_model.dart';
import 'package:instagram/pages/chat/chat_list_screen.dart';
import 'package:instagram/pages/notification/notification_screen.dart';
import 'package:instagram/pages/story/story_widget.dart';
import 'package:instagram/provider/feed_provider.dart';
import 'package:instagram/provider/notification_provider.dart';
import 'package:instagram/sharepreference/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:instagram/pages/home/posthome_widget.dart';

class FeedScreen extends StatefulWidget {
  final String userId;
  FeedScreen({required this.userId});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> posts = [];
  Map<String, bool> savedPosts = {}; // Lưu trạng thái isSave của từng bài viết
  Map<String, bool> likedPosts = {}; // Lưu trạng thái like của từng bài viết
  List<Story> stories = []; // Danh sách Story
  bool isLoading = true;
  String currentUserId = "";
  String currentUserAvatar = "";
  List<Story> _stories = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      feedProvider.fetchFeed(); // Gọi API lấy danh sách bài viết
      fetchLikedPosts(); // Gọi API lấy trạng thái like
      fetchSavedPosts(); // Gọi API lấy trạng thái đã lưu
      loadUserData();
      _fetchStories();
      // _loadUserIdAndFetchNotifications();
    });
  }

  void _loadUserIdAndFetchNotifications() async {
    String? userId = await getUserId(); // Lấy userId từ SharedPreferences

    if (userId != null) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications(userId);
    }
  }

  Future<void> fetchLikedPosts() async {
    String? userId = await getUserId();
    if (userId == null) return;

    final response = await http.get(
      Uri.parse("${dotenv.env['BASE_URL']}/likes/user/$userId"),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        likedPosts = {for (var post in data) post['postId']: true};
      });
    } else {
      print("⚠️ Lỗi khi lấy danh sách bài viết đã like");
    }
  }

  Future<void> fetchSavedPosts() async {
    String? userId = await getUserId();
    if (userId == null) return;

    final response = await http.get(
      Uri.parse("${dotenv.env['BASE_URL']}/saved-posts/$userId"),
    );

    print("📡 API Response: ${response.body}"); // In ra để kiểm tra dữ liệu

    if (response.statusCode == 200) {
      try {
        final dynamic decodedData = jsonDecode(response.body);
        print("🧐 Dữ liệu data đã lưu ảnh: $decodedData");

        if (decodedData is List) {
          setState(() {
            savedPosts = {for (var post in decodedData) post['postId']: true};
          });
        } else {
          print("⚠️ Dữ liệu không phải List, kiểm tra lại API!");
        }
      } catch (e) {
        print("❌ Lỗi parse JSON: $e");
      }
    } else {
      print("⚠️ Lỗi khi lấy danh sách bài viết đã lưu");
    }
  }

  // Lấy userId từ SharedPreferences và avatar từ Firestore
  Future<void> loadUserData() async {
    String? userId = await getUserId();

    if (userId != null) {
      setState(() {
        currentUserId = userId;
      });

      // Truy vấn Firestore để lấy avatar
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        if (mounted) {
          setState(() {
            currentUserAvatar =
                userDoc['avatar'] ?? ""; // Avatar mặc định nếu không có
          });
        }
      }
    }
  }

  Future<void> _fetchStories() async {
    try {
      final response =
          await http.get(Uri.parse("${dotenv.env['BASE_URL']}/stories/list"));
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _stories = jsonData.map((data) => Story.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        print("⚠️ Lỗi tải stories: ${response.statusCode}");
      }
    } catch (error) {
      print("❌ Lỗi khi tải stories: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Instagram CLO",
            style: TextStyle(fontFamily: 'Billabong', fontSize: 32)),
        centerTitle: false,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationScreen()),
                      );
                      String? userId = await getUserId();
                      notificationProvider.markAllAsRead(userId!);
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${notificationProvider.unreadCount}",
                          style: TextStyle(
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
                  builder: (context) =>
                      ChatListScreen(currentUserId: currentUserId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Khu vực Story
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            StoryWidget(),

          Expanded(
            child: Consumer<FeedProvider>(
              builder: (context, feedProvider, child) {
                if (feedProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (feedProvider.posts.isEmpty) {
                  return Center(child: Text("Không có bài viết nào"));
                }
                return ListView.builder(
                  itemCount: feedProvider.posts.length,
                  itemBuilder: (context, index) {
                    final post = feedProvider.posts[index];
                    print("Trạng thái provider: $post");
                    final postId = post['postId'];
                    // bool isSaved = savedPosts.containsKey(postId)
                    //     ? savedPosts[postId]!
                    //     : false;

                    // print("Trạng thái đã lưu ảnh: $isSaved");

                    return PostWidget(
                      post: post,
                      isSave: savedPosts.containsKey(postId)
                          ? savedPosts[postId]!
                          : false,
                      isLiked: likedPosts.containsKey(postId)
                          ? likedPosts[postId]!
                          : false, // Truyền trạng thái like
                      onLikeChanged: (bool newValue) async {
                        setState(() {
                          likedPosts[postId] = newValue;
                        });
                      },
                      onSaveChanged: (bool newValueSave) async {
                        setState(() {
                          savedPosts[postId] = newValueSave;
                        });
                      },
                    );
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
