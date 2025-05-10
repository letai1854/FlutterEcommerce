import 'dart:convert';
import 'dart:io'; // For SocketException and HttpClient
import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/database_helper.dart'; // For baseurl
import 'package:e_commerce_app/database/models/order/CreateOrderRequestDTO.dart';
import 'package:e_commerce_app/database/models/order/OrderDTO.dart'; // Imports OrderStatus, OrderStatusHistoryDTO, OrderPage
import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // For auth token
import 'package:flutter/foundation.dart'; // For kDebugMode, kIsWeb
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // For IOClient

  enum PaymentStatus {
        chua_thanh_toan, da_thanh_toan, loi_thanh_toan
    }

     enum OrderStatus {
        cho_xu_ly, da_xac_nhan, dang_giao, da_giao, da_huy
    }
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
  static final Map<String, Uint8List> _imageCache = {};

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

  Future<PageResponse<OrderDTO>> getOrdersForAdmin({
    int? searchOrderId,
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 0,
    int size = 20,
    String sort = 'orderDate,desc',
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
    };

    if (searchOrderId != null) {
      queryParams['searchOrderId'] = searchOrderId.toString();
    }
    if (status != null) {
      queryParams['status'] = orderStatusToString(status);
    }
    if (startDate != null) {
      queryParams['startDate'] = _formatDate(startDate);
    }
    if (endDate != null) {
      queryParams['endDate'] = _formatDate(endDate);
    }

    // Updated URL path to match Java @GetMapping("/admin/search") endpoint
    final url = Uri.parse('$_baseUrl/api/orders/admin/search')
        .replace(queryParameters: queryParams);
    
    if (kDebugMode) {
      print('Get Admin Orders Request URL: $url');
    }

    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );
      
      // Add more detailed logging
      if (kDebugMode) {
        print('Get Admin Orders Response: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          try {
            final responseBody = utf8.decode(response.bodyBytes);
            print('Get Admin Orders Response Body: $responseBody');
            
            // For 500 errors, try to extract more details
            if (response.statusCode == 500) {
              try {
                final errorData = jsonDecode(responseBody);
                if (errorData is Map && errorData.containsKey('message')) {
                  print('Server Error Details: ${errorData['message']}');
                  if (errorData.containsKey('error') && errorData.containsKey('path')) {
                    print('Error: ${errorData['error']}, Path: ${errorData['path']}');
                  }
                }
              } catch (e) {
                print('Failed to parse error response: $e');
              }
            }
          } catch (e) {
            print('Error decoding response body: $e');
          }
        } else {
          print('Empty response body with status ${response.statusCode}');
        }
      }

      switch (response.statusCode) {
        case 200:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
            return PageResponse<OrderDTO>.fromJson(
              responseBody,
              (item) => OrderDTO.fromJson(item as Map<String, dynamic>),
            );
          } else {
            throw FormatException(
                'Invalid response format for admin orders: Expected a JSON object, got ${responseBody.runtimeType}.');
          }
        case 204: // No content
          return PageResponse<OrderDTO>(
              content: [],
              totalPages: 0,
              totalElements: 0,
              number: 0,
              size: size,
              numberOfElements: 0, // Added missing required parameter
              last: true,
              first: true,
              empty: true); // Added missing required parameter
        case 400:
          String errorMessage = 'Bad request. Please check your input parameters.';
          try {
            if (response.bodyBytes.isNotEmpty) {
              final errorBody = utf8.decode(response.bodyBytes);
              errorMessage = errorBody;
            }
          } catch (_) {}
          throw Exception('$errorMessage (Status: 400)');
        case 401:
          throw Exception('User not authenticated. Please log in. (Status: 401)');
        case 403:
          throw Exception('Not authorized to access admin resources. (Status: 403)');
        case 500:
          String errorMessage = 'A server error occurred while fetching orders.';
          try {
            if (response.bodyBytes.isNotEmpty) {
              final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
              if (errorBody is Map && errorBody.containsKey('message')) {
                errorMessage = "Server error: ${errorBody['message']}";
              }
            }
          } catch (_) {}
          throw Exception('$errorMessage (Status: 500). Please contact support if this persists.');
        default:
          throw Exception('Failed to fetch admin orders. (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('SocketException during getOrdersForAdmin: $e');
      throw Exception('Network Error: Could not connect to server.');
    } on FormatException catch (e) {
      if (kDebugMode) print('FormatException during getOrdersForAdmin: $e');
      throw Exception('Server response format error for admin orders.');
    } catch (e) {
      if (kDebugMode) print('Unexpected Error during getOrdersForAdmin: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
   Future<Uint8List?> getImageFromServer(String? imagePath, {bool forceReload = false}) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    // Debug the image path to help diagnose issues
    if (kDebugMode) {
      print('Getting image from server: $imagePath');
    }
    
    // Check cache only if not forcing reload
    if (!forceReload) {
      // First check our product-specific image cache
      if (_imageCache.containsKey(imagePath)) {
        if (kDebugMode) print('Using cached image for $imagePath');
        return _imageCache[imagePath];
      }
      
      // Then check UserInfo avatar cache (existing implementation)
      if (UserInfo.avatarCache.containsKey(imagePath)) {
        if (kDebugMode) print('Using UserInfo cached image for $imagePath');
        return UserInfo.avatarCache[imagePath];
      }
    }

    try {
      String fullUrl = getImageUrl(imagePath);
      if (kDebugMode) {
        print('Fetching image from: $fullUrl');
      }
      
      // Add cache-busting parameter for forceReload
      if (forceReload) {
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        fullUrl += '?cacheBust=$cacheBuster';
      }
      
      final response = await httpClient.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        // Check if the response is actually an image by examining content type or bytes
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.startsWith('image/') && 
            !_looksLikeImageData(response.bodyBytes) &&
            kDebugMode) {
          print('Warning: Response doesn\'t appear to be an image. Content-Type: $contentType');
        }
        
        // Cache the image unless we're forcing reload
        if (!forceReload) {
          // Cache in both places for maximum compatibility
          _imageCache[imagePath] = response.bodyBytes;
          UserInfo.avatarCache[imagePath] = response.bodyBytes;
        }
        return response.bodyBytes;
      } else {
        if (kDebugMode) {
          print('Failed to load image. Status: ${response.statusCode}, Message: ${response.reasonPhrase}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching image: $e');
      }
    }

    return null;
  }
  
  // Simple check if data looks like image bytes
  bool _looksLikeImageData(Uint8List bytes) {
    if (bytes.length < 4) return false;
    
    // Check for common image format signatures
    // JPEG starts with FF D8
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;
    
    // PNG starts with 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    
    // GIF starts with 47 49 46 38
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) return true;
    
    // BMP starts with 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
    
    // WEBP starts with 52 49 46 46
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) return true;
    
    return false;
  }
  
  // Method to check if an image is already cached without fetching
  bool isImageCached(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    return _imageCache.containsKey(imagePath) || UserInfo.avatarCache.containsKey(imagePath);
  }
  
  // New method to get image directly from cache without network request
  Uint8List? getImageFromCache(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    // Check product cache first
    if (_imageCache.containsKey(imagePath)) {
      return _imageCache[imagePath];
    }
    
    // Then check avatar cache
    if (UserInfo.avatarCache.containsKey(imagePath)) {
      return UserInfo.avatarCache[imagePath];
    }
    
    return null; // Not found in any cache
  }
    String getImageUrl(String? imagePath) {
    if (imagePath == null) return '';

    // If the path already starts with http/https, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // If it's a relative path, combine with baseUrl
    // Remove any duplicate slashes between baseUrl and imagePath
    String path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$_baseUrl$path';
  }

  // Add method for updating order status by admin
  Future<OrderDTO> updateOrderStatusByAdmin(int orderId, OrderStatus newStatus, String? adminNotes) async {
    final url = Uri.parse('$_baseUrl/api/orders/$orderId/status');
    
    try {
      final requestBody = {
        'newStatus': orderStatusToString(newStatus),
        if (adminNotes != null) 'adminNotes': adminNotes,
      };

      final response = await httpClient.patch(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('Update Order Status Response: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          print('Response Body: ${utf8.decode(response.bodyBytes)}');
        }
      }

      switch (response.statusCode) {
        case 200:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          return OrderDTO.fromJson(responseBody);
        case 400:
          String errorMessage = 'Invalid request for status update';
          try {
            if (response.bodyBytes.isNotEmpty) {
              final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
              if (errorBody is Map && errorBody.containsKey('message')) {
                errorMessage = errorBody['message'];
              }
            }
          } catch (_) {}
          throw Exception('$errorMessage (Status: 400)');
        case 401:
          throw Exception('Authentication required. Please log in. (Status: 401)');
        case 403:
          throw Exception('You do not have permission to update this order. (Status: 403)');
        case 404:
          throw Exception('Order not found. (Status: 404)');
        default:
          throw Exception('Failed to update order status. (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) print('Error updating order status: $e');
      throw Exception('An error occurred while updating the order status: $e');
    }
  }

  // Add this method to retry failed requests
  Future<T> _retryRequest<T>(Future<T> Function() requestFunction, {int maxAttempts = 3}) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        return await requestFunction();
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;
        
        if (kDebugMode) {
          print('Request failed (attempt $attempts): $e');
          print('Retrying in 2 seconds...');
        }
        
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Failed after $maxAttempts attempts');
  }
}


