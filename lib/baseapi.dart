import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ Import thư viện này
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BaseApi {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  BaseApi() {
    // ✅ Lấy BASE_URL từ file .env
    // Nếu chưa load được hoặc null thì fallback về localhost mặc định để tránh crash
    final String baseUrl = dotenv.env['BASE_URL'] ?? "http://localhost:5000/api";

    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Interceptor: Tự động chèn Token vào mỗi Request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await _storage.read(key: "auth_token");
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          print("⚠️ Token hết hạn hoặc không hợp lệ");
          // Xử lý logout nếu cần
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}