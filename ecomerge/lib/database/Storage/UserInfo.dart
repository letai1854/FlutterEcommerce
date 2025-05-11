import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/models/user_model.dart';
import '../services/user_service.dart';
import '../Storage/CartStorage.dart';

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
  UserInfo._internal() {
    // Load saved user data when instance is created
    loadUserData();
  }

  // Properties to store user data and token
  User? _currentUser;
  String? _authToken = "";

  // Keys for SharedPreferences
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  // Getters for the stored data
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoggedIn => _authToken != null && _authToken!.isNotEmpty;

  // Public getter for the avatar cache
  static Map<String, Uint8List> get avatarCache => _avatarCache;

  // Method to load user data from SharedPreferences
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);
      
      if (userJson != null) {
        _currentUser = User.fromMap(jsonDecode(userJson));
      }
      
      if (token != null) {
        _authToken = token;
      }
      
      notifyListeners();
      print('User data loaded from local storage');
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Method to save user data to SharedPreferences
  Future<void> saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_currentUser != null) {
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toMap()));
      } else {
        await prefs.remove(_userKey);
      }
      
      if (_authToken != null) {
        await prefs.setString(_tokenKey, _authToken!);
      } else {
        await prefs.remove(_tokenKey);
      }
      
      print('User data saved to local storage');
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Method to update user info after login
  void updateUserInfo(Map<String, dynamic> loginResponse) async {
    if (loginResponse['token'] != null) {
      _authToken = loginResponse['token'];
    }
    if (loginResponse['user'] != null) {
      _currentUser = User.fromMap(loginResponse['user']);
    }
    
    // Save user data to local storage after updating
    await saveUserData();
    
    // First notify listeners that login state has changed
    notifyListeners();
    
    // Then sync cart data after successful login
    await syncCartAfterLogin();
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
    
    // Save changes to local storage
    saveUserData();
  }

  // Update customer points and notify listeners
  void updateCustomerPoints(double newPoints) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        fullName: _currentUser!.fullName,
        avatar: _currentUser!.avatar,
        role: _currentUser!.role,
        status: _currentUser!.status,
        customerPoints: newPoints,
        createdDate: _currentUser!.createdDate,
        updatedDate: _currentUser!.updatedDate,
      );
      print('Updated customer points to: $newPoints');
      notifyListeners(); // Notify listeners about the change
    }
    
    // Save changes to local storage
    saveUserData();
  }

  // Method to clear user info on logout
  void clearUserInfo() {
    _currentUser = null;
    _authToken = null;
    
    // Clear saved data from local storage
    saveUserData();
    
    notifyListeners(); // Notify listeners about the change
  }

  // Global logout method that can be called from anywhere
  Future<void> logout(BuildContext context) async {
    // Call the UserService logout method which handles server logout and clearing credentials
    await UserService().logout();

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
