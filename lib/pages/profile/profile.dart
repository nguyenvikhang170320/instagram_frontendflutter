import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/pages/watch/chewie_video_player.dart';
import 'package:instagram/pages/profile/editprofile.dart';
import 'package:instagram/pages/follow/followScreen.dart';
import 'package:instagram/pages/story/story_upload.dart';
import 'package:instagram/pages/story/story_widget.dart';
import 'package:instagram/services/verification_service.dart';
import 'package:instagram/pages/watch/video_item.dart';
import 'package:instagram/pages/watch/video_player_preview.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:mime/mime.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "";
  String fullname = "";
  String bio = "";
  String avatarUrl = "";
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<String> posts = [];
  List<String> savedImages = [];
  int selectedTab = 0; // 0: Grid, 1: Video, 2: Saved
  File? _selectedImage;
  List<String> videoUrls = [];
  late Future<List<String>> _savedPostsFuture;
  bool? isVerified;
  bool _requestSent = false;
  String _verificationStatus = '';
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  //load trang profile
  Future<void> _loadProfile() async {
    if (mounted) {
      _savedPostsFuture = getSavedPosts(widget.userId); //lưu ảnh
      await fetchProfileData(); // Gọi lại API để lấy thông tin mới nhất
      await fetchFollowData();
      await fetchUserPosts();
      await fetchUserVideos();
      checkVerificationStatus(); // ← gọi thêm ở đây
      setState(() {}); // Cập nhật giao diện
    }
  }

  //kiểm tra xác minh tài khoản
  Future<void> checkVerificationStatus() async {
    try {
      final result = await VerificationService.checkStatus(widget.userId);
      setState(() {
        isVerified = result['isVerified'] ?? false;
        _verificationStatus = result['status'] ?? '';
        _requestSent = (_verificationStatus == 'pending' ||
            _verificationStatus == 'approved');
      });
    } catch (e) {
      print("🔥 Lỗi khi kiểm tra xác minh: $e");
    }
  }

  //load dữ liệu trang cá nhân
  Future<void> fetchProfileData() async {
    final response = await http
        .get(Uri.parse('${dotenv.env['BASE_URL']}/users/${widget.userId}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        username = data['username'];
        fullname = data['fullname'];
        bio = data['bio'];
        avatarUrl = data['avatar'] ?? '';
      });
    } else {
      print("Lỗi khi lấy thông tin user");
    }
  }

  //load dữ liệu follow
  Future<void> fetchFollowData() async {
    final response = await http
        .get(Uri.parse('${dotenv.env['BASE_URL']}/follow/${widget.userId}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          followersCount = data['followersCount'];
          followingCount = data['followingCount'];
        });
      }
    } else {
      print("Lỗi khi lấy dữ liệu follow");
    }
  }

  //liên quan backend API post.js, load danh sách bài viết(ảnh)
  Future<void> fetchUserPosts() async {
    final response = await http
        .get(Uri.parse('${dotenv.env['BASE_URL']}/posts/${widget.userId}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          posts = data.map((post) => post['imageUrl'].toString()).toList();
          postCount = posts.length;
          print("🎥 Đã load số lượng  ${postCount} ảnh");
          print("🎥 Đã load ${posts} ảnh");
        });
      }
    } else {
      print("Lỗi khi lấy danh sách bài viết");
    }
  }

  //load ảnh đã lưu
  //load ảnh đã lưu
  Future<List<String>> getSavedPosts(String userId) async {
    try {
      // 1. 👇 LẤY TOKEN (Thêm dòng này)
      String? token = await getToken();

      if (token == null) {
        print("⚠️ Chưa có Token, không thể lấy bài viết đã lưu.");
        return [];
      }

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/saved-posts/"), // Đường dẫn đúng
        // 2. 👇 THÊM HEADER (Bắt buộc phải có cái này)
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("📡 API Response Saved Posts: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        if (decodedData is List) {
          print("🎥 Đã load ${decodedData.length} ảnh đã lưu");
          return List<String>.from(decodedData.map((post) => post['imageUrl']));
        } else {
          return [];
        }
      } else {
        print("❌ Lỗi API Saved Posts: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("🔥 Lỗi khi lấy bài viết đã lưu: $e");
      return [];
    }
  }

  //load video
  Future<void> fetchUserVideos() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/video/videos/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> videoData = body['videos'];
          setState(() {
            videoUrls =
                videoData.map((video) => video['videoUrl'].toString()).toList();
          });
          print("🎥 Đã load ${videoUrls.length} video");
        } else {
          print("⚠️ API trả về success=false");
        }
      } else {
        print("❌ Lỗi khi gọi API video: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Lỗi fetch video: $e");
    }
  }

  //build ảnh đã lưu
  Widget _buildSavedPosts() {
    return FutureBuilder<List<String>>(
      future: _savedPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi khi tải dữ liệu"));
        }

        final savedImages = snapshot.data ?? [];

        if (savedImages.isEmpty) {
          return Center(child: Text("Chưa lưu ảnh nào"));
        }

        return _buildGridPosts(savedImages);
      },
    );
  }

  //build ảnh bài đăng
  Widget _buildGridPosts(List<String> items) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(items[index]),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  //build video
  Widget _buildVideoGrid(List<String> videoUrls) {
    return GridView.builder(
      physics:
          NeverScrollableScrollPhysics(), // Để scroll toàn màn hình profile
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: videoUrls.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 9 / 16, // Tỉ lệ video dọc (TikTok-style)
      ),
      itemBuilder: (context, index) {
        final videoUrl = videoUrls[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: ChewieVideoPlayer(videoUrl: videoUrl),
                  ),
                ),
              ),
            );
          },
          child: Stack(
            children: [
              // Thumbnail hoặc loading
              Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: VideoPlayerPreview(videoUrl: videoUrl),
                ),
              ),
              // Icon play
              Positioned(
                right: 4,
                bottom: 4,
                child: Icon(Icons.play_circle_fill,
                    color: Colors.white70, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              username.isNotEmpty ? username : "Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black, // hoặc Colors.white nếu nền tối
              ),
            ),
            if (isVerified == true) ...[
              SizedBox(width: 4),
              Icon(
                Icons.verified,
                color: Colors.blue,
                size: 18,
              ),
            ],
            SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.black,
            ),
          ],
        ),
        actions: [
          // Nút gửi yêu cầu xác minh – chỉ hiển thị nếu chưa verified và chưa gửi
          if (isVerified == false && _requestSent == false)
            IconButton(
                icon: Icon(Icons.verified_outlined, color: Colors.blue),
                tooltip: 'Yêu cầu xác minh',
                onPressed: () async {
                  try {
                    final success = await VerificationService.sendRequest(
                      userId: widget.userId,
                      username: username,
                      fullName: fullname,
                      bio: bio,
                    );

                    if (success) {
                      setState(() => _requestSent = true);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("✅ Đã gửi yêu cầu"),
                          content: Text(
                              "Yêu cầu xác thực đã được gửi. Vui lòng chờ xét duyệt."),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("OK")),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("❌ Lỗi"),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("OK")),
                        ],
                      ),
                    );
                  }
                }),

          // Nút logout
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await logout(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                // Avatar + Chỉnh sửa ảnh
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : AssetImage("assets/images/user.jpg")
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () async {
                            String? userId = await getUserId();
                            if (userId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryUploadScreen(
                                      userId: userId), // Mở trang đăng story
                                ),
                              ); // Reload stories sau khi đăng
                            } else {
                              print(
                                  "⚠️ Chưa tìm thấy userId trong SharedPreferences");
                            }
                          }, // Khi bấm vào icon camera thì chọn ảnh
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Username + Tick xanh (nếu user verified)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nếu người dùng đã được xác minh, hiển thị tick xanh

                    Text(
                      fullname, // Hiển thị tên người dùng
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 5),

                // Bio của user
                Text(
                  bio,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),

                // Thông tin bài viết, followers, following
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoColumn(postCount, "Bài viết", false),
                    _buildInfoColumn(followersCount, "Người theo dõi",
                        false), // false -> followers
                    _buildInfoColumn(followingCount, "Đang theo dõi",
                        true), // true -> following
                  ],
                ),

                SizedBox(height: 10),

                // Nút chỉnh sửa profile
                ElevatedButton(
                  onPressed: () async {
                    bool? updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditProfileScreen()),
                    );

                    if (updated == true) {
                      _loadProfile(); // Load lại dữ liệu sau khi chỉnh sửa
                    }
                  },
                  child: Text('Chỉnh sửa trang cá nhân'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Divider ngăn cách
          Divider(),

          // Tabs (Bài viết - Video - Lưu)
          _buildProfileTabs(),

          // Nội dung các tab
          Expanded(
            child: selectedTab == 0
                ? (posts.isEmpty
                    ? Center(child: Text("Chưa có bài viết nào"))
                    : _buildGridPosts(posts))
                : selectedTab == 1
                    ? (videoUrls.isEmpty
                        ? Center(child: Text("Chưa có video nào"))
                        : _buildVideoGrid(videoUrls))
                    : _buildSavedPosts(),
          ),
        ],
      ),
    );
  }

  //build info
  Widget _buildInfoColumn(int count, String label, bool isFollowingTab) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            String? userId = await getUserId();
            if (userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowScreen(
                    userId: userId,
                    isFollowingTab:
                        isFollowingTab, // true: Đang theo dõi, false: Người theo dõi
                  ),
                ),
              );
            } else {
              print("Lỗi: Không lấy được userId");
            }
          },
          child: Text(
            "$count",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  //build profile tab
  Widget _buildProfileTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(FontAwesomeIcons.tableCells,
              color: selectedTab == 0 ? Colors.black : Colors.grey),
          onPressed: () => setState(() => selectedTab = 0),
        ),
        SizedBox(width: 40),
        IconButton(
          icon: Icon(FontAwesomeIcons.video,
              color: selectedTab == 1 ? Colors.black : Colors.grey),
          onPressed: () => setState(() => selectedTab = 1),
        ),
        SizedBox(width: 40),
        IconButton(
          icon: Icon(FontAwesomeIcons.solidBookmark,
              color: selectedTab == 2 ? Colors.black : Colors.grey),
          onPressed: () {
            setState(() => selectedTab = 2);
            getSavedPosts(widget.userId);
          },
        ),
      ],
    );
  }
}
