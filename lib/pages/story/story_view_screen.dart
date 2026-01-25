import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../model/story_model.dart';
import '../../provider/story_provider.dart';
import 'components/story_progress_bar.dart';
import 'components/viewers_bottom_sheet.dart';

class StoryViewScreen extends StatefulWidget {
  final List<StoryGroup> storyGroups;
  final int initialUserIndex;

  const StoryViewScreen({
    Key? key,
    required this.storyGroups,
    required this.initialUserIndex,
  }) : super(key: key);

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;

  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
    _pageController = PageController(initialPage: widget.initialUserIndex);

    _animController = AnimationController(vsync: this);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onTapNext();
      }
    });

    _loadStory(storyIndex: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // 🛠️ HÀM FORMAT THỜI GIAN
  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút";
    if (diff.inHours < 24) return "${diff.inHours} giờ";
    return "${diff.inDays} ngày";
  }

  void _loadStory({required int storyIndex, bool animateToPage = false}) {
    _currentStoryIndex = storyIndex;
    _animController.stop();
    _animController.reset();
    _animController.duration = const Duration(seconds: 5);
    _animController.forward();

    final currentGroup = widget.storyGroups[_currentUserIndex];
    final currentStory = currentGroup.stories[_currentStoryIndex];

    // ✅ FIX LỖI CRASH: Bọc trong addPostFrameCallback
    if (!currentStory.isViewed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<StoryProvider>(context, listen: false)
              .markAsViewed(currentStory.storyId, currentGroup.userId);
        }
      });
    }
  }

  void _onTapNext() {
    final currentGroup = widget.storyGroups[_currentUserIndex];
    if (_currentStoryIndex < currentGroup.stories.length - 1) {
      setState(() {
        _loadStory(storyIndex: _currentStoryIndex + 1);
      });
    } else {
      if (_currentUserIndex < widget.storyGroups.length - 1) {
        setState(() {
          _currentUserIndex++;
          _currentStoryIndex = 0;
        });
        _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut
        );
        _loadStory(storyIndex: 0);
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _onTapPrev() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _loadStory(storyIndex: _currentStoryIndex - 1);
      });
    } else {
      if (_currentUserIndex > 0) {
        setState(() {
          _currentUserIndex--;
          _currentStoryIndex = widget.storyGroups[_currentUserIndex].stories.length - 1;
        });
        _pageController.previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut
        );
        _loadStory(storyIndex: _currentStoryIndex);
      }
    }
  }

  // Hàm xóa nhanh
  void _deleteDirectly() async {
    _animController.stop();
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa tin này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final storyId = widget.storyGroups[_currentUserIndex].stories[_currentStoryIndex].storyId;
      await Provider.of<StoryProvider>(context, listen: false).deleteStory(storyId);
      Navigator.pop(context);
    } else {
      _animController.forward();
    }
  }

  void _showViewers() {
    _animController.stop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ViewersBottomSheet(
        storyId: widget.storyGroups[_currentUserIndex].stories[_currentStoryIndex].storyId,
        onDeleteSuccess: () => Navigator.pop(context),
      ),
    ).then((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Xác định xem story hiện tại có phải của mình không
    final currentGroup = widget.storyGroups[_currentUserIndex];
    bool isMyStory = currentGroup.userId == _myUid;
    final currentStory = currentGroup.stories[_currentStoryIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // ✅ FIX LOGIC VUỐT: Phân biệt vuốt lên/xuống
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! > 10) {
            Navigator.pop(context); // Vuốt xuống -> Đóng
          }
          if (details.primaryDelta! < -10 && isMyStory) {
            _showViewers(); // Vuốt lên -> Xem người xem (chỉ chủ story)
          }
        },
        onLongPress: () => _animController.stop(),
        onLongPressUp: () => _animController.forward(),
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _onTapPrev();
          } else {
            _onTapNext();
          }
        },

        child: Stack(
          children: [
            // 1. PageView (Ảnh)
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.storyGroups.length,
              itemBuilder: (context, index) {
                if (index != _currentUserIndex) return Container(color: Colors.black);
                final story = widget.storyGroups[index].stories[_currentStoryIndex];

                return CachedNetworkImage(
                  imageUrl: story.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              },
            ),

            // 2. Thanh Progress Bar & Header User info
            Column(
              children: [
                StoryProgressBar(
                  storyCount: currentGroup.stories.length,
                  currentIndex: _currentStoryIndex,
                  animController: _animController,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: currentGroup.avatar.isNotEmpty
                            ? NetworkImage(currentGroup.avatar)
                            : null,
                        child: currentGroup.avatar.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        currentGroup.username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      // ✅ FIX BIẾN: Dùng currentStory.createdAt
                      Text(
                        _formatTime(currentStory.createdAt),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                )
              ],
            ),

            // 3. ✅ UI NÚT XÓA & XEM (Phần này code bạn bị thiếu)
            if (isMyStory)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút xem người xem (Góc trái)
                    GestureDetector(
                      onTap: _showViewers,
                      child: Container(
                        margin: const EdgeInsets.only(left: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.visibility, color: Colors.white, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              "${currentStory.viewersCount} người xem",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}