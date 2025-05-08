import 'dart:convert';
import 'dart:io';
import 'package:e_commerce_app/database/database_helper.dart'; // Ensure 'baseurl' here is correctly configured for your target platform.
import 'package:e_commerce_app/database/models/coupon_dto.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:intl/intl.dart'; // For date formatting

class CouponService {
  final String _baseUrl = '$baseurl/api/coupons';
  late final http.Client _httpClient;

  CouponService() {
    _httpClient = _createSecureClient();
  }

  http.Client _createSecureClient() {
    if (kIsWeb) {
      // For web, a standard http.Client is used.
      // - Ensure backend server has CORS configured if Flutter web app is on a different origin/port.
      // - For HTTPS localhost with self-signed cert, browser must trust the certificate.
      //   Visit the backend URL (e.g., https://localhost:8443) directly in the browser
      //   and accept security warnings if necessary.
      return http.Client();
    } else {
      // For mobile and desktop platforms, HttpClient allows bypassing SSL certificate checks
      // for development with self-signed certificates on localhost.
      // - If running on Android Emulator, 'localhost' in baseurl should be '10.0.2.2' to reach host.
      // - If running on a physical mobile device, 'localhost' should be host machine's network IP.
      final HttpClient ioClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      return IOClient(ioClient);
    }
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    final authToken = UserInfo().authToken;
    if (includeAuth && authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<CouponResponseDTO> createCoupon(
      CreateCouponRequestDTO requestDTO) async {
    final url = Uri.parse(_baseUrl);
    try {
      final response = await _httpClient.post(
        url,
        headers: _getHeaders(includeAuth: true), // Admin role needed
        body: jsonEncode(requestDTO.toJson()),
      );

      if (kDebugMode) {
        print('Create Coupon Request URL: $url');
        print('Create Coupon Request Body: ${jsonEncode(requestDTO.toJson())}');
        print('Create Coupon Response Status: ${response.statusCode}');
        print(
            'Create Coupon Response Body: ${utf8.decode(response.bodyBytes)}');
      }

      if (response.statusCode == 201) {
        return CouponResponseDTO.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        String errorMessage = 'Failed to create coupon.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception(
            'Failed to create coupon: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      // SocketException typically means network layer issues (e.g., host unreachable, connection refused).
      if (kDebugMode) print('SocketException during create coupon: $e');
      throw Exception(
          'Network Error: Could not connect to server. Verify server is running and accessible.');
    } catch (e) {
      // Other exceptions, including ClientException ("Failed to fetch").
      if (kDebugMode) print('Unexpected Error during create coupon: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<List<CouponResponseDTO>> getCoupons({
    String? code,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<String, String> queryParameters = {};
    if (code != null && code.isNotEmpty) {
      queryParameters['code'] = code;
    }
    // Server expects 'yyyy-MM-dd' (ISO.DATE)
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    if (startDate != null) {
      queryParameters['startDate'] = formatter.format(startDate);
    }
    if (endDate != null) {
      queryParameters['endDate'] = formatter.format(endDate);
    }

    final url = Uri.parse(_baseUrl).replace(
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null);

    try {
      final response = await _httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true), // Admin role needed
      );

      if (kDebugMode) {
        print('Get Coupons Request URL: $url');
        print('Get Coupons Response Status: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          print(
              'Get Coupons Response Body: ${utf8.decode(response.bodyBytes)}');
        } else {
          print('Get Coupons Response Body: (Empty or 204)');
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList
            .map((jsonItem) =>
                CouponResponseDTO.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 204) {
        return []; // No content, as per server logic
      } else {
        String errorMessage = 'Failed to fetch coupons.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception(
            'Failed to fetch coupons: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      // SocketException typically means network layer issues.
      if (kDebugMode) print('SocketException during get coupons: $e');
      throw Exception(
          'Network Error: Could not connect to server. Verify server is running and accessible.');
    } catch (e) {
      // Other exceptions, including ClientException ("Failed to fetch").
      // This is where the error in the screenshot originates.
      // It means the HTTP request itself failed at a low level.
      // Common causes: Server not running, DNS issue (not for localhost),
      // SSL handshake failure (if badCertificateCallback fails or not applicable like on web),
      // or CORS issues on web.
      if (kDebugMode) print('Unexpected Error during get coupons: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<List<CouponResponseDTO>> getAvailableCoupons() async {
    final url = Uri.parse('$_baseUrl/available');

    try {
      final response = await _httpClient.get(
        url,
        headers: _getHeaders(
            includeAuth:
                true), // Changed to true to include authentication token
      );

      if (kDebugMode) {
        print('Get Available Coupons Request URL: $url');
        print('Get Available Coupons Response Status: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          print(
              'Get Available Coupons Response Body: ${utf8.decode(response.bodyBytes)}');
        } else {
          print('Get Available Coupons Response Body: (Empty or 204)');
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList
            .map((jsonItem) =>
                CouponResponseDTO.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 204) {
        return []; // No content, as per server logic
      } else {
        String errorMessage = 'Failed to fetch available coupons.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception(
            'Failed to fetch available coupons: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('SocketException during get available coupons: $e');
      throw Exception(
          'Network Error: Could not connect to server. Verify server is running and accessible.');
    } catch (e) {
      if (kDebugMode)
        print('Unexpected Error during get available coupons: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
