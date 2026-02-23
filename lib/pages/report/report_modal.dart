import 'package:flutter/material.dart';
import '../../services/report_service.dart';

class ReportModal extends StatelessWidget {
  final String targetId;
  final String targetType;

  const ReportModal({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> reportReasons = [
      "Chỉ là tôi không thích nội dung này",
      "Bắt nạt hoặc liên hệ theo cách không mong muốn",
      "Tự tử, tự gây thương tích hoặc chứng rối loạn ăn uống",
      "Bạo lực, thù ghét hoặc bóc lột",
      "Bán hoặc quảng cáo mặt hàng bị hạn chế",
      "Ảnh khỏa thân hoặc hoạt động tình dục",
      "Lừa đảo, gian lận hoặc spam",
      "Thông tin sai sự thật",
    ];

    Future<void> _handleReport(String reason) async {
      try {
        final success = await ReportService.reportPost(
          targetId,
          reason,
          targetType,
        );

        Navigator.pop(context);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã gửi báo cáo thành công"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gửi báo cáo thất bại"),
            ),
          );
        }
      } catch (_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi khi gửi báo cáo"),
          ),
        );
      }
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Báo Cáo",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tại sao bạn báo cáo nội dung này?",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Báo cáo của bạn sẽ được ẩn danh.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...reportReasons.map((reason) {
                return ListTile(
                  title: Text(reason),
                  onTap: () => _handleReport(reason),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}