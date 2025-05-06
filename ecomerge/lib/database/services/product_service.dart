import 'dart:convert';
import 'package:e_commerce_app/database/PageResponse.dart' show PageResponse;
import 'package:e_commerce_app/database/PageResponsive.dart';
import 'package:e_commerce_app/database/database_helper.dart'; // Import database_helper để lấy baseUrl và httpClient
import 'package:e_commerce_app/database/models/brand.dart';
import 'package:e_commerce_app/database/models/categories.dart';
import 'package:e_commerce_app/database/models/create_product_request_dto.dart'; // Import đúng
import 'package:e_commerce_app/database/models/product_dto.dart'; // Import đúng
import 'package:e_commerce_app/database/models/update_product_request_dto.dart'; // Import đúng
import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // Import UserInfo để lấy token
import 'package:http/http.dart' as http;
import 'dart:io'; 
import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart'; 




class ProductService {
  final String baseUrl = baseurl; // Lấy từ database_helper
  late  final http.Client httpClient;
  ProductService(){
     httpClient = _createSecureClient();
  }
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
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    final authToken = UserInfo().authToken; 
    if (includeAuth && authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }


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
      print('Create Product Request URL: $response');
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
 Future<String?> uploadImage(List<int> imageBytes, String fileName) async {
    final url = Uri.parse('$baseUrl/api/images/upload');
    print(
        "Starting image upload, bytes: ${imageBytes.length}, filename: $fileName");

    try {
      // Create a multipart request
      final request = http.MultipartRequest('POST', url);

      // Add authorization header if user is logged in
      if (UserInfo().authToken != null) {
        request.headers['Authorization'] = 'Bearer ${UserInfo().authToken}';
      }

      // Add file to the request
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Important fix: Instead of using request.send(), which uses the default client,
      // we'll manually send the request using our SSL-bypassing client
      final stream = await request.finalize();

      // Create a custom request with the same method, url, headers
      final httpRequest = http.Request(request.method, request.url);
      httpRequest.headers.addAll(request.headers);
      httpRequest.bodyBytes = await stream.toBytes();

      // Send the request using our secure client
      final streamedResponse = await httpClient.send(httpRequest);

      // Convert the response stream to a regular response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Parse the response to get the image path
        final responseData = jsonDecode(response.body);
        final imagePath = responseData['imagePath'];
        print('Image uploaded successfully: $imagePath');
        return imagePath;
      } else {
        print('Failed to upload image: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Method to upload image from file path (for mobile platforms)
  Future<String?> uploadImageFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;
      return uploadImage(bytes, fileName);
    } catch (e) {
      print('Error reading image file: $e');
      return null;
    }
  }

  // Method to get cached avatar or fetch if not available
  Future<Uint8List?> getImageFromServer(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) return null;

    if (UserInfo.avatarCache.containsKey(avatarPath)) {
      return UserInfo.avatarCache[avatarPath];
    }

    try {
      String fullUrl = getImageUrl(avatarPath);
      final response = await httpClient.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        UserInfo.avatarCache[avatarPath] = response.bodyBytes;
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching avatar: $e');
    }

    return null;
  }
  // Helper method to get the complete image URL
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
          print(response.body);
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
 Future<PageResponse<CategoryDTO>> fetchCategoriesPaginated({
     int page = 0,
     int size = 10, // Giữ default size theo server nếu muốn
     // Tham số truyền vào vẫn là property và direction riêng
     String sortBy = 'createdDate', // Default sort property
     String sortDir = 'desc',     // Default sort direction
     DateTime? startDate,
     DateTime? endDate,
  }) async {
     final Map<String, dynamic> queryParameters = {
        'page': page.toString(),
        'size': size.toString(),
        // *** SỬA CÁCH GỬI THAM SỐ SORT TẠI ĐÂY ***
        // Kết hợp property và direction thành một tham số 'sort' duy nhất
        // Đây là cách client override default sort của server
        'sort': '$sortBy,$sortDir',
    };
     // Add date parameters if provided, formatted as YYYY-MM-DD strings
     // (Giữ nguyên logic này nếu server vẫn mong đợi)
     if (startDate != null) queryParameters['startDate'] = startDate.toIso8601String().split('T')[0];
     if (endDate != null) queryParameters['endDate'] = endDate.toIso8601String().split('T')[0];


    final url = Uri.parse('$baseUrl/api/categories').replace(queryParameters: queryParameters);
    if (kDebugMode) print('Fetch Categories (Paginated) Request URL: $url'); // Print URL với tham số sort

    try {
      // Sử dụng _httpClient instance
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: false),
      );

      if (kDebugMode) {
        print('Fetch Categories (Paginated) Response Status: ${response.statusCode}');
         if (response.bodyBytes.isNotEmpty) {
           print('Fetch Categories (Paginated) Response Body: ${utf8.decode(response.bodyBytes)}');
         } else {
            print('Fetch Categories (Paginated) Response Body: (Empty or 204)');
         }
      }

      switch (response.statusCode) {
        case 200:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
             // *** SỬA TYPO PageResponsive -> PageResponse ***
             return PageResponse<CategoryDTO>.fromJson(responseBody, CategoryDTO.fromJson);
          } else {
             throw FormatException('Invalid response format for categories: Expected a JSON object (PageResponse), got ${responseBody.runtimeType}.');
          }

        case 204:
          // *** SỬA TYPO PageResponsive -> PageResponse ***
          return PageResponse.empty();

        default:
          // Xử lý lỗi chung
          String errorMessage = 'Failed to fetch categories.';
           try {
             final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
             if (errorBody is Map && errorBody.containsKey('message')) {
                errorMessage = errorBody['message'];
             } else if (errorBody is String && errorBody.isNotEmpty) {
                errorMessage = errorBody;
             }
           } catch (_) {}
          throw Exception('Failed to fetch categories: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
       if (kDebugMode) print('SocketException during fetchCategoriesPaginated: $e');
       throw Exception('Network Error: Could not connect to server. Please check your internet connection.');
    } on FormatException catch (e) {
       if (kDebugMode) print('FormatException during fetchCategoriesPaginated: $e');
       throw Exception('Server response format error. Could not parse category page data.');
    } catch (e) {
      if (kDebugMode) print('Unexpected Error during fetchCategoriesPaginated: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // ... (getAllBrands và dispose methods giữ nguyên)
   // Giữ nguyên hàm getAllBrands nếu endpoint brands vẫn trả về List
   Future<List<BrandDTO>> getAllBrands() async {
      // ... (keep the existing implementation for getAllBrands)
       final url = Uri.parse('$baseUrl/api/brands');
       if (kDebugMode) print('Get All Brands Request URL: $url');

       try {
         final response = await httpClient.get(
           url,
           headers: _getHeaders(includeAuth: false),
         );

         if (kDebugMode) {
           print('Get All Brands Response Status: ${response.statusCode}');
            if (response.bodyBytes.isNotEmpty) {
              print('Get All Brands Response Body: ${utf8.decode(response.bodyBytes)}');
            } else {
               print('Get All Brands Response Body: (Empty or 204)');
            }
         }

         switch (response.statusCode) {
           case 200:
             final responseBody = utf8.decode(response.bodyBytes);
             final List<dynamic> jsonList = jsonDecode(responseBody);
             final List<BrandDTO> brands = jsonList
                 .map((jsonItem) => BrandDTO.fromJson(jsonItem as Map<String, dynamic>))
                 .toList();
             return brands;

           case 204:
             return [];

           default:
             String errorMessage = 'Failed to fetch brands.';
             try {
               final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
               if (errorBody is Map && errorBody.containsKey('message')) {
                  errorMessage = errorBody['message'];
               } else if (errorBody is String && errorBody.isNotEmpty) {
                  errorMessage = errorBody;
               }
             } catch (_) {}
             throw Exception('Failed to fetch brands: $errorMessage (Status: ${response.statusCode})');
         }
       } on SocketException catch (e) {
          if (kDebugMode) print('SocketException during getAllBrands: $e');
          throw Exception('Network Error: Could not connect to server. Please check your internet connection.');
       } on FormatException catch (e) {
          if (kDebugMode) print('FormatException during getAllBrands: $e');
          throw Exception('Server response format error. Could not parse brand data.');
       } catch (e) {
         if (kDebugMode) print('Unexpected Error during getAllBrands: ${e.toString()}');
         throw Exception('An unexpected error occurred: ${e.toString()}');
       }
    }
  void dispose() {
    httpClient.close();
  }
}
