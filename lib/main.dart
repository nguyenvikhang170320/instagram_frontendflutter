import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:instagram/provider/feed_provider.dart';
import 'package:instagram/provider/notification_provider.dart';
import 'package:instagram/provider/profile_provider.dart';
import 'package:instagram/provider/search_provider.dart';
import 'package:instagram/provider/verification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// --- CÁC MÀN HÌNH (SCREENS) ---
import 'package:instagram/pages/login_page.dart';
import 'package:instagram/pages/onboarding_page.dart';
import 'package:instagram/pages/bottom_nav.dart';
import 'package:instagram/pages/register_page.dart';

// --- CÁC PROVIDER MỚI (Tối nay bạn tạo file xong thì các dòng này sẽ hết lỗi) ---
import 'package:instagram/provider/auth_provider.dart';
import 'package:instagram/provider/watch_provider.dart';
import 'package:instagram/provider/chat_provider.dart';
import 'package:instagram/provider/post_provider.dart';
import 'package:instagram/provider/comment_provider.dart';
import 'package:instagram/provider/like_provider.dart';
import 'package:instagram/provider/save_provider.dart';
import 'package:instagram/provider/follow_provider.dart';
import 'package:instagram/provider/story_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load biến môi trường
  await dotenv.load(fileName: ".env");

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBoMSMOC4N6R8_DnU12Vs3rqciBELIazwc',
      appId: '1:276292476346:android:ef02952082e45eeee05183',
      messagingSenderId: 'sendid',
      projectId: 'instagram-flutter-21fb3',
    ),
  );

  // Kiểm tra trạng thái đăng nhập cục bộ (để điều hướng nhanh)
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? onboarded = prefs.getBool("onboarded");
  String? userId = prefs.getString("userId");

  runApp(MyApp(userId: userId, onboarded: onboarded ?? false));
}

class MyApp extends StatelessWidget {
  final String? userId;
  final bool onboarded;

  const MyApp({Key? key, required this.userId, required this.onboarded})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ✅ Đăng ký tất cả các Provider tại đây để dùng toàn App
      providers: [
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => VerificationProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        // 1. Auth (Quan trọng nhất)
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // 2. Chức năng chính (Post, Watch, Story)
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => WatchProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),

        // 3. Tương tác (Like, Comment, Save, Follow)
        ChangeNotifierProvider(create: (_) => LikeProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => SaveProvider()),
        ChangeNotifierProvider(create: (_) => FollowProvider()),

        // 4. Chat
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // 5. Profile
        ChangeNotifierProvider(create: (_) => ProfileProvider()),


        // ❌ Đã BỎ NotificationProvider theo yêu cầu của bạn (chỉ dùng Service)
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Instagram Clone',
        theme: ThemeData.light(), // Gợi ý: Chế độ sáng

        // Logic điều hướng màn hình khởi động
        home: _getStartScreen(),

        routes: {
          "/login": (context) =>  LoginPage(),
          "/register": (context) =>  RegisterPage(),
          "/home": (context) => BottomNav(userId: userId ?? ""),
        },
      ),
    );
  }

  // Hàm kiểm tra xem nên vào màn hình nào đầu tiên
  Widget _getStartScreen() {
    if (userId != null && userId!.isNotEmpty) {
      // Đã đăng nhập -> Vào trang chủ
      return BottomNav(userId: userId!);
    } else {
      // Chưa đăng nhập -> Kiểm tra đã xem Intro chưa
      return onboarded ? const LoginPage() : const OnboardingPage();
    }
  }
}