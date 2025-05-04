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
    if (includeAuth && UserInfo().authToken != null) {
      _authToken = UserInfo().authToken;
      headers['Authorization'] = 'Bearer $_authToken';
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
      final response = await _httpClient.post(
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

  // Method to request password reset (Forgot Password)
  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/api/users/forgot-password');
    try {
      final response = await _httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true; // Request successful (backend sends email if user exists)
      } else {
        print('Failed to request password reset: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error requesting password reset: $e');
      return false;
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
