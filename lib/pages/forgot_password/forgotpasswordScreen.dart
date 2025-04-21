import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/pages/forgot_password/resetpasswordScreen.dart';
import 'package:toasty_box/toast_enums.dart';
import 'dart:convert';

import 'package:toasty_box/toast_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

// Hàm gửi OTP
  Future<void> _sendOtp() async {
    final email = _emailController.text;

    if (email.isEmpty) {
      setState(() {
        _message = 'Vui lòng nhập email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API gửi OTP
      final response = await http.post(
        Uri.parse(
            '${dotenv.env['BASE_URL']}/auth/forgot-password'), // Thay bằng URL của API bạn đã có
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _message = data['message']; // Thông báo từ API
        });

        String otp = data['otp']; // Nhận OTP từ API trả về

        // Kiểm tra lại giá trị OTP có hợp lệ không
        if (otp.isNotEmpty) {
          // Chuyển sang trang ResetPasswordScreen với email và otp
          ToastService.showSuccessToast(
            context,
            length: ToastLength.medium,
            expandedHeight: 100,
            message:
                "Chuyển sang trang đổi mật khẩu, bạn nhập otp đã gửi qua email của bạn ạ!",
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: email, otp: otp),
            ),
          );
        } else {
          ToastService.showErrorToast(
            context,
            length: ToastLength.medium,
            expandedHeight: 100,
            message: "Lỗi otp không hợp lệ!",
          );
          setState(() {
            _message = 'Mã OTP không hợp lệ hoặc không được nhận.';
          });
        }
      } else {
        // Hiển thị thông báo lỗi từ API
        setState(() {
          _message = data['message'] ?? 'Có lỗi xảy ra!';
        });
      }
    } catch (error) {
      setState(() {
        _message = 'Không thể kết nối đến server.';
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
        title: Text('Quên mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOtp,
              child:
                  _isLoading ? CircularProgressIndicator() : Text('Gửi mã OTP'),
            ),
            SizedBox(height: 20),
            if (_message.isNotEmpty) Text(_message),
          ],
        ),
      ),
    );
  }
}
