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
import 'package:e_commerce_app/database/models/create_product_review_request_dto.dart'; // Added import
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path_provider/path_provider.dart'; // For file access
import 'package:connectivity_plus/connectivity_plus.dart'; // For connectivity checking
import 'package:crypto/crypto.dart'; // For creating image filename hashes
import 'package:e_commerce_app/services/shared_preferences_service.dart'; // Added for SharedPreferences

class ProductService {
  final String baseUrl = baseurl; // Lấy từ database_helper
  late final http.Client httpClient;
  ProductService() {
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

  // Ad a static cache for product images
  static final Map<String, Uint8List> _imageCache = {};

  // Updated static variable to track network status
  static bool _isNetworkRestored = false;

  // Check if device is currently online
  // Future<bool> isOnline() async {
  //   try {
  //     var connectivityResult = await Connectivity().checkConnectivity();
  //     return connectivityResult != ConnectivityResult.none;
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error checking connectivity: $e');
  //     }
  //     // Default to assuming online if we can't check
  //     return true;
  //   }
  // }
  Future<bool> isOnline() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    print("ConnectivityResult: $result"); // In ra để debug

    if (result == ConnectivityResult.none) {
      print("Không có kết nối mạng (ConnectivityResult.none)");
      return false;
    }

    final InternetConnectionChecker customChecker =
        InternetConnectionChecker.createInstance(
      checkTimeout: const Duration(milliseconds: 1000),
    );

    print(
        "Đang kiểm tra kết nối internet thực sự (timeout mỗi địa chỉ ~1 giây)...");
    final bool isConnected = await customChecker.hasConnection;

    if (isConnected) {
      print("Đã kết nối mạng (InternetConnectionChecker)");
    } else {
      print(
          "Mất kết nối mạng (InternetConnectionChecker) hoặc kiểm tra timeout");
    }
    return isConnected;
  }

  // Get path to save images locally
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    // Create a specific directory for product images if it doesn't exist
    final imageDir = Directory('${directory.path}/product_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    return imageDir.path;
  }

  // Get a filename for a given image path using hash for consistency
  String _getImageFileName(String imagePath) {
    // Create a hash of the image path to use as filename
    var bytes = utf8.encode(imagePath);
    var digest = sha256.convert(bytes);
    return digest.toString() +
        '.png'; // Always use .png extension for consistency
  }

  // Save image to local storage
  Future<void> _saveImageToLocalStorage(
      String imagePath, Uint8List imageBytes) async {
    try {
      // Use SharedPreferencesService to save image data on non-web platforms
      if (!kIsWeb) {
        final prefsService = await SharedPreferencesService.getInstance();
        await prefsService.saveImageData(imagePath, imageBytes);
        if (kDebugMode) {
          print(
              'Saved image to SharedPreferences via ProductService: $imagePath');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving image to local storage in ProductService: $e');
      }
    }
  }

  // Load image from local storage
  Future<Uint8List?> _loadImageFromLocalStorage(String imagePath) async {
    try {
      // Use SharedPreferencesService to load image data on non-web platforms
      if (!kIsWeb) {
        final prefsService = await SharedPreferencesService.getInstance();
        final imageData = prefsService.getImageData(imagePath);
        if (imageData != null) {
          if (kDebugMode) {
            print(
                'Loaded image from SharedPreferences via ProductService: $imagePath');
          }
          return imageData;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading image from local storage in ProductService: $e');
      }
    }

    return null;
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
        print(
            'Get Product By ID Response Body: ${utf8.decode(response.bodyBytes)}');
      }

      if (response.statusCode == 200) {
        return ProductDTO.fromJson(jsonDecode(
            utf8.decode(response.bodyBytes))); // Parse and decode UTF-8
      } else {
        String errorMessage = 'Failed to fetch product details.';
        try {
          final errorBody =
              jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF-8
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception(
            'Failed to fetch product: $errorMessage (Status: ${response.statusCode})');
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
  Future<ProductDTO> createProduct(
      CreateProductRequestDTO productRequest) async {
    // Đổi tên tham số
    final url = Uri.parse('$baseUrl/api/products/create');
    try {
      final response = await httpClient.post(
        // Sử dụng _httpClient instance
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
        return ProductDTO.fromJson(jsonDecode(
            utf8.decode(response.bodyBytes))); // Parse và decode UTF-8
      } else {
        String errorMessage = 'Failed to create product.';
        try {
          final errorBody =
              jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF-8
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception(
            'Failed to create product: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('SocketException during create product: $e');
      throw Exception('Network Error: Could not connect to server.');
    } catch (e) {
      if (kDebugMode) print('Unexpected Error during create product: $e');
      throw Exception('Không hợp lệ');
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

  // Enhanced method to get image from cache or server with better caching
  Future<Uint8List?> getImageFromServer(String? imagePath,
      {bool forceReload = false}) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    // Check if we're online
    bool online = await isOnline();

    // Reset network restored flag when we go offline
    if (!online) {
      _isNetworkRestored = false;
    }

    // Check if network was just restored
    bool wasNetworkJustRestored = false;
    if (online && !_isNetworkRestored) {
      _isNetworkRestored = true;
      wasNetworkJustRestored = true;

      // Add this: Clear entire image cache when network is restored
      if (kDebugMode) {
        print(
            'Network just restored - clearing all image caches to force reload');
      }
      _imageCache.clear();
      UserInfo.avatarCache.clear();

      // Also clear local files to prevent inconsistency
      clearLocalImageCache().catchError((e) {
        if (kDebugMode) {
          print(
              'Error clearing local image cache after network restoration: $e');
        }
      });
    }

    // When network is just restored, we should behave like forceReload
    forceReload = forceReload || wasNetworkJustRestored;

    // If online and network was just restored, bypass cache for all image requests
    if (online && !forceReload && wasNetworkJustRestored) {
      if (kDebugMode) {
        print('Network restored - fetching fresh image for $imagePath');
      }
      forceReload = true;
    }

    // Check cache only if not forcing reload
    if (!forceReload) {
      // First check our product-specific image cache
      if (_imageCache.containsKey(imagePath)) {
        if (kDebugMode) print('Using in-memory cached image for $imagePath');
        return _imageCache[imagePath];
      }

      // Then check UserInfo avatar cache (existing implementation)
      if (UserInfo.avatarCache.containsKey(imagePath)) {
        return UserInfo.avatarCache[imagePath];
      }

      // If not in memory, try loading from local storage
      final localImage = await _loadImageFromLocalStorage(imagePath);
      if (localImage != null) {
        // Cache in memory for faster access next time
        _imageCache[imagePath] = localImage;
        UserInfo.avatarCache[imagePath] = localImage;
        return localImage;
      }
    }

    // ENHANCED OFFLINE HANDLING: If we're offline, make an extra effort to find the image locally
    if (!online) {
      if (kDebugMode) {
        print('Device is offline - making additional attempt to find image $imagePath locally');
      }
      
      // Try loading from local storage again with more aggressive approach
      try {
        // Try using SharedPreferencesService directly, even if we already tried _loadImageFromLocalStorage
        final prefsService = await SharedPreferencesService.getInstance();
        final localImage = prefsService.getImageData(imagePath);
        
        if (localImage != null) {
          if (kDebugMode) {
            print('Found image in local storage on second attempt: $imagePath');
          }
          // Cache in memory for future use
          _imageCache[imagePath] = localImage;
          return localImage;
        }
        
        // If exact path fails, try variations of the path that might be in storage
        if (imagePath.startsWith('/')) {
          final trimmedPath = imagePath.substring(1);
          final altLocalImage = prefsService.getImageData(trimmedPath);
          if (altLocalImage != null) {
            if (kDebugMode) {
              print('Found image with alternate path in local storage: $trimmedPath');
            }
            _imageCache[imagePath] = altLocalImage; // Store with original path
            return altLocalImage;
          }
        } else {
          // Try with a leading slash if it doesn't have one
          final altPath = '/$imagePath';
          final altLocalImage = prefsService.getImageData(altPath);
          if (altLocalImage != null) {
            if (kDebugMode) {
              print('Found image with alternate path in local storage: $altPath');
            }
            _imageCache[imagePath] = altLocalImage; // Store with original path
            return altLocalImage;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error during additional local image search: $e');
        }
      }
      
      if (kDebugMode) {
        print('Device is offline and image $imagePath is not available locally');
      }
      return null; // No more options when offline
    }

    // If we're online, continue with server request
    try {
      String fullUrl = getImageUrl(imagePath);
      // Add cache-busting parameter for forceReload or network restoration
      if (forceReload || wasNetworkJustRestored) {
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        fullUrl += '?cacheBust=$cacheBuster';

        if (kDebugMode) {
          print('Fetching fresh image from server: $fullUrl');
        }
      }

      final response = await httpClient.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        // Cache the image unless we're forcing reload
        _imageCache[imagePath] = response.bodyBytes;
        UserInfo.avatarCache[imagePath] = response.bodyBytes;

        // Also save to local storage for offline access
        await _saveImageToLocalStorage(imagePath, response.bodyBytes);

        if (forceReload && kDebugMode) {
          print('Updated all caches with fresh image from server: $imagePath');
        }

        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching image: $e');
    }

    return null;
  }

  // Add a method to force refresh all cached images when online is restored
  Future<void> refreshAllCachedImages() async {
    if (!await isOnline()) return;

    if (kDebugMode) {
      print('Refreshing all cached images after network restoration');
    }

    try {
      // Get all cached image paths
      final imagePaths = [..._imageCache.keys];

      // Refresh each image
      for (var path in imagePaths) {
        await getImageFromServer(path, forceReload: true);
      }

      if (kDebugMode) {
        print('Refreshed ${imagePaths.length} cached images');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing cached images: $e');
      }
    }
  }

  // // Save image to local storage with improved error handling
  // Future<void> _saveImageToLocalStorage(String imagePath, Uint8List imageBytes) async {
  //   try {
  //     if (imagePath.isEmpty || imageBytes.isEmpty) return;

  //     final path = await _localPath;
  //     final filename = _getImageFileName(imagePath);
  //     final file = File('$path/$filename');

  //     // Create parent directory if it doesn't exist
  //     final dir = file.parent;
  //     if (!await dir.exists()) {
  //       await dir.create(recursive: true);
  //     }

  //     await file.writeAsBytes(imageBytes);

  //     if (kDebugMode) {
  //       print('Saved image to local storage: $filename (${imageBytes.length} bytes)');
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error saving image to local storage: $e');
  //     }
  //   }
  // }

  // Clear all locally cached images - call when refresh is needed
  Future<void> clearLocalImageCache() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);

      if (await dir.exists()) {
        // Get all files in directory
        final entities = await dir.list().toList();

        // Delete all files (not directories)
        for (var entity in entities) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      // Also clear memory caches
      _imageCache.clear();
      UserInfo.avatarCache.clear();

      if (kDebugMode) {
        print('Cleared all locally cached images');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing local image cache: $e');
      }
    }
  }

  // Refresh specific image, removing from all caches and forcing reload
  Future<Uint8List?> refreshImage(String imagePath) async {
    // Remove from caches
    _imageCache.remove(imagePath);
    UserInfo.avatarCache.remove(imagePath);

    try {
      // Remove from local storage
      final path = await _localPath;
      final filename = _getImageFileName(imagePath);
      final file = File('$path/$filename');

      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('Deleted local image: $filename');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting local image: $e');
      }
    }

    // Force reload
    return await getImageFromServer(imagePath, forceReload: true);
  }

  // Method to check if an image is already cached without fetching
  bool isImageCached(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    return _imageCache.containsKey(imagePath) ||
        UserInfo.avatarCache.containsKey(imagePath);
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

  // New method to preload images for a list of products
  Future<void> preloadProductImages(List<ProductDTO> products) async {
    for (var product in products) {
      if (product.mainImageUrl != null &&
          !isImageCached(product.mainImageUrl)) {
        await getImageFromServer(product.mainImageUrl);
      }
    }
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
  Future<ProductDTO> updateProduct(
      int id, UpdateProductRequestDTO productRequest) async {
    // Đổi tên tham số
    final url = Uri.parse('$baseUrl/api/products/$id');
    try {
      final response = await httpClient.put(
        // Sử dụng _httpClient instance và phương thức PUT
        url,
        headers: _getHeaders(includeAuth: true), // Cần token ADMIN
        body: jsonEncode(productRequest.toJson()), // Chuyển đổi DTO sang JSON
      );

      if (kDebugMode) {
        print('Update Product Request URL: $url');
        // print('Update Product Request Body: ${jsonEncode(productRequest.toJson())}');
        print('Update Product Response Status: ${response.statusCode}');
        print(
            'Update Product Response Body: ${utf8.decode(response.bodyBytes)}');
      }

      if (response.statusCode == 200) {
        return ProductDTO.fromJson(jsonDecode(
            utf8.decode(response.bodyBytes))); // Parse và decode UTF-8
      } else {
        String errorMessage = 'Failed to update product.';
        try {
          final errorBody =
              jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF-8
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception(
            'Failed to update product: $errorMessage (Status: ${response.statusCode})');
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
  Future<void> deleteProduct(int id) async {
    // ID là int
    final url = Uri.parse('$baseUrl/api/products/$id');
    try {
      final response = await httpClient.delete(
        // Sử dụng _httpClient instance và phương thức DELETE
        url,
        headers: _getHeaders(includeAuth: true), // Cần token ADMIN
      );

      if (kDebugMode) {
        print('Delete Product Request URL: $url');
        print('Delete Product Response Status: ${response.statusCode}');
        print(
            'Delete Product Response Body: ${utf8.decode(response.bodyBytes)}'); // Decode UTF-8
      }
      print(response.body);
      if (response.statusCode == 204) {
        // Thành công (No Content)
        return; // Return void
      } else {
        String errorMessage = 'Failed to delete product.';
        try {
          final errorBody =
              jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF-8
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception(
            'Failed to delete product: $errorMessage (Status: ${response.statusCode})');
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
    double? minPrice, // Make sure these are nullable
    double? maxPrice, // Make sure these are nullable
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
    if (categoryId != null)
      queryParameters['categoryId'] = categoryId.toString();
    if (brandId != null) queryParameters['brandId'] = brandId.toString();
    // Only add price parameters if they are not null
    if (minPrice != null) queryParameters['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParameters['maxPrice'] = maxPrice.toString();
    if (minRating != null) queryParameters['minRating'] = minRating.toString();

    final url = Uri.parse('$baseUrl/api/products')
        .replace(queryParameters: queryParameters);

    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: false), // Make this a public API call
      );

      if (kDebugMode) {
        print("data: ${response.body}");
        print('Fetch Products Request URL: $url');
        print('Fetch Products Response Status: ${response.statusCode}');
      }

      switch (response.statusCode) {
        case 200:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
            // Now, PageResponse.fromJson uses the CORRECT ProductDTO.fromJson
            return PageResponse<ProductDTO>.fromJson(
                responseBody, ProductDTO.fromJson);
          } else {
            throw Exception(
                'Invalid response format from server: Expected a Map.');
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
          throw Exception(
              'Failed to fetch products: $errorMessage (Status: ${response.statusCode})');

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
          throw Exception(
              'Failed to fetch products: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('SocketException during fetch products: $e');
      throw Exception(
          'Network Error: Could not connect to server. Please check your internet connection.');
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
    int size = 10,
    String sortBy = 'createdDate', // Default sort property
    String sortDir = 'desc', // Default sort direction
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
    print("");
    if (startDate != null)
      queryParameters['startDate'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null)
      queryParameters['endDate'] = endDate.toIso8601String().split('T')[0];

    final url = Uri.parse('$baseUrl/api/categories')
        .replace(queryParameters: queryParameters);
    if (kDebugMode)
      print(
          'Fetch Categories (Paginated) Request URL: $url'); // Print URL với tham số sort

    try {
      // Sử dụng _httpClient instance
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: false),
      );

      if (kDebugMode) {
        print(
            'Fetch Categories (Paginated) Response Status: ${response.statusCode}');
        if (response.bodyBytes.isNotEmpty) {
          print(
              'Fetch Categories (Paginated) Response Body: ${utf8.decode(response.bodyBytes)}');
        } else {
          print('Fetch Categories (Paginated) Response Body: (Empty or 204)');
        }
      }
      print(response.body);
      switch (response.statusCode) {
        case 200:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
            // *** SỬA TYPO PageResponsive -> PageResponse ***
            return PageResponse<CategoryDTO>.fromJson(
                responseBody, CategoryDTO.fromJson);
          } else {
            throw FormatException(
                'Invalid response format for categories: Expected a JSON object (PageResponse), got ${responseBody.runtimeType}.');
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
          throw Exception(
              'Failed to fetch categories: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode)
        print('SocketException during fetchCategoriesPaginated: $e');
      throw Exception(
          'Network Error: Could not connect to server. Please check your internet connection.');
    } on FormatException catch (e) {
      if (kDebugMode)
        print('FormatException during fetchCategoriesPaginated: $e');
      throw Exception(
          'Server response format error. Could not parse category page data.');
    } catch (e) {
      if (kDebugMode)
        print('Unexpected Error during fetchCategoriesPaginated: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

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
          print(
              'Get All Brands Response Body: ${utf8.decode(response.bodyBytes)}');
        } else {
          print('Get All Brands Response Body: (Empty or 204)');
        }
      }

      switch (response.statusCode) {
        case 200:
          final responseBody = utf8.decode(response.bodyBytes);
          final List<dynamic> jsonList = jsonDecode(responseBody);
          final List<BrandDTO> brands = jsonList
              .map((jsonItem) =>
                  BrandDTO.fromJson(jsonItem as Map<String, dynamic>))
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
          throw Exception(
              'Failed to fetch brands: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('SocketException during getAllBrands: $e');
      throw Exception(
          'Network Error: Could not connect to server. Please check your internet connection.');
    } on FormatException catch (e) {
      if (kDebugMode) print('FormatException during getAllBrands: $e');
      throw Exception(
          'Server response format error. Could not parse brand data.');
    } catch (e) {
      if (kDebugMode)
        print('Unexpected Error during getAllBrands: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Method to fetch top-selling products with pagination
  Future<PageResponse<ProductDTO>> getTopSellingProducts(
      {int page = 0, int size = 10}) async {
    final url = Uri.parse(
        '$baseUrl/api/products/top-selling?page=$page&size=$size&sort=createdDate,desc');
    if (kDebugMode) {
      print('Fetching top selling products: $url');
    }
    try {
      final response = await httpClient.get(
        url,
        headers:
            _getHeaders(includeAuth: false), // Top-selling might not need auth
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        // Use the PageResponse.fromJson, ensuring ProductDTO.fromJson handles Map<String, dynamic>
        return PageResponse.fromJson(
            jsonData,
            (itemJson) =>
                ProductDTO.fromJson(itemJson as Map<String, dynamic>));
      } else {
        if (kDebugMode) {
          print('Failed to fetch top selling products: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        throw Exception(
            'Failed to load top selling products: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching top selling products: $e');
      }
      throw Exception('Error fetching top selling products: $e');
    }
  }

  // Method to fetch top-discounted products
  Future<PageResponse<ProductDTO>> getTopDiscountedProducts(
      {int page = 0, int size = 10}) async {
    final url =
        Uri.parse('$baseUrl/api/products/top-discounted?page=$page&size=$size');
    if (kDebugMode) {
      print('Fetching top discounted products: $url');
    }
    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(
            includeAuth: false), // Top-discounted might not need auth
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        // If content is empty but status is 200, PageResponse.fromJson should handle it.
        // If server sends 204 for no content, it will now be caught by the 'else' block.
        return PageResponse.fromJson(
            jsonData,
            (itemJson) =>
                ProductDTO.fromJson(itemJson as Map<String, dynamic>));
      } else {
        // This block will now handle 204 No Content as well, by throwing an exception.
        if (kDebugMode) {
          print(
              'Failed to fetch top discounted products: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        throw Exception(
            'Failed to load top discounted products: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching top discounted products: $e');
      }
      // Ensure the re-thrown exception includes the original error if it's not an HTTP status exception
      if (e is Exception &&
          e.toString().contains('Failed to load top discounted products')) {
        throw e; // Re-throw the specific HTTP status exception
      }
      throw Exception('Error fetching top discounted products: $e');
    }
  }

  // Add Product Review
  Future<ProductReviewDTO> submitReview(
      int productId, CreateProductReviewRequestDTO reviewDto) async {
    final url = Uri.parse('$baseUrl/api/products/$productId/reviews');
    final userInfo = UserInfo();
    final bool isLoggedIn = userInfo.currentUser != null;

    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(
            includeAuth: isLoggedIn), // Token needed if user is logged in
        body: jsonEncode(reviewDto.toJson()),
      );

      if (kDebugMode) {
        print('Submit Review Request URL: $url');
        print('Submit Review Request Body: ${jsonEncode(reviewDto.toJson())}');
        print('Submit Review Response Status: ${response.statusCode}');
        print(
            'Submit Review Response Body: ${utf8.decode(response.bodyBytes)}');
      }

      if (response.statusCode == 201) {
        return ProductReviewDTO.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        String errorMessage = 'Failed to submit review.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}
        throw Exception(
            'Failed to submit review: $errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('SocketException during submit review: $e');
      throw Exception('Network Error: Could not connect to server.');
    } catch (e) {
      if (kDebugMode) print('Unexpected Error during submit review: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Add a public getter for network restoration status
  static bool get isNetworkRestored => _isNetworkRestored;

  // Add public method to load image from local storage
  Future<Uint8List?> loadImageFromLocalStorage(String imagePath) async {
    return _loadImageFromLocalStorage(imagePath);
  }

  // Add public method to add image to cache
  void addImageToCache(String imagePath, Uint8List imageData) {
    _imageCache[imagePath] = imageData;
    // Also update UserInfo cache for consistency
    UserInfo.avatarCache[imagePath] = imageData;
  }

  void dispose() {
    httpClient.close();
  }
}
