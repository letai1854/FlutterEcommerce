import 'dart:convert';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/user_model.dart'; // Assuming User model is here
import '/database/database_helper.dart'; // Assuming DatabaseHelper is here
import '../database_helper.dart' as config;

class UserService {
  final String baseUrl = baseurl; // TODO: Replace with your actual backend URL
  String? _authToken; // To store JWT token

  final _httpClient = http.Client(); // Using http.Client for better testability

  // Static cache reference (using the public getter from UserInfo)
  static Map<String, Uint8List> get avatarCache => UserInfo.avatarCache;

  // Method to set the authentication token after login
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Helper to get headers, including auth token if available
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
   final userInfo = UserInfo();
    if (includeAuth && userInfo.authToken != null) {
      headers['Authorization'] = 'Bearer ${userInfo.authToken}';
    }

    return headers;
  }

  // Method to register a new user
  Future<bool?> registerUser({
    required String email,
    required String fullName,
    required String password,
    required String address,
  }) async {
    final url = Uri.parse('$baseurl/api/users/register');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'fullName': fullName,
          'password': password,
          'address': address,
        }),
      );

      print('Registration response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        User.fromMap(jsonDecode(response.body));
        return true;
      } else {
        print('Failed to register user: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during user registration: $e');
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  // Method to login user
  Future<bool> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/users/login');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        // Store the token and user info in the singleton
        setAuthToken(responseBody['token']);
        UserInfo().updateUserInfo(responseBody);

        // Check if user has avatar and pre-cache it
        String? avatarPath = UserInfo().currentUser?.avatar;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          // Get full URL if needed
          String fullAvatarUrl = getImageUrl(avatarPath);
          print('Pre-caching avatar from: $fullAvatarUrl');

          // Fetch and cache avatar image
          await _cacheAvatarImage(fullAvatarUrl, avatarPath);
        } else {
          print('User has no avatar to cache');
        }

        // Return true to indicate successful login
        print(
            'Login successful---------------------------------------------------: ${UserInfo().authToken}');
        return true;
      } else {
        print('Failed to login user: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during user login: $e');
      return false;
    }
  }

  // Helper method to fetch and cache avatar image
  Future<void> _cacheAvatarImage(String imageUrl, String avatarKey) async {
    try {
      final response = await httpClient.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Store image bytes in cache using the static public getter
        UserInfo.avatarCache[avatarKey] = response.bodyBytes;
        print(
            'Avatar cached successfully, size: ${response.bodyBytes.length} bytes');
      } else {
        print('Failed to fetch avatar image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error caching avatar image: $e');
    }
  }

  // Method to get cached avatar or fetch if not available
  Future<Uint8List?> getAvatarBytes(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) return null;

    // Return from cache if available
    if (UserInfo.avatarCache.containsKey(avatarPath)) {
      return UserInfo.avatarCache[avatarPath];
    }

    // Fetch and cache if not available
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

  // Helper method to clear avatar cache
  static void clearAvatarCache() {
    UserInfo.avatarCache.clear();
  }

  // Method to get current authenticated user's profile
  Future<User?> getCurrentUserProfile() async {
    final url = Uri.parse('$baseUrl/api/users/me');
    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        return User.fromMap(jsonDecode(response.body));
      } else {
        print('Failed to get user profile: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Method to update current authenticated user's profile
  Future<User?> updateCurrentUserProfile(Map<String, dynamic> updates) async {
    final url = Uri.parse('$baseUrl/api/users/me/update');
    try {
      final response = await httpClient.put(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return User.fromMap(jsonDecode(response.body));
      } else {
        print('Failed to update user profile: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  // Method to change current authenticated user's password
  Future<bool> changeCurrentUserPassword(
      String oldPassword, String newPassword) async {
    final url = Uri.parse('$baseUrl/api/users/me/change-password');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(
            {'oldPassword': oldPassword, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        return true; // Password changed successfully
      } else {
        print('Failed to change password: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

 Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/api/users/forgot-password');
    try {
      final response = await httpClient.post( // Sửa thành _httpClient
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );

      if (kDebugMode) {
          print('Forgot Password request URL: $url');
          print('Forgot Password request Body: ${jsonEncode({'email': email})}');
          print('Forgot Password response status: ${response.statusCode}');
          print('Forgot Password response body: ${response.body}');
      }


      if (response.statusCode == 200) {
        // Thành công, backend đã xử lý yêu cầu (không nhất thiết email tồn tại)
        return; // Return void on success
      } else {
        // API trả về lỗi (status code != 200)
        String errorMessage = 'Không thể yêu cầu mã xác thực.';
        try {
            final errorBody = jsonDecode(response.body);
            if (errorBody is Map && errorBody.containsKey('message')) {
               errorMessage = errorBody['message'];
            } else if (errorBody is String && errorBody.isNotEmpty) {
               errorMessage = errorBody;
            }
        } catch(_) {} // Ignore parsing error, use default message

        if (kDebugMode) {
            print('API Error during forgot password request: ${response.statusCode}, Message: $errorMessage');
        }
        throw Exception(errorMessage); // Ném Exception với thông báo lỗi từ backend
      }
    } catch (e) {
       // Lỗi mạng
       if (kDebugMode) print('SocketException during forgot password request: $e');
       throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.'); // Ném Exception mạng
    } 
  }

  // Bước 2: Xác thực mã OTP
  // Ném Exception nếu API trả về lỗi (status code != 200) hoặc lỗi mạng
  Future<void> verifyOtp(String email, String otp) async {
      final url = Uri.parse('$baseUrl/api/users/verify-otp');
      try {
          final response = await httpClient.post( // Sửa thành _httpClient
              url,
              headers: _getHeaders(),
              body: jsonEncode({'email': email, 'otp': otp}),
          );

          if (kDebugMode) {
              print('Verify OTP request URL: $url');
              print('Verify OTP request Body: ${jsonEncode({'email': email, 'otp': otp})}');
              print('Verify OTP response status: ${response.statusCode}');
              print('Verify OTP response body: ${response.body}');
          }


          if (response.statusCode == 200) {
              // Thành công
              return; // Return void on success
          } else {
              // API trả về lỗi (status code != 200)
              String errorMessage = 'Mã xác thực không hợp lệ hoặc đã hết hạn.';
              try {
                  final errorBody = jsonDecode(response.body);
                  if (errorBody is Map && errorBody.containsKey('message')) {
                     errorMessage = errorBody['message'];
                  } else if (errorBody is String && errorBody.isNotEmpty) {
                     errorMessage = errorBody;
                  }
              } catch(_) {}

              if (kDebugMode) {
                  print('API Error during OTP verification: ${response.statusCode}, Message: $errorMessage');
              }
              throw Exception(errorMessage); // Ném Exception
          }
      }catch (e) {
          if (kDebugMode) print('SocketException during OTP verification: $e');
          throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.'); // Ném Exception mạng
      }
  }

  // Bước 3: Đặt mật khẩu mới
  // Ném Exception nếu API trả về lỗi (status code != 200) hoặc lỗi mạng
  Future<void> setNewPassword(String email, String otp, String newPassword) async {
      final url = Uri.parse('$baseUrl/api/users/set-new-password');
      try {
          final response = await httpClient.post( // Sửa thành _httpClient
              url,
              headers: _getHeaders(),
              body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
          );

           if (kDebugMode) {
              print('Set New Password request URL: $url');
              // Không in mật khẩu mới
              print('Set New Password request Body (partial): ${jsonEncode({'email': email, 'otp': otp, 'newPassword': '...'})}');
              print('Set New Password response status: ${response.statusCode}');
              print('Set New Password response body: ${response.body}');
          }

          if (response.statusCode == 200) {
              // Thành công
              return; // Return void on success
          } else {
              // API trả về lỗi (status code != 200)
              String errorMessage = 'Không thể đặt mật khẩu mới.';
              try {
                  final errorBody = jsonDecode(response.body);
                  if (errorBody is Map && errorBody.containsKey('message')) {
                     errorMessage = errorBody['message'];
                  } else if (errorBody is String && errorBody.isNotEmpty) {
                     errorMessage = errorBody;
                  }
              } catch(_) {}

               if (kDebugMode) {
                  print('API Error during set new password: ${response.statusCode}, Message: $errorMessage');
              }
              throw Exception(errorMessage); // Ném Exception
          }
      }catch (e) {
           if (kDebugMode) print('SocketException during set new password: $e');
          throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.'); // Ném Exception mạng
      } 
  }

  // Method to reset password using token
  Future<bool> resetPassword(String token, String newPassword) async {
    final url = Uri.parse('$baseUrl/api/users/reset-password');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'token': token, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        return true; // Password reset successfully
      } else {
        print('Failed to reset password: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }


  // Method to upload an image file to the server
  Future<String?> uploadImage(List<int> imageBytes, String fileName) async {
    final url = Uri.parse('$baseUrl/api/images/upload');

    try {
      // Create a multipart request for the image upload
      final request = http.MultipartRequest('POST', url);

      // Add authorization header if user is logged in
      if (UserInfo().authToken != null) {
        request.headers['Authorization'] = 'Bearer ${UserInfo().authToken}';
      }

      // Add the file to the request
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();

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

  // Method to update user's avatar
  Future<bool> updateUserAvatar(String filePath) async {
    try {
      // First upload the image
      final imagePath = await uploadImageFile(filePath);

      if (imagePath != null) {
        // Then update the user profile with the new avatar path
        final updatedUser =
            await updateCurrentUserProfile({'avatar': imagePath});

        if (updatedUser != null) {
          // Update the local UserInfo avatar
          UserInfo().currentUser?.avatar = imagePath;
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating user avatar: $e');
      return false;
    }
  }

  // TODO: Implement methods for admin endpoints if needed (getAllUsers, getUserById, deleteUser, getUserByEmail)
  // These would require sending the auth token and potentially checking user role on the client side as well,
  // although the backend should enforce access control.
}
