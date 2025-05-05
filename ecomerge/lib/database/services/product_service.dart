import 'dart:convert';
import 'package:e_commerce_app/database/PageResponse.dart' show PageResponse;
import 'package:e_commerce_app/database/database_helper.dart'; // Import database_helper để lấy baseUrl và httpClient
import 'package:e_commerce_app/database/models/create_product_request_dto.dart'; // Import đúng
import 'package:e_commerce_app/database/models/product_dto.dart'; // Import đúng
import 'package:e_commerce_app/database/models/update_product_request_dto.dart'; // Import đúng
import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // Import UserInfo để lấy token
import 'package:http/http.dart' as http;
import 'dart:io'; // Import để bắt SocketException
import 'package:flutter/foundation.dart'; // Import kDebugMode

// Sử dụng baseUrl và httpClient từ database_helper.dart
// const String baseurl = 'YOUR_BASE_URL_HERE'; // Xóa hoặc chú thích dòng này
// final http.Client _httpClient = http.Client(); // Xóa hoặc chú thích dòng này


class ProductService {
  final String baseUrl = baseurl; // Lấy từ database_helper

  // Helper to get headers including Authorization token
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    // Lấy token từ UserInfo singleton
    final authToken = UserInfo().authToken; // Giả định authToken được lưu ở đây
    if (includeAuth && authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // === PRODUCT CRUD METHODS ===

  // Get Product By ID
  // Returns ProductDTO on success (200)
  // Throws Exception on API error or network error
  Future<ProductDTO> getProductById(int id) async {
    final url = Uri.parse('$baseUrl/api/products/$id');
    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: false), // Public API
      );

      if (kDebugMode) {
        print('Get Product By ID Request URL: $url');
        print('Get Product By ID Response Status: ${response.statusCode}');
        print('Get Product By ID Response Body: ${utf8.decode(response.bodyBytes)}');
      }

      if (response.statusCode == 200) {
        return ProductDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes))); // Parse and decode UTF-8
      } else {
        String errorMessage = 'Failed to fetch product details.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF-8
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception('Failed to fetch product: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('SocketException during get product by ID: $e');
      throw Exception('Network Error: Could not connect to server.');
    } catch (e) {
      if (kDebugMode) print('Unexpected Error during get product by ID: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Create Product
  // Returns ProductDTO on success (201)
  // Throws Exception on API error (non-201) or network error
  Future<ProductDTO> createProduct(CreateProductRequestDTO productRequest) async { // Đổi tên tham số
    final url = Uri.parse('$baseUrl/api/products/create');
    try {
      final response = await httpClient.post( // Sử dụng _httpClient instance
        url,
        headers: _getHeaders(includeAuth: true), // Cần token ADMIN
        body: jsonEncode(productRequest.toJson()), // Chuyển đổi DTO sang JSON
      );

      if (kDebugMode) {
         print('Create Product Request URL: $url');
         // In body, cẩn thận với dữ liệu nhạy cảm như mật khẩu (không có trong DTO này)
         // print('Create Product Request Body: ${jsonEncode(productRequest.toJson())}');
         print('Create Product Response Status: ${response.statusCode}');
         print('Create Product Response Body: ${response.body}');
      }


      if (response.statusCode == 201) {
        return ProductDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes))); // Parse và decode UTF-8
      } else {
        String errorMessage = 'Failed to create product.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF-8
          if (errorBody is Map && errorBody.containsKey('message')) {
             errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
             errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception('Failed to create product: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
       if (kDebugMode) print('SocketException during create product: $e');
       throw Exception('Network Error: Could not connect to server.');
    } catch (e) {
       if (kDebugMode) print('Unexpected Error during create product: $e');
       throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Update Product
  // Returns ProductDTO on success (200)
  // Throws Exception on API error (non-200) or network error
  Future<ProductDTO> updateProduct(int id, UpdateProductRequestDTO productRequest) async { // Đổi tên tham số
    final url = Uri.parse('$baseUrl/api/products/$id');
    try {
      final response = await httpClient.put( // Sử dụng _httpClient instance và phương thức PUT
        url,
        headers: _getHeaders(includeAuth: true), // Cần token ADMIN
        body: jsonEncode(productRequest.toJson()), // Chuyển đổi DTO sang JSON
      );

      if (kDebugMode) {
          print('Update Product Request URL: $url');
          // print('Update Product Request Body: ${jsonEncode(productRequest.toJson())}');
          print('Update Product Response Status: ${response.statusCode}');
          print('Update Product Response Body: ${utf8.decode(response.bodyBytes)}');
      }


      if (response.statusCode == 200) {
        return ProductDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes))); // Parse và decode UTF-8
      } else {
        String errorMessage = 'Failed to update product.';
         try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF-8
          if (errorBody is Map && errorBody.containsKey('message')) {
             errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
             errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception('Failed to update product: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
       if (kDebugMode) print('SocketException during update product: $e');
       throw Exception('Network Error: Could not connect to server.');
    } catch (e) {
       if (kDebugMode) print('Unexpected Error during update product: $e');
       throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Delete Product
  // Returns void on success (204)
  // Throws Exception on API error (non-204) or network error
  Future<void> deleteProduct(int id) async { // ID là int
      final url = Uri.parse('$baseUrl/api/products/$id');
      try {
          final response = await httpClient.delete( // Sử dụng _httpClient instance và phương thức DELETE
              url,
              headers: _getHeaders(includeAuth: true), // Cần token ADMIN
          );

          if (kDebugMode) {
              print('Delete Product Request URL: $url');
              print('Delete Product Response Status: ${response.statusCode}');
              print('Delete Product Response Body: ${utf8.decode(response.bodyBytes)}'); // Decode UTF-8
          }

          if (response.statusCode == 204) {
              // Thành công (No Content)
              return; // Return void
          } else {
              String errorMessage = 'Failed to delete product.';
               try {
                final errorBody = jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF-8
                if (errorBody is Map && errorBody.containsKey('message')) {
                   errorMessage = errorBody['message'];
                } else if (errorBody is String && errorBody.isNotEmpty) {
                   errorMessage = errorBody;
                }
              } catch (_) {}
              throw Exception('Failed to delete product: $errorMessage (Status: ${response.statusCode})');
          }
      } on SocketException catch (e) {
          if (kDebugMode) print('SocketException during delete product: $e');
          throw Exception('Network Error: Could not connect to server.');
      } catch (e) {
          if (kDebugMode) print('Unexpected Error during delete product: $e');
          throw Exception('An unexpected error occurred: ${e.toString()}');
      }
  }

  // Fetch Products (Basic implementation based on backend GET endpoint)
  // Returns List<ProductDTO> (for simplified list display without Page object)
  // Throws Exception on API error or network error
 Future<PageResponse<ProductDTO>> fetchProducts({
    String? search,
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String sortBy = 'createdDate',
    String sortDir = 'desc',
    int page = 0,
    int size = 10,
}) async {
    final Map<String, dynamic> queryParameters = {
        'page': page.toString(),
        'size': size.toString(),
        'sortBy': sortBy,
        'sortDir': sortDir,
    };
    if (search != null && search.isNotEmpty) queryParameters['search'] = search;
    if (categoryId != null) queryParameters['categoryId'] = categoryId.toString();
    if (brandId != null) queryParameters['brandId'] = brandId.toString();
    if (minPrice != null) queryParameters['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParameters['maxPrice'] = maxPrice.toString();
    if (minRating != null) queryParameters['minRating'] = minRating.toString();

    final url = Uri.parse('$baseUrl/api/products').replace(queryParameters: queryParameters);

    try {
        final response = await httpClient.get(
            url,
            headers: _getHeaders(includeAuth: true), // Cần token nếu API yêu cầu
        );

        if (kDebugMode) {
            print('Fetch Products Request URL: $url');
            print('Fetch Products Response Status: ${response.statusCode}');
        }

        switch (response.statusCode) {
            case 200:
                final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
                if (responseBody is Map<String, dynamic>) {
                    // Now, PageResponse.fromJson uses the CORRECT ProductDTO.fromJson
                    return PageResponse<ProductDTO>.fromJson(responseBody, ProductDTO.fromJson);
                } else {
                     throw Exception('Invalid response format from server: Expected a Map.');
                }

            case 204:
                // No Content
                return PageResponse.empty();

            case 400: // Bad Request
                String errorMessage = 'Bad Request';
                 try {
                    final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
                    if (errorBody is Map && errorBody.containsKey('message')) {
                       errorMessage = errorBody['message'];
                    } else if (errorBody is String && errorBody.isNotEmpty) {
                       errorMessage = errorBody;
                    }
                 } catch (_) {}
                 throw Exception('Failed to fetch products: $errorMessage (Status: ${response.statusCode})');

            default: // Other errors like 500
                String errorMessage = 'Failed to fetch products.';
                try {
                  final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
                  if (errorBody is Map && errorBody.containsKey('message')) {
                     errorMessage = errorBody['message'];
                  } else if (errorBody is String && errorBody.isNotEmpty) {
                     errorMessage = errorBody;
                  }
                } catch (_) {}
                throw Exception('Failed to fetch products: $errorMessage (Status: ${response.statusCode})');
        }
    } on SocketException catch (e) {
        if (kDebugMode) print('SocketException during fetch products: $e');
        throw Exception('Network Error: Could not connect to server. Please check your internet connection.');
    } on FormatException catch (e) {
         if (kDebugMode) print('FormatException during fetch products: $e');
         throw Exception('Server response format error. Could not parse data.');
    } catch (e) {
        if (kDebugMode) print('Unexpected Error during fetch products: $e');
        throw Exception('An unexpected error occurred: ${e.toString()}');
    }
}


  void dispose() {
    httpClient.close();
  }
}
