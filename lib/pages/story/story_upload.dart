import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:toasty_box/toast_enums.dart';
import 'dart:io';

import 'package:toasty_box/toast_service.dart';

class StoryUploadScreen extends StatefulWidget {
  final String userId;

  StoryUploadScreen({required this.userId});

  @override
  _StoryUploadScreenState createState() => _StoryUploadScreenState();
}

class _StoryUploadScreenState extends State<StoryUploadScreen> {
  File? _image;
  final String apiUrl = "${dotenv.env['BASE_URL']}/stories/upload";

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadStory() async {
    if (_image == null) return;

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    request.fields['userId'] = widget.userId;

    var response = await request.send();
    if (response.statusCode == 200) {
      if (mounted) {
        ToastService.showSuccessToast(
          context,
          length: ToastLength.medium,
          expandedHeight: 100,
          message: "Đăng story thành công",
        );
        Navigator.pop(context);
      }
    } else {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Đăng story thất bại",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đăng Story"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      _image!,
                      height: 300,
                      width: 300,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("Chọn ảnh"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _image == null ? null : uploadStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: _image == null ? Colors.grey : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("Đăng Story"),
            ),
          ],
        ),
      ),
    );
  }
}
