import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:instagram/pages/bottom_nav.dart';
import 'package:instagram/pages/forgot_password/forgotpasswordScreen.dart';
import 'package:instagram/pages/register_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:instagram/provider/feed_provider.dart';
import 'package:instagram/sharepreference/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text,
        "password": passwordController.text,
      }),
    );
    // print(response.body);
    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print(1);
        // Lưu token vào SharedPreferences
        String token = data['token'];
        await saveToken(token);
        print("✅ Token user id: $token");
        String userId = data['userId'];
        await saveUserId(userId); // Lưu userId
        print("✅ User ID: $userId");
        // Chuyển qua trang chính
        // Cập nhật userId trong FeedProvider trước khi fetch dữ liệu
        Provider.of<FeedProvider>(context, listen: false).updateUserId(userId);
        ToastService.showSuccessToast(
          context,
          length: ToastLength.medium,
          expandedHeight: 100,
          message: "Đăng nhập thành công!",
        );
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => BottomNav(userId: userId)));
      } else {
        ToastService.showErrorToast(
          context,
          length: ToastLength.medium,
          expandedHeight: 100,
          message: "Đăng nhập thất bại!",
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi máy chủ!")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Instagram',
              style: TextStyle(
                fontFamily: Theme.of(context).platform == TargetPlatform.iOS
                    ? 'SF Pro Rounded'
                    : 'Roboto',
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.email, color: Colors.grey),
                hintText: 'Email',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock, color: Colors.grey),
                hintText: 'Mật khẩu',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              ),
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Đăng nhập',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (ctx) => RegisterPage()));
              },
              child: Text(
                'Chưa có tài khoản? Đăng ký',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (ctx) => ForgotPasswordScreen()));
              },
              child: Text(
                'Quên mật khẩu?',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.facebook, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'Đăng nhập bằng Facebook',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
