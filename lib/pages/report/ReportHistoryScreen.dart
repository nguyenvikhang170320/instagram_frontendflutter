import 'package:flutter/material.dart';
import 'package:instagram/services/report_service.dart';
import 'package:intl/intl.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  late Future<List<dynamic>> _futureReports;

  @override
  void initState() {
    super.initState();
    _futureReports = ReportService.getMyReports();
  }

  String formatDate(String? iso) {
    if (iso == null) return "";
    final dt = DateTime.parse(iso);
    return DateFormat("dd/MM/yyyy HH:mm").format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo của tôi"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureReports,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Lỗi tải dữ liệu"));
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const Center(child: Text("Bạn chưa gửi báo cáo nào"));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(report['reason'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Loại: ${report['targetType']}"),
                      Text("Trạng thái: ${report['status']}"),
                      Text("Ngày: ${formatDate(report['createdAt'])}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}