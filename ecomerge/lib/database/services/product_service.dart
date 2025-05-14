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

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    final imageDir = Directory('${directory.path}/product_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    return imageDir.path;
  }

  String _getImageFileName(String imagePath) {
    var bytes = utf8.encode(imagePath);
    var digest = sha256.convert(bytes);
    return digest.toString() +
        '.png'; // Always use .png extension for consistency
  }

  Future<void> _saveImageToLocalStorage(
      String imagePath, Uint8List imageBytes) async {
    try {
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

  Future<Uint8List?> _loadImageFromLocalStorage(String imagePath) async {
    try {
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
        headers: _getHeaders(includeAuth: false),
      );

      if (kDebugMode) {
        print('Get Product By ID Request URL: $url');
        print('Get Product By ID Response Status: ${response.statusCode}');
        print(
            'Get Product By ID Response Body: ${utf8.decode(response.bodyBytes)}');
      }

      if (response.statusCode == 200) {
        return ProductDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        String errorMessage = 'Failed to fetch product details.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
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

  Future<ProductDTO> createProduct(
      CreateProductRequestDTO productRequest) async {
    final url = Uri.parse('$baseUrl/api/products/create');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(productRequest.toJson()),
      );
      print('Create Product Request URL: $response');
      if (kDebugMode) {
        print('Create Product Request URL: $url');
        print('Create Product Response Status: ${response.statusCode}');
        print('Create Product Response Body: ${response.body}');
      }

      if (response.statusCode == 201) {
        return ProductDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        String errorMessage = 'Failed to create product.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
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
      final request = http.MultipartRequest('POST', url);

      if (UserInfo().authToken != null) {
        request.headers['Authorization'] = 'Bearer ${UserInfo().authToken}';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      final stream = await request.finalize();

      final httpRequest = http.Request(request.method, request.url);
      httpRequest.headers.addAll(request.headers);
      httpRequest.bodyBytes = await stream.toBytes();

      final streamedResponse = await httpClient.send(httpRequest);

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
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

  Future<Uint8List?> getImageFromServer(String? imagePath,
      {bool forceReload = false}) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    bool online = await isOnline();

    if (!online) {
      _isNetworkRestored = false;
    }

    bool wasNetworkJustRestored = false;
    if (online && !_isNetworkRestored) {
      _isNetworkRestored = true;
      wasNetworkJustRestored = true;

      if (kDebugMode) {
        print(
            'Network just restored - clearing all image caches to force reload');
      }
      _imageCache.clear();
      UserInfo.avatarCache.clear();

      clearLocalImageCache().catchError((e) {
        if (kDebugMode) {
          print(
              'Error clearing local image cache after network restoration: $e');
        }
      });
    }

    forceReload = forceReload || wasNetworkJustRestored;

    if (online && !forceReload && wasNetworkJustRestored) {
      if (kDebugMode) {
        print('Network restored - fetching fresh image for $imagePath');
      }
      forceReload = true;
    }

    if (!forceReload) {
      if (_imageCache.containsKey(imagePath)) {
        if (kDebugMode) print('Using in-memory cached image for $imagePath');
        return _imageCache[imagePath];
      }

      if (UserInfo.avatarCache.containsKey(imagePath)) {
        return UserInfo.avatarCache[imagePath];
      }

      final localImage = await _loadImageFromLocalStorage(imagePath);
      if (localImage != null) {
        _imageCache[imagePath] = localImage;
        UserInfo.avatarCache[imagePath] = localImage;
        return localImage;
      }
    }

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
      if (forceReload || wasNetworkJustRestored) {
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        fullUrl += '?cacheBust=$cacheBuster';

        if (kDebugMode) {
          print('Fetching fresh image from server: $fullUrl');
        }
      }

      final response = await httpClient.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        _imageCache[imagePath] = response.bodyBytes;
        UserInfo.avatarCache[imagePath] = response.bodyBytes;

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

  Future<void> refreshAllCachedImages() async {
    if (!await isOnline()) return;

    if (kDebugMode) {
      print('Refreshing all cached images after network restoration');
    }

    try {
      final imagePaths = [..._imageCache.keys];

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

  Future<void> clearLocalImageCache() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);

      if (await dir.exists()) {
        final entities = await dir.list().toList();

        for (var entity in entities) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

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

  Future<Uint8List?> refreshImage(String imagePath) async {
    _imageCache.remove(imagePath);
    UserInfo.avatarCache.remove(imagePath);

    try {
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

    return await getImageFromServer(imagePath, forceReload: true);
  }

  bool isImageCached(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    return _imageCache.containsKey(imagePath) ||
        UserInfo.avatarCache.containsKey(imagePath);
  }

  Uint8List? getImageFromCache(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    if (_imageCache.containsKey(imagePath)) {
      return _imageCache[imagePath];
    }

    if (UserInfo.avatarCache.containsKey(imagePath)) {
      return UserInfo.avatarCache[imagePath];
    }

    return null;
  }

  Future<void> preloadProductImages(List<ProductDTO> products) async {
    for (var product in products) {
      if (product.mainImageUrl != null &&
          !isImageCached(product.mainImageUrl)) {
        await getImageFromServer(product.mainImageUrl);
      }
    }
  }

  String getImageUrl(String? imagePath) {
    if (imagePath == null) return '';

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    String path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$baseUrl$path';
  }

  Future<ProductDTO> updateProduct(
      int id, UpdateProductRequestDTO productRequest) async {
    final url = Uri.parse('$baseUrl/api/products/$id');
    try {
      final response = await httpClient.put(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(productRequest.toJson()),
      );

      if (kDebugMode) {
        print('Update Product Request URL: $url');
        print('Update Product Response Status: ${response.statusCode}');
        print(
            'Update Product Response Body: ${utf8.decode(response.bodyBytes)}');
      }

      if (response.statusCode == 200) {
        return ProductDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        String errorMessage = 'Failed to update product.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
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

  Future<void> deleteProduct(int id) async {
    final url = Uri.parse('$baseUrl/api/products/$id');
    try {
      final response = await httpClient.delete(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      if (kDebugMode) {
        print('Delete Product Request URL: $url');
        print('Delete Product Response Status: ${response.statusCode}');
        print(
            'Delete Product Response Body: ${utf8.decode(response.bodyBytes)}');
      }
      print(response.body);
      if (response.statusCode == 204) {
        return;
      } else {
        String errorMessage = 'Failed to delete product.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
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
    if (categoryId != null)
      queryParameters['categoryId'] = categoryId.toString();
    if (brandId != null) queryParameters['brandId'] = brandId.toString();
    if (minPrice != null) queryParameters['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParameters['maxPrice'] = maxPrice.toString();
    if (minRating != null) queryParameters['minRating'] = minRating.toString();

    final url = Uri.parse('$baseUrl/api/products')
        .replace(queryParameters: queryParameters);

    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: false),
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
            return PageResponse<ProductDTO>.fromJson(
                responseBody, ProductDTO.fromJson);
          } else {
            throw Exception(
                'Invalid response format from server: Expected a Map.');
          }

        case 204:
          return PageResponse.empty();

        case 400:
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

        default:
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
    String sortBy = 'createdDate',
    String sortDir = 'desc',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page.toString(),
      'size': size.toString(),
      'sort': '$sortBy,$sortDir',
    };
    print("");
    if (startDate != null)
      queryParameters['startDate'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null)
      queryParameters['endDate'] = endDate.toIso8601String().split('T')[0];

    final url = Uri.parse('$baseUrl/api/categories')
        .replace(queryParameters: queryParameters);
    if (kDebugMode) print('Fetch Categories (Paginated) Request URL: $url');

    try {
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
            return PageResponse<CategoryDTO>.fromJson(
                responseBody, CategoryDTO.fromJson);
          } else {
            throw FormatException(
                'Invalid response format for categories: Expected a JSON object (PageResponse), got ${responseBody.runtimeType}.');
          }

        case 204:
          return PageResponse.empty();

        default:
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
        headers: _getHeaders(includeAuth: false),
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return PageResponse.fromJson(jsonData, (itemJson) {
            try {
              if (itemJson is Map<String, dynamic>) {
                return ProductDTO.fromJson(itemJson);
              } else {
                print('Warning: Product data is not a Map: $itemJson');
                return ProductDTO(
                    name: "Error", description: "Invalid data format");
              }
            } catch (e) {
              print('Error parsing ProductDTO: $e');
              return ProductDTO(name: "Error", description: "Parser error");
            }
          });
        } catch (e) {
          print('Error parsing response JSON: $e');
          return PageResponse.empty();
        }
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
        headers: _getHeaders(includeAuth: false),
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return PageResponse.fromJson(jsonData, (itemJson) {
            try {
              if (itemJson is Map<String, dynamic>) {
                return ProductDTO.fromJson(itemJson);
              } else {
                print('Warning: Product data is not a Map: $itemJson');
                return ProductDTO(
                    name: "Error", description: "Invalid data format");
              }
            } catch (e) {
              print('Error parsing ProductDTO: $e');
              return ProductDTO(name: "Error", description: "Parser error");
            }
          });
        } catch (e) {
          print('Error parsing response JSON: $e');
          return PageResponse.empty();
        }
      } else {
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
      throw Exception('Error fetching top discounted products: $e');
    }
  }

  Future<ProductReviewDTO> submitReview(
      int productId, CreateProductReviewRequestDTO reviewDto) async {
    final url = Uri.parse('$baseUrl/api/products/$productId/reviews');
    final userInfo = UserInfo();
    final bool isLoggedIn = userInfo.currentUser != null;

    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(includeAuth: isLoggedIn),
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

  static bool get isNetworkRestored => _isNetworkRestored;

  Future<Uint8List?> loadImageFromLocalStorage(String imagePath) async {
    return _loadImageFromLocalStorage(imagePath);
  }

  void addImageToCache(String imagePath, Uint8List imageData) {
    _imageCache[imagePath] = imageData;
    UserInfo.avatarCache[imagePath] = imageData;
  }

  void dispose() {
    httpClient.close();
  }
}
