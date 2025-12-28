import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:provider/provider.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../../provider/notification_provider.dart';

class UploadPostScreen extends StatefulWidget {
  @override
  _UploadPostScreenState createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  File? _image;
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

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

  Future<String?> _uploadToBackend(File imageFile, String caption) async {
    final String backendUrl =
        "${dotenv.env['BASE_URL']}/posts/upload"; // API upload backend

    String? userId = await getUserId();
    if (userId == null) {
      print("⚠️ Không tìm thấy userId");
      return null;
    }

    try {
      var request = http.MultipartRequest("POST", Uri.parse(backendUrl));

      // Thêm ảnh vào form-data
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      // Thêm dữ liệu khác vào body request
      request.fields['userId'] = userId;
      request.fields['caption'] = caption;

      var response = await request.send();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(await response.stream.bytesToString());
        return jsonResponse['imageUrl']; // Backend trả về đường link ảnh
      } else {
        print("❌ Lỗi upload ảnh: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Lỗi khi upload ảnh: $e");
      return null;
    }
  }

  Future<void> _uploadPost() async {
    if (_image == null || _captionController.text.isEmpty) {
      ToastService.showWarningToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Vui lòng chọn ảnh, và nhập mô tả ảnh",
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl = await _uploadToBackend(_image!, _captionController.text);

    if (imageUrl == null) {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Upload ảnh thất bại!",
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }
    ToastService.showSuccessToast(
      context,
      length: ToastLength.medium,
      expandedHeight: 100,
      message: "Đăng bài thành công!",
    );

    setState(() {
      _isUploading = false;
      _image = null;
      _captionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đăng ảnh mới")),
      body: Column(
        children: [
          _image != null
              ? Image.file(_image!, height: 200, fit: BoxFit.cover)
              : TextButton(
                  onPressed: () {
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
                  },
                  child: Text("Chọn ảnh từ thư viện"),
                ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _captionController,
              decoration: InputDecoration(labelText: "Nhập mô tả..."),
            ),
          ),
          _isUploading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _uploadPost,
                  child: Text("Đăng bài"),
                ),
        ],
      ),
    );
  }
}
