import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../database/models/user_model.dart';

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
  String? _authToken;

  // Getters for the stored data
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;

  // Public getter for the avatar cache
  static Map<String, Uint8List> get avatarCache => _avatarCache;

  // Static getter to check if the user is logged in
  static bool get isLoggedIn => _instance._currentUser != null;

  // Method to update user info after login
  void updateUserInfo(Map<String, dynamic> loginResponse) {
    if (loginResponse['token'] != null) {
      _authToken = loginResponse['token'];
    }
    if (loginResponse['user'] != null) {
      _currentUser = User.fromMap(loginResponse['user']);
    }
    notifyListeners(); // Notify listeners about the change
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

  // Method to get user avatar URL
  String? getUserAvatar() {
    return _currentUser?.avatar;
  }
}
