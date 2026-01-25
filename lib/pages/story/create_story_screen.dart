import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../provider/story_provider.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _pickImage(); // Tự động mở thư viện ảnh khi vào màn hình
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } else {
      Navigator.pop(context); // Nếu không chọn gì thì back về
    }
  }

  Future<void> _uploadStory() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    final success = await Provider.of<StoryProvider>(context, listen: false)
        .postStory(_imageFile!);
    if (!mounted) return;
    setState(() => _isUploading = false);

    if (success) {
      if (mounted) Navigator.pop(context); // Đóng màn hình khi xong
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng tin thành công!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi khi đăng tin")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _imageFile == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Ảnh Preview full màn hình
          Positioned.fill(
            child: Image.file(_imageFile!, fit: BoxFit.cover),
          ),

          // Nút Đóng (Góc trái trên)
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Nút Đăng (Góc phải dưới)
          Positioned(
            bottom: 30,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: _isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_isUploading ? " Đang đăng..." : "Tin của bạn"),
            ),
          ),
        ],
      ),
    );
  }
}