// lib/utils/http_client_config.dart

import 'dart:io';

import 'package:e_commerce_app/constants.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb and kDebugMode
import 'package:http/http.dart' as http; // Import standard http client
import 'package:http/io_client.dart';
// Chỉ import IOClient và dart:io khi không phải Web, sử dụng 'conditional import'
// Đây là cách an toàn nhất để đảm bảo code dart:io không bao giờ bị biên dịch/thực thi trên Web


// final String baseurl = !isMobile
//     ? 'https://localhost:8443'
//     : 'https://192.168.1.6:8443'; // Example for Web/Android Emulator HTTPS

final String baseurl = 'https://flutter-server-74f44f97b318.herokuapp.com';

// Khai báo biến client ở tầm vực top-level, nhưng không khởi tạo ngay
// Sử dụng kiểu động 'dynamic' hoặc kiểu chung nhất 'http.Client'
dynamic _client; // Dùng dynamic vì kiểu cụ thể (IOClient/BrowserClient) phụ thuộc nền tảng

// --- Public Getter for the appropriate HTTP Client ---
// Đây là hàm sẽ khởi tạo client LƯỜI BIẾNG và TRÊN NỀN TẢNG PHÙ HỢP
http.Client get httpClient {
  // Nếu client chưa được khởi tạo
  if (_client == null) {
    if (kIsWeb) {
      // Trên Web, sử dụng BrowserClient (hoặc http.Client)
      _client = http.Client(); // http.Client tự dùng BrowserClient trên web
    } else {
      // Trên Native (Mobile/Desktop)
      // Kiểm tra xem dart:io có sẵn không
      if (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux) {
        HttpClient nativeClient = HttpClient(); // Đây là dart:io.HttpClient

        // Chỉ bỏ qua lỗi chứng chỉ trong chế độ debug trên native
        if (kDebugMode) {
          nativeClient.badCertificateCallback =
              (X509Certificate cert, String host, int port) =>
                  true; // !!! DANGER: DO NOT USE IN PRODUCTION !!!
        }
        _client =
            IOClient(nativeClient); // Bọc dart:io.HttpClient trong IOClient
      } else {
        // Fallback hoặc xử lý trường hợp nền tảng không xác định
        _client = http.Client(); // Sử dụng client chuẩn
      }
    }
  }
  // Trả về client đã được khởi tạo
  return _client as http
      .Client; // Cast về http.Client vì cả IOClient và BrowserClient đều implement interface này
}

// Optional: Dispose clients when app shuts down
void disposeHttpClients() {
  _client?.close(); // Chỉ đóng nếu client đã được khởi tạo
  _client = null; // Reset về null
}
