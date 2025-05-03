import 'dart:convert';
import 'package:e_commerce_app/constants.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = baseUrl;
  // Create a single client instance
  final http.Client _client;

  // Constructor to initialize the client
  ApiService() : _client = http.Client();

  // Method to close the client when ApiService is no longer needed
  void dispose() {
    _client.close();
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final String decodedBody = utf8.decode(response.bodyBytes);
    Map<String, dynamic> responseData = {};
    if (decodedBody.isNotEmpty) {
      try {
        final decodedJson = json.decode(decodedBody);
        if (decodedJson is Map<String, dynamic>) {
          responseData = decodedJson;
        } else if (decodedJson is List && response.statusCode >= 200 && response.statusCode < 300) {
          return {'data': decodedJson};
        }
      } catch (e) {
        print('Failed to decode JSON response body: $e');
        if (!(response.statusCode >= 200 && response.statusCode < 300)) {
          throw ApiException('Invalid response format from server.', response.statusCode);
        }
      }
    }

    print('API Response Status: ${response.statusCode}');
    print('API Response Body: $decodedBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      String errorMessage = 'API Error';
      if (responseData.containsKey('message') && responseData['message'] is String) {
        errorMessage = responseData['message'];
      } else if (decodedBody.isNotEmpty) {
        errorMessage = decodedBody;
      }
      throw ApiException(errorMessage, response.statusCode);
    }
  }
}

// Custom Exception class for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() {
    if (statusCode == 401) return 'Email hoặc mật khẩu không đúng';
    if (statusCode == 409) return 'Email đã tồn tại';
    if (message.isNotEmpty && !message.toLowerCase().contains('error')) return message;
    switch (statusCode) {
      case 400:
        return 'Dữ liệu gửi lên không hợp lệ.';
      case 404:
        return 'Không tìm thấy tài nguyên yêu cầu.';
      case 500:
        return 'Lỗi máy chủ nội bộ.';
    }
    return 'Lỗi API ($statusCode): ${message.isNotEmpty ? message : "Không có thông tin chi tiết."}';
  }
}
