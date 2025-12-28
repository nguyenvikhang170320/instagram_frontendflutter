import 'package:flutter/material.dart';
import 'package:instagram/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:instagram/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  // 1️⃣ Thêm biến này để quản lý trạng thái ẩn/hiện
  bool _isObscure = true;

  void _handleRegister() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.register(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      username: usernameController.text.trim(),
      fullname: fullnameController.text.trim(),
      context: context,
    );

    if (success) {
      ToastService.showSuccessToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Đăng ký thành công! Vui lòng đăng nhập.",
      );
      // Chuyển về trang đăng nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Đăng ký thất bại. Email có thể đã tồn tại.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  const SizedBox(height: 32),

                  // Các trường nhập liệu (Giữ nguyên UI của bạn)
                  _buildTextField('Email', emailController),
                  const SizedBox(height: 12),
                  _buildTextField('Mật khẩu', passwordController, isPassword: true),
                  const SizedBox(height: 12),
                  _buildTextField('Tên đầy đủ', fullnameController),
                  const SizedBox(height: 12),
                  _buildTextField('Tên người dùng', usernameController),

                  const SizedBox(height: 16),

                  // Nút Đăng ký
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50), // Full width
                    ),
                    onPressed: authProvider.isLoading ? null : _handleRegister,
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Đăng ký',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nút chuyển trang đăng nhập
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Đã có tài khoản? Đăng nhập',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        // Thêm icon mắt ở đuôi nếu là ô Password
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure; // Đổi trạng thái
            });
          },
        )
            : null, // Nếu không phải password thì không hiện icon
      ),
    );
  }
}