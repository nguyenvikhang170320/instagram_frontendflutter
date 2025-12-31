import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

import '../../provider/post_provider.dart';
import '../../sharepreference/sharepre.dart';

class UploadPostScreen extends StatefulWidget {
  const UploadPostScreen({super.key});

  @override
  State<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  File? _image;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85, // giảm size chút cho nhanh upload (tuỳ bạn) [web:546]
    );
    if (picked == null) return;
    setState(() => _image = File(picked.path));
  }

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text("Chọn từ thư viện"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text("Chụp ảnh"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_image != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text("Bỏ ảnh đã chọn"),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _image = null);
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Future<void> _submit() async {
    final caption = _captionController.text.trim();
    if (_image == null) {
      ToastService.showWarningToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Vui lòng chọn ảnh.",
      );
      return;
    }

    final userId = await getUserId();
    if (!mounted) return;

    if (userId == null) {
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Chưa có userId, vui lòng đăng nhập lại.",
      );
      return;
    }

    final ok = await context.read<PostProvider>().uploadPost(
      userId: userId,
      imageFile: _image!,
      caption: caption,
    );

    if (!mounted) return;

    if (ok) {
      ToastService.showSuccessToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: "Đăng bài thành công!",
      );
      Navigator.pop(context);
    } else {
      final err = context
          .read<PostProvider>()
          .error ?? "Upload thất bại!";
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: err,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context
        .watch<PostProvider>()
        .loading;
    final bottomInset = MediaQuery
        .of(context)
        .viewInsets
        .bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true, // default true [web:679]
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: loading ? null : () => Navigator.pop(context),
        ),
        title: const Text("Bài viết mới",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: loading ? null : _submit,
            child: Text(
              loading ? "Đang đăng..." : "Chia sẻ",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
          children: [
            GestureDetector(
              onTap: loading ? null : _showPickSheet,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: Colors.black12,
                  child: _image == null
                      ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 42),
                        SizedBox(height: 8),
                        Text("Nhấn để chọn ảnh"),
                      ],
                    ),
                  )
                      : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black12,
                  child: Icon(Icons.person, color: Colors.black54),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    enabled: !loading,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Viết chú thích...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            ListTile(
              enabled: !loading,
              onTap: _showPickSheet,
              leading: const Icon(Icons.collections_outlined),
              title: const Text("Chọn ảnh khác"),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
