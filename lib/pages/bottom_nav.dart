import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:instagram/pages/home/home.dart';
import 'package:instagram/pages/post/post.dart';
import 'package:instagram/pages/profile/profile.dart';
import 'package:instagram/pages/search.dart';
import 'package:instagram/pages/watch/watch.dart';

class BottomNav extends StatefulWidget {
  final String userId;
  BottomNav({required this.userId});

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  // Mặc định là danh sách người theo dõi (followers)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    bool isFollowingTab = _selectedIndex == 1 ? true : false;

    // Tạo _screens trong build() để đảm bảo mỗi lần rebuild là màn hình mới
    final List<Widget> _screens = [
      FeedScreen(userId: widget.userId), // Luôn tạo mới
      SearchScreen(
        userId: widget.userId,
      ),
      UploadPostScreen(),
      WatchScreen(),
      ProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      body: _screens[_selectedIndex], // Hiển thị màn hình tương ứng
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.house), label: ""),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.magnifyingGlass), label: ""),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.plusCircle), label: ""),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.video), label: ""),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.user), label: ""),
        ],
      ),
    );
  }
}
