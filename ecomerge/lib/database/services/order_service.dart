import 'dart:async';
import 'dart:convert';
import 'dart:io'; // For SocketException and HttpClient
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/database_helper.dart'; // For baseurl
import 'package:e_commerce_app/database/models/order/CreateOrderRequestDTO.dart';
import 'package:e_commerce_app/database/models/order/OrderDTO.dart'; // Imports OrderStatus, OrderStatusHistoryDTO, OrderPage
import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // For auth token
import 'package:flutter/foundation.dart'; // For kDebugMode, kIsWeb
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // For IOClient
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

  enum PaymentStatus {
        chua_thanh_toan, da_thanh_toan, loi_thanh_toan
    }

     enum OrderStatus {
        cho_xu_ly, da_xac_nhan, dang_giao, da_giao, da_huy
    }
class OrderService {
  final String _baseUrl = baseurl;
  late final http.Client httpClient;

  // Add connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool _wasOffline = false; // Track if we were offline before
  
  // Add static property to track network restoration status
  static bool _networkJustRestored = false;
  static bool get networkJustRestored => _networkJustRestored;

  // Add variables to track the last order query parameters
  static OrderStatus? _lastOrderStatus;
  static int _lastPage = 0;
  static int _lastSize = 10;
  static String _lastSort = 'orderDate,desc';

  OrderService() {
    httpClient = _createSecureClient();
    _initConnectivityMonitoring();
  }

  http.Client _createSecureClient() {
    if (kIsWeb) {
      return http.Client();
    } else {
      final HttpClient ioClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true); // Accept all certificates in all modes, not just debug
      return IOClient(ioClient);
    }
  }
  // static final Map<String, Uint8List> _imageCache = {};

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
    // Save the current query parameters for potential network restoration
    _lastOrderStatus = status;
    _lastPage = page;
    _lastSize = size;
    _lastSort = sort;
    
    // Refresh connectivity status
    await _checkConnectivity();
    
    // If we just came back online, always fetch fresh data from server
    if (_wasOffline && _isOnline) {
      _wasOffline = false; // Reset the flag
      
      if (kDebugMode) {
        print('OrderService: Network just restored - fetching fresh data from server');
      }
      
      // When network is restored, prioritize fetching from server before touching cache
      try {
        // Make API call without clearing cache first - so we still have local data as fallback
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
          print('Network restored - Get Current User Orders Request URL: $url');
        }
        
        final response = await httpClient.get(
          url,
          headers: _getHeaders(includeAuth: true),
        );
        
        if (response.statusCode == 200) {
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
            final orderPage = OrderPage.fromJson(responseBody);
            
            if (kDebugMode) {
              print('OrderService: Successfully fetched fresh data, now clearing cache and saving new data');
            }
            
            // First clear the cache, then save the new data
            await clearLocalOrderCache();
            await saveOrdersToLocalStorage(orderPage, status: status, page: page, size: size, sort: sort);
            
            // Mark as online data
            orderPage.isOfflineData = false;
            _networkJustRestored = false; // Reset the flag after successful data fetch
            
            if (kDebugMode) {
              print('OrderService: Successfully refreshed and saved ${orderPage.orders.length} orders to local storage');
            }
            
            return orderPage;
          }
        }
        
        // If we reach here, the API call wasn't successful, continue with normal flow
        // which will try to use existing cache
      } catch (e) {
        if (kDebugMode) {
          print('OrderService: Error fetching fresh data after network restoration: $e');
          print('OrderService: Will try normal flow with existing cache');
        }
        // Don't clear cache if fetch failed - we'll need it
      }
    }
    
    if (_isOnline) {
      // Online mode - proceed with API call
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
          print('Get Current User Orders Response Status: ${response.statusCode}');
          if (response.bodyBytes.isNotEmpty) {
            try {
              print('Get Current User Orders Response Body: ${utf8.decode(response.bodyBytes)}');
            } catch (e) {
              print('Error decoding response body: $e');
            }
          }
        }

        OrderPage orderPage;
        switch (response.statusCode) {
          case 200:
            final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
            if (responseBody is Map<String, dynamic>) {
              orderPage = OrderPage.fromJson(responseBody);
              
              // Save to local storage for offline access
              await saveOrdersToLocalStorage(orderPage, status: status, page: page, size: size, sort: sort);
              
              // Mark as online data
              orderPage.isOfflineData = false;
              return orderPage;
            } else {
              throw FormatException('Invalid response format for user orders: Expected a JSON object, got ${responseBody.runtimeType}.');
            }
          case 204: // No content
            orderPage = OrderPage(
              orders: [],
              totalPages: 0,
              totalElements: 0,
              currentPage: 0,
              pageSize: size,
              isLast: true,
              isFirst: true
            );
            
            // Save empty result to local storage too
            await saveOrdersToLocalStorage(orderPage, status: status, page: page, size: size, sort: sort);
            
            // Mark as online data
            orderPage.isOfflineData = false;
            return orderPage;
          case 401:
            throw Exception('User not authenticated. Please log in. (Status: 401)');
          case 500:
            throw Exception('An unexpected error occurred while fetching orders. (Status: 500)');
          default:
            throw Exception('Failed to fetch user orders. (Status: ${response.statusCode})');
        }
      } on SocketException catch (e) {
        if (kDebugMode) print('SocketException during getCurrentUserOrders: $e');
        
        // Try to load from local storage as fallback if API call fails due to network issues
        final localOrders = await loadOrdersFromLocalStorage(
          status: status, page: page, size: size, sort: sort
        );
        
        if (localOrders != null) {
          if (kDebugMode) {
            print('Network issue, using locally cached order data');
          }
          return localOrders;
        }
        
        // If no local cache either, rethrow the original error
        throw Exception('Network Error: Could not connect to server.');
      } on FormatException catch (e) {
        if (kDebugMode) print('FormatException during getCurrentUserOrders: $e');
        throw Exception('Server response format error for user orders.');
      } catch (e) {
        if (kDebugMode)
          print('Unexpected Error during getCurrentUserOrders: ${e.toString()}');
        
        // Try local cache as fallback for any other errors
        final localOrders = await loadOrdersFromLocalStorage(
          status: status, page: page, size: size, sort: sort
        );
        
        if (localOrders != null) {
          if (kDebugMode) {
            print('Error fetching from server, using locally cached order data');
          }
          return localOrders;
        }
        
        throw Exception('An unexpected error occurred: ${e.toString()}');
      }
    } else {
      // Offline mode - try to load from local storage
      if (kDebugMode) {
        print('Device is offline, loading orders from local storage');
      }
      
      final localOrders = await loadOrdersFromLocalStorage(
        status: status, page: page, size: size, sort: sort
      );
      
      if (localOrders != null) {
        return localOrders;
      }
      
      // If no cached data found
      throw Exception('No internet connection and no cached order data available');
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
      // Always set start time to 00:00:00 with explicit timezone (Z = UTC)
      final startOfDay = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      queryParams['startDate'] = _formatDateTimeWithTimezone(startOfDay);
    }
    if (endDate != null) {
      // Always set end time to 23:59:59 with explicit timezone (Z = UTC)
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      queryParams['endDate'] = _formatDateTimeWithTimezone(endOfDay);
    }

    // Updated URL path to match Java @GetMapping("/admin/search") endpoint
    final url = Uri.parse('$_baseUrl/api/orders/admin/search')
        .replace(queryParameters: queryParams);
    print("URL: $url");
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
    // if (!forceReload) {
    //   // First check our product-specific image cache
    //   if (_imageCache.containsKey(imagePath)) {
    //     if (kDebugMode) print('Using cached image for $imagePath');
    //     return _imageCache[imagePath];
    //   }
      
    //   // Then check UserInfo avatar cache (existing implementation)
    //   if (UserInfo.avatarCache.containsKey(imagePath)) {
    //     if (kDebugMode) print('Using UserInfo cached image for $imagePath');
    //     return UserInfo.avatarCache[imagePath];
    //   }
    // }

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
        
        // // Cache the image unless we're forcing reload
        // if (!forceReload) {
        //   // Cache in both places for maximum compatibility
        //   _imageCache[imagePath] = response.bodyBytes;
        //   UserInfo.avatarCache[imagePath] = response.bodyBytes;
        // }
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
  // bool isImageCached(String? imagePath) {
  //   if (imagePath == null || imagePath.isEmpty) return false;
  //   return _imageCache.containsKey(imagePath) || UserInfo.avatarCache.containsKey(imagePath);
  // }
  
  // New method to get image directly from cache without network request
  // Uint8List? getImageFromCache(String? imagePath) {
  //   if (imagePath == null || imagePath.isEmpty) return null;
    
  //   // Check product cache first
  //   if (_imageCache.containsKey(imagePath)) {
  //     return _imageCache[imagePath];
  //   }
    
  //   // Then check avatar cache
  //   if (UserInfo.avatarCache.containsKey(imagePath)) {
  //     return UserInfo.avatarCache[imagePath];
  //   }
    
  //   return null; // Not found in any cache
  // }
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

  // Check if device is currently online
  Future<bool> isOnline() async {
    await _checkConnectivity();
    return _isOnline;
  }
  
  // Save orders to local storage
  Future<void> saveOrdersToLocalStorage(OrderPage orderPage, {OrderStatus? status, int page = 0, int size = 10, String sort = 'orderDate,desc'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create a key that includes the query parameters
      final String storageKey = _createOrderStorageKey(status, page, size, sort);
      
      // Convert OrderPage to JSON and save
      final Map<String, dynamic> orderPageJson = {
        'orders': orderPage.orders.map((order) => _convertOrderToJson(order)).toList(),
        'totalPages': orderPage.totalPages,
        'totalElements': orderPage.totalElements,
        'currentPage': orderPage.currentPage,
        'pageSize': orderPage.pageSize,
        'isLast': orderPage.isLast,
        'isFirst': orderPage.isFirst,
      };
      
      await prefs.setString(storageKey, jsonEncode(orderPageJson));
      
      // Save timestamp
      await prefs.setInt('${storageKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('Saved orders to local storage with key: $storageKey');
      }
      
      // Also save order images
      await _saveOrderImagesToLocalStorage(orderPage.orders);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving orders to local storage: $e');
      }
    }
  }
  
  // Helper method to convert OrderDTO to JSON (avoiding toJson() dependency)
  Map<String, dynamic> _convertOrderToJson(OrderDTO order) {
    return {
      'id': order.id,
      'orderDate': order.orderDate?.toIso8601String(),
      'updatedDate': order.updatedDate?.toIso8601String(),
      'recipientName': order.recipientName,
      'recipientPhoneNumber': order.recipientPhoneNumber,
      'shippingAddress': order.shippingAddress,
      'subtotal': order.subtotal,
      'couponDiscount': order.couponDiscount,
      'pointsDiscount': order.pointsDiscount,
      'shippingFee': order.shippingFee,
      'tax': order.tax,
      'totalAmount': order.totalAmount,
      'paymentMethod': order.paymentMethod,
      'paymentStatus': order.paymentStatus,
      'orderStatus': order.orderStatus != null ? orderStatusToString(order.orderStatus!) : null,
      'pointsEarned': order.pointsEarned,
      'couponCode': order.couponCode,
      'orderDetails': order.orderDetails?.map((detail) => {
        'productVariantId': detail.productVariantId,
        'productName': detail.productName,
        'variantName': detail.variantName,
        'imageUrl': detail.imageUrl,
        'quantity': detail.quantity,
        'priceAtPurchase': detail.priceAtPurchase,
        'productDiscountPercentage': detail.productDiscountPercentage,
        'lineTotal': detail.lineTotal,
      }).toList(),
    };
  }
  
  // Load orders from local storage
  Future<OrderPage?> loadOrdersFromLocalStorage({OrderStatus? status, int page = 0, int size = 10, String sort = 'orderDate,desc'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create the same key used for saving
      final String storageKey = _createOrderStorageKey(status, page, size, sort);
      
      // Get the saved JSON
      final String? orderPageJson = prefs.getString(storageKey);
      
      if (orderPageJson == null) {
        if (kDebugMode) {
          print('No orders found in local storage for key: $storageKey');
        }
        return null;
      }
      
      // Parse the JSON
      final Map<String, dynamic> orderPageMap = jsonDecode(orderPageJson);
      
      // Reconstruct OrderPage
      final List<dynamic> ordersJson = orderPageMap['orders'] ?? [];
      final List<OrderDTO> orders = ordersJson.map((orderJson) {
        return OrderDTO(
          id: orderJson['id'],
          orderDate: orderJson['orderDate'] != null ? DateTime.tryParse(orderJson['orderDate']) : null,
          updatedDate: orderJson['updatedDate'] != null ? DateTime.tryParse(orderJson['updatedDate']) : null,
          recipientName: orderJson['recipientName'],
          recipientPhoneNumber: orderJson['recipientPhoneNumber'],
          shippingAddress: orderJson['shippingAddress'],
          subtotal: orderJson['subtotal']?.toDouble(),
          couponDiscount: orderJson['couponDiscount']?.toDouble(),
          pointsDiscount: orderJson['pointsDiscount']?.toDouble(),
          shippingFee: orderJson['shippingFee']?.toDouble(),
          tax: orderJson['tax']?.toDouble(),
          totalAmount: orderJson['totalAmount']?.toDouble(),
          paymentMethod: orderJson['paymentMethod'],
          paymentStatus: orderJson['paymentStatus'],
          orderStatus: orderStatusFromString(orderJson['orderStatus']),
          pointsEarned: orderJson['pointsEarned'],
          couponCode: orderJson['couponCode'],
          orderDetails: orderJson['orderDetails'] != null 
            ? List<OrderDetailItemDTO>.from(orderJson['orderDetails'].map((detail) => 
                OrderDetailItemDTO(
                  productVariantId: detail['productVariantId'], 
                  productName: detail['productName'],
                  variantName: detail['variantName'],
                  imageUrl: detail['imageUrl'],
                  quantity: detail['quantity'],
                  priceAtPurchase: detail['priceAtPurchase']?.toDouble(),
                  productDiscountPercentage: detail['productDiscountPercentage']?.toDouble(),
                  lineTotal: detail['lineTotal']?.toDouble(),
                )
              ))
            : null,
        );
      }).toList();
      
      final orderPage = OrderPage(
        orders: orders,
        totalPages: orderPageMap['totalPages'] ?? 0,
        totalElements: orderPageMap['totalElements'] ?? 0,
        currentPage: orderPageMap['currentPage'] ?? 0,
        pageSize: orderPageMap['pageSize'] ?? size,
        isLast: orderPageMap['isLast'] ?? true,
        isFirst: orderPageMap['isFirst'] ?? true,
      );
      
      if (kDebugMode) {
        print('Loaded ${orderPage.orders.length} orders from local storage');
      }
      
      return orderPage;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading orders from local storage: $e');
      }
      return null;
    }
  }
  
  // Create a consistent key for storing order data
  String _createOrderStorageKey(OrderStatus? status, int page, int size, String sort) {
    String key = 'orders_page${page}_size${size}_sort${sort}';
    if (status != null) {
      key += '_status${orderStatusToString(status)}';
    }
    return key;
  }
  
  // Save order images to local storage
  Future<void> _saveOrderImagesToLocalStorage(List<OrderDTO> orders) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/order_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Extract all image URLs from orders
      final List<String> imageUrls = [];
      for (var order in orders) {
        if (order.orderDetails != null) {
          for (var detail in order.orderDetails!) {
            if (detail.imageUrl != null && detail.imageUrl!.isNotEmpty) {
              imageUrls.add(detail.imageUrl!);
            }
          }
        }
      }
      
      // Save images
      for (var imageUrl in imageUrls) {
        try {
          final imageData = await getImageFromServer(imageUrl);
          if (imageData != null) {
            final fileName = _getImageFileName(imageUrl);
            final file = File('${imagesDir.path}/$fileName');
            await file.writeAsBytes(imageData);
            
            if (kDebugMode) {
              print('Saved order image to local storage: $fileName');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error saving image $imageUrl: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving order images: $e');
      }
    }
  }
  
  // Helper method to create a consistent filename for an image
  String _getImageFileName(String imagePath) {
    final bytes = utf8.encode(imagePath);
    final digest = sha256.convert(bytes);
    return digest.toString() + '.png';
  }

  // Method to fetch image from server
  // Future<Uint8List?> getImageFromServer(String imagePath) async {
  //   try {
  //     final String fullUrl = _getImageUrl(imagePath);
  //     final response = await _httpClient.get(Uri.parse(fullUrl));
      
  //     if (response.statusCode == 200) {
  //       return response.bodyBytes;
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error fetching image from server: $e');
  //     }
  //   }
  //   return null;
  // }
  
  // Helper method to get the full URL for an image
  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    String path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return _baseUrl + path;
  }
  
  // Load image from local storage
  Future<Uint8List?> loadImageFromLocalStorage(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/order_images');
      final fileName = _getImageFileName(imagePath);
      final file = File('${imagesDir.path}/$fileName');
      
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (kDebugMode) {
          print('Loaded order image from local storage: $fileName');
        }
        return bytes;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading image from local storage: $e');
      }
    }
    return null;
  }

  // Initialize connectivity monitoring
  void _initConnectivityMonitoring() {
    // Check initial connectivity
    _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final bool wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (kDebugMode) {
        print('OrderService: Connectivity changed to: ${result.toString()}');
        print('OrderService: Is online: $_isOnline');
      }
      
      // If we just came back online after being offline, trigger data refresh
      if (wasOffline && _isOnline) {
        _wasOffline = true; // Mark that we were offline and just came back online
        _networkJustRestored = true; // Set the static flag
        
        if (kDebugMode) {
          print('OrderService: Network restored - auto-refreshing order data');
        }
        
        // Don't clear the cache here - let getCurrentUserOrders handle it
        // Instead, just trigger the refresh
        _refreshOrderDataAfterNetworkRestoration();
        
        // Reset the networkJustRestored flag after a delay
        Future.delayed(const Duration(seconds: 10), () {
          _networkJustRestored = false;
        });
      }
    });
  }
  
  // Check current connectivity status
Future<void> _checkConnectivity() async {
  try {
    final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    print("ConnectivityResult: $connectivityResult");
    if(kIsWeb){
      _isOnline = true;
    }
    if (connectivityResult == ConnectivityResult.none) {
      print("Không có kết nối mạng cục bộ (Wi-Fi/Mobile Data).");
      _isOnline = false;
      return;
    }

    if(!kIsWeb){
    // Try a simple connectivity test that works in all build modes
    bool hasInternetAccess = false;
    try {
      // Try a simple HTTP request to a reliable server
      final response = await httpClient.get(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );
      hasInternetAccess = response.statusCode == 200;
    } catch (e) {
      print("Lỗi kiểm tra kết nối internet: $e");
      hasInternetAccess = false;
    }

    _isOnline = hasInternetAccess;
    print(_isOnline ? "Đã kết nối internet." : "Không có kết nối internet.");
    }
  } catch (e) {
    print("Lỗi tổng thể khi kiểm tra kết nối: $e");
    _isOnline = false;
  }
  
}

  // Clear local orders cache when network is restored or on demand
  Future<void> clearLocalOrderCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final orderKeys = allKeys.where((key) => key.startsWith('orders_')).toList();
      
      // Delete all order-related keys
      for (var key in orderKeys) {
        await prefs.remove(key);
        // Also remove timestamp key
        await prefs.remove('${key}_timestamp');
      }
      
      // Clear image cache as well
      await _clearOrderImagesCache();
      
      if (kDebugMode) {
        print('OrderService: Cleared local order cache: ${orderKeys.length} entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('OrderService: Error clearing local order cache: $e');
      }
    }
  }
  
  // Clear the order images cache
  Future<void> _clearOrderImagesCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/order_images');
      
      if (await imagesDir.exists()) {
        // Delete and recreate directory
        await imagesDir.delete(recursive: true);
        await imagesDir.create(recursive: true);
        
        if (kDebugMode) {
          print('OrderService: Cleared order images cache directory');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('OrderService: Error clearing order images cache: $e');
      }
    }
  }

  // Add a method to fetch fresh data after network restoration
  Future<void> _refreshOrderDataAfterNetworkRestoration() async {
    try {
      if (kDebugMode) {
        print('OrderService: Auto-refreshing order data with last parameters:');
        print('Status: $_lastOrderStatus, Page: $_lastPage, Size: $_lastSize, Sort: $_lastSort');
      }
      
      // Request fresh data using last known parameters
      final orderPage = await getCurrentUserOrders(
        status: _lastOrderStatus,
        page: _lastPage,
        size: _lastSize,
        sort: _lastSort,
      );
      
      if (kDebugMode) {
        print('OrderService: Successfully refreshed ${orderPage.orders.length} orders from server after network restoration');
      }
      
      // getCurrentUserOrders already handles saving to local storage
      
    } catch (e) {
      if (kDebugMode) {
        print('OrderService: Error refreshing order data after network restoration: $e');
      }
    }
  }
}

// Add isOfflineData property to OrderPage class if not already added
extension OrderPageExtension on OrderPage {
  static final Map<OrderPage, bool> _offlineFlags = {};
  
  bool get isOfflineData => _offlineFlags[this] ?? false;
  
  set isOfflineData(bool value) {
    _offlineFlags[this] = value;
  }
}

  // Add the new method to format DateTime with time components
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}T${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

// Format DateTime with explicit UTC timezone indicator (Z)
  String _formatDateTimeWithTimezone(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}T${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}Z';
  }


