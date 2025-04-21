import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/pages/userprofilescreen.dart';
import 'package:instagram/sharepreference/auth_service.dart';

class SearchScreen extends StatefulWidget {
  final String userId;
  SearchScreen({required this.userId});
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  List users = [];
  List filteredUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // Gọi API để lấy danh sách người dùng
  Future<void> fetchUsers() async {
    final String? currentUserId = await getUserId();
    final response = await http
        .get(Uri.parse("${dotenv.env['BASE_URL']}/users/all/$currentUserId"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        users = data;
        filteredUsers = users;
      });
    } else {
      print("❌ Lỗi lấy danh sách người dùng");
    }
  }

  Future<void> toggleFollow(String targetUserId, bool follow) async {
    final String? currentUserId = await getUserId();
    final url =
        "${dotenv.env['BASE_URL']}/follow"; // POST cho Follow, DELETE cho Unfollow

    final response = await (follow
        ? http.post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(
                {"followerId": currentUserId, "followingId": targetUserId}),
          )
        : http.delete(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(
                {"followerId": currentUserId, "followingId": targetUserId}),
          ));

    if (response.statusCode == 200) {
      setState(() {
        for (var user in users) {
          if (user["userId"] == targetUserId) {
            user["isFollowing"] = follow;
            break;
          }
        }
      });
    } else {
      print("❌ Lỗi khi cập nhật follow/unfollow");
    }
  }

  // Hàm tìm kiếm theo username hoặc fullname
  void filterSearchResults(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        final username = user["username"].toLowerCase();
        final fullname = user["fullname"].toLowerCase();
        return username.contains(query.toLowerCase()) ||
            fullname.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onChanged: filterSearchResults,
          decoration: InputDecoration(
            hintText: "Tìm kiếm...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          return ListTile(
            onTap: () async {
              // Khi bấm vào user, mở màn hình UserProfileScreen
              final String? currentUserId = await getUserId();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    currentUserId: currentUserId!,
                    profileUserId: user["userId"]!,
                    username: user["username"]!,
                    fullname: user["fullname"]!,
                    bio: user["bio"]!, // Thêm API lấy dữ liệu bio nếu có
                    avatar: user["avatar"]!,
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundImage: user["avatar"].isNotEmpty
                  ? NetworkImage(user["avatar"])
                  : AssetImage("assets/images/user.jpg") as ImageProvider,
            ),
            title: Text(user["username"],
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user["fullname"]),
            trailing: user["isFollowing"]
                ? ElevatedButton(
                    onPressed: () => toggleFollow(user["userId"], false),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: Text(
                      "Đang theo dõi",
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => toggleFollow(user["userId"], true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child:
                        Text("Theo dõi", style: TextStyle(color: Colors.white)),
                  ),
          );
        },
      ),
    );
  }
}
