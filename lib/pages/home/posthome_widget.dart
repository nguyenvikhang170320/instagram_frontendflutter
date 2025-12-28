import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:instagram/pages/comment/comment.dart';
import 'package:instagram/pages/report/report_modal.dart';
import 'package:instagram/pages/report/report_service.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

import '../../provider/notification_provider.dart';

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isSave;
  final ValueChanged<bool> onSaveChanged;
  final bool isLiked;
  final ValueChanged<bool> onLikeChanged;
  const PostWidget({
    Key? key,
    required this.post,
    required this.isSave,
    required this.isLiked,
    required this.onSaveChanged,
    required this.onLikeChanged,
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  String username = "Unknown";
  String avatarUrl = "";
  bool isSaved = false;
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;
  late String postId; // Khai báo biến postId
  @override
  void initState() {
    super.initState();
    isSaved = widget.isSave;
    isLiked = widget.isLiked;
    postId = widget.post['postId'] ?? ''; // Gán giá trị postId từ widget.post
    print("Trạng thái đã lưu ảnh ở phần postwidget: $isSaved");
    print("Trạng thái đã like ảnh ở phần postwidget: $isLiked");
    print("PostId: $postId");
    fetchUserData(widget.post['userId']);
    fetchLikeCount();
    fetchCommentCount();
  }

  //hiển thị số like
  Future<void> fetchLikeCount() async {
    int count = await getLikeCount(widget.post['postId']);
    if (!mounted) return; // Kiểm tra widget còn tồn tại trước khi setState
    setState(() {
      likeCount = count;
    });
  }

  Future<void> fetchCommentCount() async {
    int count = await getCommentCount(widget.post['postId']);
    if (!mounted) return;
    setState(() {
      commentCount = count;
    });
  }

  //hiển thị username and avatar người dùng
  Future<void> fetchUserData(String userId) async {
    try {
      final url = Uri.parse("${dotenv.env['BASE_URL']}/users/$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (!mounted) return; // Kiểm tra widget còn tồn tại trước khi setState
        setState(() {
          username = data['username'] ?? "Unknown";
          avatarUrl = (data['avatar'] != null && data['avatar'].isNotEmpty)
              ? data['avatar']
              : ""; // Để trống nếu không có URL
        });
      } else {
        print("⚠️ Lỗi lấy dữ liệu user: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Lỗi kết nối API: $e");
    }
  }

  Future<void> savePost(String postId, String postImageUrl) async {
    String? userId = await getUserId();
    if (userId == null) return;

    final response = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/save'),
      body: jsonEncode({
        "userId": userId,
        "postId": postId,
        "imageUrl": postImageUrl,
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      print("✅ Đã lưu bài viết");
      widget.onSaveChanged(true);
    } else {
      print("❌ Lỗi khi lưu bài viết: ${response.body}");
    }
  }

  Future<void> unsavePost(String postId) async {
    String? userId = await getUserId();
    if (userId == null) return;

    final response = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/unsave'),
      body: jsonEncode({
        "userId": userId,
        "postId": postId,
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      print("✅ Đã bỏ lưu bài viết");
      widget.onSaveChanged(false);
    } else {
      print("❌ Lỗi khi bỏ lưu bài viết: ${response.body}");
    }
  }

  //like ảnh
  Future<void> likePost(String postId) async {
    final userId = await getUserId();
    final response = await http.post(
      Uri.parse("${dotenv.env['BASE_URL']}/likes/like"),
      body: jsonEncode({"userId": userId, "postId": postId}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      print("Đã like bài viết");
    } else {
      print("Lỗi: ${response.body}");
    }
  }

  //xóa like
  Future<void> unlikePost(String postId) async {
    final userId = await getUserId();
    final response = await http.delete(
      Uri.parse("${dotenv.env['BASE_URL']}/likes/unlike"),
      body: jsonEncode({"userId": userId, "postId": postId}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      print("Đã bỏ like bài viết");
    } else {
      print("Lỗi: ${response.body}");
    }
  }

  //get like
  Future<int> getLikeCount(String postId) async {
    final response = await http.get(
      Uri.parse("${dotenv.env['BASE_URL']}/likes/$postId"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['likeCount']; // Nhận trực tiếp số lượt like từ backend
    } else {
      print("Lỗi: ${response.body}");
      return 0;
    }
  }

  //comment get count
  Future<int> getCommentCount(String postId) async {
    final response = await http
        .get(Uri.parse('${dotenv.env['BASE_URL']}/comments/count/$postId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['commentCount'];
    } else {
      return 0;
    }
  }

  //share
  void sharePost(String postContent, String postImage) async {
    String message = "📢 Nội dung: $postContent\n";

    if (postImage.isNotEmpty) {
      message += "🖼 Hình ảnh: $postImage";
    }

    await Share.share(message);
  }

  void _showReportModal(BuildContext context) async {
    String? userId = await getUserId();

    if (userId == null || postId == null) {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Không thể báo cáo! Thiếu thông tin.",
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (modalContext) => ReportModal(
        onReport: (reason) async {
          bool success = await ReportService.reportPost(postId, userId, reason);

          // Đóng modal bằng modalContext
          if (modalContext.mounted) {
            Navigator.of(modalContext).pop();
          }

          if (context.mounted) {
            if (success) {
              ToastService.showSuccessToast(
                context,
                length: ToastLength.medium,
                expandedHeight: 100,
                message: "Báo cáo bài viết thành công!",
              );
            } else {
              ToastService.showErrorToast(
                context,
                length: ToastLength.medium,
                expandedHeight: 100,
                message: "Báo cáo lỗi!",
              );
            }
          }
        },
      ),
    );
  }

  void sendNotification(String senderId, String postId, String type) async {
    final userId = await getUserId(); // người thực hiện hành động

    if (userId != null && userId != senderId) {
      Provider.of<NotificationProvider>(context, listen: false)
          .createNotification(
        userId, // người thực hiện hành động
        senderId, // người nhận thông báo
        postId,
        type, // dùng biến type thay vì cố định 'like'
      );
      print("✅ Thông báo đã được tạo!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : AssetImage("assets/images/user.jpg") as ImageProvider,
            ),
            title: Text(
              username,
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () => _showReportModal(context), // Mở modal khi bấm
            ),
          ),
          GestureDetector(
            child: Image.network(widget.post['imageUrl'],
                width: double.infinity, fit: BoxFit.cover),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: IconButton(
                    icon: Icon(
                      widget.isLiked
                          ? FontAwesomeIcons.solidHeart
                          : FontAwesomeIcons.heart,
                      color: widget.isLiked ? Colors.red : Colors.black,
                    ),
                    onPressed: () async {
                      String postId = widget.post['postId'];
                      if (widget.isLiked) {
                        await unlikePost(postId);
                        setState(() {
                          isLiked = false;
                          likeCount--; // Giảm số like
                        });
                        widget.onLikeChanged(false); // Cập nhật trạng thái
                      } else {
                        await likePost(postId);
                        setState(() {
                          isLiked = true;
                          likeCount++; // Tăng số like
                        });
                        widget.onLikeChanged(true);
                        String type = 'like';
                        print(type);
                        // String? userId = await getUserId();
                        String senderId = widget.post['userId'];
                        sendNotification(senderId, postId, 'like');
                      }
                    },
                  ),
                ),
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.comment),
                    onPressed: () async {
                      String postId = widget.post['postId'];
                      final String? userId = await getUserId();
                      String senderId = widget.post['userId'];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentScreen(
                              postId: postId,
                              senderId: senderId,
                              userId: userId!),
                        ),
                      );
                    },
                  ),
                ),
                Text('$commentCount bình luận',
                    style: TextStyle(color: Colors.black)),
                Expanded(
                  child: IconButton(
                    icon:
                        Icon(FontAwesomeIcons.paperPlane, color: Colors.black),
                    onPressed: () {
                      sharePost(
                          widget.post['caption'], widget.post['imageUrl']);
                      String type = 'share_post';
                      print(type);
                      // String? userId = await getUserId();
                      String senderId = widget.post['userId'];
                      sendNotification(senderId, postId, 'share_post');
                    },
                  ),
                ),
                SizedBox(
                  width: 120,
                ),
                Expanded(
                  child: IconButton(
                    icon: Icon(
                      widget.isSave ? Icons.bookmark : Icons.bookmark_border,
                      color: widget.isSave ? Colors.grey : Colors.black,
                    ),
                    onPressed: () async {
                      String postId = widget.post['postId'];
                      String postImageUrl = widget.post['imageUrl'];
                      final String? userId = await getUserId();
                      if (widget.isSave) {
                        await unsavePost(postId);
                        widget.onSaveChanged(false); // Cập nhật trạng thái
                      } else {
                        await savePost(postId, postImageUrl);
                        widget.onSaveChanged(true);
                        String type = 'save';
                        print(type);
                        // String? userId = await getUserId();
                        String senderId = widget.post['userId'];
                        sendNotification(senderId, postId, 'save');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$likeCount lượt thích',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text("$username ${widget.post['caption']}",
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
