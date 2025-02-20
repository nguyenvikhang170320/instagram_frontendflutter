import 'package:flutter/material.dart';
import 'package:instagram/pages/login_page.dart';
import 'package:instagram/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? onboarded = prefs.getBool("onboarded");
  String? token = prefs.getString("token");

  runApp(MyApp(startScreen: token != null ? "/home" : (onboarded == true ? "/login" : "/onboarding")));
}

class MyApp extends StatelessWidget {
  final String startScreen;

  MyApp({required this.startScreen});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instagram Clone',
      initialRoute: startScreen,
      routes: {
        "/onboarding": (context) => OnboardingPage(),
        "/login": (context) => LoginPage(),
        "/home": (context) => Scaffold(body: Center(child: Text("Trang chủ"))),
      },
    );
  }
}

