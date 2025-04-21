import 'package:flutter/material.dart';

class ReportModal extends StatelessWidget {
  final Function(String) onReport;

  ReportModal({required this.onReport});

  @override
  Widget build(BuildContext context) {
    List<String> reportReasons = [
      "Chỉ là tôi không thích nội dung này",
      "Bắt nạt hoặc liên hệ theo cách không mong muốn",
      "Tự tử, tự gây thương tích hoặc chứng rối loạn ăn uống",
      "Bạo lực, thù ghét hoặc bóc lột",
      "Bán hoặc quảng cáo mặt hàng bị hạn chế",
      "Ảnh khỏa thân hoặc hoạt động tình dục",
      "Lừa đảo, gian lận hoặc spam",
      "Thông tin sai sự thật",
    ];

    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Báo Cáo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 30,
            ),
            Text("Tại sao bạn báo cáo bài viết này?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Báo cáo của bạn sẽ được ẩn danh.",
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            ...reportReasons.map((reason) {
              return ListTile(
                title: Text(reason),
                onTap: () {
                  onReport(reason);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
