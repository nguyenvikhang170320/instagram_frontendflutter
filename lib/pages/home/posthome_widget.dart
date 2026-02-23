import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/provider/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

import 'package:instagram/pages/comment/comment.dart';
import 'package:instagram/pages/report/report_modal.dart';
import 'package:instagram/services/report_service.dart';
import 'package:instagram/sharepreference/sharepre.dart';

import '../../provider/like_provider.dart';
import '../../provider/save_provider.dart';
import '../../provider/comment_provider.dart';
import '../../provider/notification_provider.dart';

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostWidget({
    super.key,
    required this.post,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  String username = "Unknown";
  String avatarUrl = "";

  late final String postId;
  late final String ownerId;

  @override
  void initState() {
    super.initState();
    postId = (widget.post['postId'] ?? '').toString();
    ownerId = (widget.post['userId'] ?? '').toString();

    fetchUserData(ownerId);

    Future.microtask(() {
      if (!mounted) return;
      context.read<LikeProvider>().fetchLikeCount(postId);
    });
  }

  Future<void> fetchUserData(String userId) async {
    try {
      final url = Uri.parse("${dotenv.env['BASE_URL']}/users/$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          username = (data['username'] ?? "Unknown").toString();
          avatarUrl = (data['avatar'] ?? "").toString();
        });
      }
    } catch (_) {}
  }
  void sharePost(String postContent, String postImage) async {
    var message = "📢 Nội dung: $postContent\n";
    if (postImage.isNotEmpty) message += "🖼 Hình ảnh: $postImage";
    await Share.share(message);
  }

  Future<void> sendNotification(String receiverId, String postId, String type) async {
    final currentUserId = await getUserId();
    if (currentUserId == null) return;
    if (currentUserId == receiverId) return;

    // nếu Dart < 3 thì đổi sang if/else
    final message = switch (type) {
      'like' => 'đã thích bài viết của bạn',
      'save' => 'đã lưu bài viết của bạn',
      'comment' => 'đã bình luận bài viết của bạn',
      'share_post' => 'đã chia sẻ bài viết của bạn',
      _ => '',
    };

    await context.read<NotificationProvider>().createNotification(
      receiverId: receiverId,
      type: type,
      postId: postId,
      message: message,
    );
  }

  void _showReportModal(BuildContext context) async {
    final userId = await getUserId();
    if (userId == null) {
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
          targetId: postId,
          targetType: "post",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = context.select<LikeProvider, bool>((p) => p.isLiked(postId));
    final likeCount = context.select<LikeProvider, int>((p) => p.likeCountOf(postId));

    final isSaved = context.select<SaveProvider, bool>((p) => p.isSaved(postId));


    final imageUrl = (widget.post['imageUrl'] ?? '').toString();
    final caption = (widget.post['caption'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : const AssetImage("assets/images/user.jpg") as ImageProvider,
            ),
            title: Text(
              username,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showReportModal(context),
            ),
          ),

          Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // LIKE
                IconButton(
                  icon: Icon(
                    isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                    color: isLiked ? Colors.red : Colors.black,
                  ),
                  onPressed: () async {
                    final next = !isLiked;
                    try {
                      await context.read<LikeProvider>().toggleLike(
                        postId: postId,
                        nextValue: next,
                      );
                      if (next) await sendNotification(ownerId, postId, 'like');
                    } catch (_) {}
                  },
                ),

                // COMMENT (vì bạn nói comment có provider => giữ nút comment)
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () async {
                    final uid = await getUserId();
                    if (!context.mounted || uid == null) return;

                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentScreen(
                          postId: postId,
                          senderId: ownerId,
                          userId: uid,
                        ),
                      ),
                    );


                  },
                ),

                // SHARE
                IconButton(
                  icon: const Icon(FontAwesomeIcons.paperPlane, color: Colors.black),
                  onPressed: () async {
                    sharePost(caption, imageUrl);
                    await sendNotification(ownerId, postId, 'share_post');
                  },
                ),

                const Spacer(),

                // SAVE
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.grey : Colors.black,
                  ),
                  onPressed: () async {
                    final ok = await context.read<SaveProvider>().toggleSave(
                      postId: postId,
                      imageUrl: imageUrl,
                      nextValue: !isSaved,
                    );

                    if (!ok && context.mounted) {
                      ToastService.showErrorToast(
                        context,
                        length: ToastLength.medium,
                        expandedHeight: 100,
                        message: context.read<SaveProvider>().error ?? "Lỗi lưu",
                      );
                      return;
                    }
                    if (!isSaved) await sendNotification(ownerId, postId, 'save');
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$likeCount lượt thích',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text("$username $caption", style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
