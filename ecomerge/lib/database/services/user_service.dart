import 'dart:convert';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart'; // Assuming User model is here
import '/database/database_helper.dart'; // Assuming DatabaseHelper is here
import '../database_helper.dart' as config;


class UserService {
  final String baseUrl = baseurl; // TODO: Replace with your actual backend URL
  String? _authToken; // To store JWT token
   final _httpClient = http.Client(); // Using http.Client for better testability
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
      // Sử dụng _httpClient đã khai báo ở trên
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

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // Store the token and user info in the singleton
        setAuthToken(responseBody['token']);
        UserInfo().updateUserInfo(responseBody);
        // Return true to indicate successful login
        print('Login successful---------------------------------------------------: ${UserInfo().authToken}');
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

  // Method to get current authenticated user's profile
  Future<User?> getCurrentUserProfile() async {
    final url = Uri.parse('$baseUrl/api/users/me');
    try {
      final response = await _httpClient.get(
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
      final response = await _httpClient.put(
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
      final response = await _httpClient.post(
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

  // TODO: Implement methods for admin endpoints if needed (getAllUsers, getUserById, deleteUser, getUserByEmail)
  // These would require sending the auth token and potentially checking user role on the client side as well,
  // although the backend should enforce access control.

  Future<User?> testRegistration({
    String email = 'hahehiho9999@gmail.com',
    String fullName = 'tai',
    String password = '123456',
    String address = 'afew  adff ', // Add address field
  }) async {
    final url = Uri.parse('$baseUrl/api/users/register');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'fullName': fullName,
          'password': password,
          'address': address, // Include address
        }),
      );

      print('Registration response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Assuming User.fromMap can handle UserDTO structure
        return User.fromMap(jsonDecode(response.body));
      } else {
        print('Failed to register user: ${response.statusCode}');
        print('Response body: ${response.body}');
        // You might want to return response.body for error messages
        return null;
      }
    } catch (e) {
      print('Error during user registration: $e');
      return null;
    }
  }
}
