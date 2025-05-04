import 'package:flutter/material.dart';

class LoginFormProvider extends ChangeNotifier {
  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State variables
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Flag to track if this is a fresh login attempt or a screen resize
  bool _isScreenResize = false;

  // Getters
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isScreenResize => _isScreenResize;

  // Setters
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // Set the screen resize flag
  void setScreenResize(bool value) {
    _isScreenResize = value;
  }

  // Reset all form data - call this when navigating away
  void resetForm() {
    // Only clear form if it's not during a screen resize
    if (!_isScreenResize) {
      emailController.clear();
      passwordController.clear();
      _isPasswordVisible = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cleanup
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
