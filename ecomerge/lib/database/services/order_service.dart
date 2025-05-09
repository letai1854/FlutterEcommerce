import 'dart:convert';
import 'dart:io'; // For SocketException and HttpClient
import 'package:e_commerce_app/database/database_helper.dart'; // For baseurl
import 'package:e_commerce_app/database/models/order/CreateOrderRequestDTO.dart';
import 'package:e_commerce_app/database/models/order/OrderDTO.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // For auth token
import 'package:flutter/foundation.dart'; // For kDebugMode, kIsWeb
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // For IOClient

class OrderService {
  final String _baseUrl = baseurl;
  late final http.Client httpClient;

  OrderService() {
    httpClient = _createSecureClient();
  }

  http.Client _createSecureClient() {
    if (kIsWeb) {
      return http.Client();
    } else {
      final HttpClient ioClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => kDebugMode);
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

  Future<OrderDTO> createOrder(CreateOrderRequestDTO requestDTO) async {
    final url = Uri.parse('$_baseUrl/api/orders');
    if (kDebugMode) {
      print('Create Order Request URL: $url');
      try {
        print('Create Order Request Body: ${jsonEncode(requestDTO.toJson())}');
      } catch (e) {
        print('Error encoding requestDTO to JSON: $e');
      }
    }

    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(requestDTO.toJson()),
      );

      if (kDebugMode) {
        print('Create Order Response Status: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          try {
            print(
                'Create Order Response Body: ${utf8.decode(response.bodyBytes)}');
          } catch (e) {
            print('Error decoding response body: $e');
          }
        }
      }

      switch (response.statusCode) {
        case 201:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
            return OrderDTO.fromJson(responseBody);
          } else {
            throw FormatException(
                'Invalid response format for created order: Expected a JSON object, got ${responseBody.runtimeType}.');
          }
        case 400:
          String errorMessage = 'Failed to create order due to invalid data.';
          try {
            if (response.bodyBytes.isNotEmpty) {
              final decodedBody = utf8.decode(response.bodyBytes);
              try {
                final errorJson = jsonDecode(decodedBody);
                if (errorJson is Map && errorJson.containsKey('message')) {
                  errorMessage = errorJson['message'];
                } else if (errorJson is String && errorJson.isNotEmpty) {
                  errorMessage = errorJson;
                } else {
                  errorMessage = decodedBody;
                }
              } catch (_) {
                errorMessage = decodedBody;
              }
            }
          } catch (_) {}
          throw Exception('$errorMessage (Status: 400)');
        case 401:
          String errorMessage = 'User not authenticated. Please log in.';
          try {
            if (response.bodyBytes.isNotEmpty) {
              final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
              if (errorBody is Map && errorBody.containsKey('message')) {
                errorMessage = errorBody['message'];
              } else if (errorBody is String && errorBody.isNotEmpty) {
                errorMessage = errorBody;
              }
            }
          } catch (_) {}
          throw Exception('$errorMessage (Status: 401)');
        case 500:
          String errorMessage =
              'An unexpected error occurred while creating the order.';
          try {
            if (response.bodyBytes.isNotEmpty) {
              final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
              if (errorBody is Map && errorBody.containsKey('message')) {
                errorMessage = errorBody['message'];
              } else if (errorBody is String && errorBody.isNotEmpty) {
                errorMessage = errorBody;
              }
            }
          } catch (_) {}
          throw Exception('$errorMessage (Status: 500)');
        default:
          String errorMessage = 'Failed to create order.';
          try {
            if (response.bodyBytes.isNotEmpty) {
              final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
              if (errorBody is Map && errorBody.containsKey('message')) {
                errorMessage = errorBody['message'];
              } else if (errorBody is String && errorBody.isNotEmpty) {
                errorMessage = errorBody;
              }
            }
          } catch (_) {}
          errorMessage = '$errorMessage (Status: ${response.statusCode})';
          throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('SocketException during createOrder: $e');
      throw Exception('Network Error: Could not connect to server.');
    } on FormatException catch (e) {
      if (kDebugMode) print('FormatException during createOrder: $e');
      throw Exception('Server response format error for create order.');
    } catch (e) {
      if (kDebugMode)
        print('Unexpected Error during createOrder: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  void dispose() {
    httpClient.close();
    if (kDebugMode) print('OrderService httpClient disposed.');
  }
}
