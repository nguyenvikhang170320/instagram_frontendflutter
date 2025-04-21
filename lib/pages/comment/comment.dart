import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/provider/notification_provider.dart';
import 'package:instagram/sharepreference/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String userId; // Thêm userId vào constructor
  final String senderId; // Thêm userId vào constructor
  const CommentScreen(
      {Key? key,
      required this.postId,
      required this.senderId,
      required this.userId})
      : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  TextEditingController _commentController = TextEditingController();
  List<dynamic> comments = [];
  int commentCount = 0;
  bool isLoading = true;

  late String profileImage = "";

  @override
  void initState() {
    super.initState();
    fetchComments();
    fetchCommentCount();
    fetchUserAvatar(); // 🛠 Thêm hàm này
  }

  void sendCommentNotification(String senderId, String postId) async {
    final userId = await getUserId(); // người thực hiện hành động (like)

    if (userId != null && userId != senderId) {
      Provider.of<NotificationProvider>(context, listen: false)
          .createNotification(
        userId, // người thực hiện hành động
        senderId, // người nhận thông báo
        postId,
        'comment', // hoặc 'comment', 'share_post', ...
      );
    }
  }

// 🛠 Hàm lấy avatar của người dùng hiện tại
  Future<void> fetchUserAvatar() async {
    try {
      final response = await http
          .get(Uri.parse("${dotenv.env['BASE_URL']}/users/${widget.userId}"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return; // Kiểm tra widget còn tồn tại trước khi setState
        setState(() {
          profileImage =
              data['avatar'] ?? ""; // 🛠 Nếu không có avatar, trả về chuỗi rỗng
        });
      } else {
        throw Exception("Lỗi khi lấy avatar!");
      }
    } catch (error) {
      print("Lỗi lấy avatar: $error");
    }
  }

  // Gọi API lấy danh sách bình luận
  Future<void> fetchComments() async {
    try {
      final response = await http.get(
          Uri.parse("${dotenv.env['BASE_URL']}/comments/${widget.postId}"));

      if (response.statusCode == 200) {
        if (!mounted) return; // Kiểm tra widget còn tồn tại trước khi setState
        setState(() {
          comments = json.decode(response.body);
          isLoading = false;
          print("Dữ liệu từ API:");
          print(comments);
        });
      } else {
        throw Exception("Lỗi khi tải bình luận!");
      }
    } catch (error) {
      print("Lỗi: $error");
      if (!mounted) return; // Kiểm tra widget còn tồn tại trước khi setState
      setState(() {
        isLoading = false;
      });
    }
  }

  // Gọi API lấy số lượng bình luận
  Future<void> fetchCommentCount() async {
    try {
      final response = await http.get(Uri.parse(
          "${dotenv.env['BASE_URL']}/comments/count/${widget.postId}"));

      if (response.statusCode == 200) {
        setState(() {
          commentCount = json.decode(response.body)['commentCount'];
        });
      }
    } catch (error) {
      print("Lỗi: $error");
    }
  }

  // Gửi bình luận lên API
  Future<void> postComment(String commentText) async {
    if (commentText.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/comment"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "postId": widget.postId,
          "userId": widget.userId, // 🛠 Gửi userId thay vì username
          "commentText": commentText, // 🛠 Đúng key với backend
          "createdAt": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        fetchComments();
        fetchCommentCount();
      } else {
        throw Exception("Không thể gửi bình luận!");
      }
    } catch (error) {
      print("Lỗi gửi bình luận: $error");
    }
  }

  String formatTime(dynamic timestamp) {
    if (timestamp == null) return "Không rõ thời gian";

    DateTime dateTime;
    if (timestamp is int) {
      // Nếu `createdAt` là timestamp kiểu int (seconds từ Epoch)
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      print(dateTime);
    } else if (timestamp is Map && timestamp.containsKey("_seconds")) {
      // Nếu `createdAt` trả về từ Firestore với kiểu Map chứa _seconds
      dateTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp["_seconds"] * 1000);
      print(dateTime);
    } else {
      return "Không rõ thời gian";
    }

    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return "Vừa xong";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} phút trước";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} giờ trước";
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    String? currentUserId = await getUserId();
    try {
      final response = await http.delete(
        Uri.parse("${dotenv.env['BASE_URL']}/comments/delete/$commentId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"userId": currentUserId}), // Gửi userId để kiểm tra quyền xóa
      );

      if (response.statusCode == 200) {
        setState(() {
          comments.removeWhere((c) => c['commentId'] == commentId);
        });

        ToastService.showSuccessToast(
          context,
          length: ToastLength.medium,
          expandedHeight: 100,
          message: "Xóa bình luận thành công!",
        );
      } else if (response.statusCode == 403) {
        // Nếu không có quyền xóa
        ToastService.showWarningToast(
          context,
          length: ToastLength.medium,
          expandedHeight: 100,
          message: "Bạn không có quyền xóa bình luận này!",
        );
      } else {
        throw Exception("Lỗi xóa bình luận");
      }
    } catch (e) {
      print("Lỗi khi xóa bình luận: $e");
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Không thể xóa bình luận!",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bình luận ($commentCount)"),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      var comment = comments[index];
                      print(comments);
                      print(comment);
                      return _buildComment(
                          avatar: comment['avatar'],
                          username: comment['username'],
                          comment: comment['commentText'] ??
                              'Lỗi: Không có nội dung', // 🛠 Đúng key với backend
                          time: formatTime(comment['createdAt']),
                          commentId:
                              comment['commentId'] // Cần xử lý thời gian đúng
                          );
                    },
                  ),
          ),
          _buildCommentInput(profileImage),
        ],
      ),
    );
  }

  Widget _buildComment(
      {required String username,
      required String avatar,
      required String comment,
      required String time,
      required String commentId}) {
    return GestureDetector(
      onLongPress: () {
        _showDeleteDialog(commentId);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
          backgroundImage: avatar.isNotEmpty
              ? NetworkImage(avatar)
              : AssetImage("assets/images/user.jpg") as ImageProvider,
        ),
        title: Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment),
            Text(time, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Icon(Icons.favorite_border, color: Colors.white),
      ),
    );
  }

  Widget _buildCommentInput(String profileImage) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey,
            backgroundImage: profileImage.isNotEmpty
                ? NetworkImage(profileImage)
                : AssetImage("assets/images/user.jpg") as ImageProvider,
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _commentController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Nhập bình luận...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blue),
            onPressed: () async {
              postComment(_commentController.text);
              final String? userId = await getUserId(); // Người gửi bình luận

              if (userId != null) {
                String senderId =
                    widget.senderId; // Người nhận bình luận (người đã đăng bài)
                String postId = widget.postId; // ID của bài viết

                // Tạo thông báo cho người đã đăng bài (senderId là người đăng bài)
                sendCommentNotification(senderId, postId);
              } else {
                print("⚠️ Không thể lấy userId");
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận xóa"),
          content: Text("Bạn có chắc muốn xóa bình luận này không?"),
          actions: [
            TextButton(
              child: Text("Hủy", style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Xóa", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                _deleteComment(commentId);
              },
            ),
          ],
        );
      },
    );
  }
}
