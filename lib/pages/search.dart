import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:instagram/pages/userprofilescreen.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:instagram/provider/follow_provider.dart';
import 'package:instagram/provider/search_provider.dart';

import '../provider/feed_provider.dart';

class SearchScreen extends StatefulWidget {
  final String userId; // current user id
  const SearchScreen({super.key, required this.userId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = await getUserId();
      if (!mounted || uid == null) return;

      // load list user search (có isFollowing từ backend)
      await context.read<SearchProvider>().load(uid);

      // load followingIds để button follow/following luôn đúng (source of truth)
      await context.read<FollowProvider>().loadFollowingIds(uid);
    }); // addPostFrameCallback dùng khi cần async + provider notify [web:384]
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SearchProvider>();
    final fp = context.watch<FollowProvider>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: (text) => context.read<SearchProvider>().search(text),
          decoration: const InputDecoration(
            hintText: "Tìm kiếm...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      body: sp.loading
          ? const Center(child: CircularProgressIndicator())
          : (sp.error != null)
          ? Center(child: Text(sp.error!))
          : ListView.builder(
        itemCount: sp.users.length,
        itemBuilder: (context, index) {
          final user = sp.users[index];
          final targetId = (user["userId"] ?? "").toString();

          final avatar = (user["avatar"] ?? "").toString();
          final username = (user["username"] ?? "").toString();
          final fullname = (user["fullname"] ?? "").toString();
          final bio = (user["bio"] ?? "").toString();

          // Ưu tiên trạng thái follow từ FollowProvider (để đồng bộ toàn app)
          final isFollowing = fp.isFollowing(targetId);

          return ListTile(
            onTap: () async {
              final currentUserId = await getUserId();
              if (!context.mounted || currentUserId == null) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(
                    currentUserId: currentUserId,
                    profileUserId: targetId,
                    username: username,
                    fullname: fullname,
                    bio: bio,
                    avatar: avatar,
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundImage: avatar.isNotEmpty
                  ? NetworkImage(avatar)
                  : const AssetImage("assets/images/user.jpg")
              as ImageProvider,
            ),
            title: Text(username,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(fullname),
            trailing: (targetId == widget.userId)
                ? null
                : SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () async {
                  bool ok = false;

                  if (isFollowing) {
                    ok = await fp.unfollow(targetId);
                    if (ok) sp.setFollowing(targetId, false);
                  } else {
                    ok = await fp.follow(targetId);
                    if (ok) sp.setFollowing(targetId, true);
                  }

                  if (!context.mounted) return;

                  final uid = await getUserId();
                  if (!context.mounted || uid == null) return;

                  await context.read<FeedProvider>().fetchFeed(uid);

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? Colors.grey.shade200
                      : Colors.blue,
                  foregroundColor: isFollowing
                      ? Colors.black
                      : Colors.white,
                ),
                child:
                Text(isFollowing ? "Đang theo dõi" : "Theo dõi"),
              ),
            ),
          );
        },
      ),
    );
  }
}
