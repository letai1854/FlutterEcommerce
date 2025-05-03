import 'dart:convert'; // Keep for potential future use, though direct json encoding is moved
import 'dart:math';
import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:e_commerce_app/services/user_api_service.dart'; // Import the new service
import 'package:e_commerce_app/services/api_service.dart'; // Import ApiException if needed for specific handling
import '../Models/User_model.dart';

class UserController {
  // Instantiate the UserApiService
  final UserApiService _userApiService = UserApiService();

  int generateChatId() {
    return Random().nextInt(25) + 1; // Returns 1-25
  }

  // Đăng ký
  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final chatId = generateChatId();

      // Prepare data, keeping business logic here
      final requestData = {
        'email': userData['email'],
        'fullName': userData['full_name'], // Ensure key matches API expectation
        'password': userData['password'],
        'address': userData['address'],
        'role': 'customer',
        'status': true,
        'customerPoints': 0,
        'chatId': chatId,
        'createdDate': DateTime.now().toIso8601String()
      };

      // Delegate API call to the service
      final user = await _userApiService.registerUser(requestData);
      return user;
    } on ApiException catch (e) {
      print('Registration failed: ${e.message} (Status: ${e.statusCode})');
      rethrow;
    } catch (e) {
      print('Unexpected error during registration: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn trong quá trình đăng ký.');
    }
  }

  Future<User> login(String email, String password) async {
    try {
      // Delegate API call to the service
      final user = await _userApiService.loginUser(email, password);

      // Store user in provider after successful login
      UserProvider().setUser(user);
      if (UserProvider().currentUser != null) {
        print('User Logged In: ${UserProvider().currentUser!.fullName}');
      }
      return user;
    } on ApiException catch (e) {
      print('Login failed: ${e.message} (Status: ${e.statusCode})');
      rethrow;
    } catch (e) {
      print('Unexpected error during login: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn trong quá trình đăng nhập.');
    }
  }

  // Cập nhật thông tin user
  Future<User> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      // Delegate API call to the service
      final updatedUser = await _userApiService.updateUser(userId, updateData);
      return updatedUser;
    } on ApiException catch (e) {
      print('Update failed: ${e.message} (Status: ${e.statusCode})');
      rethrow;
    } catch (e) {
      print('Unexpected error during update: $e');
      throw Exception('Đã xảy ra lỗi không mong muốn trong quá trình cập nhật.');
    }
  }
}
