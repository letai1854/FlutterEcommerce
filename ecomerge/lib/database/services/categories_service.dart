import 'dart:io';
import 'dart:convert'; // Import for jsonDecode and utf8
import 'dart:typed_data'; // Required for Uint8List if upload method is in ProductService

import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart';
import 'package:e_commerce_app/database/database_helper.dart'; // Assuming this file provides baseurl
import 'package:e_commerce_app/database/models/categores/CreateCategoryRequestDTO.dart';
import 'package:e_commerce_app/database/models/categores/UpdateCategoryRequestDTO.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode and kIsWeb
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // For SSL bypass on non-web

// Import DTOs and PageResponse
// Assuming these files exist in your project with the structures discussed previously.
import 'package:e_commerce_app/database/models/categories.dart'; // Assuming CategoryDTO is here
import 'package:e_commerce_app/database/PageResponse.dart'; // Assuming PageResponse exists

// Assuming UserInfo class exists for auth token retrieval
import 'package:e_commerce_app/database/Storage/UserInfo.dart';


class CategoriesService {

  // Ensure baseurl is correctly defined in database_helper.dart
  final String baseUrl = baseurl;
  late final http.Client httpClient;

  // *** Corrected constructor name ***
  CategoriesService() {
    httpClient = _createSecureClient();
  }

  http.Client _createSecureClient() {
    if (kIsWeb) {
      // Web platform doesn't need special handling for certificates
      return http.Client();
    } else {
      // For mobile and desktop platforms, allow bypassing bad certificates (for local development with self-signed certs)
      final HttpClient ioClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      return IOClient(ioClient);
    }
  }

  // Helper method to get common headers including Authorization token if available and needed
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    // Assuming UserInfo().authToken gets the stored JWT token
    final authToken = UserInfo().authToken;
    if (includeAuth && authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // --- API Methods ---

  // Fetch Categories with Pagination and Date Filters (if backend supports it)
  // Corresponds to backend GET /api/categories
  // Java snippet shows pageable, startDate, endDate. Assuming these are used.
  

  // Get Category by ID
  // Corresponds to backend GET /api/categories/{id}
  Future<CategoryDTO> getCategoryById(int id) async {
    final url = Uri.parse('$baseUrl/api/categories/$id');
    if (kDebugMode) print('Get Category By ID Request URL: $url');

    try {
      final response = await httpClient.get(
        url,
        // Backend snippet does NOT have @PreAuthorize, assuming public
        headers: _getHeaders(includeAuth: false),
      );

      if (kDebugMode) {
        print('Get Category By ID Response Status: ${response.statusCode}');
         if (response.bodyBytes.isNotEmpty) {
           print('Get Category By ID Response Body: ${utf8.decode(response.bodyBytes)}');
         }
      }

      switch (response.statusCode) {
        case 200:
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (responseBody is Map<String, dynamic>) {
            return CategoryDTO.fromJson(responseBody);
          } else {
             throw FormatException('Invalid response format for category ID $id: Expected a JSON object, got ${responseBody.runtimeType}.');
          }

        case 404: // Not Found
           String errorMessage = 'Category not found for ID $id.';
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
           throw Exception('Category not found: $errorMessage (Status: 404)');

        default:
          String errorMessage = 'Failed to fetch category details for ID $id.';
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
          throw Exception('Failed to fetch category: $errorMessage');
      }
    } on SocketException catch (e) {
       if (kDebugMode) print('SocketException during getCategoryById: $e');
       throw Exception('Network Error: Could not connect to server.');
    } on FormatException catch (e) {
       if (kDebugMode) print('FormatException during getCategoryById: $e');
       throw Exception('Server response format error for category details.');
    } catch (e) {
      if (kDebugMode) print('Unexpected Error during getCategoryById: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }


  // Create Category
  // Corresponds to backend POST /api/categories
  // Requires ADMIN role
  Future<CategoryDTO> createCategory(CreateCategoryRequestDTO requestDTO) async {
    final url = Uri.parse('$baseUrl/api/categories');
     if (kDebugMode) print('Create Category Request URL: $url');

    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(includeAuth: true), // Requires ADMIN token
        body: jsonEncode(requestDTO.toJson()), // Send DTO as JSON body
      );

      if (kDebugMode) {
          print('Create Category Response Status: ${response.statusCode}');
           if (response.bodyBytes.isNotEmpty) {
              print('Create Category Response Body: ${utf8.decode(response.bodyBytes)}');
           }
      }

      switch (response.statusCode) {
        case 201: // Created
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
           if (responseBody is Map<String, dynamic>) {
             return CategoryDTO.fromJson(responseBody);
           } else {
              throw FormatException('Invalid response format for create category: Expected a JSON object, got ${responseBody.runtimeType}.');
           }

        case 400: // Bad Request (e.g., validation errors, duplicate name)
           String errorMessage = 'Invalid category data.';
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
           throw Exception('Failed to create category: $errorMessage (Status: 400)');

        case 403: // Forbidden (Missing or invalid ADMIN token)
           String errorMessage = 'Permission denied.';
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
           throw Exception('Permission denied: $errorMessage (Status: 403)'); // Specific error for 403

        default:
          String errorMessage = 'Failed to create category.';
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
          throw Exception('Failed to create category: $errorMessage');
      }
    } on SocketException catch (e) {
       if (kDebugMode) print('SocketException during createCategory: $e');
       throw Exception('Network Error: Could not connect to server.');
    } on FormatException catch (e) {
       if (kDebugMode) print('FormatException during createCategory: $e');
       throw Exception('Server response format error for create category.');
    } catch (e) {
      if (kDebugMode) print('Unexpected Error during createCategory: ${e.toString()}');
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
  Future<Uint8List?> getImageFromServer(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    // First check AppDataService image cache
    final appDataService = AppDataService();
    final cachedImage = appDataService.getCategoryImage(imagePath);
    if (cachedImage != null) {
      return cachedImage;
    }

    // Then check UserInfo cache
    if (UserInfo.avatarCache.containsKey(imagePath)) {
      return UserInfo.avatarCache[imagePath];
    }

    try {
      String fullUrl = getImageUrl(imagePath);
      final response = await httpClient.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        // Store in both caches
        UserInfo.avatarCache[imagePath] = response.bodyBytes;
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching image: $e');
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
  // Update Category
  // Corresponds to backend PUT /api/categories/{id}
  // Requires ADMIN role
  Future<CategoryDTO> updateCategory(int id, UpdateCategoryRequestDTO requestDTO) async {
    final url = Uri.parse('$baseUrl/api/categories/$id');
     if (kDebugMode) print('Update Category Request URL: $url');

    try {
      final response = await httpClient.put(
        url,
        headers: _getHeaders(includeAuth: true), // Requires ADMIN token
        body: jsonEncode(requestDTO.toJson()), // Send DTO as JSON body
      );

      if (kDebugMode) {
          print('Update Category Response Status: ${response.statusCode}');
           if (response.bodyBytes.isNotEmpty) {
               print('Update Category Response Body: ${utf8.decode(response.bodyBytes)}');
           }
      }

      switch (response.statusCode) {
        case 200: // OK
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
           if (responseBody is Map<String, dynamic>) {
             return CategoryDTO.fromJson(responseBody);
           } else {
              throw FormatException('Invalid response format for update category $id: Expected a JSON object, got ${responseBody.runtimeType}.');
           }

        case 400: // Bad Request
           String errorMessage = 'Invalid category data for update.';
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
           throw Exception('Failed to update category: $errorMessage (Status: 400)');

        case 403: // Forbidden
            String errorMessage = 'Permission denied.';
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
           throw Exception('Permission denied: $errorMessage (Status: 403)');

        case 404: // Not Found
           String errorMessage = 'Category not found for update.';
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
            throw Exception('Category not found for update: $errorMessage (Status: 404)');

        default:
          String errorMessage = 'Failed to update category.';
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
          throw Exception('Failed to update category: $errorMessage');
      }
    } on SocketException catch (e) {
       if (kDebugMode) print('SocketException during updateCategory: $e');
       throw Exception('Network Error: Could not connect to server.');
    } on FormatException catch (e) {
       if (kDebugMode) print('FormatException during updateCategory: $e');
       throw Exception('Server response format error for update category.');
    } catch (e) {
      if (kDebugMode) print('Unexpected Error during updateCategory: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }


  // Delete Category
  // Corresponds to backend DELETE /api/categories/{id}
  // Requires ADMIN role
  Future<void> deleteCategory(int id) async {
    final url = Uri.parse('$baseUrl/api/categories/$id');
    if (kDebugMode) print('Delete Category Request URL: $url');

    try {
      final response = await httpClient.delete(
        url,
        headers: _getHeaders(includeAuth: true), // Requires ADMIN token
      );

      if (kDebugMode) {
        print('Delete Category Response Status: ${response.statusCode}');
         if (response.bodyBytes.isNotEmpty) {
           print('Delete Category Response Body: ${utf8.decode(response.bodyBytes)}');
         }
      }

      switch (response.statusCode) {
        case 204: // No Content (Success)
          return; // Return void on success

        case 403: // Forbidden
           String errorMessage = 'Permission denied.';
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
           throw Exception('Permission denied: $errorMessage (Status: 403)'); // Specific error for 403

        case 404: // Not Found
           String errorMessage = 'Category not found for deletion.';
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
           throw Exception('Category not found for deletion: $errorMessage (Status: 404)');

        default:
          String errorMessage = 'Failed to delete category.';
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
          throw Exception('Failed to delete category: $errorMessage');
      }
    } on SocketException catch (e) {
       if (kDebugMode) print('SocketException during deleteCategory: $e');
       throw Exception('Network Error: Could not connect to server.');
    } catch (e) {
      if (kDebugMode) print('Unexpected Error during deleteCategory: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

   // Dispose the httpClient when the service is no longer needed
   void dispose() {
     httpClient.close();
     if (kDebugMode) print('CategoriesService httpClient disposed.');
   }

}

// Assuming these DTOs exist in your project.
// Example of CreateCategoryRequestDTO and UpdateCategoryRequestDTO based on common patterns:
// class CreateCategoryRequestDTO {
//   final String name;
//   final String? imageUrl; // Image URL/path if included in create request
//   CreateCategoryRequestDTO({required this.name, this.imageUrl});
//   Map<String, dynamic> toJson() => {'name': name, 'imageUrl': imageUrl};
// }
//
// class UpdateCategoryRequestDTO {
//   final String name;
//   final String? imageUrl; // Image URL/path for update
//   UpdateCategoryRequestDTO({required this.name, this.imageUrl});
//   Map<String, dynamic> toJson() => {'name': name, 'imageUrl': imageUrl};
// }
