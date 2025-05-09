import 'dart:io';
import 'dart:convert';

import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/database_helper.dart';
import 'package:e_commerce_app/database/models/CartDTO.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class CartService {
  final String baseUrl = baseurl;
  late final http.Client httpClient;
  
  // Image cache map
  final Map<String, Uint8List> _imgCache = {};

  // Constructor - setup SSL-bypassing client for all platforms
  CartService() {
    httpClient = _createSecureClient();
  }

  // Create a client that bypasses SSL certificate verification
  http.Client _createSecureClient() {
    if (kIsWeb) {
      // Web platform doesn't need special handling
      return http.Client();
    } else {
      // For mobile and desktop platforms
      final HttpClient ioClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      return IOClient(ioClient);
    }
  }

  // Get auth headers
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
      final authToken = UserInfo().authToken;
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
    }

    return headers;
  }
  
  // Get cart items
  Future<List<CartItemDTO>> getCart() async {
    final url = Uri.parse('$baseUrl/api/cart');
    
    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => CartItemDTO.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access. Please login again.');
      } else {
        throw Exception('Failed to load cart items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load cart items: $e');
    }
  }
  
  // Add item to cart
  Future<CartItemDTO> addToCart(int productVariantId, int quantity) async {
    final url = Uri.parse('$baseUrl/api/cart');
    
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'productVariantId': productVariantId,
          'quantity': quantity,
        }),
      );
      
      if (response.statusCode == 200) {
        return CartItemDTO.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        throw Exception('Invalid request: ${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access. Please login again.');
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }
  
  // Update cart item
  Future<CartItemDTO> updateCartItem(int cartItemId, int quantity) async {
    final url = Uri.parse('$baseUrl/api/cart/$cartItemId');
    
    try {
      final response = await httpClient.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'quantity': quantity,
        }),
      );
      
      if (response.statusCode == 200) {
        return CartItemDTO.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        throw Exception('Invalid request: ${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access. Please login again.');
      } else {
        throw Exception('Failed to update cart item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }
  
  // Remove item from cart
  Future<void> removeFromCart(int cartItemId) async {
    final url = Uri.parse('$baseUrl/api/cart/$cartItemId');
    
    try {
      final response = await httpClient.delete(
        url,
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 204) {
        return; // Success, no content
      } else if (response.statusCode == 400) {
        throw Exception('Invalid request: ${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access. Please login again.');
      } else {
        throw Exception('Failed to remove from cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }
  
  Future<Uint8List?> getImageFromServer(String? imagePath, {bool forceReload = false}) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    // Check cache only if not forcing reload
    if (!forceReload) {
      // First check our product-specific image cache
      if (_imgCache.containsKey(imagePath)) {
        if (kDebugMode) print('Using cached image for $imagePath');
        return _imgCache[imagePath];
      }
      
      // Then check UserInfo avatar cache (existing implementation)
      if (UserInfo.avatarCache.containsKey(imagePath)) {
        return UserInfo.avatarCache[imagePath];
      }
    }

    try {
      String fullUrl = getImageUrl(imagePath);
      // Add cache-busting parameter for forceReload
      if (forceReload) {
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        fullUrl += '?cacheBust=$cacheBuster';
      }
      
      final response = await httpClient.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        // Cache the image unless we're forcing reload
        if (!forceReload) {
          // Cache in both places for maximum compatibility
          _imgCache[imagePath] = response.bodyBytes;
          UserInfo.avatarCache[imagePath] = response.bodyBytes;
        }
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching image: $e');
    }

    return null;
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
    return '$baseUrl$path';
  }

  // Clear the image cache
  void clearImageCache() {
    _imgCache.clear();
  }
}
