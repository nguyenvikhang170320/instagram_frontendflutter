import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/pages/chat/chat_list_screen.dart';
import 'package:instagram/pages/home/home.dart';
import 'package:instagram/pages/post/post.dart';
import 'package:instagram/pages/profile/profile.dart';
import 'package:instagram/pages/search.dart';
import 'package:provider/provider.dart';
import 'package:toasty_box/toast_service.dart';

import '../main.dart';
import '../provider/feed_provider.dart';
import '../provider/follow_provider.dart';
import '../provider/post_provider.dart';
import '../provider/verification_provider.dart';
import '../provider/watch_provider.dart';
import '../sharepreference/sharepre.dart';

class BottomNav extends StatefulWidget {
  final String userId;
  const BottomNav({super.key, required this.userId});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  // --- HÀM HIỂN THỊ MENU CHỌN UPLOAD ---
  void _showUploadMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Tạo nội dung mới", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Đăng bài viết (Ảnh)'),
              onTap: () {
                Navigator.pop(context);
                _openUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.pinkAccent),
              title: const Text('Đăng Video mới'),
              onTap: () {
                Navigator.pop(context);
                _handlePickVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Logic Upload Ảnh cũ của bạn
  Future<void> _openUploadImage() async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const UploadPostScreen()),
    );

    if (!mounted) return;

    if (posted == true) {
      // Hiển thị thông báo thành công
      ToastService.showSuccessToast(context, message: "Đăng bài viết thành công!");

      setState(() => _selectedIndex = 0);
      // Refresh feed trang chủ
      await context.read<FeedProvider>().fetchFeed(widget.userId);
    }else if (posted == false) {
      // CHỈ hiện lỗi khi trang upload báo thất bại
      ToastService.showErrorToast(context, message: "Đăng bài viết thất bại. Vui lòng thử lại.");
    }
  }


  // Logic Pick Video
  Future<void> _handlePickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    final caption = await _showCaptionDialog();
    if (caption == null) return;

    // ✅ Sửa dòng 104: Dùng navigatorKey.currentContext
    ToastService.showToast(
        context,
        message: "Đang tải video lên, vui lòng đợi..."
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final String? token = await user?.getIdToken(true);

      if (token == null) return;

      // Gọi upload và truyền token rõ ràng
      final bool ok = await context.read<WatchProvider>().uploadVideo(
        filePath: video.path,
        caption: caption,
        token: token, // ✅ Đã truyền token
      );

      if (!mounted) return;

      // Kiểm tra biến ok để hiện Toast thành công/thất bại
      if (ok == true) {
        ToastService.showSuccessToast(
          context,
          message: "Đăng video thành công!",
        );

        // Load lại video
        await context.read<WatchProvider>().fetchUserVideos(widget.userId);
      } else {
        String errorMsg = context.read<WatchProvider>().error ?? "Lỗi không xác định";
        ToastService.showErrorToast(context, message: errorMsg);
      }
    } catch (e) {
      ToastService.showErrorToast(context,message: "Lỗi kết nối mạng");
    }
  }

  Future<String?> _showCaptionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nhập mô tả video"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Mô tả...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text("Đăng")),
        ],
      ),
    );
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      _showUploadMenu();
      return;
    }

    if (!mounted) return;
    setState(() => _selectedIndex = index);

    // Refresh Feed khi tap Home
    if (index == 0) {
      await context.read<FeedProvider>().fetchFeed(widget.userId);
    }

    // Refresh Profile khi tap Profile
    if (index == 4) {
      final uid = await getUserId();
      if (!mounted) return;

      if (uid != null) {
        await context.read<VerificationProvider>().checkStatus(uid);
        if (!mounted) return;
        await context.read<FollowProvider>().loadCounts(widget.userId);
        if (!mounted) return;
        await context.read<PostProvider>().fetchUserPosts(widget.userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Index 0: Home
          FeedScreen(userId: widget.userId),

          // Index 1: Search
          SearchScreen(userId: widget.userId),

          // Index 2: Placeholder nút Upload (không hiện gì)
          const SizedBox.shrink(),

          // Index 3: Watch Screen
          ChatListScreen(currentUserId: widget.userId),

          // Index 4: Profile
          ProfileScreen(userId: widget.userId),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE6E6E6), width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              iconSize: 24,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black54,
              items: const [
                BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.house), label: ""),           // 0
                BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.magnifyingGlass), label: ""), // 1
                BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.plusCircle), label: ""),      // 2
                BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.rocketchat), label: ""),           // 3 (Watch)
                BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.user), label: ""),            // 4
              ],
            ),
          ),
        ),
      ),
    );
  }
}