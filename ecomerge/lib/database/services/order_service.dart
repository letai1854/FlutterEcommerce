import 'dart:convert';
import 'dart:io'; // For SocketException and HttpClient
import 'package:e_commerce_app/database/database_helper.dart'; // For baseurl
import 'package:e_commerce_app/database/models/order/CreateOrderRequestDTO.dart';
import 'package:e_commerce_app/database/models/order/OrderDTO.dart'; // Imports OrderStatus, OrderStatusHistoryDTO, OrderPage
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

  Future<OrderPage> getCurrentUserOrders({
    OrderStatus? status,
    int page = 0, // Default to first page
    int size = 10, // Default page size
    String sort = 'orderDate,desc', // Default sort
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
    };
    if (status != null) {
      queryParams['status'] = orderStatusToString(status);
    }
    final url = Uri.parse('$_baseUrl/api/orders/me')
        .replace(queryParameters: queryParams);
    if (kDebugMode) {
      print('Get Current User Orders Request URL: $url');
    }

    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      if (kDebugMode) {
        print(
            'Get Current User Orders Response Status: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          try {
            print(
                'Get Current User Orders Response Body: ${utf8.decode(response.bodyBytes)}');
          } catch (e) {
            print('Error decoding response body: $e');
          }
        }
      }

      switch (response.statusCode) {
        case 200:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
            return OrderPage.fromJson(responseBody);
          } else {
            throw FormatException(
                'Invalid response format for user orders: Expected a JSON object, got ${responseBody.runtimeType}.');
          }
        case 204: // No content
          return OrderPage(
              orders: [],
              totalPages: 0,
              totalElements: 0,
              currentPage: 0,
              pageSize: size,
              isLast: true,
              isFirst: true);
        case 401:
          throw Exception(
              'User not authenticated. Please log in. (Status: 401)');
        case 500:
          throw Exception(
              'An unexpected error occurred while fetching orders. (Status: 500)');
        default:
          throw Exception(
              'Failed to fetch user orders. (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('SocketException during getCurrentUserOrders: $e');
      throw Exception('Network Error: Could not connect to server.');
    } on FormatException catch (e) {
      if (kDebugMode) print('FormatException during getCurrentUserOrders: $e');
      throw Exception('Server response format error for user orders.');
    } catch (e) {
      if (kDebugMode)
        print('Unexpected Error during getCurrentUserOrders: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<OrderDTO> getOrderDetailsForCurrentUser(int orderId) async {
    final url = Uri.parse('$_baseUrl/api/orders/me/$orderId');
    if (kDebugMode) {
      print('Get Order Details Request URL: $url');
    }

    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      if (kDebugMode) {
        print('Get Order Details Response Status: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          try {
            print(
                'Get Order Details Response Body: ${utf8.decode(response.bodyBytes)}');
          } catch (e) {
            print('Error decoding response body: $e');
          }
        }
      }

      switch (response.statusCode) {
        case 200:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
            return OrderDTO.fromJson(responseBody);
          } else {
            throw FormatException(
                'Invalid response format for order details: Expected a JSON object, got ${responseBody.runtimeType}.');
          }
        case 401:
          throw Exception(
              'User not authenticated. Please log in. (Status: 401)');
        case 404:
          throw Exception('Order not found. (Status: 404)');
        case 500:
          throw Exception(
              'An unexpected error occurred while fetching order details. (Status: 500)');
        default:
          throw Exception(
              'Failed to fetch order details. (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode)
        print('SocketException during getOrderDetailsForCurrentUser: $e');
      throw Exception('Network Error: Could not connect to server.');
    } on FormatException catch (e) {
      if (kDebugMode)
        print('FormatException during getOrderDetailsForCurrentUser: $e');
      throw Exception('Server response format error for order details.');
    } catch (e) {
      if (kDebugMode)
        print(
            'Unexpected Error during getOrderDetailsForCurrentUser: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<List<OrderStatusHistoryDTO>> getOrderStatusHistoryForCurrentUser(
      int orderId) async {
    final url = Uri.parse('$_baseUrl/api/orders/me/$orderId/history');
    if (kDebugMode) {
      print('Get Order Status History Request URL: $url');
    }

    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      if (kDebugMode) {
        print(
            'Get Order Status History Response Status: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          try {
            print(
                'Get Order Status History Response Body: ${utf8.decode(response.bodyBytes)}');
          } catch (e) {
            print('Error decoding response body: $e');
          }
        }
      }

      switch (response.statusCode) {
        case 200:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is List) {
            return responseBody
                .map((item) => OrderStatusHistoryDTO.fromJson(
                    item as Map<String, dynamic>))
                .toList();
          } else {
            throw FormatException(
                'Invalid response format for order status history: Expected a JSON array, got ${responseBody.runtimeType}.');
          }
        case 401:
          throw Exception(
              'User not authenticated. Please log in. (Status: 401)');
        case 404: // Order not found or no history (backend might return 200 with empty list too)
          return []; // Or throw Exception('Order not found or no history. (Status: 404)');
        case 500:
          throw Exception(
              'An unexpected error occurred while fetching order status history. (Status: 500)');
        default:
          throw Exception(
              'Failed to fetch order status history. (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode)
        print('SocketException during getOrderStatusHistoryForCurrentUser: $e');
      throw Exception('Network Error: Could not connect to server.');
    } on FormatException catch (e) {
      if (kDebugMode)
        print('FormatException during getOrderStatusHistoryForCurrentUser: $e');
      throw Exception('Server response format error for order status history.');
    } catch (e) {
      if (kDebugMode)
        print(
            'Unexpected Error during getOrderStatusHistoryForCurrentUser: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<OrderDTO> cancelOrderForCurrentUser(int orderId) async {
    final url = Uri.parse('$_baseUrl/api/orders/me/$orderId/cancel');
    if (kDebugMode) {
      print('Cancel Order Request URL: $url');
    }

    try {
      // PATCH request typically doesn't have a body for this kind of operation,
      // but if it did, it would be jsonEncode({}) or similar.
      final response = await httpClient.patch(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      if (kDebugMode) {
        print('Cancel Order Response Status: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          try {
            print(
                'Cancel Order Response Body: ${utf8.decode(response.bodyBytes)}');
          } catch (e) {
            print('Error decoding response body: $e');
          }
        }
      }

      switch (response.statusCode) {
        case 200: // OK, order cancelled
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
            return OrderDTO.fromJson(responseBody);
          } else {
            throw FormatException(
                'Invalid response format for cancelled order: Expected a JSON object, got ${responseBody.runtimeType}.');
          }
        case 400: // Bad request (e.g., order cannot be cancelled)
          String errorMessage = 'Failed to cancel order.';
          try {
            if (response.bodyBytes.isNotEmpty) {
              final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
              if (errorBody is String && errorBody.isNotEmpty) {
                errorMessage = errorBody;
              } else if (errorBody is Map && errorBody.containsKey('message')) {
                errorMessage = errorBody['message'];
              }
            }
          } catch (_) {}
          throw Exception('$errorMessage (Status: 400)');
        case 401:
          throw Exception(
              'User not authenticated. Please log in. (Status: 401)');
        case 404:
          throw Exception('Order not found. (Status: 404)');
        case 500:
          throw Exception(
              'An unexpected error occurred while cancelling the order. (Status: 500)');
        default:
          throw Exception(
              'Failed to cancel order. (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode)
        print('SocketException during cancelOrderForCurrentUser: $e');
      throw Exception('Network Error: Could not connect to server.');
    } on FormatException catch (e) {
      if (kDebugMode)
        print('FormatException during cancelOrderForCurrentUser: $e');
      throw Exception('Server response format error for cancel order.');
    } catch (e) {
      if (kDebugMode)
        print(
            'Unexpected Error during cancelOrderForCurrentUser: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  void dispose() {
    httpClient.close();
    if (kDebugMode) print('OrderService httpClient disposed.');
  }
}
