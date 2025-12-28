import 'package:flutter/material.dart';
import 'package:instagram/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm dòng này
import 'package:instagram/pages/register_page.dart';
import 'package:instagram/pages/bottom_nav.dart';
import 'package:instagram/pages/forgot_password/forgotpasswordScreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Hàm xử lý đăng nhập gọi qua Provider
  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Gọi hàm login từ Provider
    bool success = await authProvider.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (success) {
      // Lấy userId để chuyển trang (vì Provider đã lưu rồi)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId");

      ToastService.showSuccessToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Đăng nhập thành công!",
      );

      // Chuyển trang
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (ctx) => BottomNav(userId: userId ?? "")),
      );
    } else {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Email hoặc mật khẩu không đúng!",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Consumer để lắng nghe trạng thái isLoading từ AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 40),

                // Email Field
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                    hintText: 'Mật khẩu',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  ),
                  onPressed: authProvider.isLoading ? null : _handleLogin,
                  child: authProvider.isLoading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot Password & Register Links
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (ctx) => RegisterPage()));
                  },
                  child: const Text('Chưa có tài khoản? Đăng ký', style: TextStyle(color: Colors.blueAccent)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (ctx) =>  ForgotPasswordScreen()));
                  },
                  child: const Text('Quên mật khẩu?', style: TextStyle(color: Colors.blueAccent)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}