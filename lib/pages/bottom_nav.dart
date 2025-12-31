import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:instagram/pages/home/home.dart';
import 'package:instagram/pages/post/post.dart';
import 'package:instagram/pages/profile/profile.dart';
import 'package:instagram/pages/search.dart';
import 'package:instagram/pages/watch/watch.dart';
import 'package:provider/provider.dart';

import '../provider/feed_provider.dart';
import '../provider/follow_provider.dart';
import '../provider/post_provider.dart';
import '../provider/verification_provider.dart';
import '../sharepreference/sharepre.dart';

class BottomNav extends StatefulWidget {
  final String userId;
  const BottomNav({super.key, required this.userId});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  Widget _buildWatch() {
    return WatchScreen(isActive: _selectedIndex == 3);
  }

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      FeedScreen(userId: widget.userId),
      SearchScreen(userId: widget.userId),
      const SizedBox.shrink(),
      _buildWatch(), // sẽ được replace ở build()
      ProfileScreen(userId: widget.userId),
    ];
  }

  Future<void> _openUpload() async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const UploadPostScreen()),
    );

    if (!mounted) return;

    if (posted == true) {
      setState(() => _selectedIndex = 0);
    }
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      _openUpload();
      return;
    }

    setState(() => _selectedIndex = index);

    if (index == 0) {
      await context.read<FeedProvider>().fetchFeed(widget.userId);
    }
    if (index == 4) {
      final uid = await getUserId();
      if (uid != null) {
        await context.read<VerificationProvider>().checkStatus(uid);
      }
      await context.read<FollowProvider>().loadCounts(widget.userId);
      await context.read<PostProvider>().fetchUserPosts(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // rebuild list để WatchScreen nhận isActive mới
    final screens = [
      FeedScreen(userId: widget.userId),
      SearchScreen(userId: widget.userId),
      const SizedBox.shrink(),
      WatchScreen(isActive: _selectedIndex == 3),
      ProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE6E6E6), width: 1)),
        ),
        child: SafeArea(
    top: false, child: SizedBox(
          height: 60, // thử 52-60 tuỳ máy
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
              BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.house), label: ""),
              BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.magnifyingGlass), label: ""),
              BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.plusCircle), label: ""),
              BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.video), label: ""),
              BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.user), label: ""),
            ],
          ),
        ),
      ),

    )
    );
  }
}

