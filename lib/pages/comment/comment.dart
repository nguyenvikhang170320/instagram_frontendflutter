import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/provider/comment_provider.dart';
import 'package:instagram/provider/notification_provider.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String userId;   // current user
  final String senderId; // owner post

  const CommentScreen({
    super.key,
    required this.postId,
    required this.senderId,
    required this.userId,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  String profileImage = "";

  @override
  void initState() {
    super.initState();
    fetchUserAvatar();

    Future.microtask(() {
      if (!mounted) return;
      context.read<CommentProvider>().fetchComments(widget.postId);
    });
  }

  Future<void> fetchUserAvatar() async {
    try {
      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/users/${widget.userId}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          profileImage = (data['avatar'] ?? "").toString();
        });
      }
    } catch (_) {}
  }

  Future<void> sendCommentNotification() async {
    if (widget.userId == widget.senderId) return;

    await context.read<NotificationProvider>().createNotification(
      receiverId: widget.senderId,
      type: "comment",
      postId: widget.postId,
      message: "đã bình luận bài viết của bạn",
    );
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await context.read<CommentProvider>().addComment(
        postId: widget.postId,
        userId: widget.userId, // ✅ FIX
        text: text,
      );

      _commentController.clear();
      await sendCommentNotification();
      ToastService.showSuccessToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Bình luận thành công!",
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Không thể gửi bình luận!",
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await context.read<CommentProvider>().deleteComment(
        postId: widget.postId,
        commentId: commentId,
      );

      if (!mounted) return;
      ToastService.showSuccessToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Xóa bình luận thành công!",
      );
    } catch (_) {
      if (!mounted) return;
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Không thể xóa bình luận!",
      );
    }
  }
  void _showDeleteSheet(String commentId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Xóa",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteComment(commentId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  String formatTime(dynamic timestamp) {
    if (timestamp == null) return "Chưa cập nhật";

    try {
      DateTime dateTime;

      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is Map) {
        final seconds = timestamp['_seconds'];
        dateTime =
            DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      } else {
        return "Chưa cập nhật";
      }

      final difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 60) return "Vừa xong";
      if (difference.inMinutes < 60)
        return "${difference.inMinutes} phút trước";
      if (difference.inHours < 24)
        return "${difference.inHours} giờ trước";

      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (_) {
      return "Chưa cập nhật";
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommentProvider>();
    final list = cp.commentsOf(widget.postId);

    return Scaffold(
      appBar: AppBar(
        title: Text("Bình luận (${list.length})"), // ✅ FIX
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text("Chưa có bình luận"))
                : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, index) {
                final comment = list[index];
                return _buildComment(
                  username:
                  (comment['username'] ?? '').toString(),
                  avatar:
                  (comment['avatar'] ?? '').toString(),
                  comment:
                  (comment['commentText'] ?? '').toString(),
                  time: formatTime(comment['createdAt']),
                  commentId:
                  (comment['commentId'] ?? '').toString(),
                );
              },
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildComment({
    required String username,
    required String avatar,
    required String comment,
    required String time,
    required String commentId,
  }) {
    return GestureDetector(
      onLongPress: () => _showDeleteSheet(commentId), // ✅ đổi sang mở sheet
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: avatar.isNotEmpty
              ? NetworkImage(avatar)
              : const AssetImage("assets/images/user.jpg")
          as ImageProvider,
        ),
        title: Text(
          username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment),
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black,
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: profileImage.isNotEmpty
                ? NetworkImage(profileImage)
                : const AssetImage("assets/images/user.jpg")
            as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Nhập bình luận...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _submitComment,
          ),
        ],
      ),
    );
  }
}