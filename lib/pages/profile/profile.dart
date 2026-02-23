import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:instagram/pages/follow/followScreen.dart';
import 'package:instagram/pages/profile/editprofile.dart';
import 'package:instagram/pages/watch/chewie_video_player.dart';
import 'package:instagram/pages/watch/video_player_preview.dart';
import 'package:instagram/services/verification_service.dart';
import 'package:instagram/sharepreference/sharepre.dart';

import 'package:instagram/provider/profile_provider.dart';
import 'package:instagram/provider/post_provider.dart';
import 'package:instagram/provider/follow_provider.dart';
import 'package:instagram/provider/save_provider.dart';
import 'package:instagram/provider/watch_provider.dart';
import 'package:instagram/provider/verification_provider.dart';

import '../../model/user.dart';
import '../report/ReportHistoryScreen.dart';
import '../story/create_story_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedTab = 0; // 0: Posts, 1: Video, 2: Saved

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.wait([
        context.read<ProfileProvider>().fetchProfile(widget.userId),
        context.read<PostProvider>().fetchUserPosts(widget.userId),
        context.read<FollowProvider>().loadCounts(widget.userId),
        context.read<VerificationProvider>().checkStatus(widget.userId),
        context.read<WatchProvider>().fetchUserVideos(widget.userId),
        context.read<SaveProvider>().fetchSavedPosts(),
      ]);
    });
  }

  Future<void> _onTabChanged(int tab) async {
    setState(() => selectedTab = tab);

    // Lazy load Saved tab để khỏi gọi API liên tục
    if (tab == 2) {
      await context.read<SaveProvider>().fetchSavedPosts(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileP = context.watch<ProfileProvider>();
    final followP = context.watch<FollowProvider>();
    final verifyP = context.watch<VerificationProvider>();

    // map/profile model tuỳ bạn. Nếu profile là Map:
    final user = profileP.profile;
    final username = user.username;
    final fullname = user.fullname;
    final bio = user.bio;
    final avatarUrl = user.avatar;

    final isVerified = verifyP.isVerified == true;
    final requestSent =
        verifyP.status == 'pending' || verifyP.status == 'approved';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              username.isNotEmpty ? username : "Profile",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (isVerified) ...const [
              SizedBox(width: 4),
              Icon(Icons.verified, color: Colors.blue, size: 18),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: Colors.black),
          ],
        ),
        actions: [
          if (!isVerified && !requestSent)
            IconButton(
              icon: const Icon(Icons.verified_outlined, color: Colors.blue),
              tooltip: 'Yêu cầu xác minh',
              onPressed: () async {
                // cần profile đã load để có username/fullname/bio
                final success = await VerificationService.sendRequest(
                  userId: widget.userId,
                  username: username,
                  fullName: fullname,
                  bio: bio,
                );

                if (!context.mounted) return;

                if (success) {
                  await context
                      .read<VerificationProvider>()
                      .checkStatus(widget.userId);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("✅ Đã gửi yêu cầu"),
                      content: const Text(
                          "Yêu cầu xác thực đã được gửi. Vui lòng chờ xét duyệt."),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK")),
                      ],
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.report, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportHistoryScreen(),
                ),
              );
            },
          ),
          SizedBox(width: 10,),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async => logout(context),
          ),
        ],
      ),
      body: profileP.loading
          ? const Center(child: CircularProgressIndicator())
          : (profileP.error != null)
              ? Center(child: Text(profileP.error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : const AssetImage(
                                              "assets/images/user.jpg")
                                          as ImageProvider,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: () async {
                                      final uid = await getUserId();
                                      if (!context.mounted || uid == null)
                                        return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                CreateStoryScreen()),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            fullname,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            bio,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoColumn(
                                context,
                                count:
                                    context.watch<PostProvider>().posts.length,
                                label: "Bài viết",
                                isFollowingTab: false,
                                clickable: false,
                              ),
                              _buildInfoColumn(
                                context,
                                count: followP.followersCount,
                                label: "Người theo dõi",
                                isFollowingTab: false,
                                clickable: true,
                              ),
                              _buildInfoColumn(
                                context,
                                count: followP.followingCount,
                                label: "Đang theo dõi",
                                isFollowingTab: true,
                                clickable: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => EditProfileScreen()),
                              );

                              if (!context.mounted) return;

                              if (updated == true) {
                                await context
                                    .read<ProfileProvider>()
                                    .fetchProfile(widget.userId);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Chỉnh sửa trang cá nhân'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    _buildProfileTabs(
                      selectedTab: selectedTab,
                      onTabChanged: _onTabChanged,
                    ),
                    Expanded(
                      child: switch (selectedTab) {
                        0 => _PostsGrid(),
                        1 => _VideosGrid(),
                        _ => _SavedGrid(),
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoColumn(
    BuildContext context, {
    required int count,
    required String label,
    required bool isFollowingTab,
    required bool clickable,
  }) {
    final content = Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );

    if (!clickable) return content;

    return GestureDetector(
      onTap: () async {
        final uid = await getUserId();
        if (!context.mounted || uid == null) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FollowScreen(userId: uid, isFollowingTab: isFollowingTab),
          ),
        );
      },
      child: content,
    );
  }

  Widget _buildProfileTabs({
    required int selectedTab,
    required Future<void> Function(int) onTabChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(FontAwesomeIcons.tableCells,
              color: selectedTab == 0 ? Colors.black : Colors.grey),
          onPressed: () => onTabChanged(0),
        ),
        const SizedBox(width: 40),
        IconButton(
          icon: Icon(FontAwesomeIcons.video,
              color: selectedTab == 1 ? Colors.black : Colors.grey),
          onPressed: () => onTabChanged(1),
        ),
        const SizedBox(width: 40),
        IconButton(
          icon: Icon(FontAwesomeIcons.solidBookmark,
              color: selectedTab == 2 ? Colors.black : Colors.grey),
          onPressed: () => onTabChanged(2),
        ),
      ],
    );
  }
}

class _PostsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (_, pp, __) {
        if (pp.loading) return const Center(child: CircularProgressIndicator());
        if (pp.posts.isEmpty)
          return const Center(child: Text("Chưa có bài viết nào"));

        final images = pp.posts
            .map((p) => (p['imageUrl'] ?? '').toString())
            .where((url) => url.isNotEmpty)
            .toList();

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
          ),
          itemCount: images.length,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: (images.isNotEmpty)
                    ? NetworkImage(images[i])
                    : const AssetImage("assets/images/user.jpg")
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SaveProvider>(
      builder: (_, sp, __) {
        if (sp.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final ids =
            sp.savedPostIds.toList(); // Set -> List để dùng index [web:1387]

        if (ids.isEmpty) {
          return const Center(child: Text("Chưa có bài viết đã lưu"));
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: ids.length,
          itemBuilder: (_, i) {
            final postId = ids[i];
            final url = sp.imageUrlOf(postId);

            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: (url.isNotEmpty)
                      ? NetworkImage(url)
                      : const AssetImage("assets/images/user.jpg")
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VideosGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WatchProvider>(
      builder: (_, wp, __) {
        if (wp.loading) return const Center(child: CircularProgressIndicator());

        // Dùng danh sách object videos gốc để lấy được ID
        final listVideos = wp.videos;

        if (listVideos.isEmpty)
          return const Center(child: Text("Chưa có video nào"));

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 9 / 16,
          ),
          itemCount: listVideos.length,
          itemBuilder: (_, index) {
            // Lấy dữ liệu của từng video
            final video = listVideos[index];
            final String url = video['videoUrl'] ?? '';
            final String id =
                video['id']?.toString() ?? ''; // Lấy VideoId ở đây

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChewieVideoPlayer(
                      videoUrl: url,
                      videoId: id, // ✅ Đã truyền videoId vào đây
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: VideoPlayerPreview(videoUrl: url),
                  ),
                  const Positioned(
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
      },
    );
  }
}
