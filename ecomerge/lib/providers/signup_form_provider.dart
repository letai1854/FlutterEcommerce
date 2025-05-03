import 'package:flutter/material.dart';

class SignupFormProvider extends ChangeNotifier {
  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController rePasswordController = TextEditingController();

  // Location state
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedWard = '';

  // Error state
  String? _errorMessage;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isRePasswordVisible = false;

  // Getters
  String get selectedProvince => _selectedProvince;
  String get selectedDistrict => _selectedDistrict;
  String get selectedWard => _selectedWard;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isRePasswordVisible => _isRePasswordVisible;

  // Setters
  void setLocation(String province, String district, String ward) {
    _selectedProvince = province;
    _selectedDistrict = district;
    _selectedWard = ward;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleRePasswordVisibility() {
    _isRePasswordVisible = !_isRePasswordVisible;
    notifyListeners();
  }

  // Cleanup
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    addressController.dispose();
    rePasswordController.dispose();
    super.dispose();
  }
}
