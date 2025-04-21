import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/pages/login_page.dart';
import 'dart:convert';

import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp; // Nhận OTP từ màn hình quên mật khẩu trước đó

  ResetPasswordScreen({required this.email, required this.otp});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> _resetPassword() async {
    final otp = _otpController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _message = 'Vui lòng điền đầy đủ thông tin.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _message = 'Mật khẩu mới và xác nhận mật khẩu không khớp.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            '${dotenv.env['BASE_URL']}/auth/reset-password'), // URL của API bạn sử dụng
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _message = data['message']; // Thông báo thành công từ API
        });

        // Sau khi đổi mật khẩu thành công, có thể điều hướng về màn hình đăng nhập
        ToastService.showSuccessToast(
          context,
          length: ToastLength.medium,
          expandedHeight: 100,
          message: "Đổi mật khẩu thành công!",
        );
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (ctx) => LoginPage()));
      } else {
        ToastService.showErrorToast(
          context,
          length: ToastLength.medium,
          expandedHeight: 100,
          message: "Có lỗi xảy ra!",
        );
        setState(() {
          _message = data['message'] ?? 'Có lỗi xảy ra!';
        });
      }
    } catch (error) {
      print(
          "Lỗi trong quá trình gọi API: $error"); // In lỗi chi tiết ra console
      setState(() {
        _message = 'Không thể kết nối đến server: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt lại mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _otpController,
              decoration: InputDecoration(labelText: 'Nhập mã OTP'),
            ),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(labelText: 'Mật khẩu mới'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Đặt lại mật khẩu'),
            ),
            SizedBox(height: 20),
            if (_message.isNotEmpty) Text(_message),
          ],
        ),
      ),
    );
  }
}
