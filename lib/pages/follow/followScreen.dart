import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../../provider/follow_provider.dart';
import '../../sharepreference/sharepre.dart';

class FollowScreen extends StatefulWidget {
  final String userId;
  final bool isFollowingTab;
  const FollowScreen({super.key, required this.userId, required this.isFollowingTab});

  @override
  State<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends State<FollowScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final followProvider = context.read<FollowProvider>();
      final myId = await getUserId();
      if (myId != null) {
        await followProvider.loadFollowingIds(myId); // để có nút Follow/Following đúng
      }

      if (widget.isFollowingTab) {
        await followProvider.loadFollowingList(widget.userId);
      } else {
        await followProvider.loadFollowersList(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFollowingTab ? "Đang theo dõi" : "Người theo dõi"),
      ),
      body: Consumer<FollowProvider>(
        builder: (context, fp, _) {
          if (fp.isLoading) return const Center(child: CircularProgressIndicator());

          final list = widget.isFollowingTab ? fp.following : fp.followers;
          if (list.isEmpty) return const Center(child: Text("Dữ liệu trống"));

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, index) {
              final u = list[index];
              final uid = u["userId"]?.toString() ?? "";
              final isFollowing = fp.isFollowing(uid);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (u["avatar"] ?? "").toString().isNotEmpty
                      ? NetworkImage(u["avatar"])
                      : const AssetImage("assets/images/user.jpg") as ImageProvider,
                ),
                title: Text(u["username"] ?? ""),
                subtitle: Text(u["fullname"] ?? ""),
                trailing: uid == widget.userId
                    ? null
                    : SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isFollowing) {
                        fp.unfollow(uid);
                      } else {
                        fp.follow(uid);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey.shade200 : Colors.blue,
                      foregroundColor: isFollowing ? Colors.black : Colors.white,
                    ),
                    child: Text(isFollowing ? "Đang theo dõi" : "Theo dõi"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
