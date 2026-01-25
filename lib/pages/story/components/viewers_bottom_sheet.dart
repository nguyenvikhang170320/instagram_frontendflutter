import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/story_provider.dart';

class ViewersBottomSheet extends StatefulWidget {
  final String storyId;

  // Callback để báo cho màn hình cha biết là story đã bị xóa
  // Để màn hình cha tự đóng lại hoặc chuyển sang story khác
  final VoidCallback onDeleteSuccess;

  const ViewersBottomSheet({
    Key? key,
    required this.storyId,
    required this.onDeleteSuccess,
  }) : super(key: key);

  @override
  State<ViewersBottomSheet> createState() => _ViewersBottomSheetState();
}

class _ViewersBottomSheetState extends State<ViewersBottomSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _viewers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final provider = Provider.of<StoryProvider>(context, listen: false);
    final data = await provider.getViewers(widget.storyId);
    if (mounted) {
      setState(() {
        _viewers = data;
        _isLoading = false;
      });
    }
  }

  void _handleDelete() async {
    // Hiện dialog xác nhận
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa tin này?"),
        content: const Text("Bạn không thể khôi phục tin sau khi xóa."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Xóa", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final provider = Provider.of<StoryProvider>(context, listen: false);

      // Gọi hàm xóa ở Provider
      bool success = await provider.deleteStory(widget.storyId);

      if (success && mounted) {
        Navigator.pop(context); // Đóng BottomSheet
        widget.onDeleteSuccess(); // Gọi callback để đóng màn hình View
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(height: 4, width: 40, color: Colors.grey[300]),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined),
                    const SizedBox(width: 8),
                    Text("${_viewers.length} người xem",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                // Nút xóa (Thùng rác)
                IconButton(
                  onPressed: _handleDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List User
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _viewers.isEmpty
                ? const Center(child: Text("Chưa có ai xem tin", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: _viewers.length,
              itemBuilder: (context, index) {
                final user = _viewers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (user['avatar'] != null && user['avatar'] != "")
                        ? NetworkImage(user['avatar'])
                        : null,
                    child: (user['avatar'] == null || user['avatar'] == "")
                        ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user['username'] ?? "Unknown"),
                  subtitle: Text(user['fullname'] ?? ""),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}