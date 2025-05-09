import 'dart:io';
import 'dart:convert';

import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/database_helper.dart';
import 'package:e_commerce_app/database/models/UserDTO.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class AdminUserService {
  final String baseUrl = baseurl;
  late final http.Client httpClient;
  
  AdminUserService() {
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
  
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    final userInfo = UserInfo();
    if (includeAuth && userInfo.authToken != null) {
      headers['Authorization'] = 'Bearer ${userInfo.authToken}';
    }

    return headers;
  }
  
  // Get all users
  Future<List<UserDTO>> getAllUsers() async {
    final url = Uri.parse('$baseUrl/api/users');
    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('Raw API response: $jsonList');
        
        final users = jsonList.map((json) => UserDTO.fromJson(json)).toList();
        print('Parsed user count: ${users.length}');
        
        // Print detailed role information
        Map<String, int> roleCount = {};
        for (var user in users) {
          final role = user.role ?? 'unknown';
          roleCount[role] = (roleCount[role] ?? 0) + 1;
        }
        print('Role counts: $roleCount');
        
        return users;
      } else if (response.statusCode == 204) {
        print('No users found (204 status)');
        return [];
      } else {
        print('Failed to load users: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error retrieving all users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<UserDTO?> getUserById(int id) async {
    final url = Uri.parse('$baseUrl/api/users/$id');
    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );
      
      if (response.statusCode == 200) {
        return UserDTO.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        print('User with ID $id not found');
        return null;
      } else {
        print('Failed to load user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error retrieving user by ID: $e');
      return null;
    }
  }

  // Get user by email
  Future<UserDTO?> getUserByEmail(String email) async {
    final url = Uri.parse('$baseUrl/api/users/email/$email');
    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );
      
      if (response.statusCode == 200) {
        return UserDTO.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        print('User with email $email not found');
        return null;
      } else {
        print('Failed to load user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error retrieving user by email: $e');
      return null;
    }
  }

  // Update user
  Future<UserDTO?> updateUser(int id, Map<String, dynamic> userUpdates) async {
    final url = Uri.parse('$baseUrl/api/users/$id');
    try {
      final response = await httpClient.put(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(userUpdates),
      );
      
      if (response.statusCode == 200) {
        return UserDTO.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        print('User with ID $id not found');
        return null;
      } else {
        print('Failed to update user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating user: $e');
      return null;
    }
  }
  
  // Reset password method
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    final url = Uri.parse('$baseUrl/api/users/reset-password');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'verificationCode': code,
          'newPassword': newPassword,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
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
}
