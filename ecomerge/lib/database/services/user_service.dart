import 'dart:convert';
import 'package:e_commerce_app/database/database_helper.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart'; // Assuming User model is here

class UserService {
  final String baseUrl = baseurl; // TODO: Replace with your actual backend URL
  String? _authToken; // To store JWT token

  // Method to set the authentication token after login
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Helper to get headers, including auth token if available
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Method to register a new user
  Future<User?> registerUser(User user) async {
    final url = Uri.parse('$baseUrl/api/users/register');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(user.toMap()),
      );

      if (response.statusCode == 201) {
        // User created successfully
        return User.fromMap(jsonDecode(response.body));
      } else {
        // Handle other status codes (e.g., 409 Conflict for email exists)
        print('Failed to register user: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      // Handle network errors
      print('Error during user registration: $e');
      return null;
    }
  }

  // Method to login user
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/users/login');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // Store the token
        if (responseBody['token'] != null) {
          setAuthToken(responseBody['token']);
        }
        // Return the full response body (includes token and user DTO)
        return responseBody;
      } else {
        print('Failed to login user: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during user login: $e');
      return null;
    }
  }

  // Method to get current authenticated user's profile
  Future<User?> getCurrentUserProfile() async {
    final url = Uri.parse('$baseUrl/api/users/me');
    try {
      final response = await http.get(
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
      final response = await http.put(
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
  Future<bool> changeCurrentUserPassword(String oldPassword, String newPassword) async {
    final url = Uri.parse('$baseUrl/api/users/me/change-password');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
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
      final response = await http.post(
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
      final response = await http.post(
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
}
