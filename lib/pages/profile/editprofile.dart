import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:instagram/sharepreference/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    userId = await getUserId();
    if (userId == null) return;

    try {
      Dio dio = Dio();
      Response response =
          await dio.get("${dotenv.env['BASE_URL']}/users/$userId");

      if (response.statusCode == 200) {
        var user = response.data; // Lấy dữ liệu từ API
        print("User Data: $user");
        setState(() {
          _usernameController.text = user["username"] ?? null;
          _fullnameController.text =
              user["fullname"] ?? null; // Lấy fullname từ API
          _bioController.text = user["bio"] ?? null;
          _avatarUrl = user["avatar"];
        });
      }
    } catch (e) {
      print("Lỗi tải dữ liệu người dùng: $e");
    }
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
    try {
      Dio dio = Dio();
      FormData formData = FormData.fromMap({
        "username": _usernameController.text,
        "fullname": _fullnameController.text, // Gửi fullname lên API
        "bio": _bioController.text.isNotEmpty ? _bioController.text : "",

        if (_image != null)
          "avatar":
              await MultipartFile.fromFile(_image!.path, filename: "avatar"),
      });

      Response response = await dio.put(
          "${dotenv.env['BASE_URL']}/users/update/$userId",
          data: formData);

      if (response.statusCode == 200) {
        String? newAvatarUrl = response.data["avatar"];
        setState(() {
          _avatarUrl = newAvatarUrl ?? _avatarUrl; // Giữ giá trị cũ nếu null
        });
        Navigator.pop(context, true);
        ToastService.showSuccessToast(
          context,
          length: ToastLength.medium,
          expandedHeight: 100,
          message: "Cập nhật thành công",
        );
      }
    } catch (e) {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Lỗi cập nhật",
      );
      print("Lỗi $e");
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
          ],
        ),
      ),
    );
  }
}
