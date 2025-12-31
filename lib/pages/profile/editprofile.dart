import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';
import 'package:provider/provider.dart';
import 'package:instagram/provider/auth_provider.dart';

import '../../provider/profile_provider.dart';


class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _fullnameController =
      TextEditingController(); // Thêm fullname
  TextEditingController _bioController = TextEditingController();
  File? _image;
  String? _avatarUrl;
  String? userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = await getUserId();
      if (!mounted || uid == null) return;

      userId = uid;

      // đảm bảo profile có data
      await context.read<ProfileProvider>().fetchProfile(uid);

      final u = context.read<ProfileProvider>().profile;
      setState(() {
        _usernameController.text = u.username;
        _fullnameController.text = u.fullname;
        _bioController.text = u.bio;
        _avatarUrl = u.avatar;
      });
    });
  }
  @override
  void dispose() {
    _usernameController.dispose();
    _fullnameController.dispose();
    _bioController.dispose();
    super.dispose();
  }


  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      } else {
        print("Người dùng không chọn ảnh.");
      }
    } catch (e) {
      print("Lỗi khi chọn ảnh: $e");
    }
  }

  Future<void> _updateProfile() async {
    if (userId == null) return;

    final ok = await context.read<ProfileProvider>().updateProfile(
      userId: userId!,
      username: _usernameController.text,
      fullname: _fullnameController.text,
      bio: _bioController.text.isNotEmpty ? _bioController.text : "",
      avatarFile: _image,
    );

    if (!mounted) return;

    if (ok) {
      final newAvatar = context.read<ProfileProvider>().profile.avatar;
      setState(() {
        setState(() => _avatarUrl = context.read<ProfileProvider>().profile.avatar);
      });

      Navigator.pop(context, true);
      ToastService.showSuccessToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Cập nhật thành công",
      );
    } else {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: context.read<ProfileProvider>().error ?? "Lỗi cập nhật",
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chỉnh sửa trang cá nhân")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? NetworkImage(_avatarUrl!)
                              : AssetImage("assets/images/user.jpg"))
                          as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Wrap(
                            children: [
                              ListTile(
                                leading: Icon(Icons.camera_alt),
                                title: Text('Chụp ảnh'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text('Chọn từ thư viện'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }, // Khi bấm vào icon camera thì chọn ảnh
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Tên người dùng"),
            ),
            TextField(
              controller: _fullnameController,
              decoration: InputDecoration(labelText: "Họ và tên"),
            ),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(labelText: "Tiểu sử"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text("Lưu"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showChangePasswordSheet(context),
              child: const Text("Đổi mật khẩu"),
            ),
          ],
        ),
      ),
    );
  }
  void _showChangePasswordSheet(BuildContext context) {
    final emailCtl = TextEditingController();
    final otpCtl = TextEditingController();
    final newPassCtl = TextEditingController();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final auth = ctx.watch<AuthProvider>();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Đổi mật khẩu",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: emailCtl,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: otpCtl,
                          decoration: const InputDecoration(labelText: "OTP"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                          final otp = await ctx
                              .read<AuthProvider>()
                              .forgotPassword(email: emailCtl.text.trim());

                          if (ctx.read<AuthProvider>().error != null) {
                            ToastService.showErrorToast(
                              ctx,
                              length: ToastLength.medium,
                              expandedHeight: 100,
                              message:
                              ctx.read<AuthProvider>().error ?? "Lỗi",
                            );
                            return;
                          }

                          // backend bạn đang trả otp để test
                          if (otp != null && otp.isNotEmpty) {
                            otpCtl.text = otp;
                            ToastService.showSuccessToast(
                              ctx,
                              length: ToastLength.medium,
                              expandedHeight: 100,
                              message: "Đã gửi OTP (test: auto fill OTP)",
                            );
                          } else {
                            ToastService.showSuccessToast(
                              ctx,
                              length: ToastLength.medium,
                              expandedHeight: 100,
                              message: "Đã gửi OTP về email",
                            );
                          }
                        },
                        child: auth.isLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text("Gửi OTP"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: newPassCtl,
                    obscureText: obscure, // dùng obscureText cho password [web:217]
                    decoration: InputDecoration(
                      labelText: "Mật khẩu mới",
                      suffixIcon: IconButton(
                        icon: Icon(obscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setModalState(() => obscure = !obscure),
                      ),
                    ),
                  ),

                  if (auth.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      auth.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                      final ok = await ctx.read<AuthProvider>().resetPassword(
                        email: emailCtl.text.trim(),
                        newPassword: newPassCtl.text,
                        otp: otpCtl.text.trim(),
                      );

                      if (!ok) {
                        ToastService.showErrorToast(
                          ctx,
                          length: ToastLength.medium,
                          expandedHeight: 100,
                          message: ctx.read<AuthProvider>().error ?? "Lỗi",
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      ToastService.showSuccessToast(
                        context,
                        length: ToastLength.medium,
                        expandedHeight: 100,
                        message: "Đổi mật khẩu thành công",
                      );
                    },
                    child: auth.isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("Xác nhận đổi mật khẩu"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}
