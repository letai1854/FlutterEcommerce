import '../../database/models/user_model.dart'; // Assuming User model is here

class UserInfo {
  // Singleton instance
  static final UserInfo _instance = UserInfo._internal();

  // Factory constructor to return the same instance
  factory UserInfo() {
    return _instance;
  }

  // Internal constructor
  UserInfo._internal();

  // Properties to store user data and token
  User? _currentUser;
  String? _authToken="";

  // Getters for the stored data
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;

  // Method to update user info after login
  void updateUserInfo(Map<String, dynamic> loginResponse) {
    if (loginResponse['token'] != null) {
      _authToken = loginResponse['token'];
    }
    if (loginResponse['user'] != null) {
      _currentUser = User.fromMap(loginResponse['user']);
    }
  }

  // Method to clear user info on logout
  void clearUserInfo() {
    _currentUser = null;
    _authToken = null;
  }
}
