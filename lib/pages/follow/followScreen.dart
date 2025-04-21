import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FollowScreen extends StatefulWidget {
  final String userId;
  final bool isFollowingTab; // true: Đang theo dõi, false: Người theo dõi

  FollowScreen({required this.userId, required this.isFollowingTab});

  @override
  _FollowScreenState createState() => _FollowScreenState();
}

class _FollowScreenState extends State<FollowScreen> {
  List<Map<String, dynamic>> users = []; // Danh sách users
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFollowData();
  }

  Future<void> fetchFollowData() async {
    try {
      final url = widget.isFollowingTab
          ? "${dotenv.env['BASE_URL']}/follow/following/${widget.userId}"
          : "${dotenv.env['BASE_URL']}/follow/followers/${widget.userId}";

      final response = await Dio().get(url);
      if (response.statusCode == 200) {
        setState(() {
          users = List<Map<String, dynamic>>.from(response.data);
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Lỗi khi tải dữ liệu: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFollowingTab ? "Đang theo dõi" : "Người theo dõi"),
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Hiển thị vòng xoay khi đang tải
          : (users.isEmpty
              ? Center(child: Text("Dữ liệu trống")) // Khi không có dữ liệu
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final bool isFollowing = user["isFollowing"] ?? true;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            user["avatar"] != null && user["avatar"].isNotEmpty
                                ? NetworkImage(user["avatar"])
                                : AssetImage("assets/images/user.jpg")
                                    as ImageProvider,
                      ),
                      title: Text(user["username"]),
                      subtitle: Text(user["fullname"] ?? ""),
                    );
                  },
                )),
    );
  }
}
