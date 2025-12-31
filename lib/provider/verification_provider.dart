import 'package:flutter/foundation.dart';
import '../services/verification_service.dart';

class VerificationProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  bool isVerified = false;
  String status = '';
  bool requestSent = false;

  Future<void> checkStatus(String userId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await VerificationService.checkStatus(userId);
      isVerified = result['isVerified'] ?? false;
      status = (result['status'] ?? '').toString();
      requestSent = (status == 'pending' || status == 'approved');
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
