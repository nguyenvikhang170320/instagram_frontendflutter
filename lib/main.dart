import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:instagram/pages/login_page.dart';
import 'package:instagram/pages/onboarding_page.dart';
import 'package:instagram/pages/bottom_nav.dart';
import 'package:instagram/pages/profile/profile.dart';
import 'package:instagram/pages/register_page.dart';
import 'package:instagram/provider/feed_provider.dart';
import 'package:instagram/provider/notification_provider.dart';
import 'package:instagram/sharepreference/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load file .env trước khi chạy app
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyBoMSMOC4N6R8_DnU12Vs3rqciBELIazwc',
      appId: '1:276292476346:android:ef02952082e45eeee05183',
      messagingSenderId: 'sendid',
      projectId: 'instagram-flutter-21fb3',
    ),
  );

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
      providers: [
        ChangeNotifierProvider(
          create: (context) => FeedProvider(),
        ),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Instagram Clone',
        home: _getStartScreen(),
        routes: {
          "/login": (context) => LoginPage(), // ✅ Thêm route này
          "/register": (context) => RegisterPage(), // ✅ Thêm route này
          "/home": (context) => BottomNav(userId: userId ?? ""),
        },
      ),
    );
  }

  Widget _getStartScreen() {
    if (userId != null && userId!.isNotEmpty) {
      return BottomNav(userId: userId!);
    } else {
      return onboarded ? LoginPage() : OnboardingPage();
    }
  }
}
