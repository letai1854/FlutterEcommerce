import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../database/models/user_model.dart';
import '../services/user_service.dart';
import '../Storage/CartStorage.dart'; // Add import for CartStorage

class UserInfo extends ChangeNotifier {
  // Singleton instance
  static final UserInfo _instance = UserInfo._internal();

  // Avatar cache storage
  static final Map<String, Uint8List> _avatarCache = {};

  // Factory constructor to return the same instance
  factory UserInfo() {
    return _instance;
  }

  // Internal constructor
  UserInfo._internal();

  // Properties to store user data and token
  User? _currentUser;
  String? _authToken = "";

  // Getters for the stored data
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoggedIn => _authToken != null && _authToken!.isNotEmpty;

  // Public getter for the avatar cache
  static Map<String, Uint8List> get avatarCache => _avatarCache;

  // Method to update user info after login
  void updateUserInfo(Map<String, dynamic> loginResponse) async {
    if (loginResponse['token'] != null) {
      _authToken = loginResponse['token'];
    }
    if (loginResponse['user'] != null) {
      _currentUser = User.fromMap(loginResponse['user']);
    }
    
    // Sync cart data after successful login
    await syncCartAfterLogin();
    
    notifyListeners(); // Notify listeners about the change
  }

  // Enhanced method to sync cart data after login
  Future<void> syncCartAfterLogin() async {
    if (!isLoggedIn) return; // Skip if not logged in
    
    try {
      print('Starting cart synchronization after login...');
      final cartStorage = CartStorage();
      
      // Call the enhanced syncCartWithServer method that handles merging properly
      await cartStorage.syncCartWithServer();
      
      print('Cart data successfully synced and merged after login');
    } catch (e) {
      print('Error syncing cart data after login: $e');
    }
  }

  // Method to update specific user properties
  void updateUserProperty(String property, dynamic value) {
    if (_currentUser != null) {
      switch (property) {
        case 'fullName':
          _currentUser = User(
            id: _currentUser!.id,
            email: _currentUser!.email,
            fullName: value,
            avatar: _currentUser!.avatar,
            role: _currentUser!.role,
            status: _currentUser!.status,
            customerPoints: _currentUser!.customerPoints,
            createdDate: _currentUser!.createdDate,
            updatedDate: _currentUser!.updatedDate,
          );
          break;
        case 'avatar':
          _currentUser!.avatar = value;
          break;
      }
      notifyListeners(); // Notify listeners about the change
    }
  }

  // Method to clear user info on logout
  void clearUserInfo() {
    _currentUser = null;
    _authToken = null;
    notifyListeners(); // Notify listeners about the change
  }

  // Global logout method that can be called from anywhere
  void logout(BuildContext context) {
    clearUserInfo();

    // Also clear stored credentials from local storage for non-web platforms
    if (!kIsWeb) {
      UserService().clearStoredCredentials();
      print('Local stored credentials cleared during logout');
    }

    // Navigate to home page and clear navigation stack
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  // Method to get user avatar URL
  String? getUserAvatar() {
    return _currentUser?.avatar;
  }
}
