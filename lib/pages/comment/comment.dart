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
  final String userId;   // current user (người đang dùng app)
  final String senderId; // ownerId của bài post (người nhận notification)

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
      context.read<CommentProvider>().fetchCommentCount(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> fetchUserAvatar() async {
    try {
      final response =
      await http.get(Uri.parse("${dotenv.env['BASE_URL']}/users/${widget.userId}"));

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
    final currentUserId = await getUserId();
    if (currentUserId == null) return;
    if (currentUserId == widget.senderId) return;

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

    final ok = await context.read<CommentProvider>().addComment(
      postId: widget.postId,
      commentText: text,
    );

    if (!mounted) return;

    if (!ok) {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: context.read<CommentProvider>().error ?? "Không thể gửi bình luận!",
      );
      return;
    }

    _commentController.clear();
    await sendCommentNotification();
  }

  Future<void> _deleteComment(String commentId) async {
    final ok = await context.read<CommentProvider>().deleteComment(
      postId: widget.postId,
      commentId: commentId,
    );

    if (!mounted) return;

    if (ok) {
      ToastService.showSuccessToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Xóa bình luận thành công!",
      );
    } else {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: context.read<CommentProvider>().error ?? "Không thể xóa bình luận!",
      );
    }
  }

  String formatTime(dynamic timestamp) {
    if (timestamp == null) return "Chưa cập nhật";

    DateTime dateTime;
    if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else if (timestamp is Map && timestamp.containsKey("_seconds")) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp["_seconds"] * 1000);
    } else {
      return "Chưa cập nhật";
    }

    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) return "Vừa xong";
    if (difference.inMinutes < 60) return "${difference.inMinutes} phút trước";
    if (difference.inHours < 24) return "${difference.inHours} giờ trước";
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  void _showDeleteDialog(String commentId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa bình luận này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommentProvider>();
    final count = cp.commentCountOf(widget.postId);
    final list = cp.commentsOf(widget.postId);

    return Scaffold(
      appBar: AppBar(
        title: Text("Bình luận ($count)"),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: cp.loadingList
                ? const Center(child: CircularProgressIndicator())
                : (list.isEmpty
                ? const Center(child: Text("Chưa có bình luận"))
                : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, index) {
                final comment = list[index];
                return _buildComment(
                  username: (comment['username'] ?? '').toString(),
                  avatar: (comment['avatar'] ?? '').toString(),
                  comment: (comment['commentText'] ?? '').toString(),
                  time: formatTime(comment['createdAt']),
                  commentId: (comment['commentId'] ?? '').toString(),
                );
              },
            )),
          ),
          _buildCommentInput(profileImage),
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
      onLongPress: () => _showDeleteDialog(commentId),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
          backgroundImage: avatar.isNotEmpty
              ? NetworkImage(avatar)
              : const AssetImage("assets/images/user.jpg") as ImageProvider,
        ),
        title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment),
            Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.favorite_border, color: Colors.white),
      ),
    );
  }

  Widget _buildCommentInput(String profileImage) {
    return Container(
      padding: const EdgeInsets.all(8),
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
                : const AssetImage("assets/images/user.jpg") as ImageProvider,
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
              textInputAction: TextInputAction.send,
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
